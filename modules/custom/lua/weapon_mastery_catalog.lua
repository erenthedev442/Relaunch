-----------------------------------
-- Weapon Mastery catalog
--
-- Deterministic, weapon-family-specific Prime Trial 4 definitions. Runtime
-- state and spawning remain in job_mastery.lua; this file owns progression,
-- equipment validation, stats, and mechanics so the complete 14-fight matrix
-- can be integrity-tested without loading a zone.
-----------------------------------
local C =
{
    softEnrageSec  = 420,
    hardTimeoutSec = 600,
    weaponGraceTicks = 3,
    requiredPrimeVars =
    {
        'PW_Trial1_Done',
        'PW_Trial2_Done',
        'PW_Trial3_Done',
    },
    soloFailEffects =
    {
        xi.effect.PETRIFICATION,
        xi.effect.GRADUAL_PETRIFICATION,
        xi.effect.TERROR,
        xi.effect.DOOM,
        xi.effect.CHARM_I,
        xi.effect.SLEEP_I,
        xi.effect.SLEEP_II,
    },
    guardians = {},
    order = {},
    byType = {},
}

local function mechanics(name, options)
    local cfg =
    {
        name = name,
        enrage =
        {
            sec = C.softEnrageSec,
            att = options.enrageAtt or 3000,
            haste = options.enrageHaste or 120,
            msg = options.enrageMsg or 'The Guardian begins its final assault!',
        },
        phases = options.phases or {},
    }

    if options.aoe then cfg.aoe = options.aoe end
    if options.cc then cfg.cc = options.cc end
    if options.drain then cfg.drain = options.drain end
    if options.stance then cfg.stance = options.stance end
    return cfg
end

local function statBlock(att, def, acc, eva, matt, macc, meva, extra)
    local mods =
    {
        [xi.mod.ATT]           = att,
        [xi.mod.DEF]           = def,
        [xi.mod.ACC]           = acc,
        [xi.mod.EVASION]       = eva,
        [xi.mod.MATT]          = matt,
        [xi.mod.MACC]          = macc,
        [xi.mod.MEVA]          = meva,
        [xi.mod.MDEF]          = 750,
        [xi.mod.STR]           = 350,
        [xi.mod.DEX]           = 350,
        [xi.mod.VIT]           = 350,
        [xi.mod.AGI]           = 350,
        [xi.mod.INT]           = 350,
        [xi.mod.MND]           = 350,
        [xi.mod.CHR]           = 350,
        [xi.mod.STORETP]       = 100,
        [xi.mod.DOUBLE_ATTACK] = 8,
        [xi.mod.HASTE_GEAR]    = 180,
        [xi.mod.REGEN]         = 100,
    }
    for modId, value in pairs(extra or {}) do mods[modId] = value end
    return mods
end

local physicalWindow =
{
    startHpp = 90,
    periodSec = 26,
    stances =
    {
        {
            mods = { [xi.mod.DMGPHYS] = -1500, [xi.mod.DMGMAGIC] = 0 },
            msg = 'The Guardian braces against direct attacks.',
        },
        {
            mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = 0 },
            msg = 'The Guardian overextends and its guard opens!',
        },
    },
}

local arcaneWindow =
{
    startHpp = 90,
    periodSec = 24,
    stances =
    {
        {
            mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -1500 },
            msg = 'The Guardian raises an arcane ward.',
        },
        {
            mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = 0 },
            msg = 'The Guardian expends its ward and becomes vulnerable!',
        },
    },
}

local definitions =
{
    {
        key = 'handtohand', type = 'Hand-to-Hand', label = 'H2H',
        primeName = 'Varga Purnikawa', slot = xi.slot.MAIN, skill = xi.skill.HAND_TO_HAND,
        bossName = 'Guardian of the Fist', groupId = 11364, level = 145, hp = 13500000,
        damageCap = 4000, signature = 'Rapid pressure, guard cycles, and a final counter rush.',
        mods = statBlock(7200, 2050, 2050, 800, 900, 1200, 850,
            { [xi.mod.COUNTER] = 12, [xi.mod.DOUBLE_ATTACK] = 18 }),
        mechanics = mechanics('Guardian of the Fist', {
            aoe = { periodSec = 22, dmgPct = 8, msg = 'A flurry of blows sends a shockwave through the arena!' },
            stance = physicalWindow,
            phases = {
                { hp = 50, action = 'fury', att = 1600, haste = 70, msg = 'The Guardian settles into a relentless rhythm!' },
                { hp = 18, action = 'nuke', dmgPct = 16, msg = 'The Guardian unleashes its finishing combination!' },
            },
        }),
    },
    {
        key = 'dagger', type = 'Dagger', label = 'Dagger',
        primeName = 'Mpu Gandring', slot = xi.slot.MAIN, skill = xi.skill.DAGGER,
        bossName = 'Guardian of the Shadow', groupId = 11362, level = 145, hp = 12500000,
        damageCap = 4000, signature = 'High evasion, poison pressure, and brief openings.',
        mods = statBlock(6800, 1650, 2200, 1100, 1000, 1350, 950,
            { [xi.mod.TRIPLE_ATTACK] = 10 }),
        mechanics = mechanics('Guardian of the Shadow', {
            cc = { periodSec = 24, effect = xi.effect.POISON, power = 45, dur = 12,
                msg = 'A venomous edge finds its mark!' },
            stance = physicalWindow,
            phases = {
                { hp = 55, action = 'dispel', count = 1, msg = 'The Guardian steals away one of your protections!' },
                { hp = 22, action = 'fury', att = 1700, haste = 90, msg = 'The shadows begin striking from every side!' },
            },
        }),
    },
    {
        key = 'sword', type = 'Sword', label = 'Sword',
        primeName = 'Caliburnus', slot = xi.slot.MAIN, skill = xi.skill.SWORD,
        bossName = 'Guardian of the Blade', groupId = 11365, level = 146, hp = 14000000,
        damageCap = 4200, signature = 'Balanced offense, measured shockwaves, and defensive forms.',
        mods = statBlock(7200, 1900, 2050, 800, 1200, 1400, 1000),
        mechanics = mechanics('Guardian of the Blade', {
            aoe = { periodSec = 24, dmgPct = 9, msg = 'The Guardian sweeps the arena with a disciplined arc!' },
            stance = physicalWindow,
            phases = {
                { hp = 60, action = 'dispel', count = 1, msg = 'The Guardian breaks one layer of your defense!' },
                { hp = 25, action = 'fury', att = 1800, haste = 80, msg = 'The Guardian commits fully to the duel!' },
            },
        }),
    },
    {
        key = 'greatsword', type = 'Great Sword', label = 'Grt.Sword',
        primeName = 'Helheim', slot = xi.slot.MAIN, skill = xi.skill.GREAT_SWORD,
        bossName = 'Guardian of Ruin', groupId = 11367, level = 150, hp = 17000000,
        damageCap = 4500, signature = 'Slow, heavily telegraphed cleaves with punishing impact.',
        mods = statBlock(8000, 2200, 1950, 650, 1100, 1250, 900,
            { [xi.mod.DOUBLE_ATTACK] = 5, [xi.mod.HASTE_GEAR] = 100 }),
        mechanics = mechanics('Guardian of Ruin', {
            aoe = { periodSec = 30, dmgPct = 12, msg = 'The Guardian raises its blade--brace for the descending cleave!' },
            phases = {
                { hp = 65, action = 'nuke', dmgPct = 15, msg = 'The arena fractures beneath a ruinous swing!' },
                { hp = 35, action = 'dispel', count = 2, msg = 'The Guardian sunders your outer defenses!' },
                { hp = 15, action = 'fury', att = 2200, haste = 70, msg = 'The great blade becomes impossible to halt!' },
            },
        }),
    },
    {
        key = 'axe', type = 'Axe', label = 'Axe',
        primeName = 'Spalirisos', slot = xi.slot.MAIN, skill = xi.skill.AXE,
        bossName = 'Guardian of the Axe', groupId = 11363, level = 146, hp = 14000000,
        damageCap = 4200, signature = 'Sustained pressure, slowing chops, and light life drain.',
        mods = statBlock(7300, 1850, 2050, 750, 950, 1200, 850,
            { [xi.mod.DOUBLE_ATTACK] = 14 }),
        mechanics = mechanics('Guardian of the Axe', {
            cc = { periodSec = 27, effect = xi.effect.SLOW, power = 1200, dur = 10,
                msg = 'A hamstringing chop slows your assault!' },
            drain = { periodSec = 24, healPct = 0.15 },
            phases = {
                { hp = 50, action = 'fury', att = 1700, haste = 70, msg = 'The Guardian presses the advantage!' },
                { hp = 20, action = 'nuke', dmgPct = 15, msg = 'The Guardian hurls its axe in a brutal arc!' },
            },
        }),
    },
    {
        key = 'greataxe', type = 'Great Axe', label = 'Grt.Axe',
        primeName = 'Laphria', slot = xi.slot.MAIN, skill = xi.skill.GREAT_AXE,
        bossName = 'Guardian of the Vanguard', groupId = 11368, level = 150, hp = 17500000,
        damageCap = 4500, signature = 'Armor-breaking impacts and escalating berserker pressure.',
        mods = statBlock(8200, 2150, 1950, 650, 900, 1150, 850,
            { [xi.mod.DOUBLE_ATTACK] = 15, [xi.mod.HASTE_GEAR] = 120 }),
        mechanics = mechanics('Guardian of the Vanguard', {
            aoe = { periodSec = 28, dmgPct = 11, msg = 'The Vanguard crashes its weapon into the earth!' },
            phases = {
                { hp = 70, action = 'dispel', count = 1, msg = 'The Vanguard shatters one defensive blessing!' },
                { hp = 42, action = 'fury', att = 1900, haste = 80, msg = 'The Vanguard abandons all restraint!' },
                { hp = 16, action = 'enrage', att = 2800, haste = 120, msg = 'The Vanguard begins its last charge!' },
            },
        }),
    },
    {
        key = 'scythe', type = 'Scythe', label = 'Scythe',
        primeName = 'Foenaria', slot = xi.slot.MAIN, skill = xi.skill.SCYTHE,
        bossName = 'Guardian of Catastrophe', groupId = 11366, level = 149, hp = 16500000,
        damageCap = 4400, signature = 'Darkened vision, measured life drain, and execution pressure.',
        mods = statBlock(7700, 1950, 2000, 700, 1500, 1600, 1100),
        mechanics = mechanics('Guardian of Catastrophe', {
            cc = { periodSec = 26, effect = xi.effect.BLINDNESS, power = 45, dur = 12,
                msg = 'Catastrophic darkness swallows your sight!' },
            drain = { periodSec = 22, healPct = 0.20 },
            phases = {
                { hp = 55, action = 'nuke', dmgPct = 14, msg = 'The Guardian harvests the light around you!' },
                { hp = 20, action = 'fury', att = 2100, haste = 80, msg = 'The scythe hungers for its final harvest!' },
            },
        }),
    },
    {
        key = 'polearm', type = 'Polearm', label = 'Polearm',
        primeName = 'Gae Buide', slot = xi.slot.MAIN, skill = xi.skill.POLEARM,
        bossName = 'Guardian of the Dragon', groupId = 11369, level = 149, hp = 16000000,
        damageCap = 4400, signature = 'Long-range sweeps, brief binding pressure, and diving bursts.',
        mods = statBlock(7800, 1950, 2100, 850, 1050, 1300, 950,
            { [xi.mod.DOUBLE_ATTACK] = 12 }),
        mechanics = mechanics('Guardian of the Dragon', {
            cc = { periodSec = 30, effect = xi.effect.BIND, power = 1, dur = 3,
                msg = 'The Guardian pins your shadow to the ground!' },
            aoe = { periodSec = 25, dmgPct = 9, msg = 'A wide spear sweep tears across the platform!' },
            phases = {
                { hp = 45, action = 'nuke', dmgPct = 16, msg = 'The Guardian descends in a piercing dive!' },
                { hp = 18, action = 'fury', att = 1900, haste = 90, msg = 'The dragon spear strikes without pause!' },
            },
        }),
    },
    {
        key = 'katana', type = 'Katana', label = 'Katana',
        primeName = 'Dokoku', slot = xi.slot.MAIN, skill = xi.skill.KATANA,
        bossName = 'Void Blade Guardian', groupId = 11362, level = 146, hp = 13500000,
        damageCap = 4000, signature = 'Shadow-like guard cycles, paralysis, and sudden burst phases.',
        mods = statBlock(7000, 1700, 2200, 1050, 1250, 1450, 1050,
            { [xi.mod.TRIPLE_ATTACK] = 8 }),
        mechanics = mechanics('Void Blade Guardian', {
            cc = { periodSec = 28, effect = xi.effect.PARALYSIS, power = 18, dur = 10,
                msg = 'A numbing shadow technique catches your limbs!' },
            stance = physicalWindow,
            phases = {
                { hp = 60, action = 'dispel', count = 1, msg = 'A shadow blade cuts through one enhancement!' },
                { hp = 20, action = 'fury', att = 1900, haste = 100, msg = 'The Void Blade reveals its true speed!' },
            },
        }),
    },
    {
        key = 'greatkatana', type = 'Great Katana', label = 'Grt.Katana',
        primeName = 'Kusanagi', slot = xi.slot.MAIN, skill = xi.skill.GREAT_KATANA,
        bossName = 'Guardian of the Kensei', groupId = 11367, level = 150, hp = 17000000,
        damageCap = 4500, signature = 'Measured forms, decisive phase strikes, and a final meditate rush.',
        mods = statBlock(8000, 2050, 2100, 800, 1050, 1250, 900,
            { [xi.mod.STORETP] = 170 }),
        mechanics = mechanics('Guardian of the Kensei', {
            stance = physicalWindow,
            phases = {
                { hp = 66, action = 'nuke', dmgPct = 14, msg = 'The Kensei answers with a flawless counterstroke!' },
                { hp = 40, action = 'dispel', count = 1, msg = 'A precise cut removes one protection!' },
                { hp = 18, action = 'fury', att = 2300, haste = 110, msg = 'The Kensei enters the final form!' },
            },
        }),
    },
    {
        key = 'club', type = 'Club', label = 'Club',
        primeName = 'Lorg Mor', slot = xi.slot.MAIN, skill = xi.skill.CLUB,
        bossName = 'Guardian of the Mace', groupId = 11364, level = 146, hp = 14000000,
        damageCap = 4200, signature = 'Holy shockwaves, defensive wards, and restrained recovery.',
        mods = statBlock(6900, 2100, 1950, 650, 1450, 1600, 1200,
            { [xi.mod.MDEF] = 950 }),
        mechanics = mechanics('Guardian of the Mace', {
            aoe = { periodSec = 24, dmgPct = 9, msg = 'A ring of consecrated force bursts outward!' },
            drain = { periodSec = 28, healPct = 0.10 },
            phases = {
                { hp = 55, action = 'dispel', count = 1, msg = 'The sacred impact strips one blessing!' },
                { hp = 20, action = 'nuke', dmgPct = 16, msg = 'The Guardian calls down a final judgment!' },
            },
        }),
    },
    {
        key = 'staff', type = 'Staff', label = 'Staff',
        primeName = 'Opashoro', slot = xi.slot.MAIN, skill = xi.skill.STAFF,
        bossName = 'Guardian of Elements', groupId = 11366, level = 149, hp = 15000000,
        damageCap = 4300, signature = 'Alternating arcane wards, elemental pulses, and magical escalation.',
        mods = statBlock(6600, 1800, 1900, 700, 1800, 1900, 1350,
            { [xi.mod.FASTCAST] = 35 }),
        mechanics = mechanics('Guardian of Elements', {
            stance = arcaneWindow,
            aoe = { periodSec = 23, dmgPct = 9, msg = 'The elements converge and erupt around the arena!' },
            phases = {
                { hp = 60, action = 'nuke', dmgPct = 14, msg = 'The Guardian releases a concentrated elemental surge!' },
                { hp = 30, action = 'dispel', count = 2, msg = 'Elemental inversion tears through your wards!' },
                { hp = 15, action = 'fury', att = 1300, haste = 70, msg = 'Every element answers the Guardian at once!' },
            },
        }),
    },
    {
        key = 'archery', type = 'Archery', label = 'Archery',
        primeName = 'Pinaka', slot = xi.slot.RANGED, skill = xi.skill.ARCHERY,
        bossName = 'Guardian of the Hunt', groupId = 11363, level = 147, hp = 14000000,
        damageCap = 4100, signature = 'Patient volleys, slowing shots, and exposed recovery windows.',
        mods = statBlock(7100, 1750, 2250, 950, 950, 1250, 950,
            { [xi.mod.RACC] = 2300, [xi.mod.RATT] = 7500, [xi.mod.SNAPSHOT] = 35 }),
        mechanics = mechanics('Guardian of the Hunt', {
            cc = { periodSec = 28, effect = xi.effect.SLOW, power = 1000, dur = 9,
                msg = 'A pinning arrow slows your movements!' },
            stance = physicalWindow,
            phases = {
                { hp = 50, action = 'nuke', dmgPct = 14, msg = 'A high volley rains down across the platform!' },
                { hp = 18, action = 'fury', att = 1700, haste = 90, msg = 'The Guardian draws for the final shot!' },
            },
        }),
    },
    {
        key = 'marksmanship', type = 'Marksmanship', label = 'Marksman',
        primeName = 'Earp', slot = xi.slot.RANGED, skill = xi.skill.MARKSMANSHIP,
        bossName = 'Guardian of the Trigger', groupId = 11363, level = 147, hp = 14500000,
        damageCap = 4100, signature = 'Burst volleys, smoke-blind pressure, and deliberate reload lulls.',
        mods = statBlock(7200, 1800, 2250, 900, 950, 1250, 950,
            { [xi.mod.RACC] = 2350, [xi.mod.RATT] = 7700, [xi.mod.SNAPSHOT] = 40 }),
        mechanics = mechanics('Guardian of the Trigger', {
            cc = { periodSec = 26, effect = xi.effect.BLINDNESS, power = 35, dur = 10,
                msg = 'A burst of smoke obscures the firing line!' },
            phases = {
                { hp = 65, action = 'nuke', dmgPct = 12, msg = 'The Guardian fires a disciplined three-round burst!' },
                { hp = 38, action = 'dispel', count = 1, msg = 'An armor-piercing shot removes one protection!' },
                { hp = 16, action = 'fury', att = 1800, haste = 100, msg = 'The Guardian empties its final magazine!' },
            },
        }),
    },
}

