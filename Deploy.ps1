<#
.SYNOPSIS
    Master Deployment Script for Custom MPV Audio Build
    Includes Winget install, dynamic dependency downloads (yt-dlp, ffprobe), and custom configs.
#>

# =================================================================================
# 1. REQUIRE ADMIN RIGHTS
# =================================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Restarting script with Administrator privileges..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Force TLS 1.2 for web requests (Required for GitHub API downloads)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Starting MPV Custom Build Deployment" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# =================================================================================
# 2. INSTALL MPV VIA WINGET
# =================================================================================
Write-Host "[1/6] Installing Shinchiro MPV via winget..." -ForegroundColor Yellow
$wingetArgs = "install --id shinchiro.mpv --exact --silent --accept-package-agreements --accept-source-agreements"
Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow

# =================================================================================
# 3. LOCATE THE INSTALLATION DIRECTORY
# =================================================================================
$installDir = "C:\Program Files\mpv"
if (Test-Path "C:\Program Files\MPV Player") { $installDir = "C:\Program Files\MPV Player" }

$installerFolder = Join-Path $installDir "installer"
if (-not (Test-Path $installerFolder)) { New-Item -Path $installerFolder -ItemType Directory -Force | Out-Null }

Write-Host "[2/6] MPV located at: $installDir" -ForegroundColor Green

# =================================================================================
# 4. DOWNLOAD DEPENDENCIES (yt-dlp.exe & ffprobe.exe)
# =================================================================================
Write-Host "[3/6] Downloading latest dependencies from GitHub..." -ForegroundColor Yellow

try {
    # --- YT-DLP ---
    Write-Host "      -> Fetching latest yt-dlp..." -ForegroundColor DarkGray
    $ytApi = Invoke-RestMethod -Uri "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
    $ytUrl = ($ytApi.assets | Where-Object { $_.name -eq "yt-dlp.exe" }).browser_download_url
    Invoke-WebRequest -Uri $ytUrl -OutFile "$installDir\yt-dlp.exe"
    Write-Host "         Done! yt-dlp.exe installed." -ForegroundColor Green

    # --- FFPROBE ---
    Write-Host "      -> Fetching latest ffprobe (win-64)..." -ForegroundColor DarkGray
    $ffApi = Invoke-RestMethod -Uri "https://api.github.com/repos/ffbinaries/ffbinaries-prebuilt/releases/latest"
    $ffUrl = ($ffApi.assets | Where-Object { $_.name -match "ffprobe-.*win-64\.zip" }).browser_download_url
    
    $tempZip = "$env:TEMP\ffprobe_temp.zip"
    $tempExtract = "$env:TEMP\ffprobe_extract"
    
    # Download and extract the zip
    Invoke-WebRequest -Uri $ffUrl -OutFile $tempZip
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    
    # Move ffprobe.exe to MPV folder and cleanup temp files
    Move-Item -Path "$tempExtract\ffprobe.exe" -Destination "$installDir\ffprobe.exe" -Force
    Remove-Item $tempZip, $tempExtract -Recurse -Force
    Write-Host "         Done! ffprobe.exe extracted and installed." -ForegroundColor Green

} catch {
    Write-Host "      -> ERROR downloading dependencies: $($_.Exception.Message)" -ForegroundColor Red
}

# =================================================================================
# 5. COPY APPDATA FILES (Configs, Fonts, Scripts)
# =================================================================================
Write-Host "[4/6] Applying custom configs, fonts, and scripts to AppData..." -ForegroundColor Yellow
$appDataDest = "$env:APPDATA\mpv"
$appDataSource = Join-Path $PSScriptRoot "AppData"

if (-not (Test-Path $appDataDest)) { New-Item -Path $appDataDest -ItemType Directory -Force | Out-Null }
Copy-Item -Path "$appDataSource\*" -Destination $appDataDest -Recurse -Force
Write-Host "      -> Configs, Fonts, and Scripts successfully copied." -ForegroundColor Green

# =================================================================================
# 6. COPY INSTALLER FILES (DLL and .bat scripts)
# =================================================================================
Write-Host "[5/6] Copying icon library and installer scripts to Program Files..." -ForegroundColor Yellow
$installerSource = Join-Path $PSScriptRoot "Installer"

Copy-Item -Path "$installerSource\*" -Destination $installerFolder -Recurse -Force
Write-Host "      -> mpviconlib.dll and batch scripts successfully copied." -ForegroundColor Green

# =================================================================================
# 7. AUTORUN THE CUSTOM INSTALL BATCH SCRIPT
# =================================================================================
Write-Host "[6/6] Executing custom mpv-install.bat..." -ForegroundColor Yellow
$batScriptPath = Join-Path $installerFolder "mpv-install.bat"

if (Test-Path $batScriptPath) {
    # Run the batch script and wait for it to finish
    Start-Process -FilePath $batScriptPath -Wait -NoNewWindow
    Write-Host "      -> File associations and icons applied successfully." -ForegroundColor Green
} else {
    Write-Host "      -> ERROR: mpv-install.bat not found in the installer folder." -ForegroundColor Red
}

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host " MPV Setup is Complete! Enjoy your music." -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5