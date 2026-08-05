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
set "ICON_DLL=%~dp0mpviconlib.dll"
set "MPV_DIR=%~dp0.."
for %%I in ("%MPV_DIR%") do set "MPV_DIR=%%~fI"
set "MPV_EXE=%MPV_DIR%\mpv.exe"

echo ===================================================
echo  Installing MPV Custom File Associations ^& Icons
echo ===================================================
echo.

:: 3. EXTENSION AND ICON LIST
set "FORMATS=aiff:48 amr:40 ape:32 dts:38 flac:31 m3u:44 m4p:1 midi:42 mka:29 mp3:25 mpc:34 ofr:39 ogg:28 opus:46 pls:24 ra:41 tta:36 wav:26 wma:27 wv:33 3gp:7 asf:9 avi:2 dv:17 flv:11 ivf:18 m2ts:13 mkv:4 mov:6 mp4:5 mpa:47 mpg:3 mxf:14 ogm:10 rm:15 rmvb:16 ts:12 vob:23 webm:45 wmv:8"

:: 4. APPLY TO REGISTRY
for %%A in (%FORMATS%) do (
    for /f "tokens=1,2 delims=:" %%E in ("%%A") do (
        echo Registering .%%E with Icon Index %%F...
        
        reg add "HKCR\MPV.%%E" /ve /d "MPV Media File" /f >nul
        reg add "HKCR\MPV.%%E\DefaultIcon" /ve /d "\"%ICON_DLL%\",%%F" /f >nul
        reg add "HKCR\MPV.%%E\shell\open\command" /ve /d "\"%MPV_EXE%\" \"%%1\"" /f >nul
        reg add "HKCR\.%%E" /ve /d "MPV.%%E" /f >nul
    )
)

:: 5. REFRESH WINDOWS ICON CACHE INSTANTLY (Fixed PowerShell Syntax)
echo.
echo Refreshing Icon Cache...
ie4uinit.exe -show >nul 2>&1
powershell -command "$code = '[System.Runtime.InteropServices.DllImport(\"Shell32.dll\")] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'; $type = Add-Type -MemberDefinition $code -Name 'Win32' -Namespace 'API' -PassThru; $type::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)"

echo.
echo ===================================================
echo  Installation Complete!
echo ===================================================
timeout /t 5 >nul