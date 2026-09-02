<#
.SYNOPSIS
    Post-mortem one xi_map crash dump with cdb and write a .triage.txt beside it.

.DESCRIPTION
    Wheaty (src/common/WheatyExceptionReport.cpp) writes its own .log next to each
    dump, but it only names frames it has PDBs for -- a crash inside a third-party
    module (mariadbcpp.dll, ntdll) comes out as meaningless offsets, and a crash the
    in-process handler cannot survive (stack overflow) produces no report at all.
    This runs the real debugger over the dump instead:

      .ecxr / !analyze -v   -> faulting instruction, exception record, blamed module
      k / ~*k               -> full stack for the faulting thread and every thread
      lm                    -> which modules did and did not resolve symbols

    It also keeps a local symbol store so OLD dumps stay readable. xi_map.pdb is
    overwritten by every rebuild, so without archiving, a dump from last week's
    binary can never be symbolised again. Each run adds the current xi_map.exe/.pdb
    to the store (symstore dedupes by build signature, so repeat runs are no-ops).

.PARAMETER Dump
    Dump to analyse. Defaults to the newest .dmp under -DmpDir.

.PARAMETER All
    Triage every dump that has no .triage.txt yet, instead of just one.

.EXAMPLE
    .\triage_dump.ps1
    .\triage_dump.ps1 -Dump C:\server\dmp\xi_map.exe_1-9_18-55-13.dmp
    .\triage_dump.ps1 -All
#>
[CmdletBinding()]
param(
    [string]$Dump,
    [string]$DmpDir      = 'C:\server\dmp',
    [string]$ServerDir   = 'C:\server',
    [string]$SymbolStore = 'C:\symbols\local',
    [string]$SymbolCache = 'C:\symbols\cache',
    [switch]$All,
    [switch]$Force,
    [switch]$WithSymbolServer,
    [int]$TimeoutSec = 120
)

$ErrorActionPreference = 'Stop'
# Batch job on the game's shared C: drive -- never outrank the map tick.
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}

