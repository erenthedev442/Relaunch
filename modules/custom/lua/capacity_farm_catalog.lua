-----------------------------------
-- capacity_farm_catalog.lua
-- Config for the shared Capacity Point farm camp in Bibiki Bay.
-- Edit this file only; CapacityFarm.lua reads it.
--
-- DESIGN: a small always-up pool of Lv150-160 mobs that instantly respawn
-- as they're killed, so there's always a target and the capacity chain stays
-- hot. Shared/NonExclusive claim (everyone present can tag + the killer's
-- alliance gets the CP), no loot/gil (CP only). These mobs DELIBERATELY do
-- NOT set NO_CAPACITY_POINTS -- that flag is what every other custom system
-- uses to BLOCK CP; here we want CP, so we never set it.
--
-- Pairs with a CAPACITY_RATE bump in settings/map.lua (box-only) for pace.
-----------------------------------
local catalog = {}

catalog.zoneId   = xi.zone.BIBIKI_BAY          -- 4
catalog.zonePath = 'xi.zones.Bibiki_Bay'

-- Where !capacity drops the player. Verified walkable: the centre of a
-- native mob cluster on solid ground (sourced from mob_spawn_points, zone 4),
-- NOT the Sunset Docks pier (which is surrounded by water).
catalog.warpPos    = { x = 93.0, y = -45.5, z = 928.0, rot = 128 }

-- Camp centre + per-axis spread the mobs spawn within. Kept inside the
-- verified native-spawn patch (x ~89-97, z ~919-937) so nothing lands in
-- the bay. Tweak after an in-game look if any mob clips terrain/water.
catalog.campCenter = { x = 93.0, y = -45.5, z = 928.0 }
catalog.spreadX    = 5
catalog.spreadZ    = 8

-- HL NM mob_groups (registered in zone 210 / GM_Home) reused as spawn
-- templates -- the same cross-zone trick the dungeon system uses. These
-- supply only the model/base; level + HP are overridden at spawn. A small
-- variety pool so the camp isn't eight identical models.
catalog.groupZoneId = 210
catalog.templates =
{
    11355, -- Leaping Lizzy
    11357, -- Tom Tit Tat
    11358, -- Roc
    11360, -- Aquarius
    11361, -- Serket
}

catalog.mobName  = 'Capacity Phantom'  -- display name; also used to count/top-up the pool
catalog.mobCount = 24                   -- target population (kept topped up; tripled 8->24)
catalog.minLv    = 150                  -- engine rolls each spawn in [minLv, maxLv]
catalog.maxLv    = 160
catalog.maxHP    = 45000                -- low HP = quick kills (-25% from 60000)
catalog.cpBonus  = 2000                 -- flat bonus Capacity Points to the killer per kill, ON TOP of
                                        -- the engine's level-based award (both x map EXP_RATE). 0 = off.

return catalog
