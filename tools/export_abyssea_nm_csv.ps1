param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputPath = 'docs/reference/abyssea-nm-roster.csv'
)

$ErrorActionPreference = 'Stop'

$catalogPath = Join-Path $RepoRoot 'modules/custom/lua/abyssea_marks_catalog.lua'
$runtimePath = Join-Path $RepoRoot 'modules/custom/lua/AbysseaMarks.lua'
$destination = Join-Path $RepoRoot $OutputPath

if (-not (Test-Path $catalogPath) -or -not (Test-Path $runtimePath)) {
    throw 'Run this script from a Relaunch checkout containing the Abyssea Lua modules.'
}

$catalog = [IO.File]::ReadAllText($catalogPath)
$runtime = [IO.File]::ReadAllText($runtimePath)

function Split-LuaArguments {
    param([string]$Text)

    $items = [Collections.Generic.List[string]]::new()
    $start = 0
    $paren = 0
    $brace = 0
    $bracket = 0
    $quote = [char]0
    $escaped = $false

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $char = $Text[$i]
        if ($quote -ne [char]0) {
            if ($escaped) {
                $escaped = $false
            } elseif ($char -eq '\') {
                $escaped = $true
            } elseif ($char -eq $quote) {
                $quote = [char]0
            }
            continue
        }

        if ($char -eq "'" -or $char -eq '"') {
            $quote = $char
            continue
        }

        switch ($char) {
            '(' { $paren++ }
            ')' { $paren-- }
            '{' { $brace++ }
            '}' { $brace-- }
            '[' { $bracket++ }
            ']' { $bracket-- }
            ',' {
                if ($paren -eq 0 -and $brace -eq 0 -and $bracket -eq 0) {
                    $items.Add($Text.Substring($start, $i - $start).Trim())
                    $start = $i + 1
                }
            }
        }
    }

    if ($start -lt $Text.Length) {
        $items.Add($Text.Substring($start).Trim())
    }
    return $items.ToArray()
}

function Get-BalancedCall {
    param(
        [string]$Text,
        [int]$OpenParen
    )

    $depth = 0
    $quote = [char]0
    $escaped = $false
    for ($i = $OpenParen; $i -lt $Text.Length; $i++) {
        $char = $Text[$i]
        if ($quote -ne [char]0) {
            if ($escaped) {
                $escaped = $false
            } elseif ($char -eq '\') {
                $escaped = $true
            } elseif ($char -eq $quote) {
                $quote = [char]0
            }
            continue
        }

        if ($char -eq "'" -or $char -eq '"') {
            $quote = $char
        } elseif ($char -eq '(') {
            $depth++
        } elseif ($char -eq ')') {
            $depth--
            if ($depth -eq 0) {
                return @{
                    Body = $Text.Substring($OpenParen + 1, $i - $OpenParen - 1)
                    End  = $i
                }
            }
        }
    }
    throw "Unclosed Lua call at character $OpenParen"
}

