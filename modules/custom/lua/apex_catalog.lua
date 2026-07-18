-----------------------------------
-- apex_catalog.lua
-- Tunables + scaling math for APEX TRIALS -- the infinite, top-tier chase that
-- feeds the Paragon meta (see ApexTrials.lua + Paragon.lua).
--
-- Apex Trials is a Greater-Rift-style climb: you fight a single scaled Apex
-- boss per TIER, and each NEW tier you clear banks Paragon Points and raises
-- your record (Apex_HighestTier). Tiers scale FOREVER -- level reaches 150,
-- then logarithmic HP/stat growth and mechanics carry the difficulty.
--
-- Plain require()-library (returns a table). Per the custom/lua auto-load
-- rule, NOTHING here may touch xi.* at FILE scope -- all xi.* lookups live
-- inside functions, evaluated at call time. Raw zone ids are fine at scope.
-----------------------------------
local C = {}

-- ── Arena / placement ───────────────────────────────────────────────────────
-- Uses Walk of Echoes [P2] (279) -- same geometry as Walk of Echoes but
-- completely unused, giving Apex Trials its own dedicated zone separate from
-- the Endless Tower (zone 182). GM Home mob groups (zone 210) spawn here.
C.ARENA_ZONE = 279          -- xi.zone.WALK_OF_ECHOES_P2
C.GROUP_ZONE = 210          -- GM Home (where the boss mob_groups live)
C.WARP_IN    = { x = -420, y = 14, z = -49, rot = 192 }
C.EXIT_WARP  = { zoneId = 44, x = 571.471, y = -3.360, z = 512.586, rot = 65 }

-- Boss visual pool (we reuse the Tower's top-band groups and scale stats on
-- top -- the group only supplies the model + mobskills).
C.BOSS_GROUPS = { 11366, 11367, 11368, 11369 }
C.BOSS_NAMES  = { 'Apex Devourer', 'Paragon Sentinel', 'Ascendant Tyrant', 'Voidlord Eternal' }

-- ── Scaling knobs (the whole difficulty curve) ──────────────────────────────
-- Three bands keep the climb aligned to actual player progression:
--   1-50   Relic + T5 augments
--   51-100 prepared Prime / final REMA
--   101+   diminishing, leaderboard-oriented growth
--
-- Level never exceeds 150. Walk of Echoes [P2] uses level correction, and the
-- old 165->230 curve made accuracy/cRatio rather than builds decide the fight.
C.LEVEL_T1   = 135
C.LEVEL_T50  = 145
C.LEVEL_T100 = 150
C.LEVEL_CAP  = 150

C.HP_T1_GROWTH   = 1.0335
C.HP_T51_GROWTH  = 1.02
C.BASE_HP        = 1500000
C.POST_100_HP_GAIN = 2.315 -- normalized log tail: about 67.3M HP at tier 500

-- Direct modifier anchors. Values above tier 100 use the same normalized
-- logarithmic tail as HP and are hard-capped below int16 storage limits.
C.MOD_T1   = { att =  4500, def =  1500, acc =  2200, eva =  800 }
C.MOD_T50  = { att = 10000, def =  5000, acc =  5400, eva = 2500 }
C.MOD_T100 = { att = 18000, def =  8000, acc =  9000, eva = 4000 }
C.MOD_T500 = { att = 24000, def = 11200, acc = 12200, eva = 5600 }
C.MOD_CAPS = { att = 25000, def = 14000, acc = 14000, eva = 8000 }

-- Paragon Points banked the FIRST time you clear a tier: base + (tier-1)*step.
C.PP_BASE     = 10
C.PP_PER_TIER = 5

C.FLOOR_DELAY_MS = 5000     -- breather between tiers in a run

-- Affix pool: at higher tiers the boss stacks more of these (see affixCount).
-- Each is a flat mod set + an optional HP multiplier. xi.mod.* resolved at call
-- time inside affixMods() so this stays file-scope clean.
C.AFFIX_DEFS = {
    { key = 'Fortified',    hpMult = 1.15 },
    { key = 'Frenzied',     hpMult = 1.00 },
    { key = 'Regenerating', hpMult = 1.00 },
    { key = 'Empowered',    hpMult = 1.00 },
    { key = 'Vampiric',     hpMult = 1.05 },
    { key = 'Furious',      hpMult = 1.08 },
}

-- ── Scaling math (call-time; safe to touch xi.* here) ────────────────────────
local function interpolate(from, to, position, span)
    return math.floor(from + (to - from) * position / span + 0.5)
end

local function post100Progress(tier)
    if tier <= 100 then return 0 end
    return math.log(1 + (tier - 100) / 100) / math.log(5)
end

