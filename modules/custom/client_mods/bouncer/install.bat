@echo off
setlocal
title Bouncer Client Mod - Installer

REM --- self-elevate to admin (needed to write into Program Files) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges ^(approve the UAC prompt^)...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "FFXI=C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI"
set "PACK=%~dp0"

echo.
echo  Bouncer client relabel  (job name + ability names: GEO -^> BOUNCER)
echo  -------------------------------------------------------------------
echo  FFXI folder : %FFXI%
echo  Pack folder : %PACK%
echo.

if not exist "%FFXI%\FFXiMain.dll" (
    echo  ERROR: FFXiMain.dll not found at the path above.
    echo  Edit this .bat and set FFXI=^<your FINAL FANTASY XI folder^>.
    echo.
    pause
    exit /b 1
)

REM --- close-game guard: copy will fail if the client is running ---
tasklist /fi "imagename eq pol.exe" 2>nul | find /i "pol.exe" >nul && (
    echo  WARNING: PlayOnline/FFXI looks like it is running. Close the game first.
    echo.
    pause
)

REM --- back up the pristine original ONCE ---
if not exist "%FFXI%\FFXiMain.dll.orig" (
    copy /y "%FFXI%\FFXiMain.dll" "%FFXI%\FFXiMain.dll.orig" >nul
    echo  [backup ] Saved original -^> FFXiMain.dll.orig
) else (
    echo  [backup ] FFXiMain.dll.orig already present - left as-is
)

REM --- install the patched DLL (job name: Geomancer/GEO -^> Bouncer/BNC) ---
copy /y "%PACK%FFXiMain.dll" "%FFXI%\FFXiMain.dll" >nul
if %errorlevel% equ 0 (
    echo  [job name] FFXiMain.dll installed OK  ^(Geomancer/GEO -^> Bouncer/BNC^).
) else (
    echo  [job name] FAILED to copy FFXiMain.dll. Close the game fully and retry.
    echo.
    pause
    exit /b 1
)

REM --- relabel the 9 repurposed GEO Job Abilities in ROM\181\72.DAT ---
echo.
echo  [abilities] Relabeling Job Ability names...
powershell -ExecutionPolicy Bypass -NoProfile -File "%PACK%patch_abilities.ps1" -FFXI "%FFXI%"

REM --- relabel those 9 abilities' menu DESCRIPTIONS in ROM\181\74.DAT ---
echo.
echo  [descriptions] Relabeling Job Ability descriptions...
powershell -ExecutionPolicy Bypass -NoProfile -File "%PACK%patch_descriptions.ps1" -FFXI "%FFXI%"

echo.
echo  DONE - relaunch FFXI.
echo    * Job now displays as BOUNCER / BNC
echo    * JA menu and "^<name^> uses ..." now show the Bouncer ability names
echo    * JA menu descriptions now read as the Bouncer kit
echo.
pause
