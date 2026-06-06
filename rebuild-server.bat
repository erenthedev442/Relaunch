@echo off
REM ============================================================
REM Legendary FFXI - Rebuild and restart the server binaries
REM ============================================================
REM Double-click to:
REM   1. Stop the supervisor cleanly (sentinel + wait for procs)
REM   2. Source the Visual Studio 2022 dev environment
REM   3. Rebuild xi_map.exe / xi_connect.exe / xi_world.exe /
REM      xi_search.exe via CMake/Ninja (RelWithDebInfo)
REM   4. Relaunch the supervisor in a new window
REM
REM Most rebuilds touch only one .cpp at a time (incremental), so
REM expect 30s-5min depending on what changed. Full rebuilds
REM after `git pull` of upstream LSB can take 15-30 min.
REM
REM Build failures leave the supervisor STOPPED on purpose so
REM you notice the failure instead of silently running stale
REM code. Inspect rebuild-server.log, fix the source, re-run.
REM ============================================================

setlocal EnableExtensions EnableDelayedExpansion
set "REPO_ROOT=%~dp0"
set "LOG=%REPO_ROOT%rebuild-server.log"
set "BUILD_DIR=%REPO_ROOT%build\x64-Release"

REM Fresh log per run (search history is in supervisor.log instead).
> "%LOG%" echo === Rebuild started %date% %time% ===

echo.
echo ============================================================
echo  Legendary FFXI - Rebuild server binaries
echo ============================================================
echo  Repo : %REPO_ROOT%
echo  Build: %BUILD_DIR%
echo  Log  : %LOG%
echo ============================================================
echo.

REM ------------------------------------------------------------
REM Sanity: CMake build directory must already exist + be configured.
REM This script only does incremental builds; first-time configure
REM ("cmake -S . -B build/x64-Release -G Ninja ...") is a one-shot
REM the user runs by hand (typically via VS Code CMake Tools).
REM ------------------------------------------------------------
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    call :err "Build dir not configured: %BUILD_DIR%\CMakeCache.txt missing."
    call :err "Run cmake configure once (VS Code: CMake: Configure), then re-run this."
    goto :fail
)

REM ------------------------------------------------------------
REM Step 1: Find Visual Studio 2022 (vcvars64 puts MSVC + ninja
REM         + bundled cmake on PATH for this cmd session).
REM ------------------------------------------------------------
echo [1/4] Locating Visual Studio 2022 toolchain...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    call :err "vswhere.exe not found at: %VSWHERE%"
    call :err "Install Visual Studio 2022 (any edition) with the C++ workload."
    goto :fail
)

set "VS_PATH="
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do set "VS_PATH=%%i"
if not defined VS_PATH (
    call :err "vswhere returned no Visual Studio install."
    goto :fail
)

set "VCVARS=%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
if not exist "%VCVARS%" (
    call :err "vcvars64.bat not found at: %VCVARS%"
    call :err "Reinstall the 'Desktop development with C++' workload."
    goto :fail
)
call :log "Visual Studio: %VS_PATH%"

REM Note: vcvars64 prints a banner to stdout. Redirect it to the log
REM so the console stays clean; errors still surface via errorlevel.
call "%VCVARS%" >> "%LOG%" 2>&1
if errorlevel 1 (
    call :err "vcvars64.bat failed (exit %errorlevel%). Check %LOG%."
    goto :fail
)
echo       OK

REM ------------------------------------------------------------
REM Step 2: Stop the supervisor and wait for xi_map.exe to release
REM         its file handle. The build will overwrite xi_map.exe
REM         in place, so a held lock = build failure with no clear
REM         error message.
REM ------------------------------------------------------------
echo [2/4] Stopping supervisor...
> "%REPO_ROOT%supervisor.stop" echo stop
call :log "Sentinel dropped: supervisor.stop"

REM Poll for xi_map.exe absence. 30 tries x ~1s = up to 30s grace.
REM Supervisor's finally block kills all 4 binaries within 1-2s
REM of seeing the sentinel, so we usually exit this loop fast.
set /a TRIES=0
:waitstop
tasklist /FI "IMAGENAME eq xi_map.exe" 2>nul | find /i "xi_map.exe" >nul
if errorlevel 1 goto :stopped
set /a TRIES+=1
if %TRIES% GEQ 30 goto :forcekill
ping -n 2 127.0.0.1 >nul
goto :waitstop

