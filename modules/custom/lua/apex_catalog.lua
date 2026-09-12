-----------------------------------
-- apex_catalog.lua
-- Tunables + scaling math for APEX TRIALS -- the infinite, top-tier chase that
-- feeds the Paragon meta (see ApexTrials.lua + Paragon.lua).
--
-- Weapon gates (DEF cliffs), not a smooth relic-to-500 ramp:
--   1-10   Relic
--   11-30  Empyrean / Mythic
--   31-50  Aeonic
--   51+    Prime
-- Level starts at 99 and never exceeds 130. Apex mobs do not regen.
--
-- FileWatcher dofile discards the return. Mutate the cached table so live
-- tweaks apply to the next spawned floor without a map restart.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/apex_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

-- ── Arena / placement ───────────────────────────────────────────────────────
C.ARENA_ZONE = 182          -- xi.zone.WALK_OF_ECHOES
C.GROUP_ZONE = 210          -- GM Home (where the boss mob_groups live)
C.WARP_IN    = { x = -420, y = 14, z = -49, rot = 192 }
C.EXIT_WARP  = { zoneId = 44, x = 571.471, y = -3.360, z = 512.586, rot = 65 }

C.BOSS_GROUPS = { 11366, 11367, 11368, 11369 }
C.BOSS_NAMES  = { 'Apex Devourer', 'Paragon Sentinel', 'Ascendant Tyrant', 'Voidlord Eternal' }

-- ── Scaling knobs ───────────────────────────────────────────────────────────
C.LEVEL_CAP = 130

-- Paragon Points banked the FIRST time you clear a tier: base + (tier-1)*step.
C.PP_BASE     = 10
C.PP_PER_TIER = 5

C.FLOOR_DELAY_MS = 5000

-- Affix pool: no REGEN. Vampiric keeps the ATT bump only.
C.AFFIX_DEFS = {
    { key = 'Fortified', hpMult = 1.15 },
    { key = 'Frenzied',  hpMult = 1.00 },
    { key = 'Empowered', hpMult = 1.00 },
    { key = 'Vampiric',  hpMult = 1.05 },
    { key = 'Furious',   hpMult = 1.08 },
}

C.AFFIX_MILESTONES = { 25, 50, 75, 100, 200 }

-- ── Scaling math ────────────────────────────────────────────────────────────
local function interpolate(from, to, position, span)
    if span <= 0 then
        return math.floor(to + 0.5)
    end
    return math.floor(from + (to - from) * position / span + 0.5)
end

-- { first, last, lv0, lv1, hp0, hp1, att0, att1, def0, def1, acc0, acc1, eva0, eva1 }
local BANDS =
{
    {  1,  10,  99, 102, 1000000, 1600000,  2800,  3500,  1400,  2600, 1800, 2200, 400,  500 },
    { 11,  30, 105, 112, 1800000, 3200000,  4200,  6000,  7500,  8500, 2400, 3200, 550,  700 },
    { 31,  50, 115, 122, 3500000, 5000000,  7000,  9000, 11500, 12500, 3400, 4200, 750,  900 },
    { 51, 100, 125, 130, 5500000, 9000000, 11000, 16000, 16500, 17500, 4500, 6500, 1000, 1400 },
}

local POST_100 =
{
    hp  = { 9000000, 14000000 },
    att = { 16000, 19000 },
    def = { 17500, 18000 },
    acc = { 6500, 8000 },
    eva = { 1400, 1600 },
}

