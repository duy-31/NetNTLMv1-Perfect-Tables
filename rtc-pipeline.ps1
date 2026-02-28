# ============================
# CONFIGURATION
# ============================
$BaseUrl = "https://storage.googleapis.com/storage/v1/b/net-ntlmv1-tables/o?prefix=tables/"
$RootPath = "L:\Desktop\windows-build\ntlmv1"
$SortCommand = "L:\Desktop\windows-build\rtsort.exe"
$RtcCommand = "L:\Desktop\windows-build\rt2rtc.exe"
$OutputPath = "H:\NTLMv1\"

# ============================
# RÉCUPÉRATION COMPLÈTE (GESTION PAGINATION)
# ============================
Write-Host "Récupération de la liste complète des fichiers (Pagination API)..." -ForegroundColor Cyan

$AllItems = @() # On utilise un tableau simple plus flexible
$Token = ""

do {
    # Construction de l'URL avec le token si présent
    $Uri = if ([string]::IsNullOrEmpty($Token)) { $BaseUrl } else { "$BaseUrl&pageToken=$Token" }
    
    try {
        $Response = Invoke-RestMethod -Uri $Uri
        
        if ($Response.items) {
            $AllItems += $Response.items # Accumulation simple
            Write-Host "Récupérés : $($AllItems.Count) éléments..." -ForegroundColor Gray
        }
        
        $Token = $Response.nextPageToken
    } catch {
        Write-Host "Erreur lors de la requête API : $($_.Exception.Message)" -ForegroundColor Red
        break
    }
} while ($Token)

Write-Host "Total récupéré : $($AllItems.Count) fichiers. Analyse et tri numérique..." -ForegroundColor Green

# ============================
# TRI NUMÉRIQUE
# ============================
$SortedItems = $AllItems | ForEach-Object {
    $FName = $_.name.Replace("tables/","")
    if ($FName -notlike "*.rt") { return $null }

    $BName = [System.IO.Path]::GetFileNameWithoutExtension($FName)
    $IndexStr = ($BName -split "_")[-1]
    
    [int]$Idx = 0
    if ([int]::TryParse($IndexStr, [ref]$Idx)) {
        [PSCustomObject]@{
            Index    = $Idx
            Item     = $_
            FileName = $FName
            BaseName = $BName
        }
    }
} | Where-Object { $_ -ne $null } | Sort-Object Index

# --- MODIFICATION POUR REPRISE ---
$IndexDeReprise = 0
# ---------------------------------

foreach ($Entry in $SortedItems) {
    Write-Title "Reste à traiter : $($SortedItems.Count - ($SortedItems.IndexOf($Entry)))"
    $Index = $Entry.Index
    if ($Index -lt $IndexDeReprise) { continue }

    $item = $Entry.Item
    $FileName = $Entry.FileName
    $BaseName = $Entry.BaseName

    $TargetLocalDir = Join-Path $RootPath $Index
    $FinalDestination = Join-Path $OutputPath $Index
    $LocalFile = Join-Path $TargetLocalDir $FileName

    # Vérification si déjà fait
    if (Test-Path $FinalDestination) {
        if (Get-ChildItem $FinalDestination -Filter "*.rtc") {
            Write-Host ">>> Index $Index déjà présent sur H:. Skip." -ForegroundColor Gray
            continue
        }
    }

    Write-Host "`n=== TRAITEMENT INDEX : $Index ===" -ForegroundColor Cyan

    # [Le reste de votre logique de traitement 1 à 6 reste identique ici]
    # 1. Dossier local
    if (!(Test-Path $TargetLocalDir)) { New-Item -ItemType Directory -Path $TargetLocalDir | Out-Null }

    # 2. Téléchargement
    Write-Host "Étape 1 : Téléchargement..."
    Start-BitsTransfer -Source $item.mediaLink -Destination $LocalFile -DisplayName "RT-$Index"

    # 3. Sort
    Write-Host "Étape 2 : rtsort..." -ForegroundColor Yellow
    & $SortCommand $TargetLocalDir

    # 4. Convert
    Write-Host "Étape 3 : rt2rtc..." -ForegroundColor Magenta
    $OldPath = Get-Location
    Set-Location $TargetLocalDir
    & $RtcCommand "." -s 32 -e 48 -c 512 -p
    Set-Location $OldPath

    # 5. Clean
    if (Test-Path $LocalFile) { Remove-Item $LocalFile -Force }

    # 6. Move
    Write-Host "Étape 4 : Déplacement vers H:..." -ForegroundColor Green
    if (!(Test-Path $FinalDestination)) { New-Item -ItemType Directory -Path $FinalDestination | Out-Null }
    Move-Item -Path "$TargetLocalDir\*" -Destination $FinalDestination -Force
    Remove-Item $TargetLocalDir -Recurse -Force
}
