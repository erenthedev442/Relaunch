-----------------------------------
-- !invasion [start | end | status]
-- GM command to manually trigger or abort the GM Home invasion event.
-- Requires gmlevel >= 4.
--
--   !invasion         -- show current status
--   !invasion start   -- force-start (GM must be in GM Home)
--   !invasion end     -- abort + despawn all Voidsent (no rewards)
--
-- Self-contained: maintains its own state so it works without a restart
-- even though Invasion.lua is an addOverride module.
--
-- Sets xi._any_invasion_active = true/false so the reraise module can
-- see when either a scheduled or GM invasion is running.
-----------------------------------
local catalog   = require('modules/custom/lua/invasion_catalog')
local LOOT_POOL = require('modules/custom/lua/invasion_loot_pool')
local LOOT_POOL_SIZE = #LOOT_POOL
local DROP_CHANCE = 15  -- % per mob kill

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 4,
    parameters = 'sssss',
}

-- Module-level state - persists for the lifetime of the server process.
-- Closures in onMobDeath reference this via upvalue.
local state = nil

-- Forward declarations so spawnInvader's closure can call them.
local nextWave, endLocalInvasion

local function broadcastZone(zone, msg)
    if not zone then return end
    for _, p in ipairs(zone:getPlayers()) do
        p:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
    end
end

