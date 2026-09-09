$ErrorActionPreference = 'Stop'

$package    = $PSScriptRoot
$datRel     = 'ROM\286\73.DAT'
$datPath    = Join-Path $package $datRel
$recordSize = 0xC00
$firstId    = 23040
$donorId    = 26344

$vouchers = @(
    @{ Id = 23879; Name = 'Spharai Voucher' }
    @{ Id = 23880; Name = 'Mandau Voucher' }
    @{ Id = 23881; Name = 'Excalibur Voucher' }
    @{ Id = 23882; Name = 'Ragnarok Voucher' }
    @{ Id = 23883; Name = 'Guttler Voucher' }
    @{ Id = 23884; Name = 'Bravura Voucher' }
    @{ Id = 23885; Name = 'Apocalypse Voucher' }
    @{ Id = 23886; Name = 'Gungnir Voucher' }
    @{ Id = 23887; Name = 'Kikoku Voucher' }
    @{ Id = 23888; Name = 'Amanomurakumo Voucher' }
    @{ Id = 23889; Name = 'Mjollnir Voucher' }
    @{ Id = 23890; Name = 'Claustrum Voucher' }
    @{ Id = 23891; Name = 'Yoichinoyumi Voucher' }
    @{ Id = 23892; Name = 'Annihilator Voucher' }
    @{ Id = 23867; Name = 'Aegis Voucher' }
    @{ Id = 23868; Name = 'Gjallarhorn Voucher' }
)

# Unused hole we briefly cloned vouchers into. Restore stock stubs so these
# ids stay free.
$clearIds = @(24276, 24277, 24278, 24279, 24280, 24281, 24282, 24290, 24291, 24292, 24293, 24294, 24295, 24296)
$blankId  = 23869

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

function Write-Record([byte[]]$file, [int]$id, [byte[]]$dec) {
    $off = ($id - $firstId) * $recordSize
    for ($i = 0; $i -lt $recordSize; $i++) { $file[$off + $i] = Rol5 $dec[$i] }
}

function Poke-U32($arr, [int]$off, [uint32]$value) {
    $b = [BitConverter]::GetBytes($value)
    $arr[$off]     = $b[0]
    $arr[$off + 1] = $b[1]
    $arr[$off + 2] = $b[2]
    $arr[$off + 3] = $b[3]
}

function Write-CString($arr, [int]$from, [int]$to, [string]$text) {
    $bytes = [Text.Encoding]::ASCII.GetBytes($text)
    if (($from + $bytes.Length + 1) -gt $to) {
        throw "String '$text' does not fit in $from..$to"
    }
    for ($i = $from; $i -lt $to; $i++) { $arr[$i] = 0 }
    [Buffer]::BlockCopy($bytes, 0, $arr, $from, $bytes.Length)
}

if (-not (Test-Path -LiteralPath $datPath)) {
    throw "Missing $datPath -- run this from the Relaunch Custom DATs pack."
}

$file = [IO.File]::ReadAllBytes($datPath)
if (($file.Length % $recordSize) -ne 2272 -and ($file.Length % $recordSize) -ne 0) {
    # 17301504 % 3072 = 2272; the stock file is still ID-aligned from 23040.
    Write-Host ("note: trailing $($file.Length % $recordSize) bytes after last full record")
}

$donor = Decode-Id $file $donorId
$donorName = [Text.Encoding]::ASCII.GetString($donor, 0x74, 24).Split([char]0)[0]
if (-not $donorName.StartsWith('Artemis')) {
    throw "Donor $donorId is '$donorName', expected Artemis's Quiver"
}

$desc = "A Hades relic voucher. Trade it to the Weapon Forger after you have forged a Relic 119 III of your own."

foreach ($v in $vouchers) {
    $dec = [byte[]]::new($recordSize)
    [Buffer]::BlockCopy($donor, 0, $dec, 0, $recordSize)
    Poke-U32 $dec 0 ([uint32]$v.Id)
    Write-CString $dec 0x074 0x0A8 $v.Name
    Write-CString $dec 0x0A8 0x0D8 $v.Name.ToLowerInvariant()
    Write-CString $dec 0x0D8 0x108 ($v.Name.ToLowerInvariant() + 's')
    Write-CString $dec 0x108 0x180 $desc
    Write-Record $file $v.Id $dec
}

$blank = Decode-Id $file $blankId
foreach ($id in $clearIds) {
    $dec = [byte[]]::new($recordSize)
    [Buffer]::BlockCopy($blank, 0, $dec, 0, $recordSize)
    Poke-U32 $dec 0 ([uint32]$id)
    Write-Record $file $id $dec
}

$tmp = $datPath + '.tmp'
[IO.File]::WriteAllBytes($tmp, $file)
Move-Item -LiteralPath $tmp -Destination $datPath -Force

foreach ($v in $vouchers) {
    $dec = Decode-Id $file $v.Id
    $idField = [BitConverter]::ToUInt32($dec, 0)
    if ($idField -ne $v.Id) { throw "ID field $idField != $($v.Id)" }
    $name = [Text.Encoding]::ASCII.GetString($dec, 0x74, 24).Split([char]0)[0]
    if ($name -ne $v.Name) { throw "name mismatch id $($v.Id): '$name'" }
}

$jacket = Decode-Id $file 23875
$jName = [Text.Encoding]::ASCII.GetString($jacket, 0x74, 24).Split([char]0)[0]
if ($jName -ne 'Track Jacket') { throw "Track Jacket clobbered: '$jName'" }
$ring = Decode-Id $file 26169
$rName = [Text.Encoding]::ASCII.GetString($ring, 0x74, 24).Split([char]0)[0]
if ($rName -ne 'Legendary Ring') { throw "Legendary Ring clobbered: '$rName'" }

foreach ($id in $clearIds) {
    $dec = Decode-Id $file $id
    $name = [Text.Encoding]::ASCII.GetString($dec, 0x74, 24).Split([char]0)[0]
    if ($name -notin @('', '.')) { throw "clear id $id still named '$name'" }
}

$hash = (Get-FileHash -LiteralPath $datPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output 'OK'
Write-Output ("{0}  {1} bytes  sha256={2}" -f $datRel, $file.Length, $hash)
$vouchers | ForEach-Object { Write-Output ("  {0}  {1}" -f $_.Id, $_.Name) }
$clearIds | ForEach-Object { Write-Output ("  {0}  (cleared)" -f $_) }
