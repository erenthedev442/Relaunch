@echo off
setlocal
title Bouncer Client Mod - Uninstaller (restore stock GEO names)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges ^(approve the UAC prompt^)...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "FFXI=C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI"
set "PACK=%~dp0"

REM --- restore the stock job name (FFXiMain.dll) ---
if exist "%FFXI%\FFXiMain.dll.orig" (
    copy /y "%FFXI%\FFXiMain.dll.orig" "%FFXI%\FFXiMain.dll" >nul
    echo  [job name ] Restored stock FFXiMain.dll ^(GEO / Geomancer^).
) else (
    echo  [job name ] No backup found ^(FFXiMain.dll.orig^). Nothing to restore.
    echo  If needed, run the PlayOnline updater to re-fetch a clean FFXiMain.dll.
)

REM --- restore the stock ability names (ROM\181\72.DAT) ---
powershell -ExecutionPolicy Bypass -NoProfile -File "%PACK%patch_abilities.ps1" -FFXI "%FFXI%" -Restore

REM --- restore the stock ability descriptions (ROM\181\74.DAT) ---
powershell -ExecutionPolicy Bypass -NoProfile -File "%PACK%patch_descriptions.ps1" -FFXI "%FFXI%" -Restore

echo.
echo  DONE - relaunch FFXI. Stock GEO job + ability names + descriptions are back.
echo.
pause
