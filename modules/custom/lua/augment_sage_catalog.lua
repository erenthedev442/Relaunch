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
catalog.zoneId    = xi.zone.GM_HOME
catalog.zonePath  = 'xi.zones.GM_Home'
-- GM Home Gear Progression cluster (z=-25): Augment Moogle / Augment Sage / CrossJob Trainers / Cosmetic Shop.
catalog.vendorPos = { x = -1.500, y = 0.000, z = -25.000, rot = 128 }

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
catalog.ranks =
{
    {
        rank      = 1,
        title     = 'Augment Initiate',
        augCount  = 10,
        seal      = { tier = 'bronze', qty = 5  },
        trophy    = { id  = 883,  qty = 1, name = 'Behemoth Horn'           },
        nm        = 'Behemoth',
    },
    {
        rank      = 2,
        title     = 'Augment Adept',
        augCount  = 20,
        seal      = { tier = 'silver', qty = 10 },
        trophy    = { id  = 865,  qty = 1, name = "Handful of Nidhogg's Scales" },
        nm        = 'Nidhogg',
    },
    {
        rank      = 3,
        title     = 'Augment Magus',
        augCount  = 50,
        seal      = { tier = 'silver', qty = 25 },
        trophy    = { id  = 2371, qty = 1, name = 'Khimaira Horn'           },
        nm        = 'Khimaira (Tiamat-tier dragon)',
    },
    {
        rank      = 4,
        title     = 'Augment Sage',
        augCount  = 120,
        seal      = { tier = 'gold',   qty = 50 },
        trophy    = { id  = 10037, qty = 1, name = "Fafnir's Scale"         },
        nm        = 'Fafnir',
    },
    {
        rank      = 5,
        title     = 'Augment Archon',
        augCount  = 250,
        seal      = { tier = 'gold',   qty = 100 },
        trophy    = { id  = 10038, qty = 1, name = "Kirin's Mane"           },
        nm        = 'Kirin (sky-god proxy for Absolute Virtue)',
    },
}

-----------------------------------
-- MULTIPLIER + CRIT TABLES (indexed by rank, 0..5)
--
--   Augment_Moogle math:
--     mastery   = catalog.masteryMult[Augment_Mastery + 1]
--     critPct   = catalog.critChance[Augment_Mastery + 1]
--     finalMult = mastery * affinityMult * (crit ? 2.0 : 1.0)
--
-- Index 1 = rank 0 (default, no quest done). Tables are 1-based to match
-- Lua's typical indexing - add 1 to the charvar when looking up.
-----------------------------------
catalog.masteryMult = { 1.00, 1.20, 1.40, 1.60, 1.80, 2.00 }
catalog.critChance  = { 0.05, 0.08, 0.11, 0.14, 0.17, 0.20 }

-----------------------------------
-- DERIVED HELPER
-----------------------------------
function catalog.titleFor(rank)
    if rank == 0 then return 'Unranked' end
    return catalog.ranks[rank] and catalog.ranks[rank].title or 'Unknown'
end

return catalog
