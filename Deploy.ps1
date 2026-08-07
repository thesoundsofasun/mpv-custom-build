<#
.SYNOPSIS
    Web Deployment Script for MPV Custom Build
    Installs MPV, downloads dependencies (yt-dlp, ffprobe, FluidSynth), and pulls configs/icons.
#>

# =================================================================================
# 1. REQUIRE ADMIN RIGHTS
# =================================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Restarting script with Administrator privileges..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Force TLS 1.2 for web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Starting MPV Web Deployment (from GitHub)" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# =================================================================================
# 2. INSTALL MPV VIA WINGET
# =================================================================================
Write-Host "[1/7] Installing Shinchiro MPV via winget..." -ForegroundColor Yellow
$wingetArgs = "install --id shinchiro.mpv --exact --silent --accept-package-agreements --accept-source-agreements"
Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow

# =================================================================================
# 3. DYNAMICALLY LOCATE MPV.EXE
# =================================================================================
Write-Host "[2/7] Locating MPV installation..." -ForegroundColor Yellow

$installDir = $null
$possiblePaths = @(
    "C:\Program Files\mpv\mpv.exe",
    "C:\Program Files\MPV Player\mpv.exe",
    "C:\Program Files\MPV Player\mpv\mpv.exe",
    "$env:LOCALAPPDATA\Programs\mpv\mpv.exe",
    "$env:LOCALAPPDATA\mpv\mpv.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $installDir = Split-Path $path
        break
    }
}

if (-not $installDir) { $installDir = "C:\Program Files\MPV Player" }

Write-Host "      -> MPV located at: $installDir" -ForegroundColor Green

$installerFolder = Join-Path $installDir "installer"
if (-not (Test-Path $installerFolder)) { New-Item -Path $installerFolder -ItemType Directory -Force | Out-Null }

# =================================================================================
# 4. DOWNLOAD DEPENDENCIES (yt-dlp, ffprobe, FluidSynth)
# =================================================================================
Write-Host "[3/7] Downloading latest dependencies..." -ForegroundColor Yellow

try {
    # --- YT-DLP ---
    Write-Host "      -> Fetching latest yt-dlp..." -ForegroundColor DarkGray
    $ytApi = Invoke-RestMethod -Uri "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
    $ytUrl = ($ytApi.assets | Where-Object { $_.name -eq "yt-dlp.exe" }).browser_download_url
    Invoke-WebRequest -Uri $ytUrl -OutFile "$installDir\yt-dlp.exe"

    # --- FFPROBE ---
    Write-Host "      -> Fetching latest ffprobe (win-64)..." -ForegroundColor DarkGray
    $ffApi = Invoke-RestMethod -Uri "https://api.github.com/repos/ffbinaries/ffbinaries-prebuilt/releases/latest"
    $ffUrl = ($ffApi.assets | Where-Object { $_.name -match "ffprobe-.*win-64\.zip" }).browser_download_url
    
    $tempZip = "$env:TEMP\ffprobe_temp.zip"
    $tempExtract = "$env:TEMP\ffprobe_extract"
    Invoke-WebRequest -Uri $ffUrl -OutFile $tempZip
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    Move-Item -Path "$tempExtract\ffprobe.exe" -Destination "$installDir\ffprobe.exe" -Force
    Remove-Item $tempZip, $tempExtract -Recurse -Force

    # --- FLUIDSYNTH (v2.3.5) ---
    Write-Host "      -> Fetching FluidSynth v2.3.5..." -ForegroundColor DarkGray
    $fluidUrl = "https://github.com/FluidSynth/fluidsynth/releases/download/v2.3.5/fluidsynth-2.3.5-win10-x64.zip"
    $fluidZip = "$env:TEMP\fluid_temp.zip"
    $fluidExtract = "$env:TEMP\fluid_extract"
    $midiSynthDir = Join-Path $installDir "midi-synth"
    
    if (-not (Test-Path $midiSynthDir)) { New-Item -Path $midiSynthDir -ItemType Directory -Force | Out-Null }
    
    Invoke-WebRequest -Uri $fluidUrl -OutFile $fluidZip
    if (Test-Path $fluidExtract) { Remove-Item $fluidExtract -Recurse -Force }
    Expand-Archive -Path $fluidZip -DestinationPath $fluidExtract -Force
    
    # Move the contents of the FluidSynth 'bin' folder to our midi-synth folder
    Copy-Item -Path "$fluidExtract\fluidsynth-2.3.5-win10-x64\bin\*" -Destination $midiSynthDir -Recurse -Force
    Remove-Item $fluidZip, $fluidExtract -Recurse -Force

    Write-Host "         Done! Dependencies installed." -ForegroundColor Green
} catch {
    Write-Host "      -> ERROR downloading dependencies: $($_.Exception.Message)" -ForegroundColor Red
}