local function defendersInZone(zone)
    local out = {}
    for _, p in ipairs(zone:getPlayers()) do
        if p:getHP() > 0 then out[#out + 1] = p end
    end
    return out
end

local function tryDrop(killer)
    if not killer then return end
    if killer:getObjType() ~= xi.objType.PC then return end
    if math.random(100) > DROP_CHANCE then return end
    local itemId = LOOT_POOL[math.random(LOOT_POOL_SIZE)]
    pcall(function() killer:addItem(itemId, 1) end)
end

local function spawnInvader(zone, anchor, def, level, mods, hpMult, opts)
    opts = opts or {}
    local fs = catalog.fixedSpawn
    local px = fs and fs.x or anchor:getXPos()
    local py = fs and fs.y or anchor:getYPos()
    local pz = fs and fs.z or anchor:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = catalog.spawnRingMin
        + math.random() * (catalog.spawnRingMax - catalog.spawnRingMin)
    local mx = px + math.cos(angle) * dist
    local mz = pz + math.sin(angle) * dist

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = def.groupId,
        groupZoneId          = catalog.groupZoneId,
        name                 = def.name,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = level,
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            if not state then return end

            -- Per-kill item drop.
            pcall(tryDrop, killer)

            state.mobsAlive[deadMob:getID()] = nil
            for _ in pairs(state.mobsAlive) do return end  -- wave still alive

            -- Wave cleared. Use the captured `zone` (real spawn zone 48), NOT
            -- deadMob:getZone() -- invaders carry groupZoneId 210 (GM Home), so
            -- getZone() returns the wrong zone (empty player list -> the event
            -- self-aborts after wave 1, clearing the reraise flag).
            local everyone = zone:getPlayers()
            for _, p in ipairs(everyone) do
                p:setCharVar('HL_Points', (p:getCharVar('HL_Points') or 0) + catalog.reward.perWaveMarks)
                p:printToPlayer(string.format('[Invasion] Wave %d repelled! +%d marks.',
                    state.wave, catalog.reward.perWaveMarks),
                    xi.msg.channel.SYSTEM_3)
            end

            local token = state.startedAt
            local anyP  = everyone[1]
            if anyP then
                anyP:timer(catalog.interWaveDelaySec * 1000, function(pp)
                    if state and state.startedAt == token then
                        nextWave(zone)
                    end
                end)
            else
                endLocalInvasion(zone, 'abandoned')
            end
        end,
    })

    if mob then
        mob:setSpawn(mx, py, mz, 0)
        mob:spawn()
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
        mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
        if mods then
            for modId, val in pairs(mods) do mob:setMod(modId, val) end
        end
        if hpMult and hpMult > 1.0 then
            local newMax = math.floor(mob:getMaxHP() * hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
        if opts.modelSize then
            pcall(function() mob:setModelSize(opts.modelSize) end)
        end
        mob:addEnmity(anchor, 1, 1)
    end
    return mob
end

nextWave = function(zone)
    if not state then return end
    state.wave = state.wave + 1
    local waveNum = state.wave
    local w = catalog.waves[waveNum]

    if not w then
        -- All waves done - victory.
        local everyone = zone:getPlayers()
        for _, p in ipairs(everyone) do
            p:setCharVar('HL_Points', (p:getCharVar('HL_Points') or 0) + catalog.reward.victoryMarks)
            p:setCharVar('Infamy', (p:getCharVar('Infamy') or 0) + catalog.reward.victoryInfamy)
            p:setCharVar('Infamy_Lifetime', (p:getCharVar('Infamy_Lifetime') or 0) + catalog.reward.victoryInfamy)
            p:printToPlayer(string.format('[Invasion] GM Home stands! +%d marks, +%d Infamy.',
                catalog.reward.victoryMarks, catalog.reward.victoryInfamy),
                xi.msg.channel.SYSTEM_3)
        end
        broadcastZone(zone, '[Invasion] Al Zahbi holds! The Voidsent are repelled - glory to the defenders!')
        state = nil
        xi._any_invasion_active = false
        return
    end

    local defenders = defendersInZone(zone)
    if #defenders == 0 then
        endLocalInvasion(zone, 'abandoned')
        return
    end

    state.mobsAlive = {}

    local count = w.base + w.perDefender * #defenders
    for _ = 1, count do
        local anchor = defenders[math.random(#defenders)]
        local def = {
            groupId = w.groups[math.random(#w.groups)],
            name    = w.names[math.random(#w.names)],
        }
        local mob = spawnInvader(zone, anchor, def, w.level, w.mods, w.hpMult)
        if mob then state.mobsAlive[mob:getID()] = mob end
    end

    if w.boss then
        local anchor = defenders[math.random(#defenders)]
        local mob = spawnInvader(zone, anchor,
            { groupId = w.boss.group, name = w.boss.name },
            w.boss.level, w.boss.mods, w.boss.hpMult,
            { modelSize = w.boss.modelSize })
        if mob then state.mobsAlive[mob:getID()] = mob end
    end

    local any = false
    for _ in pairs(state.mobsAlive) do any = true break end
    if not any then endLocalInvasion(zone, 'error') return end

    local rem = math.max(0, state.endsAt - os.time())
    for _, p in ipairs(zone:getPlayers()) do
        p:printToPlayer(string.format('[Invasion] WAVE %d/%d - %s! (%d foes, Lv.%d%s) %dm %ds on the clock.',
            waveNum, #catalog.waves, w.label,
            count + (w.boss and 1 or 0), w.level,
            w.boss and (' + ' .. w.boss.name) or '',
            math.floor(rem / 60), rem % 60),
            xi.msg.channel.SYSTEM_3)
    end
end

endLocalInvasion = function(zone, reason)
    if not state then return end
    local mobs = state.mobsAlive
    state = nil
    xi._any_invasion_active = false
    for _, mob in pairs(mobs or {}) do
        if type(mob) == 'userdata' then
            pcall(function() if mob:getHP() > 0 then mob:setHP(0) end end)
        end
    end
    if reason == 'abandoned' then
        broadcastZone(zone, '[Invasion] The Voidsent assault fizzles - no defenders remained.')
    end
end

commandObj.onTrigger = function(player, a1, ...)
    local sub = (a1 or ''):lower()

    if sub == 'start' then
        if player:getZoneID() ~= catalog.zoneId then
            player:printToPlayer(string.format(
                '[Invasion] You must be in Al Zahbi (zone %d) to start the invasion.',
                catalog.zoneId))
            return
        end
        if state then
            player:printToPlayer('[Invasion] A GM-triggered invasion is already in progress.')
            return
        end
        state = {
            wave      = 0,
            mobsAlive = {},
            startedAt = os.time(),
            endsAt    = os.time() + catalog.timeLimitSec,
        }
        xi._any_invasion_active = true
        broadcastZone(player:getZone(),
            '[Invasion] THE VOIDSENT ARE HERE! GM Home is under attack - defend the sanctuary!')
        nextWave(player:getZone())
        player:printToPlayer('[Invasion] Invasion force-started.')

    elseif sub == 'end' or sub == 'stop' then
        if not state then
            player:printToPlayer('[Invasion] No active GM-triggered invasion.')
            return
        end
        local zone = (player:getZoneID() == catalog.zoneId)
            and player:getZone() or nil
        endLocalInvasion(zone, 'gm_abort')
        player:printToPlayer('[Invasion] Invasion aborted - all Voidsent despawned.')

    else
        if not state then
            player:printToPlayer('[Invasion] No active invasion. Usage: !invasion start | end')
        else
            local rem = math.max(0, state.endsAt - os.time())
            player:printToPlayer(string.format(
                '[Invasion] Active: Wave %d/%d | %dm %ds remaining.',
                state.wave, #catalog.waves,
                math.floor(rem / 60), rem % 60))
        end
    end
end

return commandObj
