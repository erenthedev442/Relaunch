-----------------------------------
-- !phantomfarm [bibiki|ranperre] [refill]
--   [GM] Report the Capacity Phantom pool for one of the two farms, and
--   optionally force-refill it back to the catalog's target count (100).
--   Force-refill bypasses the engine's death->timer chain by directly
--   inserting fresh dynamic entities via the same shape the engine uses
--   -- so it also works when the engine's onMobDeath closure has broken
--   (typical after a Lua hot-reload of capacity_farm_engine.lua, since
--   already-spawned mobs still hold the OLD closure reference).
--
-- USAGE
--   !phantomfarm bibiki                -- report Bibiki pool (alive/dead/target)
--   !phantomfarm ranperre              -- report Ranperre pool
--   !phantomfarm bibiki refill         -- top up Bibiki to 100 (no despawn)
--
-- WHEN
--   Players report "phantoms aren't respawning" -- this command distinguishes:
--     * pool at target (100 alive)     -> respawn IS working; players just
--                                         killed in bursts and missed the 5s
--     * pool has holes (< 100 alive)   -> engine's death->timer chain broke.
--                                         `refill` restores the count. A map
--                                         restart re-wires the chain for good.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ss',
}

local S = xi.msg.channel.SYSTEM_3

-- Farm registry: which zone -> which catalog. Add rows if more farms ever
-- get built. Keys are the human-typeable arg (case-insensitive).
local FARMS =
{
    bibiki   = { catalogPath = 'modules/custom/lua/capacity_farm_catalog',   label = 'Bibiki Bay'          },
    ranperre = { catalogPath = 'modules/custom/lua/ranperre_farm_catalog',   label = "King Ranperre's Tomb" },
}

-- Direct insertDynamicEntity call that mirrors capacity_farm_engine.lua's
-- spawnOne() shape. Kept in sync manually -- if the engine ever changes its
-- mob shape (new mods / callback wiring), update this to match. Included in
-- the command so `refill` works even when the engine closure is broken.
local function spawnOnePhantom(zone, catalog)
    local pts = catalog.spawnPoints
    local x, y, z
    if pts and #pts > 0 then
        local p = pts[math.random(#pts)]
        x, y, z = p[1], p[2], p[3]
    else
        local c = catalog.campCenter
        x = c.x + (math.random() * 2 - 1) * (catalog.spreadX or 5)
        y = c.y
        z = c.z + (math.random() * 2 - 1) * (catalog.spreadZ or 5)
    end

    local tpl = catalog.templates[math.random(#catalog.templates)]
    local gid, gzid
    if type(tpl) == 'table' then
        gid  = tpl.groupId
        gzid = tpl.groupZoneId or catalog.groupZoneId
    else
        gid  = tpl
        gzid = catalog.groupZoneId
    end

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = gid,
        groupZoneId          = gzid,
        name                 = catalog.mobName,
        x                    = x,
        y                    = y,
        z                    = z,
        rotation             = math.random(0, 255),
        minLevel             = catalog.minLv,
        maxLevel             = catalog.maxLv,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobSpawn = function(m)
            m:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
            m:setMobMod(xi.mobMod.NO_DROPS, 1)
            if catalog.maxHP and catalog.maxHP > 0 then
                m:setMaxHP(catalog.maxHP)
                m:setHP(catalog.maxHP)
            end
        end,

        -- Award CP but NO respawn timer on this refill-spawned mob: it's a
        -- one-shot patch, and re-implementing the engine's pendingRespawns
        -- state here would fork the state across two closures. When the map
        -- restarts (rewiring the engine cleanly), the engine's onMobDeath
        -- takes over for future spawns.
        onMobDeath = function(deadMob, killer)
            if killer and catalog.cpBonus and catalog.cpBonus > 0 then
                pcall(function() killer:addCapacityPoints(catalog.cpBonus) end)
            end
        end,
    })
    if not mob then return false end
    mob:setSpawn(x, y, z, 0)
    mob:spawn()
    return true
end

commandObj.onTrigger = function(player, farmArg, actionArg)
    local key = farmArg and string.lower(farmArg) or nil
    local farm = key and FARMS[key]
    if not farm then
        player:printToPlayer('Usage: !phantomfarm <bibiki|ranperre> [refill]', S)
        return
    end

    local catalog = require(farm.catalogPath)
    local zone    = GetZone(catalog.zoneId)
    if not zone then
        player:printToPlayer(string.format(
            '[phantomfarm] %s: zone %d is not loaded on this map process.',
            farm.label, catalog.zoneId), S)
        return
    end

    local entityName = 'DE_' .. catalog.mobName
    local existing   = zone:queryEntitiesByName(entityName) or {}

    local alive, dead = 0, 0
    for _, m in ipairs(existing) do
        pcall(function()
            if m:isAlive() then alive = alive + 1 else dead = dead + 1 end
        end)
    end
    local total  = alive + dead
    local target = catalog.mobCount

    player:printToPlayer(string.format(
        '[phantomfarm] %s: %d alive + %d dead-not-GC = %d total (target %d).',
        farm.label, alive, dead, total, target), S)

    local action = actionArg and string.lower(actionArg) or nil
    if action ~= 'refill' then
        if total < target then
            player:printToPlayer(string.format(
                '  => pool has holes (%d < %d). Run !phantomfarm %s refill to top up.',
                total, target, key), S)
        else
            player:printToPlayer('  => pool at target. Respawn chain is healthy.', S)
        end
        return
    end

    -- Refill: spawn (target - total) new phantoms directly. Doesn't touch
    -- existing entities (alive OR pending-GC).
    local toSpawn = math.max(0, target - total)
    if toSpawn == 0 then
        player:printToPlayer('  => already at target; refill no-op.', S)
        return
    end
    local ok = 0
    for _ = 1, toSpawn do
        if spawnOnePhantom(zone, catalog) then ok = ok + 1 end
    end
    player:printToPlayer(string.format(
        '  => refill spawned %d/%d fresh phantoms. New total ~= %d.',
        ok, toSpawn, total + ok), S)
    if ok < toSpawn then
        player:printToPlayer(
            '  NOTE: some spawns failed (dynamic-entity cap may be hit). Map restart clears cleanly.',
            S)
    end
end

return commandObj
