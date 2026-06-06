@echo off
REM ============================================================
REM  refresh-site.bat - regenerate everything, then deploy site
REM ============================================================
REM  Full pipeline:
REM    [1] Re-score gear catalogs from the DB (auto-gen sections)
REM    [2] Generate reference markdown from the Lua catalogs
REM    [3] Build the MkDocs site
REM    [4] Deploy to Cloudflare Pages
REM
REM  Step [1] needs the MySQL DB (xidb) reachable. If it is
REM  offline the re-score is skipped with a warning and the site
REM  is built from the catalog files already on disk - so doc-only
REM  edits and hand-curated catalog edits still publish without
REM  the DB running.
REM ============================================================
pushd "%~dp0"

echo.
echo === [1/4] Re-scoring gear catalogs (auto-gen sections) ===
call tools\rebalance_all.bat
if errorlevel 1 (
    echo WARNING: catalog re-score did not complete - DB offline?
    echo          Continuing with the catalog files already on disk.
)

echo.
echo === [2/4] Generating reference docs from Lua catalogs ===
python tools\docgen\generate_docs.py
if errorlevel 1 (
    echo ERROR: doc generation failed, aborting.
    popd
    exit /b 1
)

echo.
echo === [3/4] Building MkDocs site ===
call mkdocs build --clean
if errorlevel 1 (
    echo ERROR: mkdocs build failed, aborting.
    popd
    exit /b 1
)

echo.
echo === [4/4] Deploying to Cloudflare Pages ===
call npx wrangler pages deploy site --project-name=legendary-ffxi --commit-dirty=true
if errorlevel 1 (
    echo ERROR: deploy failed, aborting.
    popd
    exit /b 1
)

popd
echo.
echo === Done! Catalogs re-scored, docs regenerated, site deployed. ===
echo.
