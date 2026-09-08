<#
.SYNOPSIS
    Proactive map-tick lag monitor -- catch the next flooder/farm before players complain.

.DESCRIPTION
    The map runs ONE game-logic thread doing synchronous DB round-trips, so a single
    bad client (an invalid-packet flood, or a runaway point-farm) can push a tick past
    2000ms and lag everyone. The inactivity watchdog logs that as
    "Process main tick has taken 2000ms or more". This script scans a recent window of
    map-server.log and, when those trips cross a threshold, prints WHO/WHAT is behind it:

      * how many 2000ms tick trips happened in the window,
      * the hottest SQL the tick was stuck on (from the watchdog "Backtrace Messages"),
      * the top characters spamming rejected packets (a flood signature), and
      * for the worst flooder, their REAL client IP (accounts_sessions' INET_NTOA is
        byte-REVERSED on this server -- this un-reverses it) so you can block it.

    Read-only. Meant to run every ~5-10 min from a scheduled task (Relaunch-TickMonitor)
    and append to C:\relaunch-ops\logs\tick_monitor.log. Complements crash_report.ps1
    (which is on-demand "why did it go DOWN"); this is "why is it LAGGING, right now".

.PARAMETER WindowMin
    Look-back window in minutes (default 10).

.PARAMETER TripThreshold
    Number of 2000ms tick trips in the window that flips the report from OK to LAG (default 2).
#>
param(
    [int]$WindowMin     = 10,
    [int]$TripThreshold = 2
)

$ErrorActionPreference = 'Continue'
$MapLog = 'C:\server\log\map-server.log'
$LogDir = 'C:\relaunch-ops\logs'
$OutLog = Join-Path $LogDir 'tick_monitor.log'
$Net    = 'C:\server\settings\network.lua'
$Mysql  = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe'

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
function Emit($m) { $line = ('{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m); $line | Out-File $OutLog -Append -Encoding utf8; $line }

if (-not (Test-Path $MapLog)) { Emit "[tick_monitor] map-server.log not found -- skipping"; return }

# Read a generous tail (the log grows fast under load) and keep only lines within the window.
$cutoff = (Get-Date).AddMinutes(-$WindowMin)
$tail   = Get-Content $MapLog -Tail 25000 -ErrorAction SilentlyContinue
$recent = foreach ($l in $tail) {
    if ($l -match '^\[(\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d)') {
        $ts = [datetime]::new(2000 + [int]$Matches[3], [int]$Matches[1], [int]$Matches[2], [int]$Matches[4], [int]$Matches[5], [int]$Matches[6])
        if ($ts -ge $cutoff) { $l }
    }
}

$trips = @($recent | Where-Object { $_ -match 'main tick has taken' }).Count
if ($trips -lt $TripThreshold) {
    Emit ("[tick_monitor] OK -- {0} tick-stall trip(s) in the last {1} min (threshold {2})" -f $trips, $WindowMin, $TripThreshold)
    return
}

# --- LAG EVENT: identify the culprit -------------------------------------------------
Emit ("[tick_monitor] LAG -- {0} tick-stall (>=2000ms) trip(s) in the last {1} min" -f $trips, $WindowMin)

# Hottest SQL the tick was stuck on, aggregated across the window's watchdog dumps.
$stmts = Select-String -Path $MapLog -Pattern 'INACTIVITY WATCHDOG' -Context 0,30 |
    Select-Object -Last 20 | ForEach-Object {
        $_.Context.PostContext | Where-Object { $_ -match 'preparedStmt:' } |
            ForEach-Object { ($_ -replace '.*preparedStmt:\s*', '' -replace '\s+', ' ').Trim() }
    }
if ($stmts) {
    Emit "  hottest SQL on stalled ticks:"
    $stmts | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 |
        ForEach-Object { Emit ('    {0,4}x  {1}' -f $_.Count, ($_.Name.Substring(0, [math]::Min(90, $_.Name.Length)))) }
}

# Top characters spamming rejected packets in the window (flood signature).
$floods = $recent | Where-Object { $_ -match 'packet from \w+' -and $_ -match '\[warn\]' } |
    ForEach-Object { if ($_ -match 'packet from (\w+)') { $Matches[1] } } |
    Group-Object | Sort-Object Count -Descending | Select-Object -First 5
if ($floods) {
    Emit "  top rejected-packet senders (flooders):"
    $floods | ForEach-Object { Emit ('    {0,6}x  {1}' -f $_.Count, $_.Name) }

    # For the worst flooder, resolve their REAL client IP (un-reverse INET_NTOA).
    $worst = $floods[0].Name
    if ((Test-Path $Net) -and (Test-Path $Mysql)) {
        $u  = [regex]::Match((Get-Content $Net | Select-String 'SQL_LOGIN').Line,     "'([^']*)'").Groups[1].Value
        $pw = [regex]::Match((Get-Content $Net | Select-String 'SQL_PASSWORD').Line,  "'([^']*)'").Groups[1].Value
        $ipR = (& $Mysql -u $u "-p$pw" xi_relaunch -N -B -e "SELECT INET_NTOA(s.client_addr) FROM accounts_sessions s JOIN chars c ON c.charid=s.charid WHERE c.charname='$worst' LIMIT 1;" 2>$null | Where-Object { $_ -notmatch 'insecure' })
        if ($ipR -and $ipR -match '^(\d+)\.(\d+)\.(\d+)\.(\d+)$') {
            $realIp = '{0}.{1}.{2}.{3}' -f $Matches[4], $Matches[3], $Matches[2], $Matches[1]  # un-reverse the octets
            Emit ("    -> worst flooder '{0}' real IP = {1}  (to block: New-NetFirewallRule -DisplayName block-{1} -Direction Inbound -RemoteAddress {1} -Action Block)" -f $worst, $realIp)
        }
    }
}

Emit "  (box hardware is almost never the cause -- see relaunch-packet-flood-lag: mute the flooder / the char_points cache + throttle fixes give burst headroom.)"
