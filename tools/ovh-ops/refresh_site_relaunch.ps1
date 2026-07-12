param([switch]$NoDeploy)

# =====================================================================
# refresh_site_relaunch.ps1  --  OVH self-hosted relaunch docs refresh
#   Regenerates the PRIVATE relaunch docs site from the LIVE OVH server
#   (C:\server + localhost xi_relaunch) and deploys it to Cloudflare
#   Pages (project: fjb-relaunch).
#
#   Ported from the Azure bash cron (refresh_site_relaunch.sh) on
#   2026-07-06.  Key differences vs the Azure version:
#     * reads the LIVE DB over localhost (no remote DB, no SQL_HOST swap)
#     * LiveRoot = C:\server (docgen reads the live Lua + xi_relaunch DB
#       directly -> the Azure repo->live rsync step is dropped)
#     * no augment/catalyst regen into the live tree (docs job stays
#       read-only w.r.t. the running server; committed catalogs are
#       already current post-deploy)
#     * no weekly FFXIAH scrape here (relies on the committed baseline /
#       existing cache; can be re-added as its own task if wanted)
#   SAFE BY DESIGN: only reads xi_relaunch + deploys static files.
# =====================================================================
$ErrorActionPreference = "Continue"   # native non-zero exits do NOT throw in PS 5.1; we check $LASTEXITCODE

# ---- CONFIG ----
$DocsRepo  = "C:\relaunch-docs"
$LiveRoot  = "C:\server"
$CfProject = "fjb-relaunch"
$MkdocsCfg = "mkdocs_relaunch.yml"
$Py        = "C:\Program Files\Python312\python.exe"
$Git       = "C:\Program Files\Git\cmd\git.exe"
$Npx       = "C:\Program Files\nodejs\npx.cmd"
$LogDir    = "C:\relaunch-ops\logs"
$Log       = Join-Path $LogDir "refresh_site_relaunch.log"
$Lock      = "C:\relaunch-ops\refresh_site_relaunch.lock"
$CfEnv     = "C:\relaunch-ops\.cloudflare_env"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
function Log($m){
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m
    $line | Out-File -FilePath $Log -Append -Encoding utf8
    $line
}
# trim log if > 5 MB
if((Test-Path $Log) -and (Get-Item $Log).Length -gt 5MB){ (Get-Content $Log -Tail 2000) | Set-Content $Log -Encoding utf8 }

Log "===== refresh_site_relaunch START (NoDeploy=$NoDeploy) ====="

# ---- single-instance lock ----
$lockStream = $null
try { $lockStream = [System.IO.File]::Open($Lock, 'OpenOrCreate', 'ReadWrite', 'None') }
catch { Log "[skip] previous refresh still running -- exiting"; exit 0 }

try {
    # ---- [0/4] sync docs source to C:\server's committed state (local, no auth) ----
    Set-Location $DocsRepo
    $branch = (& $Git rev-parse --abbrev-ref HEAD 2>$null); if(-not $branch){ $branch = "relaunch" }
    Log "[0/4] syncing $DocsRepo to origin/$branch ..."
    & $Git fetch origin $branch  2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    & $Git reset --hard "origin/$branch" 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8

    # ---- [0b/4] OPS-SELFSYNC: deploy ops scripts from the checkout ----
    # The scheduled tasks run the C:\relaunch-ops COPIES of these scripts; this
    # step keeps those copies current so ops changes land via git alone (repo ->
    # C:\server on game deploy -> this checkout -> C:\relaunch-ops next hour).
    # Guard: only sync when the checkout's copy carries this same OPS-SELFSYNC
    # step, so a stale checkout can never downgrade an already-updated ops dir.
    # (Overwriting THIS running script is safe: PS parses the whole file first.)
    $repoOps = Join-Path $DocsRepo "tools\ovh-ops"
    if (Select-String -Path (Join-Path $repoOps "refresh_site_relaunch.ps1") -Pattern "OPS-SELFSYNC" -Quiet) {
        foreach ($f in @("refresh_site_relaunch.ps1", "site_drift_monitor_relaunch.py", "run_site_drift_monitor.ps1")) {
            Copy-Item (Join-Path $repoOps $f) "C:\relaunch-ops\" -Force
        }
        Log "[0b/4] ops scripts self-synced from checkout"
    } else {
        Log "[0b/4] checkout predates OPS-SELFSYNC -- ops copies left untouched"
    }

    # ---- load Cloudflare token into the environment (wrangler reads it) ----
    if(Test-Path $CfEnv){
        foreach($ln in Get-Content $CfEnv){
            if($ln -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*$'){ Set-Item -Path "Env:$($Matches[1])" -Value $Matches[2] }
        }
    }
    $tokSet = if($env:CLOUDFLARE_API_TOKEN){"yes"}else{"NO"}
    Log "[info] LiveRoot=$LiveRoot (xi_relaunch via localhost)  CF_token=$tokSet"

    # docgen reads the LIVE server tree + live DB
    $env:LEGENDARY_LIVE_ROOT = $LiveRoot

    # ---- [1/4] docgen ----
    Log "[1/4] docgen (leaderboards + player profiles from xi_relaunch)..."
    & $Py "tools\docgen\generate.py" 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    if($LASTEXITCODE -ne 0){ Log "[FATAL] docgen failed (exit $LASTEXITCODE)"; throw "docgen-failed" }

    # ---- [2/4] mkdocs build ----
    Log "[2/4] mkdocs build (config $MkdocsCfg)..."
    & $Py -m mkdocs build --clean -f $MkdocsCfg 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    if($LASTEXITCODE -ne 0){ Log "[FATAL] mkdocs build failed (exit $LASTEXITCODE)"; throw "mkdocs-failed" }

    # ---- guard: 0 player profiles => DB was down, don't publish stale ----
    $players = (Get-ChildItem "site\community\players" -Recurse -File -Filter *.html -EA SilentlyContinue |
                Where-Object { $_.DirectoryName -match '\\community\\players\\.+' }).Count
    Log "[info] built $players player profile page(s)"
    if($players -eq 0){ Log "[SKIP] 0 player profiles -- xi_relaunch unreachable; keeping last-good site"; throw "no-players-skip" }

    if($NoDeploy){ Log "[--NoDeploy] built OK; skipping Cloudflare deploy"; throw "nodeploy-stop" }

    # ---- [2b/4] inject site-wide Basic-Auth Pages Function (all routes) ----
    New-Item -ItemType Directory -Force -Path "functions" | Out-Null
    [System.IO.File]::Copy("$DocsRepo\tools\pages-functions\relaunch\[[path]].js", "$DocsRepo\functions\[[path]].js", $true)
    Log "[2b/4] site auth gate injected"

    # ---- [3/4] deploy to Cloudflare Pages ----
    Log "[3/4] deploy to Cloudflare Pages ($CfProject)..."
    $env:NO_UPDATE_NOTIFIER = "1"            # silence npm's "new version" notice on stderr
    $env:npm_config_update_notifier = "false"
    & $Npx --yes wrangler pages deploy site --project-name=$CfProject --branch=main --commit-dirty=true 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    if($LASTEXITCODE -ne 0){ Log "[FATAL] wrangler deploy failed (exit $LASTEXITCODE) -- CF token set? $tokSet"; throw "wrangler-failed" }

    Log "===== refresh_site_relaunch DONE ====="
}
catch {
    $msg = "$_"
    if($msg -notmatch 'no-players-skip|nodeploy-stop'){ Log "[ERROR] $msg" }
}
finally {
    if($lockStream){ $lockStream.Close(); Remove-Item $Lock -Force -EA SilentlyContinue }
}
