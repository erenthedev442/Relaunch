# =====================================================================
# Legendary Ring - uninstaller. Restores the original retail item DAT
# from the .orig backup the installer made. Run via the .bat launcher.
# =====================================================================
$ErrorActionPreference = 'Stop'
$rel = 'ROM\286\73.DAT'
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }

Say ''
Say '  Legendary Ring - uninstaller' Cyan

try {
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($key in @(
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnline\InstallFolder')) {
        try { (Get-ItemProperty $key -ErrorAction Stop).PSObject.Properties |
            ForEach-Object { if ($_.Value -is [string] -and (Test-Path (Join-Path $_.Value "$rel.orig"))) { $cands.Add($_.Value) } } } catch {}
    }
    foreach ($c in @(
        'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\Program Files\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\ValhallaXI\SquareEnix\FINAL FANTASY XI',
        'D:\PlayOnline\SquareEnix\FINAL FANTASY XI')) {
        if (Test-Path (Join-Path $c "$rel.orig")) { $cands.Add($c) }
    }
    $cands = @($cands | ForEach-Object { $_.TrimEnd('\') } | Select-Object -Unique)

    if ($cands.Count -eq 0) { Say 'No backup found - nothing to restore.' Yellow; return }
    $target = $cands[0]
    $dst = Join-Path $target $rel
    $bak = "$dst.orig"
    Copy-Item $bak $dst -Force
    Remove-Item $bak -Force
    Say "Restored the original item DAT at:" Green
    Say "  $target" Green
    Say 'Restart the game client.' Green
}
catch {
    Say ''
    Say "Something went wrong: $($_.Exception.Message)" Red
}
