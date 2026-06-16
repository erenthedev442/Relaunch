@echo off
REM ============================================================
REM  Legendary FFXI - Sync Lua content to Azure (no restart)
REM ============================================================
REM  Pushes modules/custom + scripts to the live Azure server.
REM  NO restart, NO SQL, NO C++ rebuild, NO DB changes.
REM
REM  The Azure FileWatcher hot-reloads changed Lua files instantly.
REM  Safe for: catalog edits, command files, script tweaks.
REM
REM  NOT sufficient for: new addOverride modules, C++ changes,
REM  SQL schema/data changes -- use deploy-everything.bat for those.
REM ============================================================
setlocal
set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SRC=D:\server"
set "REMOTE=/home/azureuser/server"
set "TGZ=%TEMP%\fjb_lua.tgz"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"

echo.
echo  Packing modules/custom + scripts...
tar -czf "%TGZ%" -C "%SRC%" modules/custom scripts
if errorlevel 1 ( echo  ERROR: tar failed. & pause & exit /b 1 )

echo  Uploading to Azure...
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_lua.tgz
if errorlevel 1 ( echo  ERROR: upload failed. & pause & exit /b 1 )
del "%TGZ%" >nul 2>&1

echo  Extracting on Azure (no restart)...
ssh -i "%KEY%" %SSHOPT% %HOST% "sudo tar -xzf /tmp/fjb_lua.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts && rm -f /tmp/fjb_lua.tgz && echo DONE"
if errorlevel 1 ( echo  ERROR: extract failed. & pause & exit /b 1 )

echo.
echo  ============================================================
echo   Content synced. FileWatcher will hot-reload Lua changes.
echo   If you added a new addOverride module, a map restart is
echo   still needed -- run deploy-everything.bat for that.
echo  ============================================================
echo.
pause
