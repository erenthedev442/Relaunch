# =====================================================================
# Legendary FFXI server supervisor
# =====================================================================
# Launches xi_connect, xi_world, xi_search, xi_map and watches them.
# If ANY of the four exits (clean or crash), kills the remaining three
# and relaunches all four. Logs every event to supervisor.log.
#
# USAGE
#   Manual launch:   double-click start-supervisor.bat
#   Stop cleanly:    Ctrl+C in this window, or run stop-supervisor.bat
#   View logs:       D:\server\supervisor.log
#
# CRASH-LOOP BACKOFF
#   Normal cadence is 5s between restart cycles. If we burn through
#   more than 5 restarts in any rolling 60-second window, we back off
#   to 30s between attempts (logged as a WARNING). Once the 60s window
#   clears, we resume normal cadence automatically. Never gives up.
# =====================================================================

$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------
$ServerRoot   = 'D:\server'
$LogPath      = Join-Path $ServerRoot 'supervisor.log'
$StopFile     = Join-Path $ServerRoot 'supervisor.stop'
$PidFile      = Join-Path $ServerRoot 'supervisor.pid'
$MaxLogBytes  = 10MB

$MysqlExe     = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe'
$DbUser       = 'root'
$DbPass       = 'warrior3'
$DbName       = 'xidb'

# Startup order matters: connect/world/search come up first because xi_map
# tries to reach them at init time. Brief delay between each lets ports
# bind before the next process probes them. Tune if your hardware is slow.
$Processes = @(
    @{ Name = 'xi_connect'; Exe = 'xi_connect.exe'; StartDelayMs = 1500 },
    @{ Name = 'xi_world';   Exe = 'xi_world.exe';   StartDelayMs = 1500 },
    @{ Name = 'xi_search';  Exe = 'xi_search.exe';  StartDelayMs = 1000 },
    @{ Name = 'xi_map';     Exe = 'xi_map.exe';     StartDelayMs =  500 }
)

$NormalRestartGapSec = 5
$BackoffRestartGapSec = 30
$CrashWindowSec   = 60
$CrashWindowLimit = 5

# ---------------------------------------------------------------------
# LOGGING
# ---------------------------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory)] [string] $Level,  # INFO / WARN / ERROR
        [Parameter(Mandatory)] [string] $Message
    )
    $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line  = "[$stamp] [$Level] $Message"

    # Console: color-code so crashes stand out.
    $color = switch ($Level) {
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red'    }
        default { 'Gray'   }
    }
    Write-Host $line -ForegroundColor $color

    # File: append, rotate when over the cap so we never balloon to GB.
    try {
        if ((Test-Path $LogPath) -and ((Get-Item $LogPath).Length -gt $MaxLogBytes)) {
            $archive = "$LogPath.1"
            if (Test-Path $archive) { Remove-Item $archive -Force }
            Move-Item $LogPath $archive -Force
        }
        Add-Content -LiteralPath $LogPath -Value $line -Encoding utf8
    } catch {
        # If we can't write the log, just keep going — better to lose log
        # lines than crash the supervisor.
        Write-Host "  (log write failed: $_)" -ForegroundColor DarkYellow
    }
}

# ---------------------------------------------------------------------
# PROCESS LIFECYCLE
# ---------------------------------------------------------------------

# Launch the 4 servers in order. Returns a list of @{ Name; Process } objects.
function Start-AllServers {
    $launched = @()
    foreach ($spec in $Processes) {
        $exe = Join-Path $ServerRoot $spec.Exe
        if (-not (Test-Path $exe)) {
            Write-Log -Level ERROR -Message "Missing binary: $exe. Cannot continue."
            throw "Required binary not found: $exe"
        }

        Write-Log -Level INFO -Message "Starting $($spec.Name) ($($spec.Exe))..."
        $p = Start-Process -FilePath $exe `
                            -WorkingDirectory $ServerRoot `
                            -PassThru
        if (-not $p) {
            Write-Log -Level ERROR -Message "Start-Process returned nothing for $($spec.Name)."
            throw "Failed to start $($spec.Name)"
        }
        Write-Log -Level INFO -Message "  $($spec.Name) PID $($p.Id) launched."
        $launched += @{ Name = $spec.Name; Process = $p }

        Start-Sleep -Milliseconds $spec.StartDelayMs
    }
    return $launched
}

# Kill every process in the list. Used after a crash (to clean up the
# survivors) and during graceful shutdown (Ctrl+C / supervisor.stop).
function Stop-AllServers {
    param([Parameter(Mandatory)] $Launched)

    foreach ($entry in $Launched) {
        $p    = $entry.Process
        $name = $entry.Name
        if (-not $p) { continue }
        try {
            $p.Refresh()
            if (-not $p.HasExited) {
                Write-Log -Level INFO -Message "Killing $name (PID $($p.Id))..."
                # No-op if it's already gone; -Force in case it ignores
                # WM_CLOSE (these are console apps so it likely will).
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                # Brief wait to let the OS release file/socket handles
                # before the next start cycle tries to bind to them.
                $p.WaitForExit(3000) | Out-Null
            }
        } catch {
            Write-Log -Level WARN -Message "Stop-Process failed for $name : $_"
        }
    }
}

# ---------------------------------------------------------------------
# DATABASE HELPERS
# ---------------------------------------------------------------------