# =================================================================================
# 5. PULL FULL REPO AS ZIP (Configs & Installer Base)
# =================================================================================
Write-Host "[4/7] Downloading configurations from GitHub repo..." -ForegroundColor Yellow

$repoZipUrl = "https://github.com/thesoundsofasun/mpv-custom-build/archive/refs/heads/main.zip"
$repoTempZip = "$env:TEMP\mpv_repo_temp.zip"
$repoExtract = "$env:TEMP\mpv_repo_extract"

if (Test-Path $repoExtract) { Remove-Item $repoExtract -Recurse -Force }
Invoke-WebRequest -Uri $repoZipUrl -OutFile $repoTempZip
Expand-Archive -Path $repoTempZip -DestinationPath $repoExtract -Force

$repoRoot = Join-Path $repoExtract "mpv-custom-build-main"

# =================================================================================
# 6. DISTRIBUTE FILES (Appdata & Program Files)
# =================================================================================
Write-Host "[5/7] Distributing base repository files..." -ForegroundColor Yellow

# Copy the "config" folder to %AppData%\mpv
$appDataDest = "$env:APPDATA\mpv"
$appDataSource = Join-Path $repoRoot "config"
if (-not (Test-Path $appDataDest)) { New-Item -Path $appDataDest -ItemType Directory -Force | Out-Null }
Copy-Item -Path "$appDataSource\*" -Destination $appDataDest -Recurse -Force

# Copy the "installer" folder to MPV's installer folder
$installerSource = Join-Path $repoRoot "installer"
Copy-Item -Path "$installerSource\*" -Destination $installerFolder -Recurse -Force

Write-Host "      -> Base Repo distributed successfully." -ForegroundColor Green

# =================================================================================
# 7. EXPLICIT RAW DOWNLOADS (Soundfont, Icon, Idle UI)
# =================================================================================
Write-Host "[6/7] Fetching explicitly requested raw files..." -ForegroundColor Yellow

try {
    # Download Soundfont directly to midi-synth folder
    Write-Host "      -> Downloading soundfont.sf2..." -ForegroundColor DarkGray
    $sf2Url = "https://raw.githubusercontent.com/thesoundsofasun/mpv-custom-build/main/resources/soundfont.sf2"
    Invoke-WebRequest -Uri $sf2Url -OutFile "$midiSynthDir\soundfont.sf2"

    # Download idle_ui.lua directly to AppData/mpv/scripts
    Write-Host "      -> Downloading idle_ui.lua..." -ForegroundColor DarkGray
    $idleUrl = "https://raw.githubusercontent.com/thesoundsofasun/mpv-custom-build/main/config/scripts/idle_ui.lua"
    $scriptsDir = "$appDataDest\scripts"
    if (-not (Test-Path $scriptsDir)) { New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $idleUrl -OutFile "$scriptsDir\idle_ui.lua"

    # Download mpv-icon.ico directly to installer folder (overwriting the old one)
    Write-Host "      -> Downloading new mpv-icon.ico..." -ForegroundColor DarkGray
    $iconUrl = "https://raw.githubusercontent.com/thesoundsofasun/mpv-custom-build/main/installer/mpv-icon.ico"
    Invoke-WebRequest -Uri $iconUrl -OutFile "$installerFolder\mpv-icon.ico"
    
    Write-Host "         Done! Raw files successfully updated." -ForegroundColor Green
} catch {
    Write-Host "      -> ERROR fetching raw files: $($_.Exception.Message)" -ForegroundColor Red
}

# =================================================================================
# 8. AUTORUN THE CUSTOM BATCH SCRIPT & CLEANUP
# =================================================================================
Write-Host "[7/7] Executing custom mpv-install.bat..." -ForegroundColor Yellow
$batScriptPath = Join-Path $installerFolder "mpv-install.bat"

if (Test-Path $batScriptPath) {
    Start-Process -FilePath $batScriptPath -Wait -NoNewWindow
    Write-Host "      -> File associations and icons applied successfully." -ForegroundColor Green
} else {
    Write-Host "      -> ERROR: mpv-install.bat not found." -ForegroundColor Red
}

# Cleanup the downloaded GitHub Zip to keep the PC clean
Remove-Item $repoTempZip, $repoExtract -Recurse -Force

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host " MPV Setup is Complete! Enjoy your music." -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5