function ConvertFrom-LuaString {
    param([string]$Value)
    $value = $Value.Trim()
    if ($value.Length -ge 2 -and
        (($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'") -or
         ($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"'))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    return $value.Replace("\'", "'").Replace('\"', '"')
}

function ConvertFrom-LuaOptions {
    param([string]$Expression)

    $result = @{}
    $value = $Expression.Trim()
    if (-not $value.StartsWith('{')) {
        return $result
    }
    $body = $value.Substring(1, $value.Length - 2)
    foreach ($part in (Split-LuaArguments $body)) {
        if ($part -match '^\s*(\w+)\s*=\s*(.+?)\s*$') {
            $result[$Matches[1]] = $Matches[2]
        }
    }
    return $result
}

function Get-Number {
    param(
        [hashtable]$Options,
        [string]$Key,
        $Default = $null
    )
    if (-not $Options.ContainsKey($Key)) {
        return $Default
    }
    $parsed = 0.0
    if ([double]::TryParse(
        $Options[$Key],
        [Globalization.NumberStyles]::Any,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$parsed)) {
        if ([math]::Floor($parsed) -eq $parsed) { return [int]$parsed }
        return $parsed
    }
    return $Default
}

$effectCycle = @('POISON', 'PARALYSIS', 'BLINDNESS', 'SLOW', 'SILENCE', 'PLAGUE', 'AMNESIA')

function Get-EffectName {
    param([hashtable]$Options)

    if (-not $Options.ContainsKey('effect')) {
        return ''
    }
    $raw = $Options['effect']
    if ($raw -match '^xi\.effect\.(\w+)$') {
        return $Matches[1]
    }
    if ($raw -match '^e\((\d+)\)$') {
        $index = [int]$Matches[1]
        return $effectCycle[(($index - 1) % $effectCycle.Count)]
    }
    return $raw
}

function ConvertFrom-Signature {
    param([string]$Expression)

    $trimmed = $Expression.Trim()
    if (-not $trimmed.StartsWith('signature(')) {
        throw "Expected signature(...), got: $trimmed"
    }
    $call = Get-BalancedCall $trimmed $trimmed.IndexOf('(')
    $args = Split-LuaArguments $call.Body
    if ($args.Count -lt 5) {
        throw "Signature has fewer than five arguments: $trimmed"
    }
    $options = if ($args.Count -ge 6) { ConvertFrom-LuaOptions $args[5] } else { @{} }

    return @{
        Title          = ConvertFrom-LuaString $args[0]
        Kind           = ConvertFrom-LuaString $args[1]
        Tell           = ConvertFrom-LuaString $args[2]
        Success        = ConvertFrom-LuaString $args[3]
        Fail           = ConvertFrom-LuaString $args[4]
        DelaySec       = Get-Number $options 'delaySec' 5
        Distance       = Get-Number $options 'distance'
        Angle          = Get-Number $options 'angle'
        DamagePct      = Get-Number $options 'damagePct'
        Hpp            = Get-Number $options 'hpp'
        FailDamagePct  = Get-Number $options 'failDamagePct'
        Effect         = Get-EffectName $options
        EffectDuration = Get-Number $options 'effectDuration'
        EffectPower    = Get-Number $options 'effectPower' 1
        RewardSec      = Get-Number $options 'rewardSec'
        RewardDef      = Get-Number $options 'rewardDef'
        RewardEva      = Get-Number $options 'rewardEva'
        RewardMdef     = Get-Number $options 'rewardMdef'
    }
}

$reversalRules = @{
    turn        = @{ Kind = 'move';        Tell = 'the pattern reverses; move at least 9 yalms!'; Distance = 9 }
    face        = @{ Kind = 'hold';        Tell = 'the pattern mirrors aggression; cease attacks!' }
    rear        = @{ Kind = 'far';         Tell = 'the rear erupts; retreat beyond 13 yalms!'; Distance = 13 }
    near        = @{ Kind = 'move';        Tell = 'the safe center shifts; move at least 9 yalms!'; Distance = 9 }
    far         = @{ Kind = 'near';        Tell = 'the outer ring closes; move within 6 yalms!'; Distance = 6 }
    move        = @{ Kind = 'rear';        Tell = 'the marked path turns forward; reach the rear!' }
    hold        = @{ Kind = 'burst';       Tell = 'the restraint breaks; deal 4% HP before it reforms!'; DamagePct = 4 }
    burst       = @{ Kind = 'far';         Tell = 'the broken ward erupts outward; retreat beyond 13 yalms!'; Distance = 13 }
    weaponskill = @{ Kind = 'far';         Tell = 'the answer detonates outward; retreat beyond 13 yalms!'; Distance = 13 }
    highhp      = @{ Kind = 'move';        Tell = 'vitality is marked; move at least 9 yalms!'; Distance = 9 }
    lowhp       = @{ Kind = 'face';        Tell = 'the pattern demands resolve; face the enemy!' }
    proc        = @{ Kind = 'weaponskill'; Tell = 'the weakness destabilizes; use a weapon skill!' }
    physical    = @{ Kind = 'hold';        Tell = 'the damage aspect reverses; cease attacks!' }
    magic       = @{ Kind = 'move';        Tell = 'the magic aspect marks the ground; move 9 yalms!'; Distance = 9 }
}

function Copy-Signature {
    param([hashtable]$Signature)
    return $Signature.Clone()
}

function New-Reversal {
    param(
        [hashtable]$Signature,
        [int]$Step
    )

    $result = Copy-Signature $Signature
    $rule = $reversalRules[$result.Kind]
    if ($null -eq $rule) { $rule = $reversalRules['move'] }
    $result.Title = "$($Signature.Title) - Reversal $Step"
    $result.Kind = $rule.Kind
    $result.Tell = $rule.Tell
    $result.Distance = if ($rule.ContainsKey('Distance')) { $rule.Distance } else { $null }
    $result.DamagePct = if ($rule.ContainsKey('DamagePct')) { $rule.DamagePct } else { $null }
    return $result
}

function Get-CounterText {
    param(
        [hashtable]$Signature,
        [int]$Hp
    )

    switch ($Signature.Kind) {
        'turn'        { return 'Turn away; the owner must not be facing the boss when the check resolves.' }
        'face'        { return 'Face the boss when the check resolves.' }
        'rear'        { return 'Move behind the boss (default safe rear arc is approximately 48 degrees).' }
        'near'        {
            $distance = if ($null -ne $Signature.Distance) { $Signature.Distance } else { 6 }
            return "Move within $distance yalms of the boss."
        }
        'far'         {
            $distance = if ($null -ne $Signature.Distance) { $Signature.Distance } else { 12 }
            return "Move at least $distance yalms from the boss."
        }
        'move'        {
            $distance = if ($null -ne $Signature.Distance) { $Signature.Distance } else { 8 }
            return "Move at least $distance yalms from the position where the tell began."
        }
        'hold'        { return 'Stop all owner damage: disengage/turn, do not weapon skill, and let the window expire.' }
        'burst'       {
            $pct = if ($null -ne $Signature.DamagePct) { [int]$Signature.DamagePct } else { 3 }
            $solo = [int][math]::Floor($Hp * $pct / 100)
            $duo = [int][math]::Floor($Hp * 1.55 * $pct / 100)
            $group = [int][math]::Floor($Hp * 2.10 * $pct / 100)
            return ('Deal {0}% of maximum HP before the check: {1:N0} solo / {2:N0} with 2 PCs / {3:N0} with 3+ PCs.' -f
                $pct, $solo, $duo, $group)
        }
        'weaponskill' { return 'The fight owner must use any weapon skill during the window.' }
        'highhp'      {
            $hpp = if ($null -ne $Signature.Hpp) { $Signature.Hpp } else { 65 }
            return "Heal the fight owner to at least $hpp% HP."
        }
        'lowhp'       {
            $hpp = if ($null -ne $Signature.Hpp) { $Signature.Hpp } else { 45 }
            return "Bring the fight owner to $hpp% HP or lower."
        }
        'proc'        { return 'Trigger the requested Abyssea weakness proc.' }
        'physical'    { return 'Deal more physical than magical damage during the window.' }
        'magic'       { return 'Deal more magical than physical damage during the window.' }
        default       { return "Unknown mechanic '$($Signature.Kind)' - catalog/runtime review required." }
    }
}

function Get-RewardText {
    param(
        [hashtable]$Signature,
        [int]$Tier,
        [bool]$Final
    )

    $seconds = if ($null -ne $Signature.RewardSec) {
        $Signature.RewardSec
    } elseif ($Final) {
        10 + 2 * $Tier
    } else {
        10
    }
    $def = if ($null -ne $Signature.RewardDef) { $Signature.RewardDef } else { 200 + 100 * $Tier }
    $eva = if ($null -ne $Signature.RewardEva) { $Signature.RewardEva } else { 50 + 50 * $Tier }
    $mdef = if ($null -ne $Signature.RewardMdef) { $Signature.RewardMdef } else { 20 + 15 * $Tier }
    return "${seconds}s vulnerability: DEF -$def, EVA -$eva, MDEF -$mdef; also removes one escalation stack."
}

function Get-ZoneAtPosition {
    param([int]$Position)

    $chosen = $null
    foreach ($marker in $zoneMarkers) {
        if ($marker.Position -gt $Position) { break }
        $chosen = $marker.Zone
    }
    if (-not $chosen) { throw "No zone marker found before catalog position $Position" }
    return $chosen
}

$zoneOrder = @(
    'Konschtat', 'Tahrongi', 'La Theine',
    'Attohwa', 'Misareaux', 'Vunkerl',
    'Altepa', 'Grauberg', 'Uleguerand'
)
$zoneMarkers = foreach ($zone in $zoneOrder) {
    $match = [regex]::Match($catalog, "(?m)^-- $([regex]::Escape($zone))\s*$")
    if (-not $match.Success) { throw "Missing catalog zone marker: $zone" }
    [pscustomobject]@{ Zone = $zone; Position = $match.Index }
}
$zoneMarkers = @($zoneMarkers | Sort-Object Position)

$zoneConfig = @{}
$zoneKeyToDisplay = @{
    ABYSSEA_KONSCHTAT = 'Konschtat'; ABYSSEA_TAHRONGI = 'Tahrongi'; ABYSSEA_LA_THEINE = 'La Theine'
    ABYSSEA_ATTOHWA = 'Attohwa'; ABYSSEA_MISAREAUX = 'Misareaux'; ABYSSEA_VUNKERL = 'Vunkerl'
    ABYSSEA_ALTEPA = 'Altepa'; ABYSSEA_GRAUBERG = 'Grauberg'; ABYSSEA_ULEGUERAND = 'Uleguerand'
}
$configPattern = '\[xi\.zone\.(ABYSSEA_\w+)\]\s*=\s*\{([^}]+)\}'
foreach ($match in [regex]::Matches($runtime, $configPattern)) {
    $zoneKey = $match.Groups[1].Value
    if (-not $zoneKeyToDisplay.ContainsKey($zoneKey)) { continue }
    $fields = @{}
    foreach ($field in [regex]::Matches($match.Groups[2].Value, '\b(\w+)\s*=\s*([\d.]+)')) {
        $fields[$field.Groups[1].Value] = [double]::Parse(
            $field.Groups[2].Value,
            [Globalization.CultureInfo]::InvariantCulture)
    }
    $zoneConfig[$zoneKeyToDisplay[$zoneKey]] = $fields
}

$tierMeta = @{
    1 = @{ Name = 'Visions'; Difficulty = 'Entry';        Target = '5-7 min solo';  Build = 'Enhanced Relic; no Atma assumed'; First = 24; Repeat = 52; Pressure = 240; Step = 30 }
    2 = @{ Name = 'Scars';   Difficulty = 'Intermediate'; Target = '7-10 min solo'; Build = 'Relic plus one Atma slot';        First = 20; Repeat = 44; Pressure = 360; Step = 25 }
    3 = @{ Name = 'Heroes';  Difficulty = 'Advanced';     Target = '10-14 min solo / 6-9 min group'; Build = 'Relic plus up to two Atma slots'; First = 16; Repeat = 36; Pressure = 480; Step = 20 }
}

$rows = [Collections.Generic.List[object]]::new()
$addMatches = [regex]::Matches($catalog, '(?m)^add\(')
foreach ($match in $addMatches) {
    $call = Get-BalancedCall $catalog ($match.Index + 3)
    $args = Split-LuaArguments $call.Body
    if ($args.Count -lt 3) { throw "Malformed add(...) at character $($match.Index)" }

    $name = ConvertFrom-LuaString $args[0]
    $tier = [int]$args[1]
    $base = ConvertFrom-Signature $args[2]
    $climax = $null
    if ($args.Count -ge 4 -and $args[3].Trim().StartsWith('signature(')) {
        $climax = ConvertFrom-Signature $args[3]
    }

    if ($null -ne $climax) {
        $phase70 = Copy-Signature $base
        $phase30 = Copy-Signature $climax
    } elseif ($tier -eq 3) {
        $phase70 = New-Reversal $base 1
        $phase30 = New-Reversal $phase70 2
    } elseif ($tier -eq 2) {
        $phase70 = Copy-Signature $base
        $phase30 = New-Reversal $base 1
    } else {
        $phase70 = Copy-Signature $base
        $phase30 = Copy-Signature $base
    }
    $phase30.DelaySec = [math]::Max(3, [int]$phase30.DelaySec - 1)

    $zone = Get-ZoneAtPosition $match.Index
    $cfg = $zoneConfig[$zone]
    $meta = $tierMeta[$tier]
    $hp = [int]$cfg.maxHP

    $phaseSets = @(
        @{ Prefix = 'Repeat'; Signature = $base;    DefaultFail = 15 + 5 * $tier; Final = $false },
        @{ Prefix = 'P70';    Signature = $phase70; DefaultFail = 15 + 5 * $tier; Final = $false },
        @{ Prefix = 'P30';    Signature = $phase30; DefaultFail = 20 + 5 * $tier; Final = $true }
    )
    $phaseData = @{}
    foreach ($phaseSet in $phaseSets) {
        $sig = $phaseSet.Signature
        $prefix = $phaseSet.Prefix
        $duration = if ($sig.Effect -and $null -eq $sig.EffectDuration) { 4 + 2 * $tier } else { $sig.EffectDuration }
        $phaseData["${prefix}Title"] = $sig.Title
        $phaseData["${prefix}Type"] = $sig.Kind
        $tellPrefix = if ($prefix -eq 'P70') {
            'At 70%: '
        } elseif ($prefix -eq 'P30') {
            'Final test at 30%: '
        } else {
            ''
        }
        $phaseData["${prefix}Tell"] = "$tellPrefix$($sig.Title) - $($sig.Tell)"
        $phaseData["${prefix}Counter"] = Get-CounterText $sig $hp
        $phaseData["${prefix}Window"] = $sig.DelaySec
        $phaseData["${prefix}FailDamage"] = if ($null -ne $sig.FailDamagePct) { $sig.FailDamagePct } else { $phaseSet.DefaultFail }
        $phaseData["${prefix}Status"] = $sig.Effect
        $phaseData["${prefix}StatusDuration"] = $duration
        $phaseData["${prefix}FailMessage"] = $sig.Fail
        $phaseData["${prefix}SuccessMessage"] = $sig.Success
        $phaseData["${prefix}Reward"] = Get-RewardText $sig $tier $phaseSet.Final
    }

    $design = if ($null -ne $climax) {
        'Flagship encounter: repeats its signature, repeats it at 70%, then changes to a bespoke climax at 30%.'
    } elseif ($tier -eq 3) {
        'Standard Heroes encounter: repeating signature, first reversal at 70%, second reversal at 30%.'
    } elseif ($tier -eq 2) {
        'Standard Scars encounter: repeating signature, same test at 70%, reversed test at 30%.'
    } else {
        'Standard Visions encounter: one mechanic taught repeatedly and reinforced at both phase floors.'
    }

    $rows.Add([pscustomobject][ordered]@{
        Boss = $name
        Zone = "Abyssea - $zone"
        Tier = $tier
        TierName = $meta.Name
        Difficulty = $meta.Difficulty
        CustomClimax = if ($null -ne $climax) { 'Yes' } else { 'No' }
        DesignSummary = $design
        IntendedBuild = $meta.Build
        TargetClearTime = $meta.Target
        Level = [int]$cfg.level
        HP_1PC = $hp
        HP_2PC = [int][math]::Floor($hp * 1.55)
        HP_3PlusPC = [int][math]::Floor($hp * 2.10)
        PopCostHuntMarks = [int]$cfg.cost
        BaseInfamy = [int]$cfg.infamy
        BaseGil = [int]$cfg.gil
        BaseCruor = [int]$cfg.cruor
        ATT_Add = [int]$cfg.att
        DEF_Add = [int]$cfg.def
        MATT_Add = [int]$cfg.matt
        ACC_Add = [int]$cfg.acc
        EVA_Add = [int]$cfg.eva
        MACC_Add = [int]$cfg.macc
        MEVA_Add = [int]$cfg.meva
        WeaponDMG_Add = [int]$cfg.weaponDmg
        DoubleAttackPct_Add = [int]$cfg.da
        HastePct_Add = ([int]$cfg.haste) / 100
        AllElementMEVA_Add = [int]$cfg.eleRes
        FirstSignatureSec = $meta.First
        RepeatIntervalSec = $meta.Repeat
        PressureStartsSec = $meta.Pressure
        PressureStepSec = $meta.Step
        RepeatTitle = $phaseData.RepeatTitle
        RepeatType = $phaseData.RepeatType
        RepeatTell = $phaseData.RepeatTell
        RepeatCounter = $phaseData.RepeatCounter
        RepeatWindowSec = $phaseData.RepeatWindow
        RepeatFailDamagePctMaxHP = $phaseData.RepeatFailDamage
        RepeatFailStatus = $phaseData.RepeatStatus
        RepeatStatusDurationSec = $phaseData.RepeatStatusDuration
        RepeatFailMessage = $phaseData.RepeatFailMessage
        RepeatSuccessMessage = $phaseData.RepeatSuccessMessage
        RepeatSuccessReward = $phaseData.RepeatReward
        Phase70Title = $phaseData.P70Title
        Phase70Type = $phaseData.P70Type
        Phase70Tell = $phaseData.P70Tell
        Phase70Counter = $phaseData.P70Counter
        Phase70WindowSec = $phaseData.P70Window
        Phase70FailDamagePctMaxHP = $phaseData.P70FailDamage
        Phase70FailStatus = $phaseData.P70Status
        Phase70StatusDurationSec = $phaseData.P70StatusDuration
        Phase70FailMessage = $phaseData.P70FailMessage
        Phase70SuccessMessage = $phaseData.P70SuccessMessage
        Phase70SuccessReward = $phaseData.P70Reward
        Phase30Title = $phaseData.P30Title
        Phase30Type = $phaseData.P30Type
        Phase30Tell = $phaseData.P30Tell
        Phase30Counter = $phaseData.P30Counter
        Phase30WindowSec = $phaseData.P30Window
        Phase30FailDamagePctMaxHP = $phaseData.P30FailDamage
        Phase30FailStatus = $phaseData.P30Status
        Phase30StatusDurationSec = $phaseData.P30StatusDuration
        Phase30FailMessage = $phaseData.P30FailMessage
        Phase30SuccessMessage = $phaseData.P30SuccessMessage
        Phase30SuccessReward = $phaseData.P30Reward
        FailEscalationPerStack = "ATT +$([int](500 * $tier)); MATT +$([int](200 * $tier))"
        PressurePerStack = "ATT +$([int](175 * $tier)); MATT +$([int](55 * $tier)); Haste +0.25%"
        OwnerRule = 'Only the player who popped the NM is checked; Trust actions do not fail hold-fire tests.'
        ProcRules = 'Red removes one escalation stack; Yellow suppresses spells and opens magic vulnerability; Blue suppresses TP moves and opens physical vulnerability.'
        RewardRules = 'First logical clear refunds half pop cost. 2+ real PCs: x2 Gil/Infamy. No Trusts: x1.5. Bonuses stack to x3.'
        SourceKey = ($name.ToLowerInvariant() -replace '[^a-z0-9]', '')
    })
}

if ($rows.Count -ne 136) {
    throw "Expected 136 Abyssea encounters, parsed $($rows.Count). CSV was not written."
}

$counts = $rows | Group-Object Tier | Sort-Object Name
$expected = @{ '1' = 45; '2' = 49; '3' = 42 }
foreach ($count in $counts) {
    if ($count.Count -ne $expected[$count.Name]) {
        throw "Tier $($count.Name) expected $($expected[$count.Name]) rows, parsed $($count.Count)."
    }
}

$parent = Split-Path -Parent $destination
if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
}
$rows | Export-Csv -Path $destination -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $($rows.Count) encounters to $destination"
