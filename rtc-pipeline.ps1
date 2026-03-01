# ============================
# CONFIGURATION
# ============================
$BaseUrl      = "https://storage.googleapis.com/storage/v1/b/net-ntlmv1-tables/o?prefix=tables/"
$RootPath     = "L:\duy-31-mandiant-ntlmv1\ntlmv1"
$SortCommand  = "L:\duy-31-mandiant-ntlmv1\rainbowcrack-1.8-win64\rtsort.exe"
$RtcCommand   = "L:\duy-31-mandiant-ntlmv1\rainbowcrack-1.8-win64\rt2rtc.exe"
$OutputPath   = "H:\NTLMv1\"

# Helper function to update the console title
function Write-Title {
    param([string]$Text)
    $Host.UI.RawUI.WindowTitle = $Text
}

# ============================
# RÉCUPÉRATION COMPLÈTE (PAGINATION)
# ============================
Write-Host "--- Connexion à Google Storage API ---" -ForegroundColor Cyan
$AllItems = [System.Collections.Generic.List[PSObject]]::new()
$Token = ""

do {
    $Uri = if ([string]::IsNullOrEmpty($Token)) { $BaseUrl } else { "$BaseUrl&pageToken=$Token" }
    try {
        $Response = Invoke-RestMethod -Uri $Uri
        if ($Response.items) {
            $Response.items | ForEach-Object { $AllItems.Add($_) }
            Write-Host "Récupérés : $($AllItems.Count) éléments..." -ForegroundColor Gray
        }
        $Token = $Response.nextPageToken
    } catch {
        Write-Host "Erreur API : $($_.Exception.Message)" -ForegroundColor Red
        break
    }
} while ($Token)

# ============================
# TRI ET FILTRAGE NUMÉRIQUE
# ============================
Write-Host "Analyse et tri des fichiers..." -ForegroundColor Green
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
} | Where-Object { $_ -ne $null } | Sort-Object Index

# ============================
# BOUCLE DE TRAITEMENT PRINCIPALE
# ============================
foreach ($Entry in $SortedItems) {
    $Index = $Entry.Index
    $TargetLocalDir   = Join-Path $RootPath $Index
    $FinalDestination = Join-Path $OutputPath $Index
    $LocalFile        = Join-Path $TargetLocalDir $Entry.FileName

    # 1. Vérification d'existence (Skip automatique)
    if (Test-Path $FinalDestination) {
        if (Get-ChildItem $FinalDestination -Filter "*.rtc") {
            Write-Host "Index $Index : Déjà traité sur H:. Passage au suivant." -ForegroundColor DarkGray
            continue
        }
    }

    # Mise à jour du titre de la fenêtre
    $Remaining = $SortedItems.Count - ($SortedItems.IndexOf($Entry))
    Write-Title "Reste à traiter : $Remaining | Index actuel : $Index"

    Write-Host "`n=== [$(Get-Date -Format 'HH:mm:ss')] TRAITEMENT INDEX : $Index ===" -ForegroundColor Cyan

    try {
        # 2. Préparation Dossier
        if (!(Test-Path $TargetLocalDir)) { New-Item -ItemType Directory -Path $TargetLocalDir -Force | Out-Null }

        # 3. Téléchargement
        Write-Host " -> Étape 1 : Téléchargement..." -NoNewline
        Start-BitsTransfer -Source $Entry.Item.mediaLink -Destination $LocalFile -DisplayName "RT-Index-$Index"
        Write-Host " Terminé." -ForegroundColor Green

        # 4. Tri (rtsort)
        Write-Host " -> Étape 2 : rtsort (Tri disque)..." -ForegroundColor Yellow
        & $SortCommand $TargetLocalDir
        if ($LASTEXITCODE -ne 0) { throw "Erreur rtsort sur l'index $Index" }

        # 5. Conversion (rt2rtc)
        Write-Host " -> Étape 3 : rt2rtc (Compression)..." -ForegroundColor Magenta
        $OldPath = Get-Location
        Set-Location $TargetLocalDir
        & $RtcCommand "." -s 32 -e 48 -c 512 -p
        $ExitCode = $LASTEXITCODE
        Set-Location $OldPath
        
        if ($ExitCode -ne 0) { throw "Erreur rt2rtc sur l'index $Index" }

        # 6. Nettoyage Local (.rt volumineux)
        if (Test-Path $LocalFile) { Remove-Item $LocalFile -Force }

        # 7. Déplacement final vers H:
        Write-Host " -> Étape 4 : Déplacement vers $OutputPath" -ForegroundColor Green
        if (!(Test-Path $FinalDestination)) { New-Item -ItemType Directory -Path $FinalDestination -Force | Out-Null }
        
        # On déplace tout le contenu (fichiers .rtc et .idx)
        Move-Item -Path "$TargetLocalDir\*" -Destination $FinalDestination -Force
        
        # On supprime le dossier de travail vide
        Remove-Item $TargetLocalDir -Recurse -Force

    } catch {
        Write-Host "[ERREUR CRITIQUE] Index $Index : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Le script va tenter de passer à l'index suivant dans 10 secondes..."
        Start-Sleep -Seconds 10
    }
}

Write-Host "`nTerminé ! Tous les fichiers ont été traités." -ForegroundColor Cyan -BackgroundColor DarkBlue
