# =====================================================================
# Relaunch Custom DATs - uninstaller. Restores EVERY .orig backup the
# installer made (all pack overrides). Run via the Uninstall .bat.
# =====================================================================
$ErrorActionPreference = 'Stop'
$pack = $PSScriptRoot
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }

Say ''
Say '  Relaunch Custom DATs - uninstaller' Cyan

try {
    $romRoot = Join-Path $pack 'ROM'
    $rels = @()
    if (Test-Path $romRoot) {
        $rels = Get-ChildItem $romRoot -Recurse -Filter '*.DAT' | ForEach-Object {
            Join-Path 'ROM' $_.FullName.Substring($romRoot.Length + 1)
        }
    }
    if ($rels.Count -eq 0) { Say 'No overrides listed in the pack.' Yellow; return }

    # find installs that have at least one matching .orig backup
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($key in @(
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnline\InstallFolder')) {
        try { (Get-ItemProperty $key -ErrorAction Stop).PSObject.Properties |
            ForEach-Object { if ($_.Value -is [string]) {
                foreach ($rel in $rels) { if (Test-Path (Join-Path $_.Value "$rel.orig")) { $cands.Add($_.Value); break } } } } } catch {}
    }
    foreach ($c in @(
        'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\Program Files\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\ValhallaXI\SquareEnix\FINAL FANTASY XI',
        'D:\PlayOnline\SquareEnix\FINAL FANTASY XI')) {
        foreach ($rel in $rels) { if (Test-Path (Join-Path $c "$rel.orig")) { $cands.Add($c); break } }
    }
    $cands = @($cands | ForEach-Object { $_.TrimEnd('\') } | Select-Object -Unique)
    if ($cands.Count -eq 0) { Say 'No backups found - nothing to restore.' Yellow; return }
    $target = $cands[0]

    $restored = 0
    foreach ($rel in $rels) {
        $dst = Join-Path $target $rel
        $bak = "$dst.orig"
        if (Test-Path $bak) {
            Copy-Item $bak $dst -Force
            Remove-Item $bak -Force
            $restored++
        }
    }
    Say "Restored $restored original DAT(s) at:" Green
    Say "  $target" Green
    Say 'Restart the game client.' Green

    # ---- Windower addon cleanup ----------------------------------------
    Say ''
    foreach ($c in @(
        'C:\Program Files (x86)\Windower4',
        'C:\Program Files\Windower4',
        'C:\Windower4',
        'D:\Windower4')) {
        $addonDir = Join-Path $c 'addons\relaunch'
        if (Test-Path $addonDir) {
            Remove-Item $addonDir -Recurse -Force
            Say "Removed Windower addon: $addonDir" Green
        }
        $init = Join-Path $c 'scripts\init.txt'
        if (Test-Path $init) {
            $txt = Get-Content $init -Raw
            $new = $txt -replace '(?im)^\s*lua\s+load\s+relaunch\s*\r?\n?', ''
            if ($new -ne $txt) {
                Set-Content $init $new -NoNewline
                Say "Removed auto-load line from: $init" Green
            }
        }
    }
}
catch {
    Say ''
    Say "Something went wrong: $($_.Exception.Message)" Red
}