# Wipe stale rows from accounts_sessions before each server start.
# If we don't do this, xi_map reads the table at boot and reconstructs
# ghost sessions — causing "Player already logged in" errors for anyone
# who was online when the server last went down.
function Clear-AccountsSessions {
    Write-Log -Level INFO -Message 'Clearing accounts_sessions (prevents ghost login errors)...'
    if (-not (Test-Path $MysqlExe)) {
        Write-Log -Level WARN -Message "  mysql not found at $MysqlExe — skipping session clear."
        return
    }
    & $MysqlExe -u $DbUser "-p$DbPass" $DbName -e 'DELETE FROM accounts_sessions;'
    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level INFO -Message '  accounts_sessions cleared.'
    } else {
        Write-Log -Level WARN -Message "  mysql exited $LASTEXITCODE — accounts_sessions may still have stale rows."
    }
}

# ---------------------------------------------------------------------
# CRASH-LOOP TRACKING
# ---------------------------------------------------------------------
$Script:RestartTimestamps = New-Object System.Collections.Generic.List[DateTime]

function Record-Restart {
    $now = Get-Date
    $Script:RestartTimestamps.Add($now)
    # Prune anything older than the rolling window.
    $cutoff = $now.AddSeconds(-$CrashWindowSec)
    $kept = $Script:RestartTimestamps | Where-Object { $_ -gt $cutoff }
    $Script:RestartTimestamps = New-Object System.Collections.Generic.List[DateTime]
    $kept | ForEach-Object { $Script:RestartTimestamps.Add($_) }
}

function Get-CurrentRestartGap {
    if ($Script:RestartTimestamps.Count -gt $CrashWindowLimit) {
        Write-Log -Level WARN -Message ("Crash loop detected ($($Script:RestartTimestamps.Count) restarts in last ${CrashWindowSec}s). Backing off to ${BackoffRestartGapSec}s between attempts until the window clears.")
        return $BackoffRestartGapSec
    }
    return $NormalRestartGapSec
}

# ---------------------------------------------------------------------
# STOP FILE HANDLING
# ---------------------------------------------------------------------
function Test-StopRequested {
    if (Test-Path $StopFile) {
        Write-Log -Level INFO -Message 'stop file detected — shutting down supervisor.'
        Remove-Item $StopFile -Force -ErrorAction SilentlyContinue
        return $true
    }
    return $false
}

# ---------------------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------------------
# Track the launched set in a script-scope variable so the `finally`
# block can see it even if the loop dies mid-iteration.
$Script:Launched = @()

try {
    # Stale stop-file from a prior run would shut us down immediately —
    # clear it before we start.
    if (Test-Path $StopFile) { Remove-Item $StopFile -Force }

    # Write our PID so stop-supervisor.bat can target us if needed.
    $PID | Out-File -LiteralPath $PidFile -Encoding ascii -Force

    Write-Log -Level INFO -Message '=========================================='
    Write-Log -Level INFO -Message "Supervisor starting (PID $PID, root $ServerRoot)"
    Write-Log -Level INFO -Message '=========================================='

    while ($true) {
        Clear-AccountsSessions
        # Cycle: start everyone, then watch.
        $Script:Launched = Start-AllServers
        Write-Log -Level INFO -Message ('All 4 servers up. Watching for any exit. PIDs: ' + (
            ($Script:Launched | ForEach-Object { "$($_.Name)=$($_.Process.Id)" }) -join ', '))

        # Poll until one exits or a stop is requested. 500ms poll is
        # plenty responsive — the server crash itself dwarfs that.
        $crashed = $null
        while ($true) {
            if (Test-StopRequested) {
                throw [System.OperationCanceledException]::new('stop file')
            }

            $anyExited = $false
            foreach ($entry in $Script:Launched) {
                $entry.Process.Refresh()
                if ($entry.Process.HasExited) {
                    $crashed   = $entry
                    $anyExited = $true
                    break
                }
            }
            if ($anyExited) { break }

            Start-Sleep -Milliseconds 500
        }

        $exitCode = $crashed.Process.ExitCode
        Write-Log -Level ERROR -Message ("$($crashed.Name) exited with code $exitCode. Killing the other 3 and restarting all 4.")

        Stop-AllServers -Launched $Script:Launched
        $Script:Launched = @()
        Record-Restart
        $gap = Get-CurrentRestartGap
        Write-Log -Level INFO -Message "Sleeping ${gap}s before restart cycle..."

        # Poll the stop-file every 500ms during the sleep so a Ctrl+C
        # / stop-supervisor.bat doesn't have to wait the full backoff
        # window (could be 30s) to take effect.
        $wakeAt = (Get-Date).AddSeconds($gap)
        while ((Get-Date) -lt $wakeAt) {
            if (Test-StopRequested) {
                throw [System.OperationCanceledException]::new('stop file')
            }
            Start-Sleep -Milliseconds 500
        }
    }
}
catch [System.OperationCanceledException] {
    Write-Log -Level INFO -Message 'Graceful shutdown requested.'
}
catch {
    Write-Log -Level ERROR -Message "Unhandled error in supervisor: $_"
    Write-Log -Level ERROR -Message $_.ScriptStackTrace
}
finally {
    # Always tear down the servers when the supervisor exits — Ctrl+C,
    # stop-file, or an exception above. Without this, an orphaned
    # xi_map would block the next run from binding its port.
    if ($Script:Launched -and $Script:Launched.Count -gt 0) {
        Write-Log -Level INFO -Message 'Cleaning up server processes...'
        Stop-AllServers -Launched $Script:Launched
    }
    if (Test-Path $PidFile) { Remove-Item $PidFile -Force -ErrorAction SilentlyContinue }
    Write-Log -Level INFO -Message 'Supervisor exited.'
    Write-Log -Level INFO -Message '=========================================='
}
