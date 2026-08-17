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

:: ======================================================================
:: --- ADDED SECTION: PATCH MPV.EXE AND UNINS000.EXE WITH CUSTOM ICON ---
:: ======================================================================
set "CUSTOM_ICON=%~dp0mpv-icon.ico"
set "UNINS_EXE=%MPV_DIR%\unins000.exe"

if exist "%CUSTOM_ICON%" (
    echo ===================================================
    echo  Patching Executables with Custom Icon...
    echo ===================================================
    echo Downloading rcedit to %TEMP%\rcedit.exe...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe' -OutFile '%TEMP%\rcedit.exe'"
    
    if exist "%TEMP%\rcedit.exe" (
        if exist "%MPV_EXE%" (
            echo Injecting custom icon into mpv.exe...
            "%TEMP%\rcedit.exe" "%MPV_EXE%" --set-icon "%CUSTOM_ICON%"
        )
        del "%TEMP%\rcedit.exe"
        echo Executable patching complete!
        echo.
    ) else (
        echo Error: rcedit failed to download.
        echo.
    )
) else (
    echo mpv-icon.ico not found, skipping executable patch...
    echo.
)
:: ======================================================================
:: --- END OF ADDED SECTION ---
:: ======================================================================

echo ===================================================
echo  Installing MPV Custom File Associations ^& Icons
echo ===================================================
echo.

:: 3. EXTENSION AND ICON LIST
set "FORMATS=aac:1 ac3:3 cda:3 aiff:3 amr:3 ape:3 dts:3 flac:5 gif:7 list:8 m3u:3 m4a:9 m4p:3 mid:3 midi:3 mka:3 mp3:11 mpc:3 ofr:3 ogg:13 opus:3 pls:3 ra:3 tta:3 wav:18 wma:3 wv:3 3gp:0 asf:2 avi:4 dv:17 flv:6 ivf:17 m2ts:17 mkv:10 mov:17 mp4:12 mpa:3 mpg:17 mxf:17 ogm:17 rm:15 rmvb:17 ts:16 qt:14 vob:17 webm:19 wmv:20"

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
