@echo off
title MPV Custom Installer
color 0B

:: 1. REQUIRE ADMINISTRATOR RIGHTS
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 2. LOCATE MPV.EXE AND DLL
:: %~dp0 is the folder this .bat is in (the installer folder)
set "ICON_DLL=%~dp0mpviconlib.dll"
set "MPV_DIR=%~dp0.."
for %%I in ("%MPV_DIR%") do set "MPV_DIR=%%~fI"
set "MPV_EXE=%MPV_DIR%\mpv.exe"

echo ===================================================
echo  Installing MPV Custom File Associations ^& Icons
echo ===================================================
echo.

:: 3. EXTENSION AND ICON LIST (Format is EXTENSION:ICON_INDEX)
set "FORMATS=mp3:25 wav:26 flac:31 mpc:34 ofr:39 aiff:48 ivf:18 wma:0 ogg:0 mka:0 aac:0 ape:0 wv:0 tta:0 ac3:0 dts:0 amr:0 ra:0 midi:0 cda:0 opus:0 mpa:0 avi:0 mpg:0 mkv:0 mp4:0 mov:0 3gp:0 wmv:0 asf:0 ogm:0 flv:0 ts:0 m2ts:0 mxf:0 rm:0 rmvb:0 dv:0 vob:0 webm:0 pls:0 m3u:0"

:: 4. APPLY TO REGISTRY
for %%A in (%FORMATS%) do (
    for /f "tokens=1,2 delims=:" %%E in ("%%A") do (
        echo Registering .%%E with Icon Index %%F...
        
        :: Create the Program ID and map the icon and executable
        reg add "HKCR\MPV.%%E" /ve /d "MPV Media File" /f >nul
        reg add "HKCR\MPV.%%E\DefaultIcon" /ve /d "\"%ICON_DLL%\",%%F" /f >nul
        reg add "HKCR\MPV.%%E\shell\open\command" /ve /d "\"%MPV_EXE%\" \"%%1\"" /f >nul
        
        :: Link the extension to the Program ID
        reg add "HKCR\.%%E" /ve /d "MPV.%%E" /f >nul
    )
)

:: 5. REFRESH WINDOWS ICON CACHE INSTANTLY
echo.
echo Refreshing Icon Cache...
ie4uinit.exe -show >nul 2>&1
powershell -command "$code = '[System.Runtime.InteropServices.DllImport(\"Shell32.dll\")] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'; Add-Type -MemberDefinition $code -Name 'Win32' -Namespace 'API' -PassThru::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)"

echo.
echo ===================================================
echo  Installation Complete!
echo ===================================================
timeout /t 5 >nul