for _, guardian in ipairs(definitions) do
    C.guardians[guardian.key] = guardian
    C.order[#C.order + 1] = guardian.key
    C.byType[guardian.type] = guardian
end

function C.completionVar(weaponKey)
    return 'PW_T4_' .. tostring(weaponKey) .. '_Done'
end

function C.isComplete(player, weaponKey)
    return (player:getCharVar(C.completionVar(weaponKey)) or 0) == 1
end

function C.primeAuthorized(player, weaponType)
    local guardian = C.byType[weaponType]
    return guardian ~= nil and C.isComplete(player, guardian.key), guardian
end

function C.supportAuthorized(player)
    return (player:getCharVar('PW_Trial4_Done') or 0) == 1
end

function C.isGrouped(player)
    local grouped = false
    pcall(function()
        for _, member in ipairs(player:getParty() or {}) do
            if member:isPC() and member:getID() ~= player:getID() then grouped = true end
        end
    end)
    pcall(function()
        for _, member in ipairs(player:getAlliance() or {}) do
            if member:isPC() and member:getID() ~= player:getID() then grouped = true end
        end
    end)
    return grouped
end

function C.hasRequiredWeapon(player, guardian)
    if not player or not guardian then return false end
    local item = player:getEquippedItem(guardian.slot)
    return item ~= nil
        and item:getSkillType() == guardian.skill
        and (item:getILvl() or 0) >= 119
end

function C.entryCheck(player, guardian)
    if not guardian then return false, 'invalid' end
    if player:getMainLvl() < 99 then return false, 'level' end
    for _, var in ipairs(C.requiredPrimeVars) do
        if (player:getCharVar(var) or 0) ~= 1 then return false, 'prior_trials' end
    end
    if (player:getCharVar('WF_Aeonic_Final') or 0) ~= 1 then return false, 'aeonic' end
    if C.isGrouped(player) then return false, 'grouped' end
    if not C.hasRequiredWeapon(player, guardian) then return false, 'weapon' end
    return true, nil
end

return C
