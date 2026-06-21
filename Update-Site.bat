@echo off
title Update Legendary Website
echo.
echo ============================================================
echo  Publishing legendary-ffxi.pages.dev from the AZURE BOX
echo.
echo  Pulls the latest docs from the Legendary branch, regenerates
echo  every page against the LIVE database, and deploys to
echo  Cloudflare Pages (production). Online players are unaffected.
echo.
echo  Takes ~2-3 minutes. Please wait -- do NOT close this window.
echo ============================================================
echo.
ssh -i "C:\Users\richa\Downloads\ffxi-server_key.pem" -o StrictHostKeyChecking=no azureuser@172.215.213.23 "bash ~/server/tools/refresh_site_azure.sh; echo; echo ===== RESULT =====; tail -14 ~/refresh_site.log"
if errorlevel 1 (
    echo.
    echo  WARNING: the publish command returned an error -- check the output above.
)
echo.
echo ============================================================
echo  Done. Look for 'Deployment complete' in the output above.
echo  Live at https://legendary-ffxi.pages.dev
echo  (give Cloudflare ~30 seconds to swap the new build in)
echo ============================================================
echo.
pause
