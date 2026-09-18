$ErrorActionPreference = 'Stop'

$package    = $PSScriptRoot
$ffxi       = 'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI'
$recordSize = 0x1400
$firstId    = 0x4000
# 0x1400 header inserts 4 bytes; names / jobs / dmg sit 4 later than 0xC00.
$jobsOff    = 0x18
$dmgOff     = 0x20
$delayOff   = 0x22
$dpsOff     = 0x24
$ilvlOff    = 0x36
$nameOff    = 0x84
$textEnd    = 0x284

$sources = [ordered]@{
    'ROM\118\108.DAT' = Join-Path $ffxi 'ROM\118\108.DAT'
}

$relicGroups = @(
    @{ Bit = [uint32]0x00080000; IDs = @(18270,18271,18638,18652,18666,19747,19840,20555,20556,20583) }
    @{ Bit = [uint32]0x00010000; IDs = @(18276,18277,18639,18653,18667,19748,19841,20645,20646,20685) }
    @{ Bit = [uint32]0x00040000; IDs = @(18264,18265,18637,18651,18665,19746,19839,20480,20481,20509) }
    @{ Bit = [uint32]0x00400000; IDs = @(18282,18283,18640,18654,18668,19749,19842,20745,20746,21683) }
    @{ Bit = [uint32]0x00200000; IDs = @(18324,18325,18647,18661,18675,19756,19849,21060,21061,21077) }
    @{ Bit = [uint32]0x00100000; IDs = @(18330,18331,18648,18662,18676,19757,19850,21135,21136,22060) }
    @{ Bit = [uint32]0x00020000; IDs = @(18336,18337,18649,18663,18677,19758,19851,21260,21261,21267,22140) }
)

function Ror5([byte]$b) {
    [byte]((($b -shr 5) -bor (($b -band 0x1F) -shl 3)) -band 0xFF)
}
function Rol5([byte]$b) {
    [byte](((($b -shl 5) -band 0xFF) -bor ($b -shr 3)) -band 0xFF)
}

function Decode-Id([byte[]]$file, [int]$id) {
    $off = ($id - $firstId) * $recordSize
    $dec = New-Object byte[] $recordSize
    for ($i = 0; $i -lt $recordSize; $i++) { $dec[$i] = Ror5 $file[$off + $i] }
    ,$dec
}

function Poke-U16($arr, [int]$off, [uint16]$value) {
    $b = [BitConverter]::GetBytes($value)
    $arr[$off]     = $b[0]
    $arr[$off + 1] = $b[1]
}
function Poke-U32($arr, [int]$off, [uint32]$value) {
    $b = [BitConverter]::GetBytes($value)
    $arr[$off]     = $b[0]
    $arr[$off + 1] = $b[1]
    $arr[$off + 2] = $b[2]
    $arr[$off + 3] = $b[3]
}

function Find-Dmg([byte[]]$arr) {
    for ($i = $nameOff; $i -lt 0x200; $i++) {
        if ($arr[$i] -eq 0x44 -and $arr[$i+1] -eq 0x4D -and $arr[$i+2] -eq 0x47 -and $arr[$i+3] -eq 0x3A) {
            return $i
        }
    }
    return -1
}

function Pad-FfxiNameCell([string]$text) {
    $bytes = [Text.Encoding]::ASCII.GetBytes($text)
    $n = $bytes.Length + 1
    if ($n -lt 8) { $n = 8 }
    elseif ($n % 4) { $n += 4 - ($n % 4) }
    $out = New-Object byte[] $n
    [Buffer]::BlockCopy($bytes, 0, $out, 0, $bytes.Length)
    ,$out
}

# 0xF840 weapons use aligned name cells + uint32 markers + a 24-byte gap
# (Idris / Epeolatry). A raw C-string wipe of 0x28 bytes destroys those
# markers and the client R0s on zone-in when it holds the item.
function Write-FfxiWeaponNames($arr, [string]$enName, [string]$enLog, [string]$enPlural) {
    $flag = [byte[]](1, 0, 0, 0)
    $gap  = New-Object byte[] 24
    $parts = New-Object System.Collections.Generic.List[byte]
    $parts.AddRange((Pad-FfxiNameCell $enName))
    $parts.AddRange($flag)
    $parts.AddRange($flag)
    $parts.AddRange($gap)
    $parts.AddRange((Pad-FfxiNameCell $enLog))
    $parts.AddRange($flag)
    $parts.AddRange($gap)
    $parts.AddRange((Pad-FfxiNameCell $enPlural))
    $parts.AddRange($flag)
    $parts.AddRange($gap)
    $block = $parts.ToArray()
    if (($nameOff + $block.Length) -gt $textEnd) { throw "name block too long ($($block.Length))" }
    for ($i = $nameOff; $i -lt $textEnd; $i++) { $arr[$i] = 0 }
    [Buffer]::BlockCopy($block, 0, $arr, $nameOff, $block.Length)
    return ($nameOff + $block.Length)
}