:forcekill
call :log "Supervisor didn't release xi_map.exe after 30s. Force-killing all four binaries."
taskkill /F /IM xi_map.exe     >> "%LOG%" 2>&1
taskkill /F /IM xi_connect.exe >> "%LOG%" 2>&1
taskkill /F /IM xi_world.exe   >> "%LOG%" 2>&1
taskkill /F /IM xi_search.exe  >> "%LOG%" 2>&1
REM Small buffer so Windows actually releases the file handles
REM before cmake tries to overwrite the .exe.
ping -n 4 127.0.0.1 >nul

:stopped
call :log "Server binaries stopped."
echo       OK

REM ------------------------------------------------------------
REM Step 3: Run the build.
REM
REM   INCREMENTAL (default): Ninja recompiles only changed files.
REM     Progress shown as [N/M] where M = dirty files this run.
REM     Typical: [1/4] ... [4/4] for a one-file edit.
REM
REM   CLEAN REBUILD: wipes all .obj / .lib / .exe first, then
REM     recompiles everything (~806 files, 15-30 min).
REM     Progress shown as [1/806] ... [806/806].
REM     Use this after a big upstream pull, or when incremental
REM     builds produce mysterious link errors.
REM
REM   Each [N/M] line is printed to the console in real-time so
REM   you can watch progress as Ninja works through the list.
REM ------------------------------------------------------------
echo [3/4] Build mode?
echo.
echo   I = Incremental (default, fast - only changed files)
echo   C = Clean rebuild (slow - all ~806 files, like VS "Rebuild All")
echo.
set "BUILD_MODE="
set /p "BUILD_MODE=Enter I or C (or press Enter for incremental): "
if /i "!BUILD_MODE!"=="C" (
    set "CLEAN_FLAG=--clean-first"
    echo.
    echo [3/4] CLEAN rebuild - wiping build artefacts then compiling all ~806 files...
    call :log "Build mode: CLEAN --clean-first"
) else (
    set "CLEAN_FLAG="
    echo.
    echo [3/4] Incremental build - compiling only what changed...
    call :log "Build mode: INCREMENTAL"
)
echo.
call :log "--- cmake --build %BUILD_DIR% --config RelWithDebInfo %CLEAN_FLAG% ---"

REM PowerShell's Tee-Object gives us console + log simultaneously.
REM Without it, '>> log 2>&1' hides progress; bare 'cmake' loses log.
REM
REM Progress format from Ninja (streamed live):
REM   [N/M] Building CXX object ...file.cpp.obj   <- compiling a source file
REM   [N/M] Linking CXX executable xi_map.exe     <- linking a final binary
REM M is the total dirty-file count for THIS run (incremental) or the
REM full ~806 for a clean rebuild.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& { cmake --build '%BUILD_DIR%' --config RelWithDebInfo %CLEAN_FLAG% 2>&1 | Tee-Object -FilePath '%LOG%' -Append; exit $LASTEXITCODE }"
set "BUILD_RC=%errorlevel%"
echo.

if %BUILD_RC% NEQ 0 (
    call :err "BUILD FAILED (exit %BUILD_RC%). Server NOT restarted."
    echo.
    echo ============================================================
    echo  BUILD FAILED - server is STOPPED.
    echo  Open rebuild-server.log, scroll to the bottom, find the
    echo  compiler error(s), fix the source, then re-run this bat.
    echo ============================================================
    pause
    exit /b %BUILD_RC%
)

call :log "Build succeeded."
echo       OK

REM ------------------------------------------------------------
REM Step 4: Relaunch supervisor in a detached console.
REM         'start ""' opens a new window so this script can exit
REM         cleanly; the supervisor lives in its own console with
REM         its own log (supervisor.log).
REM ------------------------------------------------------------
echo [4/4] Relaunching supervisor in a new window...
start "Legendary Supervisor" "%REPO_ROOT%start-supervisor.bat"
call :log "start-supervisor.bat launched."

echo.
echo ============================================================
echo  BUILD SUCCEEDED - supervisor relaunched.
echo  Watch the new "Legendary Supervisor" console for boot status.
echo  Full build log: %LOG%
echo  Supervisor log: %REPO_ROOT%supervisor.log
echo ============================================================
call :log "=== Rebuild completed successfully %date% %time% ==="
pause
exit /b 0

REM ============================================================
REM Helpers
REM ============================================================
:log
echo [%time%] %~1>> "%LOG%"
echo [%time%] %~1
goto :eof

:err
echo [%time%] ERROR: %~1>> "%LOG%"
echo [%time%] ERROR: %~1 1>&2
goto :eof

:fail
echo.
echo ============================================================
echo  REBUILD ABORTED before the build phase. See %LOG% for details.
echo  Server was NOT touched - whatever was running is still running.
echo ============================================================
pause
exit /b 1
