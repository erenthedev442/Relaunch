-----------------------------------
-- capacity_farm_catalog.lua
-- Config for the shared Capacity Point farm camp in Bibiki Bay.
-- Edit this file only; CapacityFarm.lua reads it.
--
-- DESIGN: a small always-up pool of Lv150-160 mobs that automatically respawn
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

-- BEACH-CAMP spawn pool: 19 native land spawn points around the !capacity warp
-- (filtered from mob_spawn_points; see capacity_farm_points.lua). spawnOne picks
-- a random one, so the camp spreads across the reachable beach near the warp.
-- FIXED 2026-07-12 (Lant report): the previous pull was the WHOLE zone (357
-- pts) and Bibiki Bay is mostly ocean -- ~158 of those were shoreline/water
-- spawns at y ~= 0, so phantoms spawned floating over the bay, off the walkable
-- map. The pool is now restricted to camp-elevation land (y<=-38) within 300u
-- of campCenter. campCenter/spread below are the warp landing + a fallback.
catalog.spawnPoints = require('modules/custom/lua/capacity_farm_points')

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

-- POPULATION vs the engine's HARD cap. A zone holds at most 511 *dynamic*
-- entities (including trusts and pets). Farm mobs now retain and reuse their
-- targids through native respawn instead of allocating a new dynamic entity on
-- every kill, so this pool consumes a stable 100 slots. Raising it substantially
-- would still crowd out player trusts/pets under group load.
catalog.mobCount = 100
catalog.minLv    = 150                  -- engine rolls each spawn in [minLv, maxLv]
catalog.maxLv    = 160
catalog.maxHP    = 45000                -- low HP = quick kills (-25% from 60000)
catalog.respawnSeconds = 5              -- delay after the death/despawn sequence
catalog.cpBonus  = 2000                 -- flat bonus Capacity Points to the killer per kill, ON TOP of
                                        -- the engine's level-based award (both x map EXP_RATE). 0 = off.

-- Diagnostic logging. Reports missing entities, mobs still awaiting native
-- respawn, and stale entities recovered by the Lua watchdog.
catalog.debug    = true

return catalog
