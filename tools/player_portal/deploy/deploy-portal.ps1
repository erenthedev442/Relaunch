<#
    deploy-portal.ps1 — Player Portal deploy for the OVH VPS (Relaunch repo).

    The portal migrated out of the FJB/Legendary repo on 2026-07-11: it now
    lives at tools/player_portal in github.com/richardknutzjr/Relaunch
    (branch `relaunch`), checked out on the box at C:\ffxi-portal-relaunch
    (sparse checkout of tools/player_portal only).

    Publishes the latest committed portal code and restarts the FFXIPortal task.

    IT CANNOT LOSE LOCAL WORK. Before it updates, any uncommitted changes in
    the checkout (tracked AND untracked) are auto-committed to a timestamped
    recovery branch `wip-backup/<timestamp>`. Then it hard-resets to
    origin/relaunch and restarts the FFXIPortal task. A wiped edit can always
    be recovered with:  git -C C:\ffxi-portal-relaunch checkout wip-backup/<ts>

    Secrets (.env, vapid_private.pem) live in the checkout's
    tools\player_portal\ but are gitignored — resets never touch them.

    Run it either way:
      * double-click  C:\ffxi-portal-ops\Deploy-Portal.bat   (easiest), or
      * elevated PS:  powershell -ExecutionPolicy Bypass -File <this file>

    Safe to re-run. Deterministic. Reads/writes only the portal + its own log.
#>
[CmdletBinding()]
param(
    [string]$Repo   = "C:\ffxi-portal-relaunch",
    [string]$Remote = "origin",
    [string]$Branch = "relaunch",
    [string]$Task   = "FFXIPortal",
    [string]$Health = "http://127.0.0.1:8090/"
)

$ErrorActionPreference = "Stop"
$LogDir = "C:\ffxi-portal-ops\logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Log = Join-Path $LogDir "deploy-portal.log"
function Log($m) {
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m
    $line | Out-File -FilePath $Log -Append -Encoding utf8
    Write-Host $line
}

try {
    if (-not (Test-Path $Repo)) { throw "Portal checkout not found at $Repo" }
    Set-Location $Repo
    Log "===== deploy-portal START ($Repo <- $Remote/$Branch) ====="
    $prev = (git rev-parse HEAD).Trim()
    Log "current (last-good) commit: $prev"

    # ---- 1. Never lose local work: WIP-backup anything uncommitted ----
    $dirty = git status --porcelain
    if ($dirty) {
        $ts = Get-Date -Format "yyyyMMdd-HHmmss"
        $wip = "wip-backup/$ts"
        Log "uncommitted changes found -- backing up to branch $wip"
        git checkout -b $wip | Out-Null
        git add -A | Out-Null
        git commit -m "wip-backup before portal deploy $ts" | Out-Null
        git checkout $Branch | Out-Null
        Log "backup committed to $wip"
    }

    # ---- 2. Publish latest committed code ----
    git fetch $Remote $Branch
    git reset --hard "$Remote/$Branch"
    Log ("now at: " + (git log -1 --oneline))

    # ---- 3. Keep the venv in sync with requirements.txt ----
    $App = Join-Path $Repo "tools\player_portal"
    $Py  = Join-Path $App ".venv\Scripts\python.exe"
    if (Test-Path $Py) {
        Log "pip install -r requirements.txt (quiet)"
        & $Py -m pip install -q -r (Join-Path $App "requirements.txt")
    } else {
        Log "WARNING: no venv at $Py -- run deploy\setup_portal_windows.ps1 first"
    }

    # ---- 3b. SMOKE TEST the new code BEFORE restarting (2026-07-26) ----
    # A module-level error (bad import, syntax) makes uvicorn crash-loop with
    # nothing to serve -> 502. Catch it here and ROLL BACK so the still-running
    # portal keeps serving the last-good code instead of going down.
    if (Test-Path $Py) {
        Log "smoke test: python -c 'import app'"
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        Push-Location $App
        $smoke = & $Py -c "import app" 2>&1 | Out-String
        $rc = $LASTEXITCODE
        Pop-Location
        $ErrorActionPreference = $prevEAP
        if ($rc -ne 0) {
            Log ("SMOKE FAILED (import app exit=$rc): " + $smoke.Trim())
            Log "rolling back to last-good $prev and NOT restarting -- running portal keeps serving"
            git reset --hard $prev | Out-Null
            throw "portal smoke test failed -- deploy aborted + rolled back to $prev (no restart)"
        }
        Log "smoke OK"
    }

    # ---- 4. Restart the portal ----
    Log "restarting task $Task"
    schtasks /end /tn $Task 2>$null | Out-Null
    Start-Sleep -Seconds 3
    schtasks /run /tn $Task | Out-Null
    Start-Sleep -Seconds 8

    # ---- 5. Health check ----
    $ok = $false
    foreach ($i in 1..6) {
        try {
            $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 -Uri $Health
            if ($r.StatusCode -eq 200) { $ok = $true; break }
        } catch { Start-Sleep -Seconds 5 }
    }
    if ($ok) { Log "HEALTH OK ($Health) -- deploy complete" }
    else     { Log "HEALTH FAILED ($Health) -- check portal-supervisor.log in $App" }

    Log "===== deploy-portal END ====="
}
catch {
    Log ("FATAL: " + $_.Exception.Message)
    throw
}
