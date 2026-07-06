# =====================================================================
# Relaunch FFXI server supervisor (VPS / OVH - C:\server, xi_relaunch)
# Starts xi_connect, xi_world, xi_search, xi_map and keeps them alive.
# Run via the "FFXIRelaunch" scheduled task (onstart + manual /run).
# =====================================================================
$ErrorActionPreference = 'Continue'
$root  = 'C:\server'
$mysql = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe'
$log   = Join-Path $root 'relaunch-supervisor.log'
# Startup order: connect/world/search bind first, map probes them at init.
$procs = @('xi_connect','xi_world','xi_search','xi_map')

function Log($m) {
    $line = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) $m"
    try { Add-Content -Path $log -Value $line -Encoding utf8 } catch {}
}

# Trim log if it grows large
try { if ((Get-Item $log -ErrorAction SilentlyContinue).Length -gt 10MB) { Clear-Content $log } } catch {}

Log '=== Supervisor starting ==='
# Clear stale login sessions so nobody is stuck "already logged in"
try { & $mysql -u root '--password=richard' xi_relaunch -e 'DELETE FROM accounts_sessions;' 2>$null } catch {}

$firstPass = $true
while ($true) {
    foreach ($p in $procs) {
        $running = Get-Process $p -ErrorAction SilentlyContinue
        if (-not $running) {
            $exe = Join-Path $root "$p.exe"
            if (Test-Path $exe) {
                Log "Starting $p"
                Start-Process -FilePath $exe -WorkingDirectory $root -WindowStyle Hidden
                if ($firstPass) { Start-Sleep -Seconds 2 } else { Start-Sleep -Milliseconds 500 }
            } else {
                Log "MISSING EXE: $exe"
            }
        }
    }
    $firstPass = $false
    Start-Sleep -Seconds 10
}
