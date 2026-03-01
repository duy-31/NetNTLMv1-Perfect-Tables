# ============================
# CONFIGURATION
# ============================
$BaseUrl      = "https://storage.googleapis.com/storage/v1/b/net-ntlmv1-tables/o?prefix=tables/"
$RootPath     = "L:\duy-31-mandiant-ntlmv1\ntlmv1"
$SortCommand  = "L:\duy-31-mandiant-ntlmv1\rainbowcrack-1.8-win64\rtsort.exe"
$RtcCommand   = "L:\duy-31-mandiant-ntlmv1\rainbowcrack-1.8-win64\rt2rtc.exe"
$OutputPath   = "H:\NTLMv1\"

# --- RÉGLAGE DE REPRISE ---
$IndexDeReprise = 0  # Changez ce nombre pour sauter manuellement les premiers index (ex: 500)

# Fonction pour mettre à jour le titre de la console
function Write-Title {
    param([string]$Text)
    $Host.UI.RawUI.WindowTitle = $Text
}

# ============================
# RÉCUPÉRATION DE LA LISTE (API)
# ============================
Write-Host "--- Récupération de la liste des fichiers (API) ---" -ForegroundColor Cyan
$AllItems = [System.Collections.Generic.List[PSObject]]::new()
$Token = ""

do {
    $Uri = if ([string]::IsNullOrEmpty($Token)) { $BaseUrl } else { "$BaseUrl&pageToken=$Token" }
    try {
        $Response = Invoke-RestMethod -Uri $Uri
        if ($Response.items) {
            $Response.items | ForEach-Object { $AllItems.Add($_) }
            Write-Host "Fichiers trouvés : $($AllItems.Count)..." -ForegroundColor Gray
        }
        $Token = $Response.nextPageToken
    } catch {
        Write-Host "Erreur API : $($_.Exception.Message)" -ForegroundColor Red
        break
    }
} while ($Token)

# ============================
# TRI NUMÉRIQUE
# ============================
Write-Host "Tri des données en cours..." -ForegroundColor Green
$SortedItems = $AllItems | ForEach-Object {
    $FName = $_.name.Replace("tables/","")
    if ($FName -notlike "*.rt") { return $null }

    $BName = [System.IO.Path]::GetFileNameWithoutExtension($FName)
    $IndexStr = ($BName -split "_")[-1]
    
    $Idx = 0
    if ([int]::TryParse($IndexStr, [ref]$Idx)) {
        [PSCustomObject]@{
            Index    = $Idx
            Item     = $_
            FileName = $FName
            BaseName = $BName
        }
    }
} | Where-Object { $null -ne $_ } | Sort-Object Index

# ============================
# BOUCLE DE TRAITEMENT
# ============================
foreach ($Entry in $SortedItems) {
    $Index = $Entry.Index
    
    # 1. SKIP MANUEL (via la variable en haut)
    if ($Index -lt $IndexDeReprise) {
        continue
    }

    $TargetLocalDir   = Join-Path $RootPath $Index
    $FinalDestination = Join-Path $OutputPath $Index
    $LocalFile        = Join-Path $TargetLocalDir $Entry.FileName

    # 2. SKIP AUTOMATIQUE (Vérification sur N:)
    # On skip si le dossier existe ET n'est pas vide
    if (Test-Path $FinalDestination) {
        $ExistingFiles = Get-ChildItem $FinalDestination -ErrorAction SilentlyContinue
        if ($ExistingFiles.Count -gt 0) {
            Write-Host "Index $Index : Déjà présent sur $OutputPath. Passage au suivant." -ForegroundColor DarkGray
            continue
        }
    }

    # Mise à jour du titre et affichage console
    $Remaining = $SortedItems.Count - ($SortedItems.IndexOf($Entry))
    Write-Title "Reste : $Remaining | Index : $Index"
    Write-Host "`n=== [$(Get-Date -Format 'HH:mm:ss')] TRAITEMENT INDEX : $Index ===" -ForegroundColor Cyan

    try {
        # 3. Création dossier local
        if (!(Test-Path $TargetLocalDir)) { New-Item -ItemType Directory -Path $TargetLocalDir -Force | Out-Null }

        # 4. Téléchargement (BITS)
        Write-Host " -> Étape 1 : Téléchargement..." -NoNewline
        Start-BitsTransfer -Source $Entry.Item.mediaLink -Destination $LocalFile -DisplayName "RT-Download-$Index"
        Write-Host " OK." -ForegroundColor Green

        # 5. Tri (rtsort)
        Write-Host " -> Étape 2 : rtsort..." -ForegroundColor Yellow
        & $SortCommand $TargetLocalDir
        if ($LASTEXITCODE -ne 0) { throw "Erreur lors du rtsort" }

        # 6. Compression (rt2rtc)
        Write-Host " -> Étape 3 : rt2rtc..." -ForegroundColor Magenta
        $CurrentDir = Get-Location
        Set-Location $TargetLocalDir
        & $RtcCommand "." -s 32 -e 48 -c 512 -p
        $StatusRTC = $LASTEXITCODE
        Set-Location $CurrentDir
        
        if ($StatusRTC -ne 0) { throw "Erreur lors du rt2rtc" }

        # 7. Nettoyage et Déplacement
        Write-Host " -> Étape 4 : Finalisation..." -ForegroundColor Green
        if (Test-Path $LocalFile) { Remove-Item $LocalFile -Force } # Supprime le .rt lourd

        if (!(Test-Path $FinalDestination)) { New-Item -ItemType Directory -Path $FinalDestination -Force | Out-Null }
        Move-Item -Path "$TargetLocalDir\*" -Destination $FinalDestination -Force -Confirm:$false
        Remove-Item $TargetLocalDir -Recurse -Force

    } catch {
        Write-Host "[ERREUR] Problème sur l'index $Index : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Pause de 5 secondes avant la suite..."
        Start-Sleep -Seconds 5
    }
}

Write-Host "`nTRAVAIL TERMINÉ !" -ForegroundColor White -BackgroundColor DarkGreen
