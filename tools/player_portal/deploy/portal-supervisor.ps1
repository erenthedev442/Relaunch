<#
    portal-supervisor.ps1 -- keep the Player Portal (uvicorn) running on the
    OVH VPS, mirroring the game's relaunch-supervisor.ps1 pattern.

    Registered as a Scheduled Task (see DEPLOY_WINDOWS.md) set to run at startup
    "whether the user is logged on or not." It runs uvicorn in the foreground and
    restarts it if it ever exits, logging to portal-supervisor.log next to app.py.

    The portal binds 127.0.0.1 only -- it is reachable solely through the
    Cloudflare tunnel, never directly from the internet.
#>

$ErrorActionPreference = 'Stop'

# tools/player_portal  (this script lives in .../deploy)
$AppDir = Split-Path -Parent $PSScriptRoot
$Python = Join-Path $AppDir '.venv\Scripts\python.exe'
$LogFile = Join-Path $AppDir 'portal-supervisor.log'

$BindHost = '127.0.0.1'
$Port     = if ($env:PORTAL_PORT) { $env:PORTAL_PORT } else { '8090' }

function Write-Log([string]$msg) {
    $line = ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg)
    Add-Content -Path $LogFile -Value $line -Encoding utf8
}

if (-not (Test-Path $Python)) {
    Write-Log "FATAL: venv python not found at $Python -- run the venv/pip step in DEPLOY_WINDOWS.md first."
    throw "venv python not found at $Python"
}

Set-Location $AppDir
Write-Log "supervisor start (app=$AppDir host=$BindHost port=$Port)"

# uvicorn logs to STDERR. Under $ErrorActionPreference='Stop' (set above for the
# venv preflight), PowerShell 5.1 turns the first native stderr write into a
# TERMINATING error -- so the catch below would "crash" and restart uvicorn on
# every launch. Relax it for the run loop; a genuine launch failure still throws.
$ErrorActionPreference = 'Continue'

while ($true) {
    Write-Log "launching uvicorn app:app on ${BindHost}:${Port}"
    try {
        # Foreground: this blocks until uvicorn exits. .env is loaded by app.py
        # (python-dotenv), so no env wiring is needed here.
        # NOTE: --reload was tried but misbehaved on this box (uvicorn exited
        # code=3 on change instead of in-process reloading, and didn't reliably
        # pick up scp'd code) -- reverted to a plain launch; deploys need a task
        # restart (Stop/Start FFXIPortal) to load new app.py.
        & $Python -m uvicorn app:app --host $BindHost --port $Port *>> $LogFile
        $code = $LASTEXITCODE
        Write-Log "uvicorn exited (code=$code) -- restarting in 5s"
    }
    catch {
        Write-Log ("uvicorn crashed: {0} -- restarting in 5s" -f $_.Exception.Message)
    }
    Start-Sleep -Seconds 5
}
