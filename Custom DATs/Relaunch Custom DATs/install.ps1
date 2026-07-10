# =====================================================================
# Relaunch Custom DATs - client installer
# Backs up and replaces EVERY DAT override shipped in this pack's ROM\
# folder (Legendary Ring text, Legendary Track Suit textures + names, and
# any future overrides). Universal: Windower, Ashita, or vanilla.
# Run via "Install Legendary Ring.bat" / the pack's .bat (handles admin
# elevation + keeps the window open at the end).
# =====================================================================
$ErrorActionPreference = 'Stop'
$pack = $PSScriptRoot

function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }

Say ''
Say '  Relaunch Custom DATs - installer' Cyan
Say '  --------------------------------' Cyan

try {
    # ---- collect the pack's override DATs -------------------------------
    $romRoot = Join-Path $pack 'ROM'
    if (-not (Test-Path $romRoot)) {
        Say "ERROR: no ROM folder next to this installer." Red
        Say "Make sure you extracted the WHOLE folder (not just the .bat), then run again." Red
        return
    }
    $overrides = Get-ChildItem $romRoot -Recurse -Filter '*.DAT' | ForEach-Object {
        $rel = $_.FullName.Substring($romRoot.Length + 1)   # e.g. 286\73.DAT
        [pscustomobject]@{ Rel = (Join-Path 'ROM' $rel); Src = $_.FullName }
    }
    if ($overrides.Count -eq 0) { Say 'No .DAT overrides found in the pack.' Yellow; return }
    Say "Pack contains $($overrides.Count) DAT override(s)."

    # ---- locate FINAL FANTASY XI installs that contain the FIRST DAT ----
    $probe = $overrides[0].Rel
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($key in @(
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnline\InstallFolder')) {
        try { (Get-ItemProperty $key -ErrorAction Stop).PSObject.Properties |
            ForEach-Object { if ($_.Value -is [string] -and (Test-Path (Join-Path $_.Value $probe))) { $cands.Add($_.Value) } } } catch {}
    }
    foreach ($c in @(
        'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\Program Files\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\ValhallaXI\SquareEnix\FINAL FANTASY XI',
        'D:\PlayOnline\SquareEnix\FINAL FANTASY XI')) {
        if (Test-Path (Join-Path $c $probe)) { $cands.Add($c) }
    }
    $cands = @($cands | ForEach-Object { $_.TrimEnd('\') } | Select-Object -Unique)

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
        if ([string]::IsNullOrWhiteSpace($manual) -or -not (Test-Path (Join-Path $manual $probe))) {
            Say "That folder doesn't contain $probe - cancelled." Red
            return
        }
        $target = $manual.TrimEnd('\')
    }

    # ---- install each override: back up once, copy, verify --------------
    $installed = 0; $already = 0; $skipped = 0
    foreach ($o in $overrides) {
        $dst = Join-Path $target $o.Rel
        if (-not (Test-Path $dst)) { Say "  SKIP $($o.Rel) (not in this client)" Yellow; $skipped++; continue }
        $srcHash = (Get-FileHash $o.Src -Algorithm SHA1).Hash
        if ((Get-FileHash $dst -Algorithm SHA1).Hash -eq $srcHash) { $already++; continue }
        $bak = "$dst.orig"
        if (-not (Test-Path $bak)) { Copy-Item $dst $bak -Force }
        Copy-Item $o.Src $dst -Force
        if ((Get-FileHash $dst -Algorithm SHA1).Hash -ne $srcHash) {
            Say "  VERIFY FAILED on $($o.Rel) - restoring backup." Red
            Copy-Item $bak $dst -Force
        } else {
            $installed++
        }
    }
    Say ''
    Say "  Done! installed/updated: $installed, already current: $already, skipped: $skipped" Green
    Say '  (Restart the game client if it is open.)' Green
    Say '  To undo everything, run the Uninstall .bat.' Gray
}
catch {
    Say ''
    Say "Something went wrong:" Red
    Say "  $($_.Exception.Message)" Red
    Say 'Nothing was left half-applied. You can close this and try again.' Yellow
}
