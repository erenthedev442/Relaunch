<#
    Relaunch deep crash triage -- runs every 10 min via "Relaunch-CrashTriage".

    Complements tools/crash-watcher/crash_watcher_relaunch.py rather than replacing
    it. That watcher fires within a minute and posts what Wheaty already wrote; this
    one is the slower, heavier pass that covers Wheaty's two blind spots:

      1. cdb post-mortem of every new dump, so a crash inside a module we have no
         PDBs for (mariadbcpp.dll, ntdll) still gets a blamed frame instead of
         "?trim@SQLString@sql@@...+52FF".
      2. SILENT DEATHS -- xi_map vanishing with no Wheaty report at all (seen
         2026-09-01 07:15:43). The python watcher keys off new dump files, so it
         never notices these. Here they are inferred from a supervisor restart that
         no dump, watchdog line or force-kill explains, and posted like a crash.

    Read-only against the game. Idle priority so cdb never competes with the map
    tick for the shared C: drive (a heavy batch job at Normal priority is what used
    to trip the inactivity watchdog -- see tools/ovh-ops/README.md).
#>
$ErrorActionPreference = 'Continue'
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}

$Ops        = 'C:\relaunch-ops'
$log        = Join-Path $Ops 'logs\crash_triage.log'
$stateFile  = Join-Path $Ops 'crash-triage\state.json'
$hookFile   = Join-Path $Ops '.crash_webhook'
$triageTool = Join-Path $Ops 'triage_dump.ps1'
$DmpDir     = 'C:\server\dmp'
$SupLog     = 'C:\server\relaunch-supervisor.log'
$MapLog     = 'C:\server\log\map-server.log'

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stateFile) | Out-Null
if ((Test-Path $log) -and (Get-Item $log).Length -gt 2MB) {
    (Get-Content $log -Tail 500) | Set-Content -Path $log -Encoding utf8
}
function Log([string]$m) {
    ("{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) | Out-File -FilePath $log -Append -Encoding utf8
}

function Post([string]$content) {
    if (-not (Test-Path $hookFile)) { Log 'no .crash_webhook -- not posting'; return }
    $hook = (Get-Content $hookFile -Raw).Trim()
    if ($hook -notmatch '^https://discord\.com/api/webhooks/') { Log 'webhook file is not a Discord URL'; return }
    if ($content.Length -gt 1900) { $content = $content.Substring(0, 1900) + "`n...(truncated)" }
    try {
        Invoke-RestMethod -Uri $hook -Method Post -TimeoutSec 20 `
            -ContentType 'application/json' `
            -Body ([Text.Encoding]::UTF8.GetBytes((@{ content = $content } | ConvertTo-Json -Compress))) | Out-Null
    } catch { Log "post failed: $($_.Exception.Message)" }
}

$state = @{ seen = @(); silent = @(); armed = $false }
if (Test-Path $stateFile) {
    try {
        $raw = Get-Content $stateFile -Raw | ConvertFrom-Json
        $state = @{
            seen   = @($raw.seen)
            silent = @($raw.silent)
            armed  = [bool]$raw.armed
        }
    } catch { Log 'state file unreadable -- starting fresh' }
}

Log 'crash-triage poll'

# ---- 1. cdb-triage any new dump -------------------------------------------
$new = @()
if (Test-Path $triageTool) {
    try {
        $new = @(& $triageTool -All -DmpDir $DmpDir 4>$null | Where-Object { $_ -and $_.Dump })
    } catch { Log "triage_dump failed: $($_.Exception.Message)" }
} else {
    Log "missing $triageTool -- deep triage skipped"
}

# ---- 2. silent deaths: a restart nothing else explains ---------------------
$since    = (Get-Date).AddHours(-24)
$restarts = @()
$kills    = @()
if (Test-Path $SupLog) {
    foreach ($ln in Get-Content $SupLog -ErrorAction SilentlyContinue) {
        if ($ln -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(.+)$') {
            $t = [datetime]::Parse($Matches[1])
            if ($t -lt $since) { continue }
            if     ($Matches[2] -match '^Starting xi_map')      { $restarts += $t }
            elseif ($Matches[2] -match 'HUNG xi_map confirmed') { $kills    += $t }
            elseif ($Matches[2] -match 'Supervisor starting')   { $kills    += $t }  # deliberate cycle, not a crash
        }
    }
}
$deaths = @()
foreach ($f in Get-ChildItem -Path $DmpDir -Filter *.log -File -Recurse -ErrorAction SilentlyContinue) {
    if ($f.LastWriteTime -ge $since) { $deaths += $f.LastWriteTime }
}
if (Test-Path $MapLog) {
    foreach ($hit in Select-String -Path $MapLog -Pattern 'INACTIVITY WATCHDOG HAS TRIGGERED' -ErrorAction SilentlyContinue) {
        if ($hit.Line -match '^\[(\d{2})/(\d{2})/(\d{2}) (\d{2}):(\d{2}):(\d{2})') {
            $t = Get-Date -Year (2000 + [int]$Matches[3]) -Month $Matches[1] -Day $Matches[2] `
                          -Hour $Matches[4] -Minute $Matches[5] -Second $Matches[6]
            if ($t -ge $since) { $deaths += $t }
        }
    }
}

$silentNow = @()
foreach ($r in $restarts) {
    $near = @($deaths + $kills | Where-Object { ($r - $_).TotalSeconds -ge 0 -and ($r - $_).TotalSeconds -le 180 })
    if ($near.Count -eq 0) { $silentNow += $r.ToString('yyyy-MM-dd HH:mm:ss') }
}

# ---- 3. report what is genuinely new --------------------------------------
if (-not $state.armed) {
    # First run: record the world as-is so history is not replayed into Discord.
    $state.seen   = @($new | ForEach-Object { $_.Dump })
    $state.silent = $silentNow
    $state.armed  = $true
    Log "armed: $($state.seen.Count) triaged dump(s), $($silentNow.Count) prior silent death(s) recorded, nothing posted"
} else {
    foreach ($r in $new) {
        if ($state.seen -contains $r.Dump) { continue }
        $msg = @(
            '**Deep triage (cdb)** — ' + $r.Dump,
            '```',
            "exception : $($r.Exception)",
            "blamed    : $($r.Blamed)  (module $($r.Module))",
            $(if ($r.Source)  { "source    : $($r.Source)" }  else { $null }),
            $(if ($r.TopGame) { "top game  : $($r.TopGame)" } else { $null }),
            '```',
            "Full output: ``$($r.Triage)``"
        ) | Where-Object { $_ -ne $null }
        Post ($msg -join "`n")
        Log "posted triage for $($r.Dump): $($r.Blamed)"
        $state.seen += $r.Dump
    }

    foreach ($s in $silentNow) {
        if ($state.silent -contains $s) { continue }
        Post (@(
            '**xi_map SILENT DEATH** — no crash dump was produced',
            "Restarted by the supervisor at **$s**.",
            'No Wheaty report, no inactivity-watchdog line, no supervisor force-kill:',
            'the process vanished before its own handler could run (stack overflow or a',
            'kill from outside). Check `C:\server\dmp\wer\` for a kernel-written dump and',
            'run `crash_report.ps1 -Hours 24 -Context 10` for the map log around it.'
        ) -join "`n")
        Log "posted SILENT DEATH at $s"
        $state.silent += $s
    }
}

# Keep state bounded.
$state.seen   = @($state.seen   | Select-Object -Last 400)
$state.silent = @($state.silent | Select-Object -Last 200)
$state | ConvertTo-Json -Compress | Set-Content -Path $stateFile -Encoding utf8
Log 'done'
