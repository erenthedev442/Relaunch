-----------------------------------
-- test_dummy_catalog.lua
-- Data for the Test Dummy NPC (modules/custom/lua/TestDummy.lua).
--
-- The Test Dummy is a training-target NPC at GM Home. Players talk
-- to it, pick a tier, and a stationary dummy mob spawns next to the
-- NPC. The dummy:
--   - has a huge HP pool (won't die during normal testing)
--   - won't aggro (doesn't come at the player on detection)
--   - won't move from the spawn point (NO_MOVE = 1)
--   - won't drop loot / award capacity points
--   - WILL still engage and hit back if the player attacks it, but
--     because the underlying pool (Leaping Lizzy, mob_groups 11355)
--     is set for a low-tier mob even at high levels, its outgoing
--     damage is tickle-tier on geared L99 players. Hitback is useful
--     for testing PDT / MDT mitigation - it's not a threat.
--
-- Mob source: reuses Hunting League mob_groups 11355 (Leaping_Lizzy)
-- registered in modules/custom/sql/hunting_league_gm_home_mobs.sql.
-- No new SQL is needed.
-----------------------------------

local catalog = {}

-- GM Home Admin cluster (z=-28): Game Master / Companion Master /
-- Test Dummy.
catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        =  3.000,
    y        =  0.000,
    z        = -30.000,
    rotation =  128,
}

-- Where the dummy mob appears when summoned. Pulled WELL away from the
-- new tight 4-row NPC layout so combat at the dummy doesn't visually
-- crowd the lobby. Placed off to the east in open empty space.
catalog.spawnPos =
{
    x = 20.000,
    y = 0.000,
    z = -20.000,
    rotation = 192,
}

-- Tier presets. Each tier sets:
--   minLevel/maxLevel - REQUIRED. Drives defense/evasion stat scaling
--                       so a higher-tier dummy harder to hit / less
--                       penetrated by physical hits. Without these
--                       the engine defaults to level 255 and the mob
--                       loads as "unhittable garbage" (same caveat
--                       documented in GameMaster.lua).
--   hp               - explicit HP override (raw value, set after
--                       spawn() via setMaxHP + setHP).
--   groupId          - mob_groups row to inherit the stat pool from.
--                       Using 11355 (Leaping_Lizzy) for all tiers so
--                       the visual model + base damage stay tickle-
--                       tier across levels.
catalog.tiers =
{
    Standard =
    {
        minLevel = 99,
        maxLevel = 99,
        hp       = 10000000,            -- 10M HP
        groupId  = 11355,
    },

    Endgame =
    {
        minLevel = 150,
        maxLevel = 150,
        hp       = 50000000,            -- 50M HP
        groupId  = 11355,
    },

    Insane =
    {
        minLevel = 200,
        maxLevel = 200,
        hp       = 100000000,           -- 100M HP
        groupId  = 11355,
    },
}

-- Stable menu order.
catalog.tierOrder = { 'Standard', 'Endgame', 'Insane' }

return catalog