function Paint-KrakenPlusOneIcon([byte[]]$arr) {
    $bmp = -1
    for ($i = 0x200; $i -lt 0x400; $i++) {
        if ($arr[$i] -eq 0x28 -and $arr[$i + 4] -eq 32 -and $arr[$i + 8] -eq 32 -and ([BitConverter]::ToUInt16($arr, $i + 14) -eq 8)) {
            $bmp = $i
            break
        }
    }
    if ($bmp -lt 0) { throw 'Kraken Club +1: no 32x32 8-bit icon' }

    $palOff = $bmp + 40
    $pixOff = $palOff + 1024
    $used = @{}
    for ($i = 0; $i -lt 1024; $i++) { $used[$arr[$pixOff + $i]] = $true }

    $white = -1
    for ($i = 255; $i -ge 0; $i--) {
        if (-not $used.ContainsKey([byte]$i)) { $white = $i; break }
    }
    if ($white -lt 0) {
        for ($i = 0; $i -lt 256; $i++) {
            $b = $arr[$palOff + $i * 4]
            $g = $arr[$palOff + $i * 4 + 1]
            $r = $arr[$palOff + $i * 4 + 2]
            if ($r -ge 248 -and $g -ge 248 -and $b -ge 248) { $white = $i; break }
        }
    }
    if ($white -lt 0) { throw 'Kraken Club +1: no free palette index for white' }

    $free = New-Object System.Collections.Generic.List[int]
    for ($i = 255; $i -ge 0; $i--) {
        if (-not $used.ContainsKey([byte]$i)) { $free.Add($i) }
    }
    if ($free.Count -lt 3) { throw 'Kraken Club +1: need 3 free palette indexes for HQ plate' }
    $outer = [int]$free[0]
    $bevel = [int]$free[1]
    $fill  = [int]$free[2]
    foreach ($slot in @(
        @{ I = $outer; C = 184 },
        @{ I = $bevel; C = 160 },
        @{ I = $fill;  C = 136 }
    )) {
        $arr[$palOff + $slot.I * 4]     = [byte]$slot.C
        $arr[$palOff + $slot.I * 4 + 1] = [byte]$slot.C
        $arr[$palOff + $slot.I * 4 + 2] = [byte]$slot.C
        $arr[$palOff + $slot.I * 4 + 3] = 0x80
    }
    for ($y = 0; $y -lt 32; $y++) {
        for ($x = 0; $x -lt 32; $x++) {
            $off = $pixOff + ((31 - $y) * 32 + $x)
            $idx = $arr[$off]
            $b = $arr[$palOff + $idx * 4]
            $g = $arr[$palOff + $idx * 4 + 1]
            $r = $arr[$palOff + $idx * 4 + 2]
            if (($r + $g + $b) -gt 80) { continue }
            $ring = [Math]::Min([Math]::Min($x, $y), [Math]::Min(31 - $x, 31 - $y))
            if ($ring -le 1) { $arr[$off] = [byte]$outer }
            elseif ($ring -eq 2) { $arr[$off] = [byte]$bevel }
            else { $arr[$off] = [byte]$fill }
        }
    }
}

function Replace-Digits($arr, [int]$from, [int]$to, [string]$old, [string]$new) {
    $oldB = [Text.Encoding]::ASCII.GetBytes($old)
    $newB = [Text.Encoding]::ASCII.GetBytes($new)
    $hits = 0
    for ($i = $from; $i -le ($to - $oldB.Length); $i++) {
        $ok = $true
        for ($j = 0; $j -lt $oldB.Length; $j++) {
            if ($arr[$i + $j] -ne $oldB[$j]) { $ok = $false; break }
        }
        if ($ok) {
            for ($j = 0; $j -lt $oldB.Length; $j++) {
                $arr[$i + $j] = if ($j -lt $newB.Length) { $newB[$j] } else { [byte]0x20 }
            }
            $hits++
        }
    }
    $hits
}

