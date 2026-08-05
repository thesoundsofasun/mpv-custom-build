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

:: 2. EXTENSION LIST (Just the extensions, no icon numbers needed)
set "FORMATS=mp3 wav flac mpc ofr aiff ivf wma ogg mka aac ape wv tta ac3 dts amr ra midi cda opus mpa avi mpg mkv mp4 mov 3gp wmv asf ogm flv ts m2ts mxf rm rmvb dv vob webm pls m3u"

:: 3. REMOVE FROM REGISTRY
for %%E in (%FORMATS%) do (
    echo Unregistering .%%E...
    
    :: Delete the custom MPV ProgID
    reg delete "HKCR\MPV.%%E" /f >nul 2>&1
    
    :: Clear the default association for the extension
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