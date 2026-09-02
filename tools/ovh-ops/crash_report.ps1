<#
.SYNOPSIS
    Answer "why did the server go down" for a time window, in one command.

.DESCRIPTION
    Correlates every source that records an xi_map death and prints them as one
    timeline, because no single source sees them all:

      C:\server\dmp\*.log        Wheaty crash reports (exception + symbolised frame)
      C:\server\dmp\wer\*.dmp    kernel-written dumps -- the only trace of a crash
                                 the in-process handler could not survive
      map-server.log             inactivity-watchdog trips (a stalled tick, not a fault)
      relaunch-supervisor.log    restarts, hung-map force-kills, and the arrival time
                                 that gives each death its recovery gap

    A supervisor restart with no dump and no watchdog line is reported as a SILENT
    DEATH -- that combination is real (2026-09-01 07:15:43) and is invisible to the
    Discord crash watcher, which only reacts to Wheaty reports.

.PARAMETER Hours
    Look-back window. Default 24.

.PARAMETER Context
    Print this many map-server.log lines from just before each death.

.EXAMPLE
    .\crash_report.ps1
    .\crash_report.ps1 -Hours 72
    .\crash_report.ps1 -Hours 24 -Context 10
#>
[CmdletBinding()]
param(
    [int]$Hours   = 24,
    [int]$Context = 0,
    [string]$DmpDir  = 'C:\server\dmp',
    [string]$ServerDir = 'C:\server',
    [string]$MapLog  = 'C:\server\log\map-server.log',
    [string]$SupLog  = 'C:\server\relaunch-supervisor.log'
)

$ErrorActionPreference = 'Continue'
$since = (Get-Date).AddHours(-$Hours)
$events = New-Object System.Collections.ArrayList

function Add-Event($time, $kind, $detail, $source) {
    [void]$events.Add([pscustomobject]@{
        Time = $time; Kind = $kind; Detail = $detail; Source = $source; Recovered = $null
    })
}

# ---- 1. Wheaty crash reports ----------------------------------------------
foreach ($f in Get-ChildItem -Path $DmpDir -Filter *.log -File -ErrorAction SilentlyContinue) {
    if ($f.LastWriteTime -lt $since) { continue }
    $head = Get-Content $f.FullName -TotalCount 200 -ErrorAction SilentlyContinue
    if (-not $head) { continue }
    $text = $head -join "`n"
    if ($text -notmatch '!!! CRASH !!!') { continue }

    $exc = ''; $sha = ''; $when = $f.LastWriteTime
    if ($text -match '(?m)^Exception code:\s*(.+?)\s*$') { $exc = $Matches[1] }
    if ($text -match '(?m)^Git SHA:\s*(\S+)')            { $sha = $Matches[1] }
    if ($text -match '(?m)^Time of crash:\s*(.+?)\s*$') {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParse($Matches[1], [ref]$parsed)) { $when = $parsed }
    }

    # First frame that is our code and not async plumbing.
    $frame = ''
    foreach ($ln in (Get-Content $f.FullName -TotalCount 400)) {
        if ($ln -match '\(C:\\server\\src\\[^)]+, line \d+\)' -and
            $ln -notmatch 'asio-src|vcstartup|WheatyExceptionReport') {
            if ($ln -match '^\s*[0-9A-F]{8,}\s+[0-9A-F]{8,}\s+(.+?)\s+\(C:\\server\\(src\\[^)]+), line (\d+)\)') {
                $frame = "{0} ({1}:{2})" -f $Matches[1], ($Matches[2] -replace '\\', '/'), $Matches[3]
                break
            }
        }
    }
    if (-not $frame) { $frame = '(no game frame named)' }

    $triage = [IO.Path]::ChangeExtension($f.FullName, '.triage.txt')
    $extra  = ''
    if (Test-Path $triage) {
        $v = Select-String -Path $triage -Pattern '^blamed    :' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($v) { $extra = '  | cdb ' + ($v.Line -replace '^blamed    :\s*', '') }
    }
    Add-Event $when 'CRASH' ("$exc  $frame$extra  [$sha]") $f.Name
}

