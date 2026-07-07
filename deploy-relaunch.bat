@echo off
REM ============================================================
REM  Relaunch - Deploy Everything (OVH box). Double-click to run.
REM  Pulls code, rebuilds C++, applies SQL, restarts the server,
REM  and republishes the relaunch website. See deploy-relaunch.ps1
REM  for the step-by-step + deploy-relaunch.log for the last run.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-relaunch.ps1"
