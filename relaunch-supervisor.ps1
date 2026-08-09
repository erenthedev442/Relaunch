# =====================================================================
# Relaunch FFXI server supervisor (VPS / OVH - C:\server, xi_relaunch)
# Starts xi_connect, xi_world, xi_search, xi_map and keeps them alive.
# Run via the "FFXIRelaunch" scheduled task (onstart + manual /run).
#
# Liveness: a process that has EXITED is restarted (missing from the
# process table). But xi_map can also HANG WITHOUT EXITING -- the
# inactivity watchdog throws to abort the process, and if teardown wedges
# the process stays present-but-dead. A presence-only check can't see that,
# so a hung map sat as a zombie for ~2h on 2026-08-08 (18:20 watchdog trip,
# no restart until a manual 20:16 deploy). Fix: xi_map also gets a
# hung-check that force-kills the zombie so the loop below restarts it.
#
# Hang signal = the main tick is provably not advancing. A healthy map
# burns CPU continuously (~60ms / 8s even idle, measured 2026-08-08); a
# blocked/deadlocked process accumulates ~0 CPU. We only kill after the
# CPU stays frozen across several consecutive samples, so a merely
# CPU-STARVED-but-healthy map (transient disk/CPU contention, which is the
# usual cause of a watchdog trip) recovers and is never killed. NOTE: this
# catches the observed blocked/silent hang; a hypothetical *spin* hang
# (main thread pegged in an infinite loop) burns CPU and is NOT caught here
# -- extend with a busy+log-silent rule if one is ever seen.
# =====================================================================
$ErrorActionPreference = 'Continue'
$root   = 'C:\server'
$mysql  = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe'
$log    = Join-Path $root 'relaunch-supervisor.log'
$maplog = Join-Path $root 'log\map-server.log'
# Startup order: connect/world/search bind first, map probes them at init.
$procs = @('xi_connect','xi_world','xi_search','xi_map')

# --- xi_map hung-detection tuning ---------------------------------------
$MapBootGraceSec        = 300  # ignore the hung-check until map is this old (full boot ~1-2 min)
$MapCpuQuietGateSec     = 120  # only bother CPU-sampling once map-server.log has been quiet this long
                               # (healthy quiet gaps reach ~17 min, so log silence alone is NOT a hang)
$MapCpuSampleSec        = 6    # CPU sampling window
$MapCpuFrozenMs         = 15   # < this many CPU-ms over the window == blocked/not ticking (healthy ~47ms/6s)
$MapHungStrikesToKill   = 3    # consecutive unhealthy samples (~16s apart) before we force-kill
# Second, independent signature -- a *spin* hang (main thread pegged in an infinite
# loop): CPU is NOT frozen, so the rule above misses it, but the log goes silent (the
# tick never completes) and CPU stays pegged. Kill only when BOTH hold, so a healthy
# server -- idle (moderate CPU) or busy (logs often, never silent this long) -- is safe.
$MapLogHardCeilingSec   = 1800 # log silence past this (30 min; healthy max ~17 min) is abnormal
$MapCpuPeggedMs         = 3000 # > this CPU-ms over the window (~50%+ of one core) == spinning, not idle

function Log($m) {
    $line = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) $m"
    try { Add-Content -Path $log -Value $line -Encoding utf8 } catch {}
}

function Clear-StaleSessions {
    try { & $mysql -u root '--password=richard' xi_relaunch -e 'DELETE FROM accounts_sessions;' 2>$null } catch {}
}

# Trim log if it grows large
try { if ((Get-Item $log -ErrorAction SilentlyContinue).Length -gt 10MB) { Clear-Content $log } } catch {}

Log '=== Supervisor starting ==='
# Only clear login sessions on a genuine COLD start (map not already up), so a
# monitoring restart of this task on a live server doesn't disturb online players.
if (-not (Get-Process xi_map -ErrorAction SilentlyContinue)) {
    Log 'Cold start: clearing stale login sessions'
    Clear-StaleSessions
} else {
    Log 'Map already running: monitoring only (sessions left intact)'
}

$firstPass      = $true
$mapHungStrikes = 0
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
        elseif ($p -eq 'xi_map') {
            # --- hung xi_map detection (present in the process table but not ticking) ---
            $procAgeSec = 0
            try { $procAgeSec = ((Get-Date) - $running.StartTime).TotalSeconds } catch {}
            if ($procAgeSec -gt $MapBootGraceSec) {
                $logAgeSec = 0
                try { $logAgeSec = ((Get-Date) - (Get-Item $maplog).LastWriteTime).TotalSeconds } catch {}
                if ($logAgeSec -gt $MapCpuQuietGateSec) {
                    # Log has been quiet a while -- confirm the tick is actually moving via CPU.
                    $cpu1 = $running.TotalProcessorTime.TotalMilliseconds
                    Start-Sleep -Seconds $MapCpuSampleSec
                    $running2 = Get-Process xi_map -ErrorAction SilentlyContinue
                    if ($running2) {
                        $cpuDelta = $running2.TotalProcessorTime.TotalMilliseconds - $cpu1
                        # Two unhealthy signatures, both meaning the main tick is not doing normal work:
                        #   frozen = ~0 CPU                          -> blocked/deadlocked (2026-08-08 zombie)
                        #   spin   = pegged CPU AND log past ceiling  -> infinite loop on the main thread
                        # Healthy idle (moderate CPU) and healthy busy (logs frequently) match neither.
                        $frozen = $cpuDelta -lt $MapCpuFrozenMs
                        $spin   = ($logAgeSec -gt $MapLogHardCeilingSec) -and ($cpuDelta -gt $MapCpuPeggedMs)
                        if ($frozen -or $spin) {
                            $mapHungStrikes++
                            $sig = if ($frozen) { 'CPU frozen (blocked)' } else { 'CPU pegged + log past ceiling (spin)' }
                            Log ("xi_map {0}: {1}ms/{2}s, log quiet {3}s - strike {4}/{5}" -f `
                                 $sig, [math]::Round($cpuDelta,1), $MapCpuSampleSec, [int]$logAgeSec, $mapHungStrikes, $MapHungStrikesToKill)
                            if ($mapHungStrikes -ge $MapHungStrikesToKill) {
                                Log "HUNG xi_map confirmed ($sig) - force killing (PID $($running2.Id)); loop will restart it"
                                try { Stop-Process -Id $running2.Id -Force -ErrorAction Stop } catch { Log "Stop-Process failed: $_" }
                                $mapHungStrikes = 0
                                Clear-StaleSessions      # players reconnect after the restart
                                Start-Sleep -Seconds 2   # let the OS release the socket before relaunch
                            }
                        } else {
                            # tick is advancing normally -- healthy (or recovered from transient starvation)
                            $mapHungStrikes = 0
                        }
                    }
                } else {
                    # log is fresh -- tick is clearly alive
                    $mapHungStrikes = 0
                }
            }
        }
    }
    $firstPass = $false
    Start-Sleep -Seconds 10
}
