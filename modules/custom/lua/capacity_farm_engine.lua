-----------------------------------
-- capacity_farm_engine.lua
-- Factory that creates a capacity-farm Module for any zone.
-- Call makeFarm(catalog) with a catalog table (same shape as
-- capacity_farm_catalog.lua) to get a Module that seeds and
-- maintains an always-up Capacity Point farm in that zone.
--
-- Both CapacityFarm.lua (Bibiki Bay) and RanperreFarm.lua (King
-- Ranperre's Tomb) use this factory so the logic lives in one place.
-----------------------------------
require('modules/module_utils')

local function makeFarm(catalog)
    local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
    require(string.format('scripts/zones/%s/Zone', _zoneName))

    local logTag = catalog.logTag or ('capacity_farm_' .. (_zoneName or 'unknown'))
    local m = Module:new(logTag)

    -- Aggro-safe warp: filter any spawn point within noSpawnRadius (default 25y,
    -- comfortably above the 20-yalm sight/sound range for Lv150 mobs) of warpPos.
    -- Farm mobs are isAggroable + SIGHT_AND_HEARING, so a point closer than that
    -- would engage the player the instant !capacity drops them in. Runs once at
    -- module load; the giant auto-generated point files stay untouched.
    local aggroBuffer = catalog.noSpawnRadius or 25.0
    local warp        = catalog.warpPos
    local safePoints  = nil
    if catalog.spawnPoints and warp then
        local wx, wy, wz = warp.x, warp.y, warp.z
        local r2 = aggroBuffer * aggroBuffer
        safePoints = {}
        local dropped = 0
        for _, p in ipairs(catalog.spawnPoints) do
            local dx, dy, dz = p.x - wx, p.y - wy, p.z - wz
            if (dx*dx + dy*dy + dz*dz) > r2 then
                safePoints[#safePoints + 1] = p
            else
                dropped = dropped + 1
            end
        end
        print(string.format('[%s] warp-safe spawn pool: %d kept, %d dropped within %.1fy of warp (%.1f, %.1f, %.1f)',
            logTag, #safePoints, dropped, aggroBuffer, wx, wy, wz))
    end

    local function insideAggro(x, y, z)
        if not warp then return false end
        local dx, dy, dz = x - warp.x, y - warp.y, z - warp.z
        return (dx*dx + dy*dy + dz*dz) <= (aggroBuffer * aggroBuffer)
    end

    local campZone
    local ensurePopulation  -- forward decl
    local pendingRespawns = 0  -- timers in-flight; keeps ensurePopulation from double-spawning

    local function spawnOne()
        if not campZone then return end

        local x, y, z
        local pts = safePoints
        if pts and #pts > 0 then
            local p = pts[math.random(#pts)]
            x, y, z = p.x, p.y, p.z
        else
            -- Random fallback around campCenter: reject picks inside the warp
            -- aggro buffer and retry a few times before falling back to the
            -- centre coord (safer than a spinning loop if the buffer swallows
            -- the whole spread box).
            local c = catalog.campCenter
            for _ = 1, 8 do
                x = c.x + math.random(-catalog.spreadX, catalog.spreadX)
                y = c.y
                z = c.z + math.random(-catalog.spreadZ, catalog.spreadZ)
                if not insideAggro(x, y, z) then break end
            end
            if insideAggro(x, y, z) then
                x, y, z = c.x, c.y, c.z
            end
        end

        -- Templates may be plain numbers (use catalog.groupZoneId) or
        -- {groupId=N, groupZoneId=M} tables for cross-zone mixed pools.
        local tpl  = catalog.templates[math.random(#catalog.templates)]
        local gid, gzid
        if type(tpl) == 'table' then
            gid  = tpl.groupId
            gzid = tpl.groupZoneId or catalog.groupZoneId
        else
            gid  = tpl
            gzid = catalog.groupZoneId
        end

        local rot = math.random(0, 255)

        local mob = campZone:insertDynamicEntity({
            objtype     = xi.objType.MOB,
            groupId     = gid,
            groupZoneId = gzid,
            name        = catalog.mobName,
            x           = x,
            y           = y,
            z           = z,
            rotation    = rot,
            minLevel    = catalog.minLv,
            maxLevel    = catalog.maxLv,
            detection   = xi.detects.SIGHT_AND_HEARING,
            isAggroable = true,

            -- REQUIRED: a dead dynamic mob must free its targid (held ~60s,
            -- then reusable). Every respawn here is a NEW insertDynamicEntity;
            -- without this each kill permanently leaks one of the zone's 511
            -- dynamic slots and spawning stops dead after a few hundred kills.
            releaseIdOnDisappear = true,

            -- CMobEntity::Spawn() calls CalculateMobStats() which recalculates HP
            -- from pool data, overwriting our custom maxHP.  onMobSpawn fires AFTER
            -- CalculateMobStats on every spawn (initial + auto-respawn), so re-apply
            -- our settings here.  Same for mob mods: restoreModifiers() on respawn
            -- reverts to the pool baseline, so re-apply after it runs.
            onMobSpawn = function(m)
                m:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
                m:setMobMod(xi.mobMod.NO_DROPS, 1)
                if catalog.maxHP and catalog.maxHP > 0 then
                    m:setMaxHP(catalog.maxHP)
                    m:setHP(catalog.maxHP)
                end
            end,

            onMobDeath = function(deadMob, killer)
                if killer and catalog.cpBonus and catalog.cpBonus > 0 then
                    pcall(function() killer:addCapacityPoints(catalog.cpBonus) end)
                end
                -- C++ auto-respawn never fires for dynamic entities (they are
                -- deleted on despawn before TrySpawn can run), so drive repop
                -- from Lua. NOTE: the timer must live on the ENTITY -- CLuaZone
                -- has no :timer binding. The dying mob's AI keeps ticking
                -- through its ~12s death state, so a 5s timer reliably fires.
                -- The callback refills via ensurePopulation() (not a blind
                -- spawnOne) so the camp converges on mobCount even if timers
                -- and top-ups race; pendingRespawns stops ensurePopulation
                -- from double-counting a kill whose corpse already left the
                -- entity list.
                pendingRespawns = pendingRespawns + 1
                deadMob:timer(5000, function()
                    pendingRespawns = math.max(0, pendingRespawns - 1)
                    ensurePopulation()
                end)
            end,
        })
        if not mob then
            print(string.format('[%s] insertDynamicEntity returned nil (groupId %d, groupZoneId %d)',
                logTag, gid, gzid))
            return
        end

        mob:setSpawn(x, y, z, rot)
        mob:spawn()
        -- Note: mob:spawn() triggers CMobEntity::Spawn() → onMobSpawn callback above,
        -- which sets maxHP, NO_DROPS and NON_EXCLUSIVE claim.  No separate calls needed.
    end

    ensurePopulation = function()
        if not campZone then return end
        -- Count ALL existing entities (alive + dead-but-not-yet-gc'd).
        -- Dead dynamic mobs hold their targid for ~60s; pendingRespawns
        -- accounts for in-flight timers so we don't over-spawn.
        local existing = campZone:queryEntitiesByName('DE_' .. catalog.mobName)
        local count    = existing and #existing or 0
        local toSpawn  = math.max(0, catalog.mobCount - count - pendingRespawns)
        for _ = 1, toSpawn do
            spawnOne()
        end
        if catalog.debug and toSpawn > 0 then
            print(string.format('[%s] ensurePopulation: %d existing -> +%d spawned (target %d)',
                logTag, count, toSpawn, catalog.mobCount))
        end
    end

    m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
        super(zone)
        campZone = zone
        ensurePopulation()
    end)

    m:addOverride(catalog.zonePath .. '.Zone.onZoneIn', function(player, prevZone)
        local cs = super(player, prevZone)
        campZone = player:getZone()
        ensurePopulation()
        return cs
    end)

    -- Periodic safety net: verify the pool every Vana'diel hour (~2 real min).
    -- Also resets pendingRespawns: any legit in-flight timer is <=5s old, so a
    -- nonzero count here means a timer was lost (mob cleaned up early) and
    -- would otherwise under-fill the camp forever.
    m:addOverride(catalog.zonePath .. '.Zone.onGameHour', function(zone)
        super(zone)
        if campZone then
            pendingRespawns = 0
            ensurePopulation()
        end
    end)

    return m
end

return makeFarm