function C.bossLevel(tier)
    if tier <= 50 then
        return interpolate(C.LEVEL_T1, C.LEVEL_T50, tier - 1, 49)
    elseif tier <= 100 then
        return interpolate(C.LEVEL_T50, C.LEVEL_T100, tier - 50, 50)
    end

    return C.LEVEL_CAP
end

function C.bossHp(tier)
    local hp50 = C.BASE_HP * (C.HP_T1_GROWTH ^ 49)
    if tier <= 50 then
        return math.floor(C.BASE_HP * (C.HP_T1_GROWTH ^ (tier - 1)))
    end

    local hp100 = hp50 * (C.HP_T51_GROWTH ^ 50)
    if tier <= 100 then
        return math.floor(hp50 * (C.HP_T51_GROWTH ^ (tier - 50)))
    end

    return math.floor(hp100 * (1 + C.POST_100_HP_GAIN * post100Progress(tier)))
end

local function scaledMod(tier, key)
    if tier <= 50 then
        return interpolate(C.MOD_T1[key], C.MOD_T50[key], tier - 1, 49)
    elseif tier <= 100 then
        return interpolate(C.MOD_T50[key], C.MOD_T100[key], tier - 50, 50)
    end

    local value = C.MOD_T100[key] +
        (C.MOD_T500[key] - C.MOD_T100[key]) * post100Progress(tier)
    return math.min(C.MOD_CAPS[key], math.floor(value + 0.5))
end

-- Flat stat mods for a tier. Direct values remain int16-safe forever; HP,
-- affixes, mechanics, and execution carry the climb after the soft stat caps.
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

C.AFFIX_MILESTONES = { 25, 50, 75, 100, 200, 300 }

