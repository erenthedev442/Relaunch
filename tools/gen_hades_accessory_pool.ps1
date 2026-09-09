# Build modules/custom/lua/hades_accessory_catalog.lua from exports/gear_source_audit.csv.
# Sourced 99+ accessories: 499-999 by +tier and score. Invasion-only / no real source: 1499.

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$csv    = Join-Path $root 'exports\gear_source_audit.csv'
$out    = Join-Path $root 'modules\custom\lua\hades_accessory_catalog.lua'
$slots  = @('Neck', 'Ear', 'Ring', 'Back', 'Waist')

function Accessory-Price([string]$name, [int]$score, [bool]$sourced) {
    if (-not $sourced) { return 1499 }
    $tier = 0
    if ($name -match '\+3$') { $tier = 3 }
    elseif ($name -match '\+2$') { $tier = 2 }
    elseif ($name -match '\+1$') { $tier = 1 }
    $base = 499 + ($tier * 125)
    $bump = [Math]::Min(100, [int]($score / 8))
    return [Math]::Min(999, $base + $bump)
}

function Esc([string]$s) {
    return ($s -replace '\\', '\\' -replace "'", "\\'")
}

function FamilyOf($name) {
    return (($name -replace ' \+[1234]$', '') -split ' ')[0]
}

$jobNeck = '^(Warriors Bead|Abyssal Bead|Knights Bead|Dragoons Collar|Samurais Nodowa|Bards Charm|Sorcerers Stole|Ninja Nodowa|Argute Stole|Duelists Torque|Bagua Charm|Assassins Gorget|Beastmaster Collar|Clerics Torque|Commodore Charm|Etoile Gorget|Futhark Torque|Mirage Stole|Monks Nodowa|Puppetmasters Collar|Scouts Gorget|Summoners Collar)'
$jobEar  = '^(Amini|Arbatel|Azimuth|Beckoners|Bhikku|Boii|Chasseurs|Chevaliers|Ebers|Enchanters|Erilaz|Fili|Hashishin|Hattori|Heathens|Karagoz|Kasuga|Lethargy|Maculele|Nourishing|Nukumi|Peltasts|Skulkers|Wicce) '
$npcJunk = 'Fickblix|Hoxne|Cornelia|Lehko|Medada|Gurebu-Ogurebu|Ragelise|Ephramad|Dumakulem|Emporox|Patricius|Kayre|Praan|Adoulin Ring|Woltaris|Weatherspoon|Renaye|Vocane|Karieyh|Niht Mantle|Bookworm|Trepidity|Updraft Mantle|Maulers Mantle|Bane Cape|Anchoret|Weard Mantle|Yokaze|Pastoralist|Evasionist|Dispersal|Toetapper|Ghostfyre|Lifestream|Canny Cape|Judge'

$gear = @()
Import-Csv $csv | ForEach-Object {
    if ($slots -notcontains $_.slot) { return }
    $ilvl = 0; [void][int]::TryParse($_.ilvl, [ref]$ilvl)
    $lvl  = 0; [void][int]::TryParse($_.level, [ref]$lvl)
    if ($lvl -lt 99 -and $ilvl -lt 119) { return }
    $score = 0; [void][int]::TryParse($_.score, [ref]$score)
    $sourced = [bool]($_.retail_source -or $_.relaunch_source)
    $gear += [pscustomobject]@{
        id       = [int]$_.item_id
        name     = $_.name
        slot     = $_.slot
        score    = $score
        sourced  = $sourced
        relaunch = $_.relaunch_source
        retail   = $_.retail_source
    }
}

$unsourced = $gear | Where-Object { -not $_.sourced }
$pickU = New-Object System.Collections.Generic.List[object]
$seen  = @{}
$slotU = @{ Neck = 0; Ear = 0; Ring = 0; Back = 0; Waist = 0 }
$slotUCap = @{ Neck = 18; Ear = 40; Ring = 26; Back = 8; Waist = 8 }

function Add-Pick($row) {
    if (-not $row) { return }
    if ($seen.ContainsKey($row.id)) { return }
    if ($slotU[$row.slot] -ge $slotUCap[$row.slot]) { return }
    $seen[$row.id] = $true
    $slotU[$row.slot] = $slotU[$row.slot] + 1
    $pickU.Add($row)
}

foreach ($row in ($unsourced | Where-Object { $_.name -match '^(Cessance|Dedition|Epaminondas|Sacro Gorget|Locus Ring|Schere|Friomisi)' })) {
    Add-Pick $row
}
foreach ($row in ($unsourced | Where-Object { $_.name -match $jobEar -and $_.name -match '\+2$' })) {
    Add-Pick $row
}
foreach ($row in ($unsourced | Where-Object { $_.name -match $jobEar -and $_.name -match '\+1$' })) {
    Add-Pick $row
}
foreach ($row in ($unsourced | Where-Object { $_.name -match '^(Sulevias|Meghanada|Ayanmo|Flamma|Mummu|Mallquis|Hizamaru|Jhakri|Inyanga|Taliah) Ring' })) {
    Add-Pick $row
}
foreach ($row in ($unsourced | Where-Object { $_.name -notmatch $npcJunk } | Sort-Object score -Descending)) {
    if ($pickU.Count -ge 100) { break }
    Add-Pick $row
}
# If a slot cap starved the pool, relax caps and fill by score.
if ($pickU.Count -lt 100) {
    $slotUCap = @{ Neck = 40; Ear = 50; Ring = 40; Back = 20; Waist = 20 }
    foreach ($row in ($unsourced | Where-Object { $_.name -notmatch $npcJunk } | Sort-Object score -Descending)) {
        if ($pickU.Count -ge 100) { break }
        Add-Pick $row
    }
}

$eligible = $gear | Where-Object {
    $_.sourced -and
    $_.relaunch -notmatch 'AF/Relic/Emp' -and
    $_.relaunch -notmatch 'Dynamis \+4' -and
    $_.relaunch -notmatch 'Infamy' -and
    $_.relaunch -notmatch 'Medal Vendor' -and
    $_.relaunch -notmatch 'Sparks' -and
    $_.name -notmatch $jobNeck
}
$pickS = New-Object System.Collections.Generic.List[object]
$slotCount = @{ Neck = 0; Ear = 0; Ring = 0; Back = 0; Waist = 0 }
$familyCount = @{}

foreach ($row in ($eligible | Sort-Object score -Descending)) {
    if ($pickS.Count -ge 100) { break }
    if ($seen.ContainsKey($row.id)) { continue }
    $fam = FamilyOf $row.name
    $have = if ($familyCount.ContainsKey($fam)) { $familyCount[$fam] } else { 0 }
    if ($have -ge 4) { continue }
    if ($slotCount[$row.slot] -ge 22) { continue }
    $seen[$row.id] = $true
    $familyCount[$fam] = $have + 1
    $slotCount[$row.slot] = $slotCount[$row.slot] + 1
    $pickS.Add($row)
}

$all = @($pickU + $pickS) | Sort-Object id
if ($all.Count -lt 100) { throw "accessory pool too small: $($all.Count)" }

$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add('-----------------------------------')
[void]$lines.Add('-- hades_accessory_catalog.lua')
[void]$lines.Add('--')
[void]$lines.Add('-- Weekend Gild stall. One accessory per UTC week, same name')
[void]$lines.Add('-- for every player. Generated by tools/gen_hades_accessory_pool.ps1')
[void]$lines.Add('-- from exports/gear_source_audit.csv.')
[void]$lines.Add('--')
[void]$lines.Add('-- sourced = has a retail or curated relaunch source.')
[void]$lines.Add('-- Invasion-only pieces are unsourced and cost 1499.')
[void]$lines.Add('-- Sourced pieces cost 499-999 from +tier and score.')
[void]$lines.Add('-- Infamy, medal-vendor, Sparks, and job-reforge necks stay out.')
[void]$lines.Add('-----------------------------------')
[void]$lines.Add("local CATALOG_KEY = 'modules/custom/lua/hades_accessory_catalog'")
[void]$lines.Add('local C = package.loaded[CATALOG_KEY]')
[void]$lines.Add("if type(C) ~= 'table' then")
[void]$lines.Add('    C = {}')
[void]$lines.Add('end')
[void]$lines.Add('package.loaded[CATALOG_KEY] = C')
[void]$lines.Add('')
[void]$lines.Add('C.UNSOURCED_PRICE = 1499')
[void]$lines.Add('C.SOURCED_LO      = 499')
[void]$lines.Add('C.SOURCED_HI      = 999')
[void]$lines.Add('')
[void]$lines.Add('C.items =')
[void]$lines.Add('{')

$uCount = 0
foreach ($row in $all) {
    $price = Accessory-Price $row.name $row.score $row.sourced
    $src = 'true'
    if (-not $row.sourced) {
        $src = 'false'
        $uCount++
    }
    $name = Esc $row.name
    [void]$lines.Add(("    {{ id = {0}, name = '{1}', slot = '{2}', sourced = {3}, price = {4} }}," -f $row.id, $name, $row.slot, $src, $price))
}

[void]$lines.Add('}')
[void]$lines.Add('')
[void]$lines.Add('C.byId = {}')
[void]$lines.Add('for _, row in ipairs(C.items) do')
[void]$lines.Add('    C.byId[row.id] = row')
[void]$lines.Add('end')
[void]$lines.Add('')
[void]$lines.Add('function C.weeklyPiece(weekId)')
[void]$lines.Add('    local n = #C.items')
[void]$lines.Add('    if n == 0 then')
[void]$lines.Add('        return nil')
[void]$lines.Add('    end')
[void]$lines.Add('    weekId = weekId or tonumber(os.date(''!%Y%W''))')
[void]$lines.Add('    return C.items[(((weekId or 0) * 37) % n) + 1]')
[void]$lines.Add('end')
[void]$lines.Add('')
[void]$lines.Add('return C')
[void]$lines.Add('')

[IO.File]::WriteAllText($out, ($lines -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Output ("wrote {0} pieces ({1} unsourced @1499, {2} sourced 499-999) -> {3}" -f $all.Count, $uCount, ($all.Count - $uCount), $out)
