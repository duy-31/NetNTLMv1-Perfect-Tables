# ============================
# CONFIGURATION
# ============================
$ListUrl = "https://storage.googleapis.com/storage/v1/b/net-ntlmv1-tables/o?prefix=tables/"
$RootPath = "L:\duy-31-mandiant-ntlmv1\ntlmv1"
$SortCommand = "L:\duy-31-mandiant-ntlmv1\rainbowcrack-1.8-win64\rtsort.exe"
$RtcCommand = "L:\duy-31-mandiant-ntlmv1\rainbowcrack-1.8-win64\rt2rtc.exe"
$OutputPath = "H:\NTLMv1\"

# Création du dossier racine si inexistant
if (!(Test-Path $RootPath)) { New-Item -ItemType Directory -Path $RootPath | Out-Null }
if (!(Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }

# ============================
# LECTURE DE LA LISTE JSON ET FILTRE
# ============================
$json = Invoke-RestMethod -Uri $ListUrl
if (-not $json.items) { Write-Host "Aucun fichier trouvé."; exit }

# --- MODIFICATION POUR REPRISE ---
$IndexDeReprise = 1719
# ---------------------------------

foreach ($item in $json.items) {
    $FileName = $item.name.Replace("tables/","")
    if ($FileName -eq "" -or $FileName -notlike "*.rt") { continue }

    # Extraction de l'index (ex: ..._0.rt -> 0)
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $IndexStr = ($BaseName -split "_")[-1]
    
    # Conversion en entier pour une comparaison fiable
    [int]$Index = 0
    if (-not [int]::TryParse($IndexStr, [ref]$Index)) { continue }

    # Sauter si l'index est inférieur à 1719
    if ($Index -lt $IndexDeReprise) {
        continue
    }

    # Définition des chemins
    $TargetLocalDir = Join-Path $RootPath $Index
    $LocalFile = Join-Path $TargetLocalDir $FileName
    $FinalDestination = Join-Path $OutputPath $Index
    $ExpectedRtcFile = Join-Path $FinalDestination "$BaseName.rtc"

    # ============================
    # LOGIQUE DE REPRISE (RESUME)
    # ============================
    # On vérifie si le fichier .rtc final existe déjà dans le dossier de destination sur H:
    if (Test-Path $ExpectedRtcFile) {
        Write-Host ">>> Index $Index déjà traité (présent sur H:). Passage au suivant." -ForegroundColor Gray
        continue
    }

    Write-Host "`n=== TRAITEMENT INDEX : $Index ===" -ForegroundColor Cyan

    # 1. Création du répertoire local de travail
    if (!(Test-Path $TargetLocalDir)) { New-Item -ItemType Directory -Path $TargetLocalDir | Out-Null }

    # 2. Téléchargement directement dans le dossier de l'index
    if (!(Test-Path $LocalFile)) {
        Write-Host "Étape 1 : Téléchargement de $FileName..."
        try {
            Start-BitsTransfer -Source $item.mediaLink -Destination $LocalFile -DisplayName "RT-$Index" -ErrorAction Stop
        } catch {
            Write-Host "Erreur de téléchargement pour l'index $Index. On passe au suivant." -ForegroundColor Red
            continue
        }
    }

    # 3. Exécution de rtsort
    Write-Host "Étape 2 : Tri (rtsort)..." -ForegroundColor Yellow
    & $SortCommand $TargetLocalDir

    # 4. Exécution de rt2rtc
    Write-Host "Étape 3 : Conversion (rt2rtc)..." -ForegroundColor Magenta
    Push-Location $TargetLocalDir
    & $RtcCommand "." -s 32 -e 48 -c 512 -p
    Pop-Location

    # 5. Nettoyage du fichier .rt (sécurité si -p n'a pas fonctionné)
    if (Test-Path $LocalFile) {
        Write-Host "Étape 4 : Nettoyage du fichier source .rt"
        Remove-Item $LocalFile -Force
    }

    # 6. Déplacement du répertoire complet vers H:\
    Write-Host "Étape 5 : Déplacement vers $FinalDestination" -ForegroundColor Green
    try {
        if (Test-Path $FinalDestination) { 
            Move-Item -Path "$TargetLocalDir\*" -Destination $FinalDestination -Force -ErrorAction Stop
            Remove-Item $TargetLocalDir -Recurse -Force
        } else {
            Move-Item -Path $TargetLocalDir -Destination $OutputPath -Force -ErrorAction Stop
        }
    } catch {
        Write-Host "Erreur lors du déplacement : $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "=== Terminé pour l'index $Index ===" -ForegroundColor Green

}