local function bandFor(tier)
    for i = 1, #BANDS do
        local b = BANDS[i]
        if tier >= b[1] and tier <= b[2] then
            return b
        end
    end
    return BANDS[#BANDS]
end

local function inBand(tier, fromIdx, toIdx)
    local b = bandFor(tier)
    local span = b[2] - b[1]
    return interpolate(b[fromIdx], b[toIdx], tier - b[1], span)
end

function C.bossLevel(tier)
    tier = math.max(1, math.floor(tier or 1))
    if tier > 100 then
        return C.LEVEL_CAP
    end
    return inBand(tier, 3, 4)
end

function C.bossHp(tier)
    tier = math.max(1, math.floor(tier or 1))
    if tier <= 100 then
        return inBand(tier, 5, 6)
    end
    if tier <= 200 then
        return interpolate(POST_100.hp[1], POST_100.hp[2], tier - 100, 100)
    end
    local progress = math.log(1 + (tier - 200) / 100) / math.log(5)
    return math.floor(POST_100.hp[2] * (1 + 0.35 * progress))
end

local function scaledMod(tier, key)
    tier = math.max(1, math.floor(tier or 1))
    local idx =
    {
        att = { 7, 8 },
        def = { 9, 10 },
        acc = { 11, 12 },
        eva = { 13, 14 },
    }
    local pair = idx[key]
    if tier <= 100 then
        return inBand(tier, pair[1], pair[2])
    end
    local post = POST_100[key]
    if tier <= 200 then
        return interpolate(post[1], post[2], tier - 100, 100)
    end
    return post[2]
end

function C.bossMods(tier)
    return {
        [xi.mod.ATT] = scaledMod(tier, 'att'),
        [xi.mod.DEF] = scaledMod(tier, 'def'),
        [xi.mod.ACC] = scaledMod(tier, 'acc'),
        [xi.mod.EVA] = scaledMod(tier, 'eva'),
    }
end

function C.ppReward(tier)
    return C.PP_BASE + (tier - 1) * C.PP_PER_TIER
end

function C.affixCount(tier)
    local count = 0
    for _, milestone in ipairs(C.AFFIX_MILESTONES) do
        if tier < milestone then break end
        count = count + 1
    end
    return math.min(#C.AFFIX_DEFS, count)
end

function C.affixMods(key, tier)
    local scale = math.min(3, 1 + math.floor((tier - 1) / 200))
    if key == 'Fortified' then
        return { [xi.mod.DEF] = 800 * scale }
    elseif key == 'Frenzied' then
        return { [xi.mod.HASTE_GEAR] = 150, [xi.mod.DOUBLE_ATTACK] = 5 * scale }
    elseif key == 'Empowered' then
        return { [xi.mod.ATT] = 1000 * scale, [xi.mod.STR] = 100 * scale }
    elseif key == 'Vampiric' then
        return { [xi.mod.ATT] = 500 * scale }
    elseif key == 'Furious' then
        return { [xi.mod.ATT] = 750 * scale, [xi.mod.HASTE_GEAR] = 100 }
    end
    return {}
end

function C.mechCfg(tier)
    -- No scripted %HP pulses (aoe / nuke). Damage is melee, magic, and TP only.
    if tier >= 200 then
        return {
            name   = 'Apex Absolute',
            enrage = { sec = 120, att = 9000, haste = 220, msg = 'transcends its limits -- the assault becomes absolute!' },
            stance = { startHpp = 90, periodSec = 12, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'turns impervious to steel -- magic only!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards every spell aside -- use steel!' },
            } },
            cc     = { periodSec = 18, effect = xi.effect.SILENCE, dur = 8, msg = 'silences the unworthy!' },
            phases = {
                { hp = 60, action = 'dispel',  count = 5, msg = 'rips your enhancements away!' },
                { hp = 30, action = 'fury',    att = 4500, haste = 140, msg = 'enters a killing fury!' },
                { hp = 15, action = 'enrage',  att = 9000, haste = 280, msg = 'screams -- final form unleashed!' },
            },
            doom   = { startHpp = 10, dur = 20, msg = 'marks you for absolute death!' },
        }
    elseif tier >= 100 then
        return {
            name   = 'Apex Imperator',
            enrage = { sec = 150, att = 7000, haste = 180, msg = 'surges with unstoppable force!' },
            stance = { startHpp = 85, periodSec = 14, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hardens against all physical -- switch to magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'negates all magic -- cut it down!' },
            } },
            cc     = { periodSec = 22, effect = xi.effect.TERROR, dur = 6, msg = 'projects overwhelming dread!' },
            phases = {
                { hp = 50, action = 'dispel',  count = 4, msg = 'strips your enhancements!' },
                { hp = 15, action = 'fury',    att = 4000, haste = 120, msg = 'enters a berserker state!' },
            },
            doom   = { startHpp = 12, dur = 25, msg = 'passes judgment -- doom upon you!' },
        }
    elseif tier >= 51 then
        return {
            name   = 'Apex Warlord',
            enrage = { sec = 180, att = 6000, haste = 160, msg = 'reaches full battle-fury!' },
            stance = { startHpp = 80, periodSec = 15, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'locks body against weapons -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards against all magic -- use steel!' },
            } },
            cc     = { periodSec = 24, effect = xi.effect.TERROR, dur = 5, msg = 'unleashes a wave of terror!' },
            phases = {
                { hp = 40, action = 'dispel',  count = 3, msg = 'tears away your enhancements!' },
                { hp = 10, action = 'enrage',  att = 7000, haste = 200, msg = 'screams and goes berserk!' },
            },
        }
    elseif tier >= 31 then
        return {
            name   = 'Apex Conqueror',
            enrage = { sec = 200, att = 5500, haste = 140, msg = 'grows impatient -- attacks accelerate!' },
            stance = { startHpp = 75, periodSec = 16, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'resists all steel -- switch to magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'deflects all magic -- hit with weapons!' },
            } },
            phases = {
                { hp = 15, action = 'fury',    att = 3500, haste = 100, msg = 'fights with renewed fury!' },
            },
        }
    elseif tier >= 11 then
        return {
            name   = 'Apex Champion',
            enrage = { sec = 220, att = 5000, haste = 130, msg = 'hardens its resolve -- intensifying its assault!' },
            stance = { startHpp = 80, periodSec = 18, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'armors itself against physical -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'warps all spells aside -- use weapons!' },
            } },
            phases = {
                { hp = 50, action = 'dispel', count = 3, msg = 'rips your buffs away!' },
                { hp = 20, action = 'fury',   att = 3000, haste = 100, msg = 'enters a fury state!' },
            },
        }
    end

    return {
        name   = 'Apex Challenger',
        enrage = { sec = 240, att = 4000, haste = 120, msg = 'grows restless -- pressing harder!' },
        phases = {
            { hp = 35, action = 'fury', att = 2500, haste = 80, msg = 'surges with sudden power!' },
        },
    }
end

return C
