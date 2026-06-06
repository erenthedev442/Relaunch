<#
  patch_abilities.ps1  --  Bouncer client relabel, ability-name half.

  Renames the 9 repurposed GEO Job Abilities in the FFXI client's ability-NAME
  table (ROM\181\72.DAT) so the JA menu and the "<player> uses ..." messages read
  as the Bouncer kit instead of the donor GEO names.  This is the companion to the
  FFXiMain.dll job-name swap (install.bat) -- together they make the client show
  BOUNCER everywhere.

  Cosmetic + client-side only.  The server neither knows nor cares about these
  strings; they live in your local game DATs.

  Mechanism: the table is fixed 80-byte records; each name is null-terminated ASCII
  in a ~32-byte slot.  We overwrite the name bytes in place (same file size) and
  null-clear the old remainder, never touching the per-record metadata.  Every new
  name is short enough to fit the slot.

  Usage (normally invoked by install.bat / uninstall.bat, not by hand):
    powershell -ExecutionPolicy Bypass -File patch_abilities.ps1 -FFXI "<FFXI folder>"
    powershell -ExecutionPolicy Bypass -File patch_abilities.ps1 -FFXI "<FFXI folder>" -Restore

  Idempotent: re-running detects already-renamed entries and skips them.
  Reversible: the first run backs up 72.DAT -> 72.DAT.orig; -Restore copies it back.
#>
param(
    [string]$FFXI = 'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'

$dat = Join-Path $FFXI 'ROM\181\72.DAT'
$bak = "$dat.orig"

# Donor GEO name  ->  Bouncer ability name (must match bouncer_abilities.lua/.sql).
$map = [ordered]@{
    'Bolster'            = 'Last Call'
    'Full Circle'        = 'Step Outside'
    'Ecliptic Attrition' = 'Sucker Punch'
    'Widened Compass'    = 'Crowd Control'
    'Collimated Fervor'  = 'Bodyguard'
    'Life Cycle'         = 'Retaliate'
    'Blaze of Glory'     = 'Brace'
    'Dematerialize'      = 'Hold the Line'
    'Theurgic Focus'     = 'Bloodbind'
}

if (-not (Test-Path -LiteralPath $dat)) {
    Write-Host "  ERROR: ability-name DAT not found:"
    Write-Host "         $dat"
    Write-Host "         Check the FFXI path and retry."
    exit 1
}

# ---- Restore mode: put the stock GEO names back ----------------------------
if ($Restore) {
    if (Test-Path -LiteralPath $bak) {
        Copy-Item -LiteralPath $bak -Destination $dat -Force
        Write-Host "  [restore] ability names -> stock GEO (from 72.DAT.orig)"
    } else {
        Write-Host "  [restore] no backup (72.DAT.orig) found - nothing to restore"
    }
    exit 0
}

# ---- Install mode ----------------------------------------------------------
# Back up the pristine original ONCE.
if (-not (Test-Path -LiteralPath $bak)) {
    Copy-Item -LiteralPath $dat -Destination $bak -Force
    Write-Host "  [backup ] 72.DAT -> 72.DAT.orig"
} else {
    Write-Host "  [backup ] 72.DAT.orig already present - left as-is"
}

$bytes  = [System.IO.File]::ReadAllBytes($dat)
$latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')   # 1 byte <-> 1 char
$ascii  = [System.Text.Encoding]::ASCII
$snap   = $latin1.GetString($bytes)                           # offsets == byte offsets
$origLen = $bytes.Length
$patched = 0

foreach ($old in $map.Keys) {
    $new = $map[$old]
    $idx = $snap.IndexOf($old)

    if ($idx -lt 0) {
        if ($snap.IndexOf($new) -ge 0) {
            Write-Host ("  [skip   ] {0,-18} already '{1}'" -f $old, $new)
        } else {
            Write-Host ("  [WARN   ] {0,-18} not found (client version differs?)" -f $old)
        }
        continue
    }

    $ob = $ascii.GetBytes($old)
    $nb = $ascii.GetBytes($new)

    # Write the new name, then null-clear through the end of the old name (+1 for
    # a guaranteed terminator).  All within the record's name slot; metadata untouched.
    [Array]::Copy($nb, 0, $bytes, $idx, $nb.Length)
    $clearEnd = $idx + [Math]::Max($ob.Length, $nb.Length)
    for ($p = $idx + $nb.Length; $p -le $clearEnd; $p++) { $bytes[$p] = 0 }

    Write-Host ("  [patch  ] {0,-18} -> {1}" -f $old, $new)
    $patched++
}

if ($bytes.Length -ne $origLen) {
    Write-Host "  ERROR: internal size mismatch - aborting without writing."
    exit 1
}

if ($patched -gt 0) {
    [System.IO.File]::WriteAllBytes($dat, $bytes)
    Write-Host "  [done   ] $patched ability name(s) relabeled in 72.DAT"
} else {
    Write-Host "  [done   ] nothing to change (already relabeled)"
}
