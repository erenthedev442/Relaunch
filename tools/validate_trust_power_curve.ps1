# Offline validation of trust_power_scaling curve targets at master 50 / 75 / 99.
# Mirrors modules/custom/lua/trust_power_scaling.lua + trust_power_catalog.lua.
# Usage: pwsh tools/validate_trust_power_curve.ps1

$ErrorActionPreference = 'Stop'

$tierMult = @{ C = 0.52; B = 0.72; A = 0.94; S = 1.18 }
$defaultCap = 40000
$matsuiCap = 99999
$shan2MbCap = 79999

function Progress([int]$L) {
    $L = [Math]::Max(1, [Math]::Min(99, $L))
    return [Math]::Pow(($L / 99.0), 1.35)
}

function MeleePkg([double]$p, [double]$t) {
    return [ordered]@{
        weaponD = [int][Math]::Floor((55 + 165 * $p) * $t)
        att     = [int][Math]::Floor((120 + 680 * $p) * $t)
        acc     = [int][Math]::Floor((150 + 750 * $p) * $t)
        wsd     = [int][Math]::Floor((10 + 45 * $p) * $t)
        da      = [int][Math]::Floor((8 + 32 * $p) * $t)
    }
}

function MagePkg([double]$p, [double]$t) {
    return [ordered]@{
        matt = [int][Math]::Floor((10 + 430 * $p) * $t)
        macc = [int][Math]::Floor((15 + 485 * $p) * $t)
        mdmg = [int][Math]::Floor((80 + 13420 * $p) * $t)
        fc   = [int][Math]::Min(80, [Math]::Floor((10 + 70 * $p) * [Math]::Min($t, 1.1)))
        mbb  = [int][Math]::Floor((5 + 55 * $p) * $t)
    }
}

$samples = @(
    @{ Name = 'Kupipi (healer B)';   Role = 'healer'; Tier = 'B'; Cap = $defaultCap; MbCap = 0 }
    @{ Name = 'Zeid II (melee S)';   Role = 'melee';  Tier = 'S'; Cap = $defaultCap; MbCap = 0 }
    @{ Name = 'August (melee S)';    Role = 'melee';  Tier = 'S'; Cap = $defaultCap; MbCap = 0 }
    @{ Name = 'Shantotto (nuker A)'; Role = 'nuker';  Tier = 'A'; Cap = $defaultCap; MbCap = 0 }
    @{ Name = 'Shantotto II (S)';    Role = 'nuker';  Tier = 'S'; Cap = $defaultCap; MbCap = $shan2MbCap }
    @{ Name = 'Matsui-P (hybrid S)'; Role = 'hybrid'; Tier = 'S'; Cap = $matsuiCap; MbCap = 0 }
    @{ Name = 'Meat (tank S)';       Role = 'tank';   Tier = 'S'; Cap = $defaultCap; MbCap = 0 }
)

Write-Host 'Trust power curve validation (scaler floors only; scripts add flavor on top)'
Write-Host ('=' * 78)

foreach ($lvl in @(50, 75, 99)) {
    $p = Progress $lvl
    Write-Host ''
    Write-Host ("Master level {0}  progress={1:N3}" -f $lvl, $p)
    Write-Host ('-' * 78)
    foreach ($s in $samples) {
        $t = $tierMult[$s.Tier]
        $line = '{0,-24} tier={1} cap={2}' -f $s.Name, $s.Tier, $s.Cap
        if ($s.MbCap -gt 0) { $line += " mbCap=$($s.MbCap)" }
        Write-Host $line
        switch ($s.Role) {
            'melee' {
                $m = MeleePkg $p $t
                Write-Host ("  melee  D={0} ATT={1} ACC={2} WSD={3} DA={4}" -f $m.weaponD, $m.att, $m.acc, $m.wsd, $m.da)
            }
            'nuker' {
                $m = MagePkg $p $t
                Write-Host ("  mage   MATT={0} MACC={1} MAGIC_DMG={2} FC={3} MB+={4}" -f $m.matt, $m.macc, $m.mdmg, $m.fc, $m.mbb)
            }
            'hybrid' {
                $me = MeleePkg $p ($t * 0.85)
                $ma = MagePkg $p ($t * 0.85)
                Write-Host ("  hybrid D={0} ATT={1} | MATT={2} MAGIC_DMG={3}" -f $me.weaponD, $me.att, $ma.matt, $ma.mdmg)
            }
            'healer' {
                $m = MagePkg $p ($t * 0.55)
                Write-Host ("  support MATT={0} MACC={1} FC={2} (heal band, not DPS)" -f $m.matt, $m.macc, $m.fc)
            }
            'tank' {
                $m = MeleePkg $p ($t * 0.55)
                Write-Host ("  tank   D={0} ATT={1} ACC={2} (mitigation from tank package)" -f $m.weaponD, $m.att, $m.acc)
            }
        }
    }
}

Write-Host ''
Write-Host 'Expectations at master 99:'
Write-Host '  - Melee S ATT ~900+, weapon D ~240+, typical WS aiming 36-40k before hard cap'
Write-Host '  - Nuker S MATT ~490+, MAGIC_DAMAGE ~15k+, T4/T5+MB aiming 36-40k (Shan II MB up to 79999)'
Write-Host '  - Master 50 progress ~0.42 of full; master 75 ~0.70 — hits should stay well under 40k'
Write-Host '  - Hard caps: most 40000 | Matsui-P 99999 | Shantotto II MB 79999'
Write-Host ''
Write-Host 'In-game spot checks after map rebuild + SQL apply:'
Write-Host '  1) Master 50/75/99 dummy: Shantotto nuke, Zeid II WS, Meat provoke, Cornelia bubble'
Write-Host '  2) Shantotto II magic burst vs non-burst (MB may exceed 40k up to 79999)'
Write-Host '  3) Matsui-P can exceed 40k up to 99999; Fellow still independent'
