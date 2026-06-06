@echo off
title Fix Legendary Connection
REM ============================================================
REM  Fix Legendary Connection
REM  Run this ONCE if you log in but then get "Resolving host: Ryan"
REM  and the loader closes. It points the old server names (Ryan/Dad)
REM  at the current Legendary server so the game can finish connecting.
REM
REM  It needs Administrator (it edits the Windows hosts file), so you'll
REM  get a Windows Yes/No (UAC) prompt - click YES.
REM ============================================================

REM --- self-elevate to Administrator ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator access ^(needed to fix the connection^)...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "PS=%TEMP%\_fix_legendary.ps1"
> "%PS%" echo $ErrorActionPreference = 'Stop'
>>"%PS%" echo $h = Join-Path $env:WINDIR 'System32\drivers\etc\hosts'
>>"%PS%" echo Copy-Item $h ($h + '.legendary.bak') -Force
>>"%PS%" echo $ip = '172.215.213.23'
>>"%PS%" echo $keep = @(Get-Content $h ^| Where-Object { ($_ -notmatch 'Ryan') -and ($_ -notmatch 'Dad') })
>>"%PS%" echo $keep += '# Legendary server'
>>"%PS%" echo $keep += ($ip + ' Ryan')
>>"%PS%" echo $keep += ($ip + ' Dad')
>>"%PS%" echo Set-Content -Path $h -Value $keep -Encoding ASCII
>>"%PS%" echo Write-Host ''
>>"%PS%" echo Write-Host 'Fixed - Ryan and Dad now point to the Legendary server (172.215.213.23).' -ForegroundColor Green

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%"
set "RC=%errorlevel%"
del "%PS%" >nul 2>&1

echo.
if not "%RC%"=="0" (
    echo Something went wrong editing the hosts file. Send your admin a screenshot.
) else (
    echo ============================================================
    echo  Done! Close this window and start the game again normally.
    echo  ^(A backup of your hosts file was saved as hosts.legendary.bak^)
    echo ============================================================
)
pause
