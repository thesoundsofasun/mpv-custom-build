<#
.SYNOPSIS
    Web Deployment Script for MPV Custom Build
    Installs MPV, downloads dependencies, and pulls configs/icons directly from GitHub.
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

if (-not $installDir) {
    $installDir = "C:\Program Files\mpv" # Safe fallback
}

Write-Host "      -> MPV located at: $installDir" -ForegroundColor Green

$installerFolder = Join-Path $installDir "installer"
if (-not (Test-Path $installerFolder)) { New-Item -Path $installerFolder -ItemType Directory -Force | Out-Null }

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
    
    Invoke-WebRequest -Uri $ffUrl -OutFile $tempZip
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    Move-Item -Path "$tempExtract\ffprobe.exe" -Destination "$installDir\ffprobe.exe" -Force
    Remove-Item $tempZip, $tempExtract -Recurse -Force
    Write-Host "         Done! ffprobe.exe extracted and installed." -ForegroundColor Green

} catch {
    Write-Host "      -> ERROR downloading dependencies: $($_.Exception.Message)" -ForegroundColor Red
}

# =================================================================================
# 5. PULL FILES DIRECTLY FROM YOUR GITHUB REPO
# =================================================================================
Write-Host "[4/6] Downloading custom configs and icons from your GitHub repo..." -ForegroundColor Yellow

$repoZipUrl = "https://github.com/thesoundsofasun/mpv-custom-build/archive/refs/heads/main.zip"
$repoTempZip = "$env:TEMP\mpv_repo_temp.zip"
$repoExtract = "$env:TEMP\mpv_repo_extract"

if (Test-Path $repoExtract) { Remove-Item $repoExtract -Recurse -Force }
Invoke-WebRequest -Uri $repoZipUrl -OutFile $repoTempZip
Expand-Archive -Path $repoTempZip -DestinationPath $repoExtract -Force

$repoRoot = Join-Path $repoExtract "mpv-custom-build-main"
Write-Host "      -> Repo successfully downloaded and extracted." -ForegroundColor Green

# =================================================================================
# 6. DISTRIBUTE FILES
# =================================================================================
Write-Host "[5/6] Distributing files to AppData and Program Files..." -ForegroundColor Yellow

# Copy the "config" folder to %AppData%\mpv
$appDataDest = "$env:APPDATA\mpv"
$appDataSource = Join-Path $repoRoot "config"

if (-not (Test-Path $appDataDest)) { New-Item -Path $appDataDest -ItemType Directory -Force | Out-Null }
Copy-Item -Path "$appDataSource\*" -Destination $appDataDest -Recurse -Force
Write-Host "      -> Configs, Fonts, and Scripts applied." -ForegroundColor Green

# Copy the "installer" folder (.dll and .bat files) to MPV's installer folder
$installerSource = Join-Path $repoRoot "installer"
Copy-Item -Path "$installerSource\*" -Destination $installerFolder -Recurse -Force
Write-Host "      -> mpviconlib.dll and installer scripts applied." -ForegroundColor Green

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
