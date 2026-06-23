-----------------------------------
-- paragon_catalog.lua
-- Tunables for the PARAGON board -- the meta-progression that Apex Trials feeds
-- (see Paragon.lua). Paragon Points (banked by Apex Trials) buy:
--   * Paragon Levels -- an infinite prestige track (number + title flair).
--   * Perks -- small, HARD-CAPPED permanent stat boosts (login-applied).
--   * a Daily Might buff -- unlock once, claim once per UTC day.
--
-- Plain require()-library. Per the auto-load rule, NO xi.* at FILE scope --
-- every xi.* lookup lives inside a function, evaluated at call time.
-----------------------------------
local C = {}

C.NPC_POS = { x = 15.000, y = 0.000, z = -35.000, rot = 128 }  -- GM Home, right end of the z=-35 endgame row

-- ── Paragon Level (infinite prestige) ───────────────────────────────────────
-- Cost in Paragon Points to go from level `cur` to `cur + 1`. Ramps.
C.LEVEL_COST_BASE = 25
C.LEVEL_COST_STEP = 5
function C.levelCost(cur) return C.LEVEL_COST_BASE + cur * C.LEVEL_COST_STEP end

-- ── Perks (permanent, capped, login-applied addMods) ────────────────────────
-- perRank * maxRank = the hard cap (owner-set: ATT/ACC +1000, DEF +2000,
-- HP +5000). modKeys are xi.mod field NAMES, resolved at call time in modIds().
C.PERKS = {
    { id = 'vigor',     label = 'Vigor',     modKeys = { 'HP' },           perRank = 500, maxRank = 10, costBase = 20, costStep =  8 },
    { id = 'might',     label = 'Might',     modKeys = { 'ATT', 'RATT' },  perRank = 100, maxRank = 10, costBase = 30, costStep = 12 },
    { id = 'precision', label = 'Precision', modKeys = { 'ACC', 'RACC' },  perRank = 100, maxRank = 10, costBase = 30, costStep = 12 },
    { id = 'warding',   label = 'Warding',   modKeys = { 'DEF' },          perRank = 200, maxRank = 10, costBase = 20, costStep =  8 },
}

function C.perkById(id)
    for _, p in ipairs(C.PERKS) do if p.id == id then return p end end
    return nil
end

function C.perkRankCost(perk, curRank) return perk.costBase + curRank * perk.costStep end

function C.modIds(perk)
    local ids = {}
    for _, k in ipairs(perk.modKeys) do ids[#ids + 1] = xi.mod[k] end
    return ids
end

-- ── Daily Might buff (unlock once, claim once/UTC-day) ───────────────────────
-- A 2-hour throughput/sustain surge built from proven status effects (the Henge
-- auto-buff pattern). Distinct from the permanent perks -- no overlap.
C.DAILY_MIGHT_UNLOCK   = 80
C.DAILY_MIGHT_DURATION = 7200   -- seconds (2h)
C.DAILY_MIGHT_HP       = 3000   -- MAX_HP_BOOST (flat)
C.DAILY_MIGHT_REGAIN   = 50     -- REGAIN (TP/tick)
C.DAILY_MIGHT_REFRESH_PCT = 0.10  -- REFRESH = this * maxMP / tick
C.DAILY_MIGHT_REGEN_PCT   = 0.05  -- REGEN   = this * maxHP / tick

-- ── Title flair by Paragon Level (displayed text, NOT a client title) ────────
C.TITLE_TIERS = {
    { lvl = 100, name = 'Voidlord'  },
    { lvl =  50, name = 'Eternal'   },
    { lvl =  25, name = 'Ascendant' },
    { lvl =   1, name = 'Paragon'   },
}
function C.titleFor(lvl)
    for _, t in ipairs(C.TITLE_TIERS) do
        if lvl >= t.lvl then return t.name end
    end
    return 'Aspirant'
end

return C
