This is a fantastic way to package your setup. By structuring your GitHub
repository properly, you can make this an absolute "1-click install" for
yourself or anyone else.

Here is exactly how to structure your repository files, followed by the Master
Deployment Script that connects all the dots.

1. The GitHub Repository Structure

Create a folder on your computer named mpv-custom-build. Inside it, organize
your files exactly like this:

mpv-custom-build/
│
├── Deploy.ps1                     <-- (The Master Script provided below)
│
├── AppData/                       <-- (Everything in here goes to %AppData%\mpv)
│   ├── mpv.conf
│   ├── input.conf
│   ├── fonts/
│   │   └── AbletonSans.ttf        <-- (Your custom fonts)
│   └── scripts/
│       ├── autoload.lua
│       ├── shuffle_toggle.lua     <-- (Your custom scripts)
│       └── sort_track_metadata.lua 
│
└── Installer/                     <-- (Everything in here goes to C:\Program Files\...)
    ├── mpviconlib.dll
    └── Apply-Icons.ps1            <-- (The icon script we made in the previous step)

2. The Master Deployment Script (Deploy.ps1)

This is the script that orchestrates everything. It asks for Admin rights,
installs MPV, moves all the folders exactly where you requested, and
automatically triggers your icon script at the very end.

Copy this code and save it as Deploy.ps1 in the root of your repo folder.

<#
.SYNOPSIS
    Master Deployment Script for Custom MPV Audio Build
#>

# 1. REQUIRE ADMIN RIGHTS (Needed for winget, Program Files, and Registry)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Restarting script with Administrator privileges..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Starting MPV Custom Build Deployment" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# 2. INSTALL MPV VIA WINGET
Write-Host "[1/5] Installing Shinchiro MPV via winget..." -ForegroundColor Yellow
# Using Start-Process with -Wait ensures the script pauses until the download/install is 100% finished
$wingetArgs = "install --id shinchiro.mpv --exact --silent --accept-package-agreements --accept-source-agreements"
Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow

# 3. LOCATE THE INSTALLATION DIRECTORY
# Winget usually uses "mpv" but we will check "MPV Player" just in case based on your prompt.
$installDir = "C:\Program Files\mpv"
if (Test-Path "C:\Program Files\MPV Player") { $installDir = "C:\Program Files\MPV Player" }

$installerFolder = Join-Path $installDir "installer"
if (-not (Test-Path $installerFolder)) { New-Item -Path $installerFolder -ItemType Directory -Force | Out-Null }

Write-Host "[2/5] MPV located at: $installDir" -ForegroundColor Green

# 4. COPY APPDATA FILES (Configs, Fonts, Scripts)
Write-Host "[3/5] Applying custom configs, fonts, and scripts to AppData..." -ForegroundColor Yellow
$appDataDest = "$env:APPDATA\mpv"
$appDataSource = Join-Path $PSScriptRoot "AppData"

# Create AppData folder if it doesn't exist
if (-not (Test-Path $appDataDest)) { New-Item -Path $appDataDest -ItemType Directory -Force | Out-Null }

# Copy everything inside Repo/AppData/ to %AppData%/mpv/
Copy-Item -Path "$appDataSource\*" -Destination $appDataDest -Recurse -Force
Write-Host "      -> Configs, Fonts, and Scripts successfully copied." -ForegroundColor Green

# 5. COPY INSTALLER FILES (DLL and Icon Script)
Write-Host "[4/5] Copying icon library and installer script to Program Files..." -ForegroundColor Yellow
$installerSource = Join-Path $PSScriptRoot "Installer"

# Copy mpviconlib.dll and Apply-Icons.ps1
Copy-Item -Path "$installerSource\*" -Destination $installerFolder -Recurse -Force
Write-Host "      -> mpviconlib.dll and Icon script successfully copied." -ForegroundColor Green

# 6. AUTORUN THE ICON SCRIPT
Write-Host "[5/5] Executing custom mpv-install.bat..." -ForegroundColor Yellow
$batScriptPath = Join-Path $installerFolder "mpv-install.bat"

if (Test-Path $batScriptPath) {
    Start-Process -FilePath $batScriptPath -Wait -NoNewWindow
    Write-Host "      -> Icons applied successfully." -ForegroundColor Green
}

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host " MPV Setup is Complete! Enjoy your music." -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5

3. How to use it

1.  Fill up your AppData and Installer folders as shown in the structure above.
2.  Ensure your Apply-Icons.ps1 script (from our previous conversation) points
    to the correct DLL path (C:\Program Files\MPV
    Player\installer\mpviconlib.dll or C:\Program
    Files\mpv\installer\mpviconlib.dll).
3.  Commit everything to your GitHub repository.

When someone clones your repo or downloads the .zip, all they have to do is
right-click Deploy.ps1 and hit Run with PowerShell.

The script will automatically grab Admin privileges, wait for winget to finish
installing, build the AppData folder, move your fonts/scripts, move the DLL, and
finally trigger your icon script seamlessly in the background!