$epeo99Desc = "DMG:154 Delay:489`nEnmity+18`n`"Dimidiation`"`nAftermath: Increases accuracy and attack`nOccasionally attacks twice or thrice"
$epeo119IDesc = "DMG:199 Delay:489`nGreat Sword skill +242`nParrying skill +242`nMagic Accuracy skill +215`nEnmity+18`n`"Dimidiation`"`nAftermath: Increases accuracy and attack`nOccasionally attacks twice or thrice"
$idris99Desc = "DMG:80 Delay:280`n`"Exudation`"`nAftermath: Increases Magic Accuracy and `"Magic Atk. Bonus`"`nOccasionally attacks twice or thrice"
$idris119IDesc = "DMG:110 Delay:280`nClub skill +242`nParrying skill +242`nMagic Accuracy skill +228`n`"Exudation`"`nAftermath: Increases Magic Accuracy and `"Magic Atk. Bonus`"`nOccasionally attacks twice or thrice"
$idris119Desc = "DMG:139 Delay:280`nMagic Accuracy+25`n`"Magic Atk. Bonus`"+25`nMagic Damage+155`nClub skill +242`nParrying skill +242`nMagic Accuracy skill +228`nLuopan: Damage taken -25%`n`"Exudation`"`nAftermath: Increases Magic Accuracy and `"Magic Atk. Bonus`"`nOccasionally attacks twice or thrice"
$krakenP1Desc = "DMG:16 Delay:264`nOccasionally attacks 2 to 8 times`nAccuracy+25`nStore TP+4`nSubtle Blow+5`nClub skill +269`nParrying skill +269`nMagic Accuracy skill +228"

$RUN       = [uint32]0x00400000
$GEO       = [uint32]0x00200000
$ALL_JOBS  = [uint32]0x007FFFFE
$KRAKEN_NQ = 17440
$KRAKEN_P1 = 19973

New-Item -ItemType Directory -Force -Path (Join-Path $package 'ROM\118') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $package 'ROM\0') | Out-Null

$report = New-Object System.Collections.Generic.List[string]

foreach ($rel in $sources.GetEnumerator()) {
    $src = Get-Item -LiteralPath $rel.Value
    $file = [IO.File]::ReadAllBytes($src.FullName)
    if (($file.Length % $recordSize) -ne 0) { throw "Unexpected size $($file.Length) for $($rel.Key) (need 0x1400 stride)" }
    $isEnglish = $rel.Key -like '*118*'

    foreach ($g in $relicGroups) {
        foreach ($id in $g.IDs) {
            $dec = Decode-Id $file $id
            $jobs = [BitConverter]::ToUInt32($dec, $jobsOff) -bor $g.Bit
            Poke-U32 $dec $jobsOff $jobs
            $off = ($id - $firstId) * $recordSize
            for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
        }
    }

    $clones = @()
    # 0x1400: stuffing full Epeolatry/Idris records into retail stub ids 19968-19971
    # R0s the new client. Job bits on live relic ids plus Martial Wraps stay.

    foreach ($c in $clones) {
        $dec = Decode-Id $file $c.Donor
        Poke-U32 $dec 0 $c.NewId
        Poke-U32 $dec $jobsOff $c.Jobs
        Poke-U16 $dec $dmgOff $c.Dmg
        $dec[$ilvlOff] = $c.Ilvl
        if ($c.ContainsKey('Delay')) {
            Poke-U16 $dec $delayOff $c.Delay
            Poke-U16 $dec $dpsOff ([uint16][Math]::Floor($c.Dmg * 6000 / $c.Delay))
        }
        if ($isEnglish -and $c.ContainsKey('EnName')) {
            $descOff = Write-FfxiWeaponNames $dec $c.EnName $c.EnLog $c.EnPlural
            if ($c.EnDesc) {
                $text = [Text.Encoding]::ASCII.GetBytes($c.EnDesc)
                if (($descOff + $text.Length + 1) -gt $textEnd) { throw 'EN desc too long after rename' }
                [Buffer]::BlockCopy($text, 0, $dec, $descOff, $text.Length)
            }
        } elseif ($isEnglish -and $c.EnDesc) {
            $descOff = Find-Dmg $dec
            if ($descOff -lt 0) { throw "No DMG: on donor $($c.Donor)" }
            $text = [Text.Encoding]::ASCII.GetBytes($c.EnDesc)
            if (($descOff + $text.Length + 1) -gt $textEnd) { throw 'EN desc too long' }
            for ($i = $descOff; $i -lt $textEnd; $i++) { $dec[$i] = 0 }
            [Buffer]::BlockCopy($text, 0, $dec, $descOff, $text.Length)
        }
        if (-not $isEnglish -and $c.JpOld) {
            $hits = Replace-Digits $dec $nameOff $textEnd $c.JpOld $c.JpNew
            if ($hits -lt 1) { throw "JP $($c.NewId): '$($c.JpOld)' not found" }
        }
        if (-not $isEnglish -and $c.Donor -eq 21070) {
            $null = Replace-Digits $dec $nameOff $textEnd '+10' '   '
        }
        $null = Replace-Digits $dec $nameOff $textEnd ([string]$c.Donor) ([string]$c.NewId)
        $off = ($c.NewId - $firstId) * $recordSize
        for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
    }

    foreach ($id in 20753, 21685) {
        $dec = Decode-Id $file $id
        Poke-U32 $dec $jobsOff $RUN
        $off = ($id - $firstId) * $recordSize
        for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
    }

    # 21070 is retail 119: strip GEO+10 so only 119 III (21080) advertises it.
    $dec = Decode-Id $file 21070
    if ($isEnglish) {
        $descOff = Find-Dmg $dec
        if ($descOff -lt 0) { throw 'No DMG: on 21070' }
        $text = [Text.Encoding]::ASCII.GetBytes($idris119Desc)
        if (($descOff + $text.Length + 1) -gt $textEnd) { throw '21070 EN desc too long' }
        for ($i = $descOff; $i -lt $textEnd; $i++) { $dec[$i] = 0 }
        [Buffer]::BlockCopy($text, 0, $dec, $descOff, $text.Length)
    } else {
        $hits = Replace-Digits $dec $nameOff $textEnd '+10' '   '
        if ($hits -lt 1) { throw 'JP 21070: +10 (Geomancy) not found' }
    }
    $off = (21070 - $firstId) * $recordSize
    for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }

    if ($isEnglish) {
        $dec = Decode-Id $file 21410
        $nameBytes = [Text.Encoding]::ASCII.GetBytes('Martial Wraps')
        for ($i = 0; $i -lt 16; $i++) { $dec[$nameOff + $i] = 0 }
        [Buffer]::BlockCopy($nameBytes, 0, $dec, $nameOff, $nameBytes.Length)
        $off = (21410 - $firstId) * $recordSize
        for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
    }

    # 19972 and 19973 stay retail empty stubs. A named 0xF840 clone at
    # 19973 still R0s zone-in (name-table rewrite was not sufficient).

    $out = Join-Path $package $rel.Key
    [IO.File]::WriteAllBytes($out, $file)
    $hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
    $srcHash = (Get-FileHash -LiteralPath $src.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -eq $srcHash) { throw "$($rel.Key) hash matches source - nothing was written" }
    $report.Add(('{0}  {1} bytes  sha256={2}' -f $rel.Key, $file.Length, $hash))
}

