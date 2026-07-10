# =====================================================================
# Legendary Ring - client DAT installer
# Backs up the retail item DAT and drops in the Legendary Ring override.
# Universal: works whether the player uses Windower, Ashita, or neither.
# Run via "Install Legendary Ring.bat" (handles the admin prompt + keeps
# the window open at the end).
# =====================================================================
$ErrorActionPreference = 'Stop'
$pack   = $PSScriptRoot
$srcDat = Join-Path $pack 'ROM\286\73.DAT'
$rel    = 'ROM\286\73.DAT'

function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }

Say ''
Say '  Legendary Ring - installer' Cyan
Say '  --------------------------' Cyan

try {
    if (-not (Test-Path $srcDat)) {
        Say "ERROR: can't find $rel next to this installer." Red
        Say "Make sure you extracted the WHOLE folder (not just the .bat), then run again." Red
        return
    }
    $srcHash = (Get-FileHash $srcDat -Algorithm SHA1).Hash

    # ---- locate FINAL FANTASY XI installs that contain this DAT ----------
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($key in @(
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnline\InstallFolder')) {
        try { (Get-ItemProperty $key -ErrorAction Stop).PSObject.Properties |
            ForEach-Object { if ($_.Value -is [string] -and (Test-Path (Join-Path $_.Value $rel))) { $cands.Add($_.Value) } } } catch {}
    }
    foreach ($c in @(
        'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\Program Files\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\ValhallaXI\SquareEnix\FINAL FANTASY XI',
        'D:\PlayOnline\SquareEnix\FINAL FANTASY XI')) {
        if (Test-Path (Join-Path $c $rel)) { $cands.Add($c) }
    }
    $cands = $cands | ForEach-Object { $_.TrimEnd('\') } | Select-Object -Unique

    # ---- pick the target -------------------------------------------------
    $target = $null
    if ($cands.Count -eq 1) {
        $target = $cands[0]
        Say "Found FFXI: $target" Green
    } elseif ($cands.Count -gt 1) {
        Say 'Multiple FFXI installs found:' Yellow
        for ($i=0; $i -lt $cands.Count; $i++) { Say "  [$($i+1)] $($cands[$i])" }
        do { $sel = Read-Host "Pick which one to patch (1-$($cands.Count))" } while (-not ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $cands.Count))
        $target = $cands[[int]$sel-1]
    } else {
        Say "Couldn't auto-detect FINAL FANTASY XI." Yellow
        $manual = Read-Host 'Paste the full path to your "FINAL FANTASY XI" folder (or Enter to cancel)'
        if ([string]::IsNullOrWhiteSpace($manual) -or -not (Test-Path (Join-Path $manual $rel))) {
            Say "That folder doesn't contain $rel - cancelled." Red
            return
        }
        $target = $manual.TrimEnd('\')
    }

    $dstDat = Join-Path $target $rel
    if ((Get-FileHash $dstDat -Algorithm SHA1).Hash -eq $srcHash) {
        Say 'Already installed - the Legendary Ring DAT is in place. Nothing to do.' Green
        return
    }

    # ---- back up the original once, then copy ----------------------------
    $bak = "$dstDat.orig"
    if (-not (Test-Path $bak)) { Copy-Item $dstDat $bak -Force; Say "Backed up original -> $bak" Gray }
    else { Say "Backup already exists -> $bak (keeping it)" Gray }

    Copy-Item $srcDat $dstDat -Force
    if ((Get-FileHash $dstDat -Algorithm SHA1).Hash -eq $srcHash) {
        Say ''
        Say '  Done! The ring now shows as "Legendary Ring" in-game.' Green
        Say '  (Restart the game client if it is open.)' Green
        Say '  To undo, run: Uninstall Legendary Ring.bat' Gray
    } else {
        Say 'Copy finished but verification failed - restoring backup.' Red
        Copy-Item $bak $dstDat -Force
    }
}
catch {
    Say ''
    Say "Something went wrong:" Red
    Say "  $($_.Exception.Message)" Red
    Say 'Nothing was left half-applied. You can close this and try again.' Yellow
}
