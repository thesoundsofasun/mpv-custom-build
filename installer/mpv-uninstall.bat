@echo off
title MPV Custom Uninstaller
color 0C

:: 1. REQUIRE ADMINISTRATOR RIGHTS
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo ===================================================
echo  Removing MPV File Associations ^& Icons
echo ===================================================
echo.

:: 2. EXTENSION LIST 
set "FORMATS=aac ac3 cda aiff amr ape dts flac m3u m4p midi mka mp3 mpc ofr ogg opus pls ra tta wav wma wv 3gp asf avi dv flv ivf m2ts mkv mov mp4 mpa mpg mxf ogm rm rmvb ts vob webm wmv"

:: 3. REMOVE FROM REGISTRY
for %%E in (%FORMATS%) do (
    echo Unregistering .%%E...
    reg delete "HKCR\MPV.%%E" /f >nul 2>&1
    reg delete "HKCR\.%%E" /ve /f >nul 2>&1
)

:: 4. REFRESH WINDOWS ICON CACHE
echo.
echo Refreshing Icon Cache...
ie4uinit.exe -show >nul 2>&1
powershell -command "$code = '[System.Runtime.InteropServices.DllImport(\"Shell32.dll\")] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'; Add-Type -MemberDefinition $code -Name 'Win32' -Namespace 'API' -PassThru::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)"

echo.
echo ===================================================
echo  Uninstallation Complete!
echo ===================================================
timeout /t 5 >nul