$en = [IO.File]::ReadAllBytes((Join-Path $package 'ROM\118\108.DAT'))
$checks = @(
    @{ Id = 20753; Jobs = $RUN; Dmg = 243; Ilvl = 119; Name = 'Epeolatry' }
    @{ Id = 21685; Jobs = $RUN; Dmg = 305; Ilvl = 119; Name = 'Epeolatry' }
    @{ Id = 19972; Jobs = [uint32]0; Dmg = 0; Ilvl = 0; Name = '.'; Flags = 0xF040 }
    @{ Id = 19973; Jobs = [uint32]0; Dmg = 0; Ilvl = 0; Name = '.'; Flags = 0xF040 }
    @{ Id = 21410; Jobs = [uint32]0x007FFFFE; Dmg = 0; Ilvl = 0; Name = 'Martial Wraps' }
)
foreach ($c in $checks) {
    $dec = Decode-Id $en $c.Id
    $idField = [BitConverter]::ToUInt32($dec, 0)
    if ($idField -ne $c.Id) { throw "ID field $idField != $($c.Id)" }
    $jobs = [BitConverter]::ToUInt32($dec, $jobsOff)
    if ($jobs -ne $c.Jobs) { throw ("jobs mismatch id {0}: 0x{1:X8}" -f $c.Id, $jobs) }
    $dmg = [BitConverter]::ToUInt16($dec, $dmgOff)
    if ($dmg -ne $c.Dmg) { throw "dmg mismatch id $($c.Id) got $dmg" }
    if ($dec[$ilvlOff] -ne $c.Ilvl) { throw "ilvl mismatch id $($c.Id)" }
    $name = [Text.Encoding]::ASCII.GetString($dec, $nameOff, 24).Split([char]0)[0]
    if (-not $name.StartsWith($c.Name)) { throw "name mismatch id $($c.Id): '$name'" }
    if ($c.ContainsKey('Flags')) {
        $flags = [BitConverter]::ToUInt16($dec, 0x04)
        if ($flags -ne $c.Flags) { throw ("flags mismatch id {0}: 0x{1:X4}" -f $c.Id, $flags) }
    }
    $text = [Text.Encoding]::ASCII.GetString($dec, $nameOff, 0x200)
    if ($c.Needle) {
        if ($text.IndexOf($c.Needle) -lt 0) { throw "missing $($c.Needle) on $($c.Id)" }
    }
    if ($c.Forbid -and $text.IndexOf($c.Forbid) -ge 0) {
        throw "forbidden '$($c.Forbid)' still on $($c.Id)"
    }
}
$mandau = Decode-Id $en 18270
if (([BitConverter]::ToUInt32($mandau, $jobsOff) -band [uint32]0x00080000) -eq 0) {
    throw 'Mandau DNC bit missing'
}

Write-Output 'OK'
$report | ForEach-Object { Write-Output $_ }
