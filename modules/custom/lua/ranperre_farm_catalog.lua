-----------------------------------
-- ranperre_farm_catalog.lua
-- Config for the Capacity Point farm in King Ranperre's Tomb.
-- Edit this file only; RanperreFarm.lua (via capacity_farm_engine)
-- reads it. Mirrors capacity_farm_catalog.lua in shape.
-----------------------------------
local catalog = {}

catalog.zoneId   = xi.zone.KING_RANPERRES_TOMB  -- 190
catalog.zonePath = 'xi.zones.King_Ranperres_Tomb'
catalog.logTag   = 'ranperre_farm'

-- Confirmed native main-floor point, kept outside the farm's aggro buffer.
-- Keep in sync with the !capacity ranperre pos in commands/capacity.lua.
catalog.warpPos    = { x = -54.55, y = 7.21, z = 82.03, rot = 0 }

-- Fallback camp-center patch (used when spawnPoints is nil/empty).
catalog.campCenter = { x = -26.0, y = 7.0, z = 21.0 }
catalog.spreadX    = 30
catalog.spreadZ    = 30

-- Native walkable points from mob_spawn_points. The shared engine restricts
-- these to the main-floor camp around campCenter so mobs remain nearby.
catalog.spawnPoints = require('modules/custom/lua/ranperre_farm_points')
catalog.spawnRadius = 85
catalog.spawnMinY   = 5
catalog.spawnMaxY   = 9

-- Mixed template pool: native undead for tomb flavor + capacity-built HL NM
-- models (zone 210 / GM_Home) for the bulk of the camp.
-- Each entry is a {groupId, groupZoneId} pair; the engine picks one randomly.
catalog.groupZoneId = 190  -- fallback for any plain-number entries
catalog.templates =
{
    -- Native undead (zone 190) — keep the tomb atmosphere
    { groupId = 19, groupZoneId = 190 }, -- Crypt_Ghost
    { groupId =  8, groupZoneId = 190 }, -- Spook
    -- Capacity-built HL NM models (zone 210 / GM_Home) — same pool as Bibiki Bay
    { groupId = 11355, groupZoneId = 210 }, -- Leaping Lizzy
    { groupId = 11357, groupZoneId = 210 }, -- Tom Tit Tat
    { groupId = 11358, groupZoneId = 210 }, -- Roc
    { groupId = 11360, groupZoneId = 210 }, -- Aquarius
    { groupId = 11361, groupZoneId = 210 }, -- Serket
}

catalog.mobName  = 'Capacity Phantom'

-- 100 persistent mobs: same 511 dynamic-entity limit as Bibiki Bay; each mob
-- reuses its targid while player trusts and pets share the remaining pool.
catalog.mobCount = 100
catalog.minLv    = 150
catalog.maxLv    = 160
catalog.maxHP    = 120000
catalog.respawnSeconds = 5
catalog.cpBonus  = 2000

catalog.debug    = true

return catalog
