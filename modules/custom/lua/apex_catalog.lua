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
-- Reuse the Endless Tower arena (Walk of Echoes, 182) + the GM Home mob groups
-- (registered under zone 210). Each climber gets their own dynamic boss; the
-- Apex onZoneIn only fires for players holding an Apex session, so it never
-- collides with a Tower run sharing the zone.
C.ARENA_ZONE = 182          -- xi.zone.WALK_OF_ECHOES
C.GROUP_ZONE = 210          -- GM Home (where the boss mob_groups live)
C.WARP_IN    = { x = -420, y = 14, z = -49, rot = 192 }
C.EXIT_WARP  = { zoneId = 210, x = -15, y = 0, z = -18, rot = 128 }

-- Boss visual pool (we reuse the Tower's top-band groups and scale stats on
-- top -- the group only supplies the model + mobskills).
C.BOSS_GROUPS = { 11366, 11367, 11368, 11369 }
C.BOSS_NAMES  = { 'Apex Devourer', 'Paragon Sentinel', 'Ascendant Tyrant', 'Voidlord Eternal' }

-- ── Scaling knobs (the whole difficulty curve) ──────────────────────────────
C.BASE_LEVEL = 165          -- tier 1 boss level (a step above your 150-160 NMs)
C.LEVEL_STEP = 4            -- +level per tier...
C.LEVEL_CAP  = 230          -- ...capped uint8-safe (the Tower's 275 actually WRAPPED)
C.BASE_HP    = 9000000      -- tier 1 HP
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

return C