function Find-Tool([string]$name) {
    $roots = @(
        "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64",
        "C:\Program Files\Windows Kits\10\Debuggers\x64",
        "C:\Program Files\Debugging Tools for Windows (x64)"
    )
    foreach ($r in $roots) {
        $p = Join-Path $r $name
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$cdb = Find-Tool 'cdb.exe'
if (-not $cdb) {
    throw ("cdb.exe not found. Install the Windows SDK debuggers:`n" +
           "  curl.exe -L -o C:\Temp\winsdksetup.exe ""https://go.microsoft.com/fwlink/?linkid=2272610""`n" +
           "  C:\Temp\winsdksetup.exe /features OptionId.WindowsDesktopDebuggers /quiet /norestart")
}

# ---- archive the current build's symbols so future dumps stay readable ------
$symstore = Find-Tool 'symstore.exe'
if ($symstore) {
    New-Item -ItemType Directory -Force -Path $SymbolStore | Out-Null
    foreach ($f in @('xi_map.exe', 'xi_map.pdb')) {
        $src = Join-Path $ServerDir $f
        if (Test-Path $src) {
            # /compress off keeps the store directly readable by cdb; symstore skips
            # anything already present under the same signature, so this is cheap.
            & $symstore add /f $src /s $SymbolStore /t xi_map /o 2>&1 | Out-Null
        }
    }
}

# Local symbols only by DEFAULT. This box cannot reach msdl.microsoft.com at any
# useful speed -- with the public store in the path cdb wedged past 420s, while the
# same analysis with local symbols finishes in ~6s and still resolves the faulting
# instruction, registers and every xi_map frame. Opt in with -WithSymbolServer when
# you specifically need Microsoft's ntdll/kernel32 symbols and can wait; without
# them !analyze -v blames "ntdll_wrong_symbols", which you should ignore in favour
# of the FAULTING INSTRUCTION and stack below it.
$symPath = "$SymbolStore;$ServerDir"
if ($WithSymbolServer) {
    $symPath = "srv*$SymbolCache*https://msdl.microsoft.com/download/symbols;$symPath"
    New-Item -ItemType Directory -Force -Path $SymbolCache | Out-Null
}

# ---- pick the dump(s) ------------------------------------------------------
$targets = @()
if ($Dump) {
    if (-not (Test-Path $Dump)) { throw "No such dump: $Dump" }
    $targets = @(Get-Item $Dump)
} else {
    $pool = @(Get-ChildItem -Path $DmpDir -Filter *.dmp -File -Recurse -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending)
    if (-not $pool) { Write-Host "No dumps under $DmpDir"; return }
    if ($All) { $targets = $pool } else { $targets = @($pool[0]) }
}

$results = @()
foreach ($d in $targets) {
    $out = [IO.Path]::ChangeExtension($d.FullName, '.triage.txt')
    if ((Test-Path $out) -and -not $Force) {
        Write-Verbose "skip (already triaged): $($d.Name)"
        continue
    }

    Write-Host "Analysing $($d.Name) ..."
    # Commands go in via STDIN, not -c, and that detail matters twice over:
    #   * With only stdout redirected, cdb blocks forever at the `0:000>` prompt
    #     under a non-interactive session (SSH, Task Scheduler), so every analysis
    #     died on the timeout instead of finishing in seconds.
    #   * With -c commands AND a `q` on stdin, cdb races the two and quits after the
    #     first -c command, producing an empty report.
    # Feeding the whole script down stdin, ending in `q`, is deterministic in both.
    #
    # Deliberately NO `.reload /f`: forcing every module's symbols off the Microsoft
    # symbol server takes many minutes on this box and times the run out. Deferred
    # loading (SYMOPT_DEFERRED_LOADS, on by default) fetches only what the stack
    # actually touches, which is the handful of modules we care about.
    # .ecxr first so the stack shown is the FAULTING context, not the handler's.
    $script = @(
        '.symopt+0x40'
        '.ecxr'
        '!analyze -v'
        '.echo ---FAULTING-STACK---'
        'kb 40'
        '.echo ---ALL-THREADS---'
        '~*kb 12'
        '.echo ---MODULES---'
        'lm 1m'
        'q'
    )

    $stdout = "$out.tmp"
    $stdin  = "$out.cdbin"
    Set-Content -Path $stdin -Value $script -Encoding ascii
    $proc = Start-Process -FilePath $cdb -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdout -RedirectStandardInput $stdin `
            -ArgumentList @('-z', $d.FullName, '-y', $symPath)
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
        try { $proc.Kill() } catch {}
        Write-Warning "cdb timed out after ${TimeoutSec}s on $($d.Name)"
    }

    $text = ''
    if (Test-Path $stdout) { $text = Get-Content $stdout -Raw; Remove-Item $stdout -Force }
    Remove-Item $stdin -Force -ErrorAction SilentlyContinue

    # ---- distil a verdict --------------------------------------------------
    function Field([string]$key) {
        $m = [regex]::Match($text, "(?m)^$([regex]::Escape($key)):\s*(.+?)\s*$")
        if ($m.Success) { return $m.Groups[1].Value }
        return ''
    }
    # cdb states the real exception on load, e.g.
    #   (31e4.138): Access violation - code c0000005 (first/second chance not available)
    # Prefer that over !analyze's EXCEPTION_CODE_STR, which is garbage when the OS
    # symbols do not match (it reports a checksum, not an exception code).
    $exc = ''
    $mx = [regex]::Match($text, '\([0-9a-f]+\.[0-9a-f]+\):\s*(.+?)\s*-\s*code\s*([0-9a-f]{8})')
    if ($mx.Success) { $exc = "$($mx.Groups[2].Value) ($($mx.Groups[1].Value))" }
    if (-not $exc) { $exc = Field 'ExceptionCode' }
    $sym    = Field 'SYMBOL_NAME'
    $mod    = Field 'MODULE_NAME'
    $srcline= Field 'FAULTING_SOURCE_LINE'
    $srcfile= Field 'FAULTING_SOURCE_FILE'
    $bucket = Field 'FAILURE_BUCKET_ID'

    # Top game frame from the faulting stack (skip asio/std plumbing).
    $topGame = ''
    $stackSection = ''
    $i = $text.IndexOf('---FAULTING-STACK---')
    if ($i -ge 0) {
        $j = $text.IndexOf('---ALL-THREADS---', $i)
        if ($j -lt 0) { $j = $text.Length }
        $stackSection = $text.Substring($i, $j - $i)
        foreach ($ln in $stackSection -split "`r?`n") {
            if ($ln -match 'xi_map!' -and $ln -notmatch 'asio::|std::|WheatyExceptionReport') {
                $topGame = ($ln -replace '^\s*[0-9a-f`]+\s+[0-9a-f`]+\s+', '').Trim()
                break
            }
        }
    }

    # The faulting instruction + operand is usually the whole story (e.g. a `lock xadd`
    # on a garbage pointer = an atomic refcount touched through a freed object).
    $faultSym = ''; $faultIns = ''
    $lines = $text -split "`r?`n"
    # Start AFTER the echoed initial command: cdb prints the process's current
    # (post-handler) context on load, and that decoy pair -- typically
    # ntdll!NtGetContextThread -- sits above everything .ecxr produces.
    # cdb prints the process's CURRENT (post-handler) context when the dump loads --
    # typically ntdll!NtGetContextThread -- long before .ecxr restores the faulting
    # one. Anchor on the LAST register dump instead of that decoy; .ecxr's register
    # block is the last `rax=` in the file before the stack sections.
    $start = 0
    for ($k = 0; $k -lt $lines.Count; $k++) {
        if ($lines[$k] -match '^rax=') { $start = $k + 1 }
        if ($lines[$k] -match '^---FAULTING-STACK---') { break }
    }
    for ($k = $start; $k -lt $lines.Count - 1; $k++) {
        if ($lines[$k] -match '^[A-Za-z0-9_]+![^\s]+:\s*$') {
            $nxt = $lines[$k + 1]
            if ($nxt -match '^[0-9a-f`]+\s+[0-9a-f]+\s+\S') {
                $faultSym = $lines[$k].TrimEnd(':')
                $faultIns = ($nxt -replace '^[0-9a-f`]+\s+[0-9a-f]+\s+', '').Trim()
                break
            }
        }
    }

    $verdict = @()
    $verdict += "dump      : $($d.FullName)"
    $verdict += "crashed   : $($d.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    $verdict += "exception : $exc"
    if ($faultSym) { $verdict += "faulting  : $faultSym" }
    if ($faultIns) { $verdict += "instr     : $faultIns" }
    $verdict += "blamed    : $sym  (module $mod)"
    if ($srcfile) { $verdict += "source    : $srcfile$(if ($srcline) { "  ->  $srcline" })" }
    if ($topGame) { $verdict += "top game  : $topGame" }
    if ($bucket)  { $verdict += "bucket    : $bucket" }
    if ($mod -match 'wrong_symbols') {
        $verdict += "NOTE      : !analyze blamed mismatched OS symbols -- ignore 'blamed' and read"
        $verdict += "            'faulting'/'instr' and the stack. Re-run -WithSymbolServer for a"
        $verdict += "            real !analyze verdict (slow: msdl is barely reachable from here)."
    }
    if ($text -match 'ERROR: Module load completed but symbols could not be loaded for .*xi_map') {
        $verdict += "WARNING   : no matching xi_map.pdb for this build -- frames are unreliable."
        $verdict += "            Symbols are archived per build in $SymbolStore from now on."
    }

    $header = @(
        '=== triage_dump.ps1 ===',
        "generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "cdb       : $cdb",
        "sympath   : $symPath",
        '',
        '--- VERDICT ---'
    ) + $verdict + @('', '--- FULL cdb OUTPUT ---', '')

    ($header + ($text -split "`r?`n")) | Set-Content -Path $out -Encoding utf8
    Write-Host ($verdict -join "`n")
    Write-Host "-> $out`n"

    $results += [pscustomobject]@{
        Dump      = $d.Name
        When      = $d.LastWriteTime
        Exception = $exc
        Blamed    = $sym
        Module    = $mod
        Source    = $srcline
        Faulting  = $faultSym
        Instr     = $faultIns
        TopGame   = $topGame
        Triage    = $out
    }
}

if (-not $results) { Write-Host "Nothing new to triage (use -Force to redo)." }
$results
