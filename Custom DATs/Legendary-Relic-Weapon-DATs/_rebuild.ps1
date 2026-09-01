$ErrorActionPreference = 'Stop'

$package    = $PSScriptRoot
$ffxi       = 'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI'
$recordSize = 0xC00
$firstId    = 0x4000

$sources = [ordered]@{
    'ROM\118\108.DAT' = Join-Path $ffxi 'ROM\118\108.DAT'
    'ROM\0\6.DAT'     = Join-Path $ffxi 'ROM\0\6.DAT'
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
    for ($i = 0x80; $i -lt 0x200; $i++) {
        if ($arr[$i] -eq 0x44 -and $arr[$i+1] -eq 0x4D -and $arr[$i+2] -eq 0x47 -and $arr[$i+3] -eq 0x3A) {
            return $i
        }
    }
    return -1
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

$RUN     = [uint32]0x00400000
$GEO     = [uint32]0x00200000

New-Item -ItemType Directory -Force -Path (Join-Path $package 'ROM\118') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $package 'ROM\0') | Out-Null

$report = New-Object System.Collections.Generic.List[string]

foreach ($rel in $sources.GetEnumerator()) {
    $src = Get-Item -LiteralPath $rel.Value
    $file = [IO.File]::ReadAllBytes($src.FullName)
    if (($file.Length % $recordSize) -ne 0) { throw "Unexpected size $($file.Length) for $($rel.Key)" }
    $isEnglish = $rel.Key -like '*118*'

    foreach ($g in $relicGroups) {
        foreach ($id in $g.IDs) {
            $dec = Decode-Id $file $id
            $jobs = [BitConverter]::ToUInt32($dec, 0x14) -bor $g.Bit
            Poke-U32 $dec 0x14 $jobs
            $off = ($id - $firstId) * $recordSize
            for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
        }
    }

    $clones = @(
        @{ Donor = 20753; NewId = 19968; Jobs = $RUN; Dmg = [uint16]154; Ilvl = [byte]0;   EnDesc = $epeo99Desc;    JpOld = '243'; JpNew = '154' }
        @{ Donor = 20753; NewId = 19969; Jobs = $RUN; Dmg = [uint16]199; Ilvl = [byte]119; EnDesc = $epeo119IDesc;  JpOld = '243'; JpNew = '199' }
        @{ Donor = 21070; NewId = 19970; Jobs = $GEO;     Dmg = [uint16]80;  Ilvl = [byte]0;   EnDesc = $idris99Desc;   JpOld = '139'; JpNew = '80' }
        @{ Donor = 21070; NewId = 19971; Jobs = $GEO;     Dmg = [uint16]110; Ilvl = [byte]119; EnDesc = $idris119IDesc; JpOld = '139'; JpNew = '110' }
    )

    foreach ($c in $clones) {
        $dec = Decode-Id $file $c.Donor
        Poke-U32 $dec 0 $c.NewId
        Poke-U32 $dec 0x14 $c.Jobs
        Poke-U16 $dec 0x1C $c.Dmg
        $dec[0x32] = $c.Ilvl
        if ($isEnglish -and $c.EnDesc) {
            $descOff = Find-Dmg $dec
            if ($descOff -lt 0) { throw "No DMG: on donor $($c.Donor)" }
            $text = [Text.Encoding]::ASCII.GetBytes($c.EnDesc)
            if (($descOff + $text.Length + 1) -gt 0x280) { throw 'EN desc too long' }
            for ($i = $descOff; $i -lt 0x280; $i++) { $dec[$i] = 0 }
            [Buffer]::BlockCopy($text, 0, $dec, $descOff, $text.Length)
        }
        if (-not $isEnglish -and $c.JpOld) {
            $hits = Replace-Digits $dec 0x80 0x280 $c.JpOld $c.JpNew
            if ($hits -lt 1) { throw "JP $($c.NewId): '$($c.JpOld)' not found" }
        }
        if (-not $isEnglish -and $c.Donor -eq 21070) {
            $null = Replace-Digits $dec 0x80 0x280 '+10' '   '
        }
        $null = Replace-Digits $dec 0x80 0x280 ([string]$c.Donor) ([string]$c.NewId)
        $off = ($c.NewId - $firstId) * $recordSize
        for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
    }

    foreach ($id in 20753, 21685) {
        $dec = Decode-Id $file $id
        Poke-U32 $dec 0x14 $RUN
        $off = ($id - $firstId) * $recordSize
        for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
    }

    # 21070 is retail 119: strip GEO+10 so only 119 III (21080) advertises it.
    $dec = Decode-Id $file 21070
    if ($isEnglish) {
        $descOff = Find-Dmg $dec
        if ($descOff -lt 0) { throw 'No DMG: on 21070' }
        $text = [Text.Encoding]::ASCII.GetBytes($idris119Desc)
        if (($descOff + $text.Length + 1) -gt 0x280) { throw '21070 EN desc too long' }
        for ($i = $descOff; $i -lt 0x280; $i++) { $dec[$i] = 0 }
        [Buffer]::BlockCopy($text, 0, $dec, $descOff, $text.Length)
    } else {
        $hits = Replace-Digits $dec 0x80 0x280 '+10' '   '
        if ($hits -lt 1) { throw 'JP 21070: +10 (Geomancy) not found' }
    }
    $off = (21070 - $firstId) * $recordSize
    for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }

    $out = Join-Path $package $rel.Key
    [IO.File]::WriteAllBytes($out, $file)
    $hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLowerInvariant()
    $srcHash = (Get-FileHash -LiteralPath $src.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -eq $srcHash) { throw "$($rel.Key) hash matches source - nothing was written" }
    $report.Add(('{0}  {1} bytes  sha256={2}' -f $rel.Key, $file.Length, $hash))
}

