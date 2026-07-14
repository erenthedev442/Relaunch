@echo off
setlocal enabledelayedexpansion
rem ---------------------------------------------------------------
rem  deploy.bat — apply generated SQL patches to the LSB database.
rem  Written once by ffxi-dat-editor's Deploy button; edit the
rem  MySQL connection block below and keep it customized.
rem ---------------------------------------------------------------

rem -- MySQL connection ------------------------------------------------
set MYSQL_EXE=C:\xampp\mysql\bin\mysql.exe
set DB_HOST=127.0.0.1
set DB_PORT=3306
set DB_USER=root
set DB_PASS=
set DB_NAME=xidb

rem -- Where the generated .sql files live (this script's own dir) ----
set SQL_DIR=%~dp0

echo Applying every *_lsb_patch.sql in %SQL_DIR% ...
for %%F in ("%SQL_DIR%*_lsb_patch.sql") do (
    echo   -- %%~nxF
    "%MYSQL_EXE%" -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "%%F"
    if errorlevel 1 (
        echo   FAILED to apply %%~nxF ^(errorlevel !errorlevel!^)
        exit /b 1
    )
)

echo All patches applied. Any -- TODO ^(needs Lua^) lines in the .sql
echo files still need a matching item script under
echo scripts/globals/items/^<sortname^>.lua on the server side.
endlocal
