<#
.SYNOPSIS
    Web Deployment Script for MPV Custom Build
    Installs MPV, downloads dependencies (yt-dlp, ffprobe), and pulls configs/icons/synths natively from GitHub.
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
Write-Host "[1/6] Installing Shinchiro MPV via winget..." -ForegroundColor Yellow
$wingetArgs = "install --id shinchiro.mpv --exact --silent --accept-package-agreements --accept-source-agreements"
Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow

# =================================================================================
# 3. DYNAMICALLY LOCATE MPV.EXE
# =================================================================================
Write-Host "[2/6] Locating MPV installation..." -ForegroundColor Yellow

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
# 4. DOWNLOAD EXTERNAL DEPENDENCIES (yt-dlp, ffprobe)
# =================================================================================
Write-Host "[3/6] Downloading external dependencies..." -ForegroundColor Yellow

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

    Write-Host "         Done! External dependencies installed." -ForegroundColor Green
} catch {
    Write-Host "      -> ERROR downloading dependencies: $($_.Exception.Message)" -ForegroundColor Red
}

# =================================================================================
# 5. PULL FULL REPO AS ZIP
# =================================================================================
Write-Host "[4/6] Downloading repository files from GitHub..." -ForegroundColor Yellow

$repoZipUrl = "https://github.com/thesoundsofasun/mpv-custom-build/archive/refs/heads/main.zip"
$repoTempZip = "$env:TEMP\mpv_repo_temp.zip"
$repoExtract = "$env:TEMP\mpv_repo_extract"

if (Test-Path $repoExtract) { Remove-Item $repoExtract -Recurse -Force }
Invoke-WebRequest -Uri $repoZipUrl -OutFile $repoTempZip
Expand-Archive -Path $repoTempZip -DestinationPath $repoExtract -Force

$repoRoot = Join-Path $repoExtract "mpv-custom-build-main"

# =================================================================================
# 6. DISTRIBUTE FILES (Appdata, Installer, and Midi-Synth)
# =================================================================================
Write-Host "[5/6] Distributing repository files..." -ForegroundColor Yellow

# Copy the "config" folder to %AppData%\mpv (This handles mpv.conf, input.conf, idle_ui.lua, fonts, etc.)
$appDataDest = "$env:APPDATA\mpv"
$appDataSource = Join-Path $repoRoot "config"
if (-not (Test-Path $appDataDest)) { New-Item -Path $appDataDest -ItemType Directory -Force | Out-Null }
Copy-Item -Path "$appDataSource\*" -Destination $appDataDest -Recurse -Force
Write-Host "      -> Configs, Fonts, and Scripts applied." -ForegroundColor Green

# Copy the "installer" folder to MPV's installer folder (This handles mpviconlib.dll, mpv-icon.ico, and bat scripts)
$installerSource = Join-Path $repoRoot "installer"
Copy-Item -Path "$installerSource\*" -Destination $installerFolder -Recurse -Force
Write-Host "      -> Installer files applied." -ForegroundColor Green

# Copy the "midi-synth" folder directly into the MPV Player installation directory
$midiSynthSource = Join-Path $repoRoot "midi-synth"
$midiSynthDest = Join-Path $installDir "midi-synth"
if (Test-Path $midiSynthSource) {
    if (-not (Test-Path $midiSynthDest)) { New-Item -Path $midiSynthDest -ItemType Directory -Force | Out-Null }
    Copy-Item -Path "$midiSynthSource\*" -Destination $midiSynthDest -Recurse -Force
    Write-Host "      -> MIDI Synthesizer applied." -ForegroundColor Green
}

# (Optional fallback) If you left soundfont.sf2 in the 'resources' folder instead of 'midi-synth', copy it over!
$resourceSf2 = Join-Path $repoRoot "resources\soundfont.sf2"
if (Test-Path $resourceSf2) {
    Copy-Item -Path $resourceSf2 -Destination "$midiSynthDest\soundfont.sf2" -Force
}

# =================================================================================
# 7. AUTORUN THE CUSTOM BATCH SCRIPT & CLEANUP
# =================================================================================
Write-Host "[6/6] Executing custom mpv-install.bat..." -ForegroundColor Yellow
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
