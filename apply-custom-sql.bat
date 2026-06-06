@echo off
REM ============================================================
REM  apply-custom-sql.bat - apply the custom sql\zz_*.sql layer
REM  (item_mods / item_latents / etc.) to the game DB in one go.
REM
REM  Reads DB credentials from settings\network.lua automatically.
REM  Idempotent (INSERT IGNORE / ON DUPLICATE KEY UPDATE), so it is
REM  safe to re-run. Restart the map server afterward so the new
REM  item stats load.
REM
REM  Examples:
REM    apply-custom-sql.bat                 (all zz_ files, local DB)
REM    apply-custom-sql.bat --dry-run       (show targets, change nothing)
REM    apply-custom-sql.bat sql\zz_relic_119iii_mods.sql   (one file)
REM ============================================================
pushd "%~dp0"
python tools\apply_custom_sql.py %*
popd