# ---- 2. WER dumps (crashes Wheaty could not report) ------------------------
$werDir = Join-Path $DmpDir 'wer'
foreach ($f in Get-ChildItem -Path $werDir -Filter *.dmp -File -ErrorAction SilentlyContinue) {
    if ($f.LastWriteTime -lt $since) { continue }
    $triage = [IO.Path]::ChangeExtension($f.FullName, '.triage.txt')
    $detail = 'kernel-written dump (no Wheaty report)'
    if (Test-Path $triage) {
        $v = Select-String -Path $triage -Pattern '^(exception|blamed)  ' -ErrorAction SilentlyContinue
        if ($v) { $detail = ($v | ForEach-Object { ($_.Line -replace '\s+', ' ').Trim() }) -join '  ' }
    } else {
        $detail += ' -- run triage_dump.ps1 -All'
    }
    Add-Event $f.LastWriteTime 'WER' $detail $f.Name
}

# ---- 3. Inactivity-watchdog trips ------------------------------------------
if (Test-Path $MapLog) {
    foreach ($hit in Select-String -Path $MapLog -Pattern 'INACTIVITY WATCHDOG HAS TRIGGERED' -ErrorAction SilentlyContinue) {
        if ($hit.Line -match '^\[(\d{2})/(\d{2})/(\d{2}) (\d{2}):(\d{2}):(\d{2})') {
            $t = Get-Date -Year (2000 + [int]$Matches[3]) -Month $Matches[1] -Day $Matches[2] `
                          -Hour $Matches[4] -Minute $Matches[5] -Second $Matches[6]
            if ($t -ge $since) { Add-Event $t 'WATCHDOG' 'main tick blocked >=2000ms (stall, not a fault)' 'map-server.log' }
        }
    }
}

# ---- 4. Supervisor: restarts and force-kills -------------------------------
$restarts   = New-Object System.Collections.ArrayList
$coldStarts = New-Object System.Collections.ArrayList
if (Test-Path $SupLog) {
    foreach ($ln in Get-Content $SupLog -ErrorAction SilentlyContinue) {
        if ($ln -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(.+)$') {
            $t = [datetime]::Parse($Matches[1]); $msg = $Matches[2]
            if ($t -lt $since) { continue }
            if     ($msg -match '^Starting xi_map')      { [void]$restarts.Add($t) }
            elseif ($msg -match 'Supervisor starting')   { [void]$coldStarts.Add($t) }
            elseif ($msg -match 'HUNG xi_map confirmed') { Add-Event $t 'HUNG-KILL' $msg 'relaunch-supervisor.log' }
        }
    }
}
# A rebuild replaces xi_map.exe, and the deploy stops/starts the game around it.
# Those restarts are indistinguishable from a silent death in the supervisor log,
# so use the binary's mtime to recognise them and not cry crash over a deploy.
$binTime = $null
if (Test-Path (Join-Path $ServerDir 'xi_map.exe')) { $binTime = (Get-Item (Join-Path $ServerDir 'xi_map.exe')).LastWriteTime }

# ---- 5. Silent deaths: a restart no other source explains ------------------
$explained = @($events | Where-Object { $_.Kind -ne 'HUNG-KILL' })
foreach ($r in $restarts) {
    $near = $explained | Where-Object { ($r - $_.Time).TotalSeconds -ge 0 -and ($r - $_.Time).TotalSeconds -le 180 }
    $boot = $events | Where-Object { $_.Kind -eq 'HUNG-KILL' -and ($r - $_.Time).TotalSeconds -ge 0 -and ($r - $_.Time).TotalSeconds -le 180 }
    if ($near -or $boot) { continue }

    # Deliberate cycles that are not crashes.
    $cold = $coldStarts | Where-Object { [Math]::Abs(($r - $_).TotalSeconds) -le 180 }
    if ($cold) { Add-Event $r 'RESTART' 'supervisor cold start (deploy / manual cycle)' 'relaunch-supervisor.log'; continue }
    if ($binTime -and [Math]::Abs(($r - $binTime).TotalMinutes) -le 30) {
        Add-Event $r 'RESTART' 'xi_map.exe rebuilt around this time (deploy)' 'xi_map.exe mtime'
        continue
    }

    Add-Event $r.AddSeconds(-5) 'SILENT' 'process vanished: no dump, no watchdog, no supervisor kill' 'inferred from restart'
}

# ---- 6. Pair each death with its restart for the recovery gap --------------
$sorted = @($events | Sort-Object Time)
foreach ($e in $sorted) {
    $after = $restarts | Where-Object { ($_ - $e.Time).TotalSeconds -ge 0 -and ($_ - $e.Time).TotalSeconds -le 600 } | Sort-Object | Select-Object -First 1
    if ($after) { $e.Recovered = [int]($after - $e.Time).TotalSeconds }
}

# ---- report ----------------------------------------------------------------
"";
"xi_map deaths in the last $Hours h  (since $($since.ToString('yyyy-MM-dd HH:mm')))"
"=" * 78
if (-not $sorted) {
    "No deaths recorded. Server was up for the whole window."
} else {
    $sorted | ForEach-Object {
        $gap = if ($null -ne $_.Recovered) { "{0,4}s" -f $_.Recovered } else { "   ?" }
        "{0}  {1,-9} down {2}  {3}" -f $_.Time.ToString('MM-dd HH:mm:ss'), $_.Kind, $gap, $_.Detail
    }
    ""
    "By cause"
    "-" * 78
    $sorted | Group-Object Kind | Sort-Object Count -Descending | ForEach-Object {
        "{0,4}x  {1}" -f $_.Count, $_.Name
    }
    ""
    "Repeat offenders (same source file faulting more than once)"
    "-" * 78
    # Group by FILE, not by frame: the same broken data structure surfaces through
    # several different functions (treasure_pool.cpp crashed once in delMember and
    # once in checkTreasureItem), and grouping by frame hides exactly that pattern.
    $rep = $sorted | Where-Object { $_.Kind -eq 'CRASH' } |
           Group-Object { if ($_.Detail -match '\((src/[^:) ]+):\d+\)') { $Matches[1] } else { 'unattributed' } } |
           Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending
    if ($rep) {
        $rep | ForEach-Object {
            "{0,4}x  {1}" -f $_.Count, $_.Name
            $_.Group | ForEach-Object { "         {0}  {1}" -f $_.Time.ToString('MM-dd HH:mm'), (($_.Detail -split '\s{2,}')[1]) }
        }
    } else { "  none -- every crash in this window was in a different source file" }

    $totalDown = ($sorted | Where-Object { $null -ne $_.Recovered } | Measure-Object Recovered -Sum).Sum
    ""
    "Total recorded downtime: ${totalDown}s across $($sorted.Count) event(s)"
    $untriaged = @(Get-ChildItem -Path $DmpDir -Filter *.dmp -File -Recurse -ErrorAction SilentlyContinue |
                   Where-Object { $_.LastWriteTime -ge $since -and -not (Test-Path ([IO.Path]::ChangeExtension($_.FullName, '.triage.txt'))) })
    if ($untriaged) { "$($untriaged.Count) dump(s) in this window have no cdb triage yet -- run: triage_dump.ps1 -All" }
}

if ($Context -gt 0 -and $sorted -and (Test-Path $MapLog)) {
    ""
    "Map log before each death"
    "=" * 78
    $all = Get-Content $MapLog -ErrorAction SilentlyContinue
    foreach ($e in $sorted) {
        $stamp = '[{0:MM/dd/yy HH:mm}' -f $e.Time
        $idx = -1
        for ($i = $all.Count - 1; $i -ge 0; $i--) {
            if ($all[$i].StartsWith($stamp.Substring(0, 15))) { $idx = $i; break }
        }
        ""
        "--- $($e.Time.ToString('MM-dd HH:mm:ss'))  $($e.Kind) ---"
        if ($idx -ge 0) { $all[([Math]::Max(0, $idx - $Context + 1))..$idx] }
        else            { "  (no map-server.log lines at that minute -- log may have rotated)" }
    }
}
""
