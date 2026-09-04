# =====================================================================
# Relaunch Custom DATs - client installer
# Backs up and replaces EVERY DAT override shipped in this pack's ROM\
# folder (Legendary Ring text, Legendary Track Suit textures + names, and
# any future overrides). Universal: Windower, Ashita, or vanilla.
# Run via "Install Relaunch DATs.bat" / the pack's .bat (handles admin
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
        if (-not (Test-Path $dst)) {
            $dstDir = Split-Path $dst
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item $o.Src $dst -Force
            $installed++
            continue
        }
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

    # ---- Windower addon (relaunch resource overrides) -------------------
    # The DATs handle what the FFXI client displays; this addon handles what
    # Windower / GearSwap SEE by name. Without it, GearSwap can't equip
    # "Legendary Ring" or the Track Suit pieces (res.items is baked from
    # RETAIL DATs, not client DATs).
    $addonSrc = Join-Path $pack 'Windower\addons\relaunch'
    if (Test-Path $addonSrc) {
        Say ''
        Say '  Windower addon (GearSwap / autoexec name lookups)' Cyan
        Say '  -------------------------------------------------' Cyan

        # Find Windower4 install. Common paths + registry.
        $wCands = New-Object System.Collections.Generic.List[string]
        try { $r = Get-ItemProperty 'HKCU:\Software\Windower' -ErrorAction Stop
              if ($r.InstallPath -and (Test-Path (Join-Path $r.InstallPath 'addons'))) { $wCands.Add($r.InstallPath) } } catch {}
        foreach ($c in @(
            'C:\Program Files (x86)\Windower4',
            'C:\Program Files\Windower4',
            'C:\Windower4',
            'D:\Windower4')) {
            if (Test-Path (Join-Path $c 'addons')) { $wCands.Add($c) }
        }
        $wCands = @($wCands | ForEach-Object { $_.TrimEnd('\') } | Select-Object -Unique)

        $wTarget = $null
        if ($wCands.Count -eq 1) {
            $wTarget = $wCands[0]
            Say "  Found Windower: $wTarget" Green
        } elseif ($wCands.Count -gt 1) {
            Say '  Multiple Windower installs:' Yellow
            for ($i=0; $i -lt $wCands.Count; $i++) { Say "    [$($i+1)] $($wCands[$i])" }
            do { $sel = Read-Host "  Which one to install the addon into (1-$($wCands.Count), or 0 to skip)" } while (-not ($sel -match '^\d+$' -and [int]$sel -ge 0 -and [int]$sel -le $wCands.Count))
            if ([int]$sel -gt 0) { $wTarget = $wCands[[int]$sel-1] }
        } else {
            Say '  No Windower install detected.' Yellow
            $manual = Read-Host '  Paste path to Windower4 (or Enter to skip)'
            if (-not [string]::IsNullOrWhiteSpace($manual) -and (Test-Path (Join-Path $manual 'addons'))) {
                $wTarget = $manual.TrimEnd('\')
            }
        }

        if ($wTarget) {
            $addonDst = Join-Path $wTarget 'addons\relaunch'
            if (-not (Test-Path $addonDst)) { New-Item -ItemType Directory -Path $addonDst -Force | Out-Null }
            Copy-Item (Join-Path $addonSrc '*') $addonDst -Recurse -Force
            Say "  Copied addon -> $addonDst" Green

            # Offer to append `lua load relaunch` to init.txt so it auto-loads.
            $init = Join-Path $wTarget 'scripts\init.txt'
            if (Test-Path $init) {
                $initTxt = Get-Content $init -Raw -ErrorAction SilentlyContinue
                if ($initTxt -notmatch '(?im)^\s*lua\s+load\s+relaunch\s*$') {
                    $yn = Read-Host '  Add `lua load relaunch` to Windower init.txt so it auto-loads? (Y/n)'
                    if ($yn -notmatch '^(n|no)$') {
                        Add-Content $init "`r`nlua load relaunch"
                        Say "  Added auto-load line to $init" Green
                    } else {
                        Say '  Skipped auto-load. Type `//lua l relaunch` once per session to enable.' Yellow
                    }
                } else {
                    Say '  init.txt already contains `lua load relaunch`.' Green
                }
            } else {
                Say "  init.txt not found -- type '//lua l relaunch' once per session, or create $init with a 'lua load relaunch' line." Yellow
            }
        } else {
            Say '  Skipped Windower addon install (no target).' Yellow
        }
    }

    Say ''
    Say '  To undo everything, run the Uninstall .bat.' Gray
}
catch {
    Say ''
    Say "Something went wrong:" Red
    Say "  $($_.Exception.Message)" Red
    Say 'Nothing was left half-applied. You can close this and try again.' Yellow
}
