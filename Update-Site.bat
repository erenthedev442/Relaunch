@echo off
title Update Legendary Site
echo.
echo ============================================================
echo  Updating legendary-ffxi.pages.dev from the AZURE BOX
echo  (reads the LIVE database, so player counts and the new
echo   branding stay correct -- unlike the old laptop refresh).
echo  This takes about a minute. Please wait...
echo ============================================================
echo.
ssh -i "C:\Users\richa\Downloads\ffxi-server_key.pem" azureuser@172.215.213.23 "bash ~/server/tools/refresh_site_azure.sh; echo; tail -4 ~/refresh_site.log"
echo.
echo ============================================================
echo  Done. Open https://legendary-ffxi.pages.dev
echo  (give Cloudflare a few seconds to swap the new version in)
echo ============================================================
echo.
pause
