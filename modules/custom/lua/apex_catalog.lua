-----------------------------------
-- apex_catalog.lua
-- Tunables + scaling math for APEX TRIALS -- the infinite, top-tier chase that
-- feeds the Paragon meta (see ApexTrials.lua + Paragon.lua).
--
-- Apex Trials is a Greater-Rift-style climb: you fight a single scaled Apex
-- boss per TIER, and each NEW tier you clear banks Paragon Points and raises
-- your record (Apex_HighestTier). Tiers scale FOREVER -- level ramps to a
-- uint8-safe cap, then HP and stat mods carry the difficulty infinitely.
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
C.BASE_LEVEL = 165          -- tier 1 boss level (a step above your 150-160 NMs)
C.LEVEL_STEP = 4            -- +level per tier...
C.LEVEL_CAP  = 230          -- ...capped uint8-safe (the Tower's 275 actually WRAPPED)
C.BASE_HP    = 1100000      -- tier 1 HP
C.HP_GROWTH  = 1.13         -- HP multiplies by this each tier -> infinite wall
C.ATT_PER_TIER = 450        -- flat stat mods that climb forever (the real cap-breaker)
C.DEF_PER_TIER = 380
C.ACC_PER_TIER = 70
C.EVA_PER_TIER = 50

-- Paragon Points banked the FIRST time you clear a tier: base + (tier-1)*step.
C.PP_BASE     = 10
C.PP_PER_TIER = 5

C.FLOOR_DELAY_MS = 5000     -- breather between tiers in a run

-- Affix pool: at higher tiers the boss stacks more of these (see affixCount).
-- Each is a flat mod set + an optional HP multiplier. xi.mod.* resolved at call
-- time inside affixMods() so this stays file-scope clean.
C.AFFIX_DEFS = {
    { key = 'Fortified',    hpMult = 1.30 },
    { key = 'Frenzied',     hpMult = 1.00 },
    { key = 'Regenerating', hpMult = 1.00 },
    { key = 'Empowered',    hpMult = 1.00 },
    { key = 'Vampiric',     hpMult = 1.10 },
    { key = 'Furious',      hpMult = 1.15 },
}

-- ── Scaling math (call-time; safe to touch xi.* here) ────────────────────────
function C.bossLevel(tier)
    return math.min(C.LEVEL_CAP, C.BASE_LEVEL + (tier - 1) * C.LEVEL_STEP)
end

function C.bossHp(tier)
    return math.floor(C.BASE_HP * (C.HP_GROWTH ^ (tier - 1)))
end

-- Flat stat mods for a tier (climb forever -> the infinite difficulty).
function C.bossMods(tier)
    local t = tier - 1
    return {
        [xi.mod.ATT] = t * C.ATT_PER_TIER,
        [xi.mod.DEF] = t * C.DEF_PER_TIER,
        [xi.mod.ACC] = t * C.ACC_PER_TIER,
        [xi.mod.EVA] = t * C.EVA_PER_TIER,
    }
end

function C.ppReward(tier)
    return C.PP_BASE + (tier - 1) * C.PP_PER_TIER
end

-- Number of stacked affixes at a tier: +1 every 5 tiers, capped at the pool size.
function C.affixCount(tier)
    return math.min(#C.AFFIX_DEFS, math.floor(tier / 5))
end

-- Resolve an affix key into its concrete mod set (xi.mod.* at call time).
function C.affixMods(key, tier)
    local scale = 1 + math.floor(tier / 10)  -- affixes also intensify with depth
    if key == 'Fortified' then
        return { [xi.mod.DEF] = 800 * scale }
    elseif key == 'Frenzied' then
        return { [xi.mod.HASTE_GEAR] = 150, [xi.mod.DOUBLE_ATTACK] = 10 * scale }
    elseif key == 'Regenerating' then
        return { [xi.mod.REGEN] = 200 * scale }
    elseif key == 'Empowered' then
        return { [xi.mod.ATT] = 3000 * scale, [xi.mod.STR] = 100 * scale }
    elseif key == 'Vampiric' then
        return { [xi.mod.REGEN] = 300 * scale, [xi.mod.ATT] = 1500 * scale }  -- sustains + hits
    elseif key == 'Furious' then
        return { [xi.mod.ATT] = 2000 * scale, [xi.mod.HASTE_GEAR] = 100 }
    end
    return {}
end

-- ── Hardcore mechanics configs (mob_mechanics_library.lua) ──────────────────
-- Configs are BANDED by tier so the fight evolves as players climb.
-- Added 2026-06-22. Rules:
--   DMGPHYS/DMGMAGIC cap at -5000 (= -50% dmg taken -- heavy resist, not immunity).
--   ATT/REGEN are always routed through the library's safeAddMod; never write them here.
--   addGroupId reuses C.BOSS_GROUPS[1] (11366, zone 210/GM Home) so adds are always valid.
--   Low tiers: enrage + aoe.  Mid: +stance.  High: +cc + dispel.  Max: full kit.
local ADDS_GROUP = C.BOSS_GROUPS[1]  -- 11366, zone 210 (same zone the bosses come from)
local ADDS_ZONE  = C.GROUP_ZONE      -- 210

-- Returns the mechCfg for a given Apex tier.
function C.mechCfg(tier)
    if tier >= 30 then
        -- ── TIER 30+ "Apex Absolute" ─ full kit, tightest clock, punishing ──────
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
    elseif tier >= 20 then
        -- ── TIER 20–29 "Apex Imperator" ─ doom added, tight enrage ──────────────
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
    elseif tier >= 15 then
        -- ── TIER 15–19 "Apex Warlord" ─ CC + dispel added ───────────────────────
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
    elseif tier >= 10 then
        -- ── TIER 10–14 "Apex Conqueror" ─ drain added ────────────────────
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
    elseif tier >= 5 then
        -- ── TIER 5–9 "Apex Champion" ─ stance dance added ───────────────────────
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
        -- ── TIER 1–4 "Apex Challenger" ─ entry-level: enrage + AoE ─────────────
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
