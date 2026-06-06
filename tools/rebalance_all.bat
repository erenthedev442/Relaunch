@echo off
REM ============================================================
REM  rebalance_all.bat - re-score every gear catalog in one shot
REM ============================================================
REM  Runs the three gear scorers, then rebuilds the auto-promoted
REM  Infamy Vendor top-picks list, its equipment-type browse map
REM  (catalog.itemTypeMap), and the +4 reforge catalog.
REM  Each script rewrites ONLY its own catalog's auto-generated
REM  section in place - hand-curated sections are left untouched.
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

echo.
echo === [4/6] Building Infamy Vendor top-picks ===
python tools\build_infamy_top_picks.py
if errorlevel 1 ( echo ERROR: infamy top-picks failed & popd & exit /b 1 )

echo.
echo === [5/6] Building Infamy Vendor equipment-type map ===
REM  Must run AFTER top-picks: it classifies catalog.vendorItems +
REM  catalog.vendorItemsAuto by slot/skill for the NPC's grouped browser.
python tools\build_infamy_typemap.py
if errorlevel 1 ( echo ERROR: infamy typemap failed & popd & exit /b 1 )

echo.
echo === [6/6] Building +4 reforge catalog ===
python tools\build_infamy_plus4_catalog.py
if errorlevel 1 ( echo ERROR: +4 reforge catalog failed & popd & exit /b 1 )

popd
echo.
echo === Done! All catalogs re-scored. ===
