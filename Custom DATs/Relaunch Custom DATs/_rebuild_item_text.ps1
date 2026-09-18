$ErrorActionPreference = 'Stop'

# September 2026: 0x1400 records. Only in-place string edits on live retail
# rows. Cloning a full item onto a stub id R0s this client.

$package    = $PSScriptRoot
$ffxi       = 'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI'
$datRel     = 'ROM\286\73.DAT'
$srcPath    = Join-Path $ffxi $datRel
$datPath    = Join-Path $package $datRel
$recordSize = 0x1400
$firstId    = 23040

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

# Overwrite a C-string but stop before the 01 00 00 00 language flag.
function Poke-Slot([byte[]]$arr, [int]$from, [int]$flagAt, [string]$text) {
    $bytes = [Text.Encoding]::ASCII.GetBytes($text)
    if (($from + $bytes.Length + 1) -gt $flagAt) {
        throw "String '$text' does not fit in $from..$flagAt"
    }
    for ($i = $from; $i -lt $flagAt; $i++) { $arr[$i] = 0 }
    [Buffer]::BlockCopy($bytes, 0, $arr, $from, $bytes.Length)
}

if (-not (Test-Path -LiteralPath $srcPath)) {
    throw "Missing retail $srcPath. Update FFXI first."
}

New-Item -ItemType Directory -Force -Path (Split-Path $datPath) | Out-Null
Copy-Item -LiteralPath $srcPath -Destination $datPath -Force
$file = [IO.File]::ReadAllBytes($datPath)
if (($file.Length % $recordSize) -ne 0) {
    throw "Retail $datRel is $($file.Length) bytes; expected a 0x1400-stride file."
}

$ring = Decode-Id $file 26169
$name = [Text.Encoding]::ASCII.GetString($ring, 0x78, 24).Split([char]0)[0]
if ($name -ne 'Reraise Ring' -and $name -ne 'Legendary Ring') {
    throw "Item 26169 is '$name', expected Reraise Ring"
}
Poke-Slot $ring 0x78 0x8C 'Legendary Ring'
Poke-Slot $ring 0xA8 0xB8 'legendary ring'
Poke-Slot $ring 0xD4 0xE4 'legendary rings'
Poke-Slot $ring 0x100 0x180 "Capacity Points Boost +300%`nExperience Points Boost +300%`nAuto Reraise Effect"
Write-Record $file 26169 $ring

$tmp = $datPath + '.tmp'
[IO.File]::WriteAllBytes($tmp, $file)
Move-Item -LiteralPath $tmp -Destination $datPath -Force

$ring = Decode-Id $file 26169
$got = [Text.Encoding]::ASCII.GetString($ring, 0x78, 24).Split([char]0)[0]
if ($got -ne 'Legendary Ring') { throw "Legendary Ring write failed: '$got'" }
if ($ring[0x8C] -ne 1) { throw 'name language flag wiped' }
if ($ring[0xB8] -ne 1) { throw 'log language flag wiped' }

$hash = (Get-FileHash -LiteralPath $datPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output 'OK'
Write-Output ("{0}  {1} bytes  sha256={2}" -f $datRel, $file.Length, $hash)
Write-Output '  26169  Legendary Ring (in-place, flags kept)'
