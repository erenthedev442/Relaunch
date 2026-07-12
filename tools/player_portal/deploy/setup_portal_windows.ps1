<#
    setup_portal_windows.ps1 -- ONE-SHOT installer for the Player Portal on the
    OVH relaunch VPS (Windows), co-located with the xi_relaunch DB.

    Run it in an ELEVATED PowerShell on the VPS:

        Set-ExecutionPolicy -Scope Process Bypass -Force
        .\setup_portal_windows.ps1

    It is idempotent -- safe to re-run. It:
      1. clones (or pulls) the Legendary branch to C:\ffxi-portal
      2. builds the venv + installs requirements
      3. creates portal_ro / portal_rw + tables on xi_relaunch  (prompts for pwds)
      4. writes .env (fresh JWT secret, COOKIE_SECURE=true)
      5. registers + starts the FFXIPortal scheduled task (uvicorn on 127.0.0.1:8090)
      6. health-checks http://127.0.0.1:8090/api/health
      7. (optional) installs the cloudflared tunnel service if you pass -TunnelToken

    The tunnel token is handed to you separately (set up in the Cloudflare
    dashboard). You can pass it now, or install the tunnel later by re-running
    with just -TunnelToken '<token>' -SkipApp.

    Password note: to keep the auto-generated SQL simple, avoid a single-quote (')
    in the two DB passwords. Everything else is fine.
#>
[CmdletBinding()]
param(
    [string] $RepoDir     = 'C:\ffxi-portal',
    [int]    $Port        = 8090,
    [string] $DbName      = 'xi_relaunch',
    [string] $DbAdminUser = 'root',
    [string] $TunnelToken = '',
    [switch] $SkipDb,
    [switch] $SkipApp
)

$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m){   Write-Host "    $m" -ForegroundColor Green }
function Warn($m){ Write-Host "    $m" -ForegroundColor Yellow }
function Die($m){  Write-Host "FATAL: $m" -ForegroundColor Red; exit 1 }

# --- elevation (needed for the scheduled task + cloudflared service) ----------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Die "Run this in an ELEVATED PowerShell (right-click -> Run as administrator)." }

function Find-Tool([string]$name, [string[]]$fallbacks){
    $c = Get-Command $name -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in $fallbacks) { if (Test-Path $p) { return $p } }
    return $null
}

$AppDir = Join-Path $RepoDir 'tools\player_portal'

