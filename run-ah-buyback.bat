@echo off
setlocal
title Legendary - AH Buyback (Manual Run)

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"

echo.
echo  Legendary - AH Buyback (Manual Run)
echo  Connects to the Azure box and runs one full market-maker pass
echo  (stocks gear + buys back player listings at sell price).
echo.
set "GO="
set /p GO="  Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo  Cancelled.& goto :end )

echo.
echo  Pushing latest config to box...
scp -i "%KEY%" %SSHOPT% "D:\server\tools\ah_market_maker_config.json" %HOST%:~/server/tools/ah_market_maker_config.json
if errorlevel 1 ( echo  ERROR: config push failed - aborting.& goto :end )

echo  Running ah_market_maker.py --commit on the box...
echo  (output streams live below)
echo  -------------------------------------------------------
ssh -i "%KEY%" %SSHOPT% %HOST% "source ~/docs-venv/bin/activate && cd ~/server && python tools/ah_market_maker.py --commit 2>&1 | tee -a ~/ah_market_maker.log"
echo  -------------------------------------------------------
echo.
echo  Done. Run "Legendary - AH Bot Status.bat" to verify results.
echo.

:end
pause
