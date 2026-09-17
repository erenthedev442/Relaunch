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

-- FileWatcher dofile discards return; keep the same table require() already has.
local KEY = 'modules/custom/lua/capacity_farm_engine'
local exported = package.loaded[KEY]
if type(exported) ~= 'table' then
    exported = {}
end
package.loaded[KEY] = exported

local function punishUnder99(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end
    if not player:isAlive() then
        return
    end
    if (player:getMainLvl() or 0) >= 99 then
        return
    end
    player:printToPlayer(
        'Capacity farms are for level 99 only. No experience is awarded here.',
        xi.msg.channel.SYSTEM_3)
    player:setHP(0)
end

local function attach99Only(mob)
    if not mob then
        return
    end
    pcall(function()
        mob:addListener('ENGAGE', 'CAPACITY_99ONLY', function(_, target)
            punishUnder99(target)
        end)
        mob:addListener('DEATH', 'CAPACITY_99ONLY_DEATH', function(_, killer)
            if killer and killer.getAlliance then
                for _, member in ipairs(killer:getAlliance() or {}) do
                    punishUnder99(member)
                end
            else
                punishUnder99(killer)
            end
        end)
    end)
end

local function applySoundAggroTo(mob, soundRange, sightRange)
    if not mob then
        return
    end
    local range = soundRange or 20
    mob:setMobMod(xi.mobMod.DETECTION, xi.detects.SIGHT_AND_HEARING)
    mob:setMobMod(xi.mobMod.SOUND_RANGE, range)
    if sightRange then
        mob:setMobMod(xi.mobMod.SIGHT_RANGE, sightRange)
    elseif (mob:getMobMod(xi.mobMod.SIGHT_RANGE) or 0) < 15 then
        mob:setMobMod(xi.mobMod.SIGHT_RANGE, 15)
    end
    -- insertDynamicEntity only sets isAggroable (other mobs attacking this
    -- one). Auto-aggro on players is m_Aggro, which comes from the HL pool
    -- and can be 0. Force it on every stamp / spawn.
    pcall(function()
        mob:setAggressive(true)
        mob:setMobMod(xi.mobMod.ALWAYS_AGGRO, 1)
    end)
    -- Same dynamic entity respawns; restoreModifiers() wipes DETECTION unless
    -- a SPAWN listener re-applies it after onMobSpawn.
    pcall(function()
        mob:addListener('SPAWN', 'CAPACITY_SOUND', function(m)
            m:setMobMod(xi.mobMod.DETECTION, xi.detects.SIGHT_AND_HEARING)
            m:setMobMod(xi.mobMod.SOUND_RANGE, range)
            if sightRange then
                m:setMobMod(xi.mobMod.SIGHT_RANGE, sightRange)
            elseif (m:getMobMod(xi.mobMod.SIGHT_RANGE) or 0) < 15 then
                m:setMobMod(xi.mobMod.SIGHT_RANGE, 15)
            end
            m:setAggressive(true)
            m:setMobMod(xi.mobMod.ALWAYS_AGGRO, 1)
        end)
    end)
    attach99Only(mob)
    pcall(function()
        mob:setLocalVar('CapacityFarmLimitOnly', 1)
    end)
end

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

    -- Random point in a 4-corner quad (bilinear). Extra jitter keeps the
    -- camp from looking like a grid or a line.
    local function pickInQuad(quad)
        local u = 0.05 + 0.90 * math.random()
        local v = 0.05 + 0.90 * math.random()
        local a, b, c, d = quad[1], quad[2], quad[3], quad[4]
        local x = (1 - u) * (1 - v) * a.x + u * (1 - v) * b.x + u * v * c.x + (1 - u) * v * d.x
        local y = (1 - u) * (1 - v) * a.y + u * (1 - v) * b.y + u * v * c.y + (1 - u) * v * d.y
        local z = (1 - u) * (1 - v) * a.z + u * (1 - v) * b.z + u * v * c.z + (1 - u) * v * d.z
        x = x + (math.random() - 0.5) * 8
        z = z + (math.random() - 0.5) * 8
        return x, y, z
    end

    local function pickSpawn()
        if catalog.spawnQuad and #catalog.spawnQuad == 4 then
            local x, y, z
            for _ = 1, 16 do
                x, y, z = pickInQuad(catalog.spawnQuad)
                if not insideAggro(x, y, z) then
                    return x, y, z
                end
            end
            return x, y, z
        end

        local pts = safePoints
        if pts and #pts > 0 then
            local p = pts[math.random(#pts)]
            return p.x, p.y, p.z
        end

        local cx, cy, cz = catalog.campCenter.x, catalog.campCenter.y, catalog.campCenter.z
        for _ = 1, 8 do
            local x = cx + math.random(-catalog.spreadX, catalog.spreadX)
            local z = cz + math.random(-catalog.spreadZ, catalog.spreadZ)
            if not insideAggro(x, cy, z) then
                return x, cy, z
            end
        end
        return cx, cy, cz
    end

    local function pickTemplate(x, y, z)
        local pool = catalog.templates
        if catalog.waterTemplates and catalog.waterMinX and x >= catalog.waterMinX then
            pool = catalog.waterTemplates
        end
        local tpl = pool[math.random(#pool)]
        if type(tpl) == 'table' then
            return tpl.groupId, tpl.groupZoneId or catalog.groupZoneId
        end
        return tpl, catalog.groupZoneId
    end

    local campZone
    local ensurePopulation  -- forward decl
    -- Native respawn normally completes well inside this window (15s death
    -- state, 3s fade, then the 30s SpawnHandler wave). Anything still
    -- disappeared after this is stale and is recovered in-place.
    local staleRespawnSeconds = math.max(60, (catalog.respawnSeconds or 5) + 45)

    local function applySoundAggro(mob)
        if catalog.soundAggro then
            applySoundAggroTo(mob, catalog.soundRange or 20, catalog.sightRange)
        else
            attach99Only(mob)
            pcall(function()
                mob:setLocalVar('CapacityFarmLimitOnly', 1)
            end)
        end
    end

    if catalog.spawnQuad and #catalog.spawnQuad == 4 then
        print(string.format('[%s] random quad scatter (%d corners), warp buffer %.1fy',
            logTag, #catalog.spawnQuad, aggroBuffer))
    end

    local function spawnOne()
        if not campZone then return end

        local x, y, z = pickSpawn()
        local gid, gzid = pickTemplate(x, y, z)
        local rot = math.random(0, 255)

        local mob = campZone:insertDynamicEntity({
            objtype     = xi.objType.MOB,
            groupId     = gid,
            groupZoneId = gzid,
            name        = catalog.mobName,
            packetName  = catalog.packetName or catalog.mobName,
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
                applySoundAggro(m)
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

            onMobDeath = function(deadMob, player)
                -- onMobDeath can run once per eligible alliance member. Keep
                -- the first timestamp, and refresh this module instance's zone
                -- reference so FileWatcher reloads cannot strand the pool.
                campZone = deadMob:getZone()
                if deadMob:getLocalVar('CapacityFarmDiedAt') == 0 then
                    deadMob:setLocalVar('CapacityFarmDiedAt', GetSystemTime())
                end
                -- Fires before C++ DistributeExperiencePoints. Dead members
                -- get 0 EXP / 0 merits / 0 CP.
                punishUnder99(player)
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
                applySoundAggro(mob)
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

    -- FileWatcher: restamp every living farm mob so sound aggro is not
    -- stuck behind a map restart or the next death/respawn.
    local okApply, applyErr = pcall(function()
        local zoneId = catalog.zoneId
        if not zoneId then
            print(string.format('[%s] sound aggro: no zoneId', logTag))
            return
        end
        local zone = GetZone(zoneId)
        if not zone then
            print(string.format('[%s] sound aggro: zone %s not loaded', logTag, tostring(zoneId)))
            return
        end
        campZone = zone
        local existing = zone:queryEntitiesByName('DE_' .. catalog.mobName)
        local n = 0
        for _, mob in ipairs(existing or {}) do
            applySoundAggro(mob)
            n = n + 1
        end
        print(string.format('[%s] sound aggro applied to %d live %s', logTag, n, catalog.mobName))
    end)
    if not okApply then
        print(string.format('[%s] sound aggro failed: %s', logTag, tostring(applyErr)))
    end

    -- FileWatcher of a new farm module never re-registers Zone hooks. Seed
    -- (or top up) the pool now so the camp exists without a map restart.
    if not campZone and catalog.zoneId then
        pcall(function()
            campZone = GetZone(catalog.zoneId)
        end)
    end
    if campZone then
        if catalog.resettleOnLoad and catalog.spawnQuad then
            local existing = campZone:queryEntitiesByName('DE_' .. catalog.mobName)
            local moved = 0
            for _, mob in ipairs(existing or {}) do
                local x, y, z = pickSpawn()
                local rot = math.random(0, 255)
                pcall(function()
                    mob:setSpawn(x, y, z, rot)
                    if mob:isSpawned() then
                        DespawnMob(mob:getID())
                    end
                end)
                moved = moved + 1
            end
            catalog.resettleOnLoad = false
            print(string.format('[%s] resettled %d %s onto random quad points (repop ~5s)',
                logTag, moved, catalog.mobName))
        end
        ensurePopulation()
    end

    return m
end

-- FileWatcher of this factory does not re-run CapacityFarm.lua. Stamp the
-- cached Bibiki catalog here so a mid-file reload still hits every live Phantom.
do
    local cat = package.loaded['modules/custom/lua/capacity_farm_catalog']
    if type(cat) == 'table' and cat.zoneId and cat.mobName then
        local ok, err = pcall(function()
            local zone = GetZone(cat.zoneId)
            if not zone then
                print('[capacity_farm_engine] sound aggro: Bibiki zone not loaded')
                return
            end
            local existing = zone:queryEntitiesByName('DE_' .. cat.mobName)
            local n = 0
            local soundRange = cat.soundRange or 20
            for _, mob in ipairs(existing or {}) do
                applySoundAggroTo(mob, soundRange, cat.sightRange)
                n = n + 1
            end
            print(string.format('[capacity_farm_engine] sound aggro applied to %d live %s', n, cat.mobName))
        end)
        if not ok then
            print('[capacity_farm_engine] sound aggro failed: ' .. tostring(err))
        end
    end
end

-- Return as a callable table so moduleutils::LoadLuaModules (which scans every
-- .lua under modules/custom and rejects bare-function returns as "Invalid
-- object returned") stops erroring on this file at every boot. Consumers keep
-- their `local makeFarm = require(...)` + `makeFarm(catalog)` calls unchanged
-- thanks to the __call metamethod. Empty overrides list satisfies the Module
-- shape check but adds no runtime hooks -- the actual capacity-farm Modules
-- are created dynamically by makeFarm() and registered as normal per zone.
exported.overrides = exported.overrides or {}
exported.makeFarm  = makeFarm
return setmetatable(exported, { __call = function(_, catalog) return makeFarm(catalog) end })