$en = [IO.File]::ReadAllBytes((Join-Path $package 'ROM\118\108.DAT'))
$checks = @(
    @{ Id = 19968; Jobs = $RUN; Dmg = 154; Ilvl = 0;   Name = 'Epeolatry'; Needle = 'DMG:154' }
    @{ Id = 19969; Jobs = $RUN; Dmg = 199; Ilvl = 119; Name = 'Epeolatry'; Needle = 'DMG:199' }
    @{ Id = 19970; Jobs = $GEO;     Dmg = 80;  Ilvl = 0;   Name = 'Idris';     Needle = 'DMG:80' }
    @{ Id = 19971; Jobs = $GEO;     Dmg = 110; Ilvl = 119; Name = 'Idris';     Needle = 'DMG:110'; Forbid = 'Geomancy' }
    @{ Id = 20753; Jobs = $RUN; Dmg = 243; Ilvl = 119; Name = 'Epeolatry' }
    @{ Id = 21070; Jobs = $GEO;     Dmg = 139; Ilvl = 119; Name = 'Idris';     Needle = 'DMG:139'; Forbid = 'Geomancy' }
    @{ Id = 21080; Jobs = $GEO;     Dmg = 175; Ilvl = 119; Name = 'Idris';     Needle = 'Geomancy' }
    @{ Id = 21685; Jobs = $RUN; Dmg = 305; Ilvl = 119; Name = 'Epeolatry' }
)
foreach ($c in $checks) {
    $dec = Decode-Id $en $c.Id
    $idField = [BitConverter]::ToUInt32($dec, 0)
    if ($idField -ne $c.Id) { throw "ID field $idField != $($c.Id)" }
    $jobs = [BitConverter]::ToUInt32($dec, 0x14)
    if ($jobs -ne $c.Jobs) { throw ("jobs mismatch id {0}: 0x{1:X8}" -f $c.Id, $jobs) }
    $dmg = [BitConverter]::ToUInt16($dec, 0x1C)
    if ($dmg -ne $c.Dmg) { throw "dmg mismatch id $($c.Id) got $dmg" }
    if ($dec[0x32] -ne $c.Ilvl) { throw "ilvl mismatch id $($c.Id)" }
    $name = [Text.Encoding]::ASCII.GetString($dec, 0x80, 24).Split([char]0)[0]
    if (-not $name.StartsWith($c.Name)) { throw "name mismatch id $($c.Id): '$name'" }
    $text = [Text.Encoding]::ASCII.GetString($dec, 0x80, 0x200)
    if ($c.Needle) {
        if ($text.IndexOf($c.Needle) -lt 0) { throw "missing $($c.Needle) on $($c.Id)" }
    }
    if ($c.Forbid -and $text.IndexOf($c.Forbid) -ge 0) {
        throw "forbidden '$($c.Forbid)' still on $($c.Id)"
    }
}
$mandau = Decode-Id $en 18270
if (([BitConverter]::ToUInt32($mandau, 0x14) -band [uint32]0x00080000) -eq 0) {
    throw 'Mandau DNC bit missing'
}

Write-Output 'OK'
$report | ForEach-Object { Write-Output $_ }
