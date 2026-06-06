<#
  patch_descriptions.ps1  --  Bouncer client relabel, ability-DESCRIPTION half.

  Rewrites the help/tooltip text of the 9 repurposed GEO Job Abilities in the
  FFXI client's ability-DESCRIPTION table (ROM\181\74.DAT) so the JA menu's
  description line reads as the Bouncer kit instead of the donor GEO flavour.
  This is the third companion to the FFXiMain.dll job-name swap (install.bat)
  and the ability-NAME patch (patch_abilities.ps1) -- together they make the
  client show BOUNCER everywhere: job name, ability names, AND descriptions.

  Cosmetic + client-side only.  The server neither knows nor cares about these
  strings; they live in your local game DATs.

  Mechanism: 74.DAT is a fixed-stride "d_msg" table (5888 records of 0x100
  bytes); each description is null-terminated ASCII at record+0x28, followed by
  zero padding to the next record.  We locate each stock GEO description by its
  exact text and overwrite it in place with the (shorter) Bouncer text, then
  null-clear the old remainder -- same file size, metadata untouched.  Every new
  description is shorter than the donor GEO description it replaces, so it always
  fits the slot.

  Usage (normally invoked by install.bat / uninstall.bat, not by hand):
    powershell -ExecutionPolicy Bypass -File patch_descriptions.ps1 -FFXI "<FFXI folder>"
    powershell -ExecutionPolicy Bypass -File patch_descriptions.ps1 -FFXI "<FFXI folder>" -Restore

  Idempotent: re-running detects already-renamed entries and skips them.
  Reversible: the first run backs up 74.DAT -> 74.DAT.orig; -Restore copies it back.
#>
param(
    [string]$FFXI = 'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'

$dat = Join-Path $FFXI 'ROM\181\74.DAT'
$bak = "$dat.orig"

# Stock GEO ability description  ->  Bouncer ability description.
# Each Bouncer line MUST be <= the GEO line it replaces (so it fits the slot the
# old string occupied).  Keyed by the donor ability so it matches the NAME map in
# patch_abilities.ps1 and the behaviours in bouncer_abilities.lua:
#   Bolster            -> Last Call      (2hr: can't-die + full reflect/leech)
#   Full Circle        -> Step Outside   (single-target taunt)
#   Ecliptic Attrition -> Sucker Punch   (Stun + claim)
#   Widened Compass    -> Crowd Control  (AoE enmity reinforce)
#   Collimated Fervor  -> Bodyguard      (grant an ally brief invuln)
#   Life Cycle         -> Retaliate      (self reflect/leech stance)
#   Blaze of Glory     -> Brace          (self -25% damage taken)
#   Dematerialize      -> Hold the Line  (self brief full invuln)
#   Theurgic Focus     -> Bloodbind      (self heal, 25% of max HP)
$map = [ordered]@{
    'Enhances the effects of your geomancy spells.'                                                                            = 'Cannot be knocked out; reflects all damage.'
    'Causes your luopan to vanish.'                                                                                            = 'Provokes a single enemy.'
    'Enhances the effects of your luopan. Increases the rate at which your luopan consumes its HP.'                            = 'Delivers a stunning blow that claims the enemy.'
    'Increases the area of effect of geomancy spells.'                                                                         = 'Reinforces your enmity toward nearby enemies.'
    'Enhances the influence of Cardinal Chant on your next spell cast.'                                                        = 'Shields a party member from all damage briefly.'
    'Distributes one fourth of your HP to your luopan.'                                                                        = 'Reflects damage taken and absorbs it as HP.'
    'Increases the effects of your next applicable geomancy spell. Consumes half of that luopan''s HP.'                        = 'Reduces damage taken by 25% for a short time.'
    'Prevents your luopan from receiving damage.'                                                                              = 'Briefly negates all damage you take.'
    'Increases the power of your next applicable elemental magic spell. Casting range and area of effect are reduced by half.' = 'Restores HP equal to 25% of your maximum.'
}

if (-not (Test-Path -LiteralPath $dat)) {
    Write-Host "  ERROR: ability-description DAT not found:"
    Write-Host "         $dat"
    Write-Host "         Check the FFXI path and retry."
    exit 1
}

# ---- Restore mode: put the stock GEO descriptions back ---------------------
if ($Restore) {
    if (Test-Path -LiteralPath $bak) {
        Copy-Item -LiteralPath $bak -Destination $dat -Force
        Write-Host "  [restore] ability descriptions -> stock GEO (from 74.DAT.orig)"
    } else {
        Write-Host "  [restore] no backup (74.DAT.orig) found - nothing to restore"
    }
    exit 0
}

# ---- Install mode ----------------------------------------------------------
# Back up the pristine original ONCE.
if (-not (Test-Path -LiteralPath $bak)) {
    Copy-Item -LiteralPath $dat -Destination $bak -Force
    Write-Host "  [backup ] 74.DAT -> 74.DAT.orig"
} else {
    Write-Host "  [backup ] 74.DAT.orig already present - left as-is"
}

$bytes  = [System.IO.File]::ReadAllBytes($dat)
$latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')   # 1 byte <-> 1 char
$ascii  = [System.Text.Encoding]::ASCII
$snap   = $latin1.GetString($bytes)                           # offsets == byte offsets
$origLen = $bytes.Length
$patched = 0

foreach ($old in $map.Keys) {
    $new = $map[$old]

    # Count occurrences so we never clobber the wrong record if a description
    # ever turns out to be non-unique.
    $occ = 0; $scan = 0
    while (($scan = $snap.IndexOf($old, $scan)) -ge 0) { $occ++; $scan += $old.Length }

    if ($occ -eq 0) {
        if ($snap.IndexOf($new) -ge 0) {
            Write-Host ("  [skip   ] '{0}' already done" -f $new)
        } else {
            Write-Host ("  [WARN   ] stock text not found (client version differs?): '{0}'" -f $old)
        }
        continue
    }
    if ($occ -gt 1) {
        Write-Host ("  [WARN   ] '{0}...' found {1}x - ambiguous, skipped for safety" -f $old.Substring(0, [Math]::Min(28, $old.Length)), $occ)
        continue
    }

    $ob = $ascii.GetBytes($old)
    $nb = $ascii.GetBytes($new)

    if ($nb.Length -gt $ob.Length) {
        Write-Host ("  [WARN   ] replacement longer than slot ({0} > {1}), skipped: '{2}'" -f $nb.Length, $ob.Length, $new)
        continue
    }

    $idx = $snap.IndexOf($old)

    # Write the new description, then null-clear through the end of the old one
    # (+1 for a guaranteed terminator).  All within the record's text slot.
    [Array]::Copy($nb, 0, $bytes, $idx, $nb.Length)
    $clearEnd = $idx + [Math]::Max($ob.Length, $nb.Length)
    for ($p = $idx + $nb.Length; $p -le $clearEnd; $p++) { $bytes[$p] = 0 }

    Write-Host ("  [patch  ] {0,-46} -> {1}" -f ("'" + $old.Substring(0, [Math]::Min(44, $old.Length)) + "'"), $new)
    $patched++
}

if ($bytes.Length -ne $origLen) {
    Write-Host "  ERROR: internal size mismatch - aborting without writing."
    exit 1
}

if ($patched -gt 0) {
    [System.IO.File]::WriteAllBytes($dat, $bytes)
    Write-Host "  [done   ] $patched ability description(s) relabeled in 74.DAT"
} else {
    Write-Host "  [done   ] nothing to change (already relabeled)"
}