-- Affixes arrive at progression milestones rather than filling the entire pool
-- by tier 30. This keeps the Relic band readable and preserves new pressure for
-- the elite climb.
function C.affixCount(tier)
    local count = 0
    for _, milestone in ipairs(C.AFFIX_MILESTONES) do
        if tier < milestone then break end
        count = count + 1
    end
    return math.min(#C.AFFIX_DEFS, count)
end

-- Resolve an affix key into its concrete mod set (xi.mod.* at call time).
function C.affixMods(key, tier)
    local scale = math.min(3, 1 + math.floor((tier - 1) / 200))
    if key == 'Fortified' then
        return { [xi.mod.DEF] = 800 * scale }
    elseif key == 'Frenzied' then
        return { [xi.mod.HASTE_GEAR] = 150, [xi.mod.DOUBLE_ATTACK] = 5 * scale }
    elseif key == 'Regenerating' then
        return { [xi.mod.REGEN] = 75 * scale }
    elseif key == 'Empowered' then
        return { [xi.mod.ATT] = 1000 * scale, [xi.mod.STR] = 100 * scale }
    elseif key == 'Vampiric' then
        return { [xi.mod.REGEN] = 100 * scale, [xi.mod.ATT] = 500 * scale }
    elseif key == 'Furious' then
        return { [xi.mod.ATT] = 750 * scale, [xi.mod.HASTE_GEAR] = 100 }
    end
    return {}
end

-- ── Hardcore mechanics configs (mob_mechanics_library.lua) ──────────────────
-- Configs are BANDED by tier so the fight evolves as players climb.
-- Added 2026-06-22. Rules:
--   DMGPHYS/DMGMAGIC cap at -5000 (= -50% dmg taken -- heavy resist, not immunity).
--   ATT/REGEN are always routed through the library's safeAddMod; never write them here.
--   addGroupId reuses C.BOSS_GROUPS[1] (11366, zone 210/GM Home) so adds are always valid.
--   Relic tiers introduce mechanics gradually. Prime tiers require the full
--   gear-set dance, while the complete Absolute kit is reserved for the elite
--   climb beyond tier 200.
local ADDS_GROUP = C.BOSS_GROUPS[1]  -- 11366, zone 210 (same zone the bosses come from)
local ADDS_ZONE  = C.GROUP_ZONE      -- 210

-- Returns the mechCfg for a given Apex tier.
function C.mechCfg(tier)
    if tier >= 200 then
        -- ── TIER 200+ "Apex Absolute" ─ full kit, tightest clock, punishing ─────
        return {
            name   = 'Apex Absolute',
            enrage = { sec = 120, att = 9000, haste = 220, msg = 'transcends its limits -- the assault becomes absolute!' },
            stance = { startHpp = 90, periodSec = 12, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'turns impervious to steel -- magic only!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards every spell aside -- use steel!' },
            } },
            aoe    = { periodSec = 10, dmgPct = 30, msg = 'detonates the arena -- shockwave outward!' },
            cc     = { periodSec = 18, effect = xi.effect.SILENCE, dur = 8, msg = 'silences the unworthy!' },
            drain  = { periodSec = 7, healPct = 3 },
            phases = {
                { hp = 60, action = 'dispel',  count = 5, msg = 'rips your enhancements away!' },
                { hp = 45, action = 'nuke',    dmgPct = 40, msg = 'collapses reality in a blast!' },
                { hp = 30, action = 'fury',    att = 4500, haste = 140, msg = 'enters a killing fury!' },
                { hp = 15, action = 'enrage',  att = 9000, haste = 280, msg = 'screams -- final form unleashed!' },
            },
            doom   = { startHpp = 10, dur = 20, msg = 'marks you for absolute death!' },
        }
    elseif tier >= 100 then
        -- ── TIER 100–199 "Apex Imperator" ─ doom added, tight enrage ───────────
        return {
            name   = 'Apex Imperator',
            enrage = { sec = 150, att = 7000, haste = 180, msg = 'surges with unstoppable force!' },
            stance = { startHpp = 85, periodSec = 14, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hardens against all physical -- switch to magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'negates all magic -- cut it down!' },
            } },
            aoe    = { periodSec = 12, dmgPct = 26, msg = 'erupts with void energy!' },
            cc     = { periodSec = 22, effect = xi.effect.TERROR, dur = 6, msg = 'projects overwhelming dread!' },
            drain  = { periodSec = 8, healPct = 2 },
            phases = {
                { hp = 50, action = 'dispel',  count = 4, msg = 'strips your enhancements!' },
                { hp = 30, action = 'nuke',    dmgPct = 35, msg = 'unleashes a void cataclysm!' },
                { hp = 15, action = 'fury',    att = 4000, haste = 120, msg = 'enters a berserker state!' },
            },
            doom   = { startHpp = 12, dur = 25, msg = 'passes judgment -- doom upon you!' },
        }
    elseif tier >= 75 then
        -- ── TIER 75–99 "Apex Warlord" ─ CC + dispel added ──────────────────────
        return {
            name   = 'Apex Warlord',
            enrage = { sec = 180, att = 6000, haste = 160, msg = 'reaches full battle-fury!' },
            stance = { startHpp = 80, periodSec = 15, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'locks body against weapons -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards against all magic -- use steel!' },
            } },
            aoe    = { periodSec = 12, dmgPct = 24, msg = 'pulses with destructive energy!' },
            cc     = { periodSec = 24, effect = xi.effect.TERROR, dur = 5, msg = 'unleashes a wave of terror!' },
            drain  = { periodSec = 9, healPct = 2 },
            phases = {
                { hp = 40, action = 'dispel',  count = 3, msg = 'tears away your enhancements!' },
                { hp = 20, action = 'nuke',    dmgPct = 30, msg = 'fires a void blast!' },
                { hp = 10, action = 'enrage',  att = 7000, haste = 200, msg = 'screams and goes berserk!' },
            },
        }
    elseif tier >= 50 then
        -- ── TIER 50–74 "Apex Conqueror" ─ drain added ──────────────────────────
        return {
            name   = 'Apex Conqueror',
            enrage = { sec = 200, att = 5500, haste = 140, msg = 'grows impatient -- attacks accelerate!' },
            stance = { startHpp = 75, periodSec = 16, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'resists all steel -- switch to magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'deflects all magic -- hit with weapons!' },
            } },
            aoe    = { periodSec = 13, dmgPct = 22, msg = 'shakes the arena with a shockwave!' },
            drain  = { periodSec = 10, healPct = 2 },
            phases = {
                { hp = 15, action = 'fury',    att = 3500, haste = 100, msg = 'fights with renewed fury!' },
            },
        }
    elseif tier >= 25 then
        -- ── TIER 25–49 "Apex Champion" ─ stance dance added ────────────────────
        return {
            name   = 'Apex Champion',
            enrage = { sec = 220, att = 5000, haste = 130, msg = 'hardens its resolve -- intensifying its assault!' },
            stance = { startHpp = 80, periodSec = 18, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'armors itself against physical -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'warps all spells aside -- use weapons!' },
            } },
            aoe    = { periodSec = 14, dmgPct = 20, msg = 'fires a shockwave in all directions!' },
            phases = {
                { hp = 50, action = 'dispel', count = 3, msg = 'rips your buffs away!' },
                { hp = 20, action = 'fury',   att = 3000, haste = 100, msg = 'enters a fury state!' },
            },
        }
    else
        -- ── TIER 1–24 "Apex Challenger" ─ entry-level: enrage + AoE ────────────
        return {
            name   = 'Apex Challenger',
            enrage = { sec = 240, att = 4000, haste = 120, msg = 'grows restless -- pressing harder!' },
            aoe    = { periodSec = 16, dmgPct = 18, msg = 'releases a burst of void energy!' },
            phases = {
                { hp = 35, action = 'fury', att = 2500, haste = 80, msg = 'surges with sudden power!' },
            },
        }
    end
end

return C