# =====================================================================
# 1-6: portal app (skip with -SkipApp when you only want the tunnel step)
# =====================================================================
if (-not $SkipApp) {
    $git = Find-Tool 'git' @()
    if (-not $git) { Die "git not found on PATH. Install Git for Windows, then re-run." }

    $py = Find-Tool 'py' @('C:\Windows\py.exe')
    if (-not $py) { $py = Find-Tool 'python' @() }
    if (-not $py) { Die "Python not found (py/python). Install Python 3.10+ (Add to PATH), then re-run." }

    # ---- 1. code ----
    Info "Portal code -> $RepoDir"
    if (Test-Path (Join-Path $RepoDir '.git')) {
        & $git -C $RepoDir fetch --depth 1 origin Legendary
        & $git -C $RepoDir reset --hard origin/Legendary
        Ok "updated to origin/Legendary"
    } else {
        & $git clone --branch Legendary --depth 1 `
            https://github.com/richardknutzjr/FFXI-Private-Server-FJB.git $RepoDir
        Ok "cloned"
    }
    if (-not (Test-Path (Join-Path $AppDir 'app.py'))) { Die "app.py not found under $AppDir" }

    # ---- 2. venv + deps ----
    Info "Python venv + requirements"
    $venvPy = Join-Path $AppDir '.venv\Scripts\python.exe'
    if (-not (Test-Path $venvPy)) { & $py -m venv (Join-Path $AppDir '.venv') }
    & $venvPy -m pip install --upgrade pip --quiet
    & $venvPy -m pip install -r (Join-Path $AppDir 'requirements.txt') --quiet
    Ok "dependencies installed"

    # ---- collect DB passwords once (used by both the SQL and the .env) ----
    if (-not $SkipDb) {
        $roPass = Read-Host "Set a password for portal_ro (read-only)" -AsSecureString
        $rwPass = Read-Host "Set a password for portal_rw (write)   " -AsSecureString
        $adminPass = Read-Host "MariaDB $DbAdminUser password (to create the users)" -AsSecureString
        $roPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($roPass))
        $rwPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($rwPass))
        $adminPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPass))
        if ($roPlain -match "'" -or $rwPlain -match "'") { Die "DB passwords must not contain a single-quote (')." }

        # ---- 3. DB users + tables ----
        Info "Creating portal_ro / portal_rw + tables on $DbName"
        $mysql = Find-Tool 'mysql' @(
            'C:\Program Files\MariaDB 11.4\bin\mysql.exe',
            'C:\Program Files\MariaDB 11.3\bin\mysql.exe',
            'C:\Program Files\MariaDB 10.11\bin\mysql.exe',
            'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe')
        if (-not $mysql) { Die "mysql client not found. Add MariaDB's bin\ to PATH or edit the path list, then re-run (or run the .sql by hand and pass -SkipDb)." }

        $sqlPath = Join-Path $AppDir 'sql\portal_setup_windows.sql'
        $sql = (Get-Content $sqlPath -Raw).
            Replace('CHANGE_ME_read_password',  $roPlain).
            Replace('CHANGE_ME_write_password', $rwPlain)
        $env:MYSQL_PWD = $adminPlain
        try {
            $sql | & $mysql -h 127.0.0.1 -u $DbAdminUser $DbName
            if ($LASTEXITCODE -ne 0) { Die "mysql returned $LASTEXITCODE -- check the admin password / DB name." }
        } finally { Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue }
        Ok "DB users + portal_item_log + portal_vault ready"
    }

    # ---- 4. .env ----
    Info "Writing .env"
    $envPath = Join-Path $AppDir '.env'
    if (Test-Path $envPath) { Copy-Item $envPath "$envPath.bak" -Force; Warn "existing .env backed up to .env.bak" }
    $jwt = (& $venvPy -c "import secrets; print(secrets.token_urlsafe(48))").Trim()
    if (-not $SkipDb) {
        @(
            "PORTAL_DB_HOST=127.0.0.1"
            "PORTAL_DB_PORT=3306"
            "PORTAL_DB_USER=portal_ro"
            "PORTAL_DB_PASS=$roPlain"
            "PORTAL_DB_NAME=$DbName"
            "PORTAL_DB_WRITE_USER=portal_rw"
            "PORTAL_DB_WRITE_PASS=$rwPlain"
            "PORTAL_JWT_SECRET=$jwt"
            "PORTAL_JWT_TTL_HOURS=12"
            "PORTAL_COOKIE_NAME=portal_session"
            "PORTAL_COOKIE_SECURE=true"
            "PORTAL_COOKIE_SAMESITE=lax"
            "PORTAL_CORS_ORIGINS="
        ) | Set-Content $envPath -Encoding utf8
        Ok ".env written"
    } elseif (-not (Test-Path $envPath)) {
        Warn "-SkipDb and no existing .env: copy .env.example to .env and fill it in before the task will start."
        Copy-Item (Join-Path $AppDir '.env.example') $envPath
    }

    # ---- 5. scheduled task ----
    Info "Registering the FFXIPortal scheduled task"
    $ps1 = Join-Path $AppDir 'deploy\portal-supervisor.ps1'
    if (Get-ScheduledTask -TaskName 'FFXIPortal' -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName 'FFXIPortal' -Confirm:$false
    }
    $action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ps1`""
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName 'FFXIPortal' -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    Start-ScheduledTask -TaskName 'FFXIPortal'
    Ok "task registered + started"

    # ---- 6. health check ----
    Info "Health check (up to 30s)"
    $healthy = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep 2
        try {
            $r = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/health" -TimeoutSec 3
            if ($r.ok) { $healthy = $true; break }
        } catch { }
    }
    if ($healthy) { Ok "portal healthy on http://127.0.0.1:$Port" }
    else { Warn "no healthy response yet -- check: Get-Content $AppDir\portal-supervisor.log -Tail 40" }
}

# =====================================================================
# 7: cloudflared tunnel (optional)
# =====================================================================
if ($TunnelToken) {
    Info "Installing the cloudflared tunnel service"
    $cf = Find-Tool 'cloudflared' @('C:\Program Files\cloudflared\cloudflared.exe', "$env:ProgramFiles\cloudflared\cloudflared.exe")
    if (-not $cf) { Die "cloudflared.exe not found -- install it, then re-run with -TunnelToken '<token>' -SkipApp." }
    & $cf service install $TunnelToken
    Start-Sleep 2
    try { Start-Service cloudflared -ErrorAction SilentlyContinue } catch { }
    Ok "cloudflared installed -- the portal should now be live at its hostname once DNS points here."
} else {
    Info "No -TunnelToken given: skipping the tunnel step (portal is up locally on 127.0.0.1:$Port)."
}

Write-Host ""
Ok "Done. If the app step was healthy, tell your operator so they can finish the Cloudflare + Azure cutover."
