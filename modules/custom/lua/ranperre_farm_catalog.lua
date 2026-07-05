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

-- Where !ranperre warps the player. Matches a native walkable spawn
-- point on the main floor (y~7) near the center of the zone.
catalog.warpPos    = { x = -26.0, y = 7.0, z = 21.0, rot = 0 }

-- Fallback camp-center patch (used when spawnPoints is nil/empty).
catalog.campCenter = { x = -26.0, y = 7.0, z = 21.0 }
catalog.spreadX    = 30
catalog.spreadZ    = 30

-- Zone-wide spawn pool: all 495 native walkable points in King Ranperre's
-- Tomb from mob_spawn_points. (0,0,0) and (1,1,1) dummy rows filtered.
catalog.spawnPoints = require('modules/custom/lua/ranperre_farm_points')

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

-- 100 mobs: same cap reasoning as Bibiki Bay (511 dynamic-entity limit;
-- dead mobs hold their targid for 60s; trusts/pets share the pool).
catalog.mobCount = 100
catalog.minLv    = 150
catalog.maxLv    = 160
-- 9000 HP matches Locus Colibri -- quick kills so the capacity chain
-- stays hot. The native Locus Dire Bat has ~300k HP; this camp fixes that.
catalog.maxHP    = 9000
catalog.cpBonus  = 2000

catalog.debug    = true

return catalog
