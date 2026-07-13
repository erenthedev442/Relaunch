-----------------------------------
-- augment_sage_catalog.lua
-- Configuration for the Augment Sage NPC. Defines the 5-rank promotion
-- chain (Track 1 of the augment side-quest) and the multiplier curve the
-- Augment Moogle applies at trade time.
--
-- Charvars used:
--   Augment_Mastery   : 0..5    -- highest rank cleared
--   Augment_Count     : 0..N    -- lifetime successful augments (incremented
--                                   by Augment_Moogle on each completed trade)
--
-- See also:
--   augment_affinity_catalog.lua  : per-NM category bonuses (Track 2)
--   Augment_Moogle.lua            : applies the multipliers + crit chance
--   Augment_Sage.lua              : the NPC that consumes this catalog
--
-- ALL trophy IDs verified against sql/item_basic.sql. If you swap a trophy
-- to a different NM drop, also update the docgen so the docs reflect it.
-----------------------------------
local catalog = {}

-----------------------------------
-- ZONE / NPC PLACEMENT
--   Single source of truth for Augment_Sage placement + docgen.
--   Lives in the same zone as the Augment Moogle (GM_Home) so players
--   don't have to zone-hop between trade and rank-up.
-----------------------------------
catalog.zoneId    = xi.zone.ABDHALJS_ISLE_PURGONORGO
catalog.zonePath  = 'xi.zones.Abdhaljs_Isle-Purgonorgo'
-- GM Home Gear Progression cluster; face north toward the forge row.
catalog.vendorPos = { x = 565.000, y = -3.360, z = 534.400, rot = 64 }

-----------------------------------
-- SEAL CURRENCY (shared with Armor / Weapons / Hunting League NPCs)
-----------------------------------
catalog.seals =
{
    bronze = { id = 9539, name = 'Beastmens Medal' },
    silver = { id = 9541, name = 'Kindreds Medal'  },
    gold   = { id = 9543, name = 'Demons Medal'    },
}

-----------------------------------
-- RANK CHAIN
--   5 ranks of mastery. Each row promotes Augment_Mastery from (rank-1) to
--   rank when the player meets all three requirements:
--     * augCount  : lifetime augments (>=)
--     * seal      : seal tier + qty (consumed on promotion)
--     * trophy    : NM-drop trophy + qty (consumed on promotion)
--
-- masteryMult[rank+1] is the flat multiplier the Augment Moogle applies on
-- every augment value at that rank. critChance[rank+1] is the per-trade
-- probability of a 2x crit augment.
-----------------------------------
-- =========================================================
-- RELAUNCH: Rank gates replaced with content milestones.
--   hlRank         : requires HL_Tier >= this value
--   prestigeLevel  : requires Prestige_Level_<mainJob> >= this value
-- No seals, trophies, or augment counts required.
-- =========================================================
catalog.ranks =
{
    {
        rank   = 1,
        title  = 'Augment Initiate',
        hlRank = 2,    -- HL Rank 2
    },
    {
        rank   = 2,
        title  = 'Augment Adept',
        hlRank = 3,    -- HL Rank 3
    },
    {
        rank          = 3,
        title         = 'Augment Magus',
        hlRank        = 5,   -- HL Rank 5 (Legend)
        prestigeLevel = 5,   -- Prestige Level 5 on any job
        rebirths      = 1,   -- 1 total rebirth across all jobs
    },
    {
        rank          = 4,
        title         = 'Augment Sage',
        prestigeLevel = 15,  -- Prestige Level 15 on any job
        rebirths      = 10,  -- 10 total rebirths across all jobs
    },
    {
        rank           = 5,
        title          = 'Augment Archon',
        prestigeLevel  = 30,  -- Prestige Level 30 on any job
        rebirths       = 20,  -- 20 total rebirths across all jobs
        gauntletClears = 1,   -- at least 1 Gauntlet clear
    },
}

-----------------------------------
-- RANK EFFECT TABLES (indexed by rank, 0..5)
--
-- 2026-06-30 TIER REVAMP (Augment_Moogle.lua): trades now ROLL within the
-- player's content-gated Augment Tier band. Mastery rank's effects:
--   * roll floor = tierSlice.min + rank   (rank 0-5 lifts the worst rolls)
--   * critPct    = catalog.critChance[Augment_Mastery + 1]
--       crit = a PERFECT roll (tier band max), once per trade
--   * affinity (augment_affinity_catalog) = roll twice, keep the better
-- catalog.masteryMult is RETIRED from the Moogle math (kept only so old
-- readers don't nil-error; do not tune it expecting an effect).
--
-- Index 1 = rank 0 (default, no quest done). Tables are 1-based to match
-- Lua's typical indexing - add 1 to the charvar when looking up.
-----------------------------------
catalog.masteryMult = { 1.00, 1.20, 1.40, 1.60, 1.80, 2.00 }
catalog.critChance  = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 }

-----------------------------------
-- DERIVED HELPER
-----------------------------------
function catalog.titleFor(rank)
    if rank == 0 then return 'Unranked' end
    return catalog.ranks[rank] and catalog.ranks[rank].title or 'Unknown'
end

return catalog
