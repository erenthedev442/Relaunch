@echo off
REM ============================================================
REM  rebalance_all.bat - re-score every gear catalog in one shot
REM ============================================================
REM  Runs the three gear scorers (armor / weapons / accessories), which
REM  refresh the scored catalog.infamy tiers used by the medal gear vendors.
REM  Each script rewrites ONLY its own catalog's auto-generated section in
REM  place - hand-curated sections are left untouched.
REM
REM  Needs the MySQL DB (xidb) reachable. Safe to run from any
REM  folder: it cd's to the repo root first.
REM ============================================================
pushd "%~dp0.."

echo.
echo === [1/6] Scoring armor ===
python tools\score_armor.py
if errorlevel 1 ( echo ERROR: armor scoring failed & popd & exit /b 1 )

echo.
echo === [2/6] Scoring weapons ===
python tools\score_weapons.py
if errorlevel 1 ( echo ERROR: weapons scoring failed & popd & exit /b 1 )

echo.
echo === [3/6] Scoring accessories ===
python tools\score_accessories.py
if errorlevel 1 ( echo ERROR: accessories scoring failed & popd & exit /b 1 )

REM  Infamy vendor generators (top-picks / typemap / +4) retired 2026-07-06:
REM  the vendor is now a hand-curated accessories-only shop, and its weapons +
REM  armor moved to the Voidwatch NM loot tables. Nothing to auto-build here.

popd
echo.
echo === Done! All catalogs re-scored. ===
