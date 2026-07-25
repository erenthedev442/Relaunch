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
        local center      = catalog.campCenter
        local spawnRadius = catalog.spawnRadius
        local spawnR2     = spawnRadius and spawnRadius * spawnRadius or nil
        safePoints = {}
        local dropped = 0
        for _, p in ipairs(catalog.spawnPoints) do
            local dx, dy, dz = p.x - wx, p.y - wy, p.z - wz
            local inCamp = true
            if center and spawnR2 then
                local cdx, cdz = p.x - center.x, p.z - center.z
                inCamp = cdx*cdx + cdz*cdz <= spawnR2
            end

            if catalog.spawnMinY and p.y < catalog.spawnMinY then
                inCamp = false
            elseif catalog.spawnMaxY and p.y > catalog.spawnMaxY then
                inCamp = false
            end

            if inCamp and (dx*dx + dy*dy + dz*dz) > r2 then
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
    -- Native respawn normally completes well inside this window (15s death
    -- state, 3s fade, then the 30s SpawnHandler wave). Anything still
    -- disappeared after this is stale and is recovered in-place.
    local staleRespawnSeconds = math.max(60, (catalog.respawnSeconds or 5) + 45)

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
            -- Keep the same dynamic entity and targid for every life. Setting a
            -- respawn enables SpawnHandler; releaseIdOnDisappear must stay false
            -- or the zone deletes the entity before TrySpawn can reuse it.
            respawn              = catalog.respawnSeconds or 5,
            releaseIdOnDisappear = false,

            -- CMobEntity::Spawn() calls CalculateMobStats() which recalculates HP
            -- from pool data, overwriting our custom maxHP.  onMobSpawn fires AFTER
            -- CalculateMobStats on every spawn (initial + auto-respawn), so re-apply
            -- our settings here.  Same for mob mods: restoreModifiers() on respawn
            -- reverts to the pool baseline, so re-apply after it runs.
            onMobSpawn = function(m)
                m:setLocalVar('CapacityFarmDiedAt', 0)
                m:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
                m:setMobMod(xi.mobMod.NO_DROPS, 1)
                -- Preserve the normal kill reward for merits while preventing
                -- these dedicated Lv99 camps from adding normal job EXP.
                m:setLocalVar('CapacityFarmLimitOnly', 1)
                -- C++ folds this killer-only flat bonus into the normal mob CP
                -- award before applying the strict 60k per-player/per-kill cap.
                m:setLocalVar('CapacityFarmBonus', catalog.cpBonus or 0)
                if catalog.maxHP and catalog.maxHP > 0 then
                    m:setMaxHP(catalog.maxHP)
                    m:setHP(catalog.maxHP)
                end
            end,

            onMobDeath = function(deadMob)
                -- onMobDeath can run once per eligible alliance member. Keep
                -- the first timestamp, and refresh this module instance's zone
                -- reference so FileWatcher reloads cannot strand the pool.
                campZone = deadMob:getZone()
                if deadMob:getLocalVar('CapacityFarmDiedAt') == 0 then
                    deadMob:setLocalVar('CapacityFarmDiedAt', GetSystemTime())
                end
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

        local existing = campZone:queryEntitiesByName('DE_' .. catalog.mobName)
        local total     = existing and #existing or 0
        local alive     = 0
        local waiting   = 0
        local recovered = 0
        local now       = GetSystemTime()

        -- Keep persistent entities (and their targids), but do not mistake a
        -- permanently disappeared entity for healthy population. Native
        -- respawn is primary; this watchdog only intervenes after a full
        -- death/despawn/spawn-wave window has elapsed.
        for _, mob in ipairs(existing or {}) do
            if mob:isAlive() then
                alive = alive + 1
            else
                local diedAt = mob:getLocalVar('CapacityFarmDiedAt')
                local stale  = not mob:isSpawned() and
                    (diedAt == 0 or now - diedAt >= staleRespawnSeconds)

                if stale then
                    -- Cancel any orphaned pending registration before forcing
                    -- this same entity back up, then restore automatic respawn.
                    mob:setRespawnTime(0)
                    mob:spawn()
                    mob:setRespawnTime(catalog.respawnSeconds or 5)
                    if mob:isAlive() then
                        alive     = alive + 1
                        recovered = recovered + 1
                    end
                else
                    waiting = waiting + 1
                end
            end
        end

        -- Only genuinely missing entities allocate new dynamic targids.
        local toSpawn = math.max(0, catalog.mobCount - total)
        for _ = 1, toSpawn do
            spawnOne()
        end

        if catalog.debug and (toSpawn > 0 or recovered > 0 or waiting > 0) then
            print(string.format(
                '[%s] ensurePopulation: %d alive, %d awaiting respawn, %d stale recovered, +%d missing spawned (target %d)',
                logTag, alive, waiting, recovered, toSpawn, catalog.mobCount))
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

    -- Periodic safety net: replace missing entities and recover any persistent
    -- entity that native respawn left disappeared for longer than one complete
    -- respawn cycle.
    m:addOverride(catalog.zonePath .. '.Zone.onGameHour', function(zone)
        super(zone)
        if campZone then
            ensurePopulation()
        end
    end)

    return m
end

-- Return as a callable table so moduleutils::LoadLuaModules (which scans every
-- .lua under modules/custom and rejects bare-function returns as "Invalid
-- object returned") stops erroring on this file at every boot. Consumers keep
-- their `local makeFarm = require(...)` + `makeFarm(catalog)` calls unchanged
-- thanks to the __call metamethod. Empty overrides list satisfies the Module
-- shape check but adds no runtime hooks -- the actual capacity-farm Modules
-- are created dynamically by makeFarm() and registered as normal per zone.
return setmetatable(
    { overrides = {}, makeFarm = makeFarm },
    { __call = function(_, catalog) return makeFarm(catalog) end }
)
