-----------------------------------
-- Dynamis - Divergence -- shared engine (relaunch custom)
--
-- One engine drives all four Dynamis [D] instances. Each zone's
-- instances/<name>.lua supplies a CONFIG table (mob IDs, unlock slot, exit point)
-- and delegates its instance callbacks here, so the wave / timer / unlock logic
-- lives in exactly one place and scales to all four cities.
--
-- Loop: enter -> Wave 1 (Squadron trash + time-extension statues + Mid-Boss)
--             -> Wave 2 (Regiment trash + Mega-Boss) -> complete -> slot unlock.
-- Statue kill = +1 min, Mid/Mega-Boss = +30 min (capped at 120). Medals drop from
-- the mobs themselves via mob_droplist (modules/custom/sql/dynamis_divergence.sql).
--
-- Entry is currency-trade + createInstance from the entry NPC (relaunch-friendly,
-- solo allowed). This engine only owns what happens once you are inside.
-----------------------------------
xi = xi or {}
xi.divergence = xi.divergence or {}

local TIME_CAP_MIN  = 120
local STATUE_EXTEND = 1
local BOSS_EXTEND   = 30
local EXIT_DELAY_MS = 8000

-- Armor slot -> bit in the player's 'DivergenceSlots' charVar.
-- Body reforge unlocks once all four (1|2|4|8 = 15) are set.
xi.divergence.slotBit = { feet = 1, hands = 2, head = 4, legs = 8 }

local function tell(instance, msg)
    for _, p in pairs(instance:getChars()) do
        p:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
    end
end

-- A pre-loaded instance entity reads as "not alive" before it is spawned, so only
-- call this on mobs the current wave has already spawned.
local function isDead(instance, mobid)
    local mob = GetMobByID(mobid, instance)
    return mob ~= nil and not mob:isAlive()
end

-- Extend the timer (capped) and refresh the on-screen countdown for everyone.
local function extendTime(instance, addMin, elapsed)
    local cur = instance:getTimeLimit()            -- minutes
    local new = math.min(TIME_CAP_MIN, cur + addMin)
    if new <= cur then
        return
    end
    instance:setTimeLimit(new * 60)                -- setter takes seconds
    local remaining = math.floor(new * 60 - elapsed / 1000)
    for _, p in pairs(instance:getChars()) do
        p:countdown(remaining)
    end
end

-----------------------------------
-- Lifecycle -- called from each zone's instances/<name>.lua
-----------------------------------
xi.divergence.onInstanceCreated = function(instance, cfg)
    instance:setLocalVar('divWave', 1)
    for _, mobId in ipairs(cfg.wave1Mobs) do
        SpawnMob(mobId, instance)
    end
    for _, mobId in ipairs(cfg.statues) do
        SpawnMob(mobId, instance)
    end
    SpawnMob(cfg.midBoss, instance)
end

xi.divergence.placePlayer = function(player, instance, cfg)
    player:setInstance(instance)
    local p = cfg.entryPos
    player:setPos(p[1], p[2], p[3], p[4], instance:getZone():getID())
end

xi.divergence.startCountdown = function(player)
    local instance = player:getInstance()
    if instance then
        player:countdown(instance:getTimeLimit() * 60)
    end
end

xi.divergence.onInstanceTimeUpdate = function(instance, elapsed, cfg)
    -- Hard time limit (rolled here so extensions are a one-liner).
    if instance:getTimeLimit() * 60 - elapsed / 1000 <= 0 then
        instance:fail()
        return
    end

    -- Time-extension statues -- credit each exactly once.
    for _, sid in ipairs(cfg.statues) do
        local key = 'st' .. sid
        if instance:getLocalVar(key) == 0 and isDead(instance, sid) then
            instance:setLocalVar(key, 1)
            extendTime(instance, STATUE_EXTEND, elapsed)
            tell(instance, '[Divergence] A statue crumbles -- time extended (+1 min).')
        end
    end

    local wave = instance:getLocalVar('divWave')
    if wave == 1 then
        if isDead(instance, cfg.midBoss) then
            instance:setLocalVar('divWave', 2)
            extendTime(instance, BOSS_EXTEND, elapsed)
            for _, mobId in ipairs(cfg.wave2Mobs) do
                SpawnMob(mobId, instance)
            end
            SpawnMob(cfg.megaBoss, instance)
            tell(instance, '[Divergence] The Mid-Boss falls! The Regiment and its Mega-Boss advance! (+30 min)')
        end
    elseif wave == 2 then
        if isDead(instance, cfg.megaBoss) then
            instance:setLocalVar('divWave', 3)
            instance:complete()
        end
    end
end

xi.divergence.onInstanceComplete = function(instance, cfg)
    local slotBit = xi.divergence.slotBit[cfg.entrySlot] or 0
    for _, p in pairs(instance:getChars()) do
        local slots = p:getCharVar('DivergenceSlots')
        if slotBit ~= 0 and bit.band(slots, slotBit) == 0 then
            slots = bit.bor(slots, slotBit)
            p:setCharVar('DivergenceSlots', slots)
            p:printToPlayer(string.format('[Divergence] Reforge unlocked: %s armor!', cfg.entrySlot:upper()), xi.msg.channel.SYSTEM_3)
            if bit.band(slots, 15) == 15 then
                p:printToPlayer('[Divergence] All four slots cleared -- BODY reforge unlocked!', xi.msg.channel.SYSTEM_3)
            end
        end
        p:printToPlayer('[Divergence] Victory! Returning you to San d\'Oria...', xi.msg.channel.SYSTEM_3)
        p:timer(EXIT_DELAY_MS, function(pp)
            local e = cfg.exitPos
            pp:setPos(e[1], e[2], e[3], e[4], cfg.exitZone)
        end)
    end
end

xi.divergence.onInstanceFailure = function(instance, cfg)
    for _, p in pairs(instance:getChars()) do
        p:printToPlayer('[Divergence] Time expired. Returning you to San d\'Oria...', xi.msg.channel.SYSTEM_3)
        p:timer(5000, function(pp)
            local e = cfg.exitPos
            pp:setPos(e[1], e[2], e[3], e[4], cfg.exitZone)
        end)
    end
end

return xi.divergence
