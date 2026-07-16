-----------------------------------
-- Abyssea marks encounter runtime
--
-- Listener-driven, owner-scoped mechanics for the marks-popped Abyssea
-- roster.  The encounter catalog supplies a distinct signature for every
-- logical NM; this module supplies the common telegraph/counter/failure
-- lifecycle without replacing the mobs' retail skill lists or scripts.
-----------------------------------

local M = {}

local states = {}

local LISTENERS =
{
    'ABY_MARKS_COMBAT',
    'ABY_MARKS_DAMAGE',
    'ABY_MARKS_WS',
    'ABY_MARKS_DEATH',
}

local function now()
    return os.time()
end

local function safeName(entity)
    local value
    pcall(function() value = entity:getName() end)
    return value or 'Abyssea NM'
end

local function ownerEntity(state)
    if not state or not state.ownerId then
        return nil
    end

    local player
    pcall(function() player = GetPlayerByID(state.ownerId) end)
    return player
end

local function ownerFor(state)
    local player = ownerEntity(state)
    return player and player:getHP() > 0 and player or nil
end

local function partyPCs(owner)
    local result = {}
    local seen = {}

    local function add(player)
        if not player then return end
        local ok, isPc = pcall(function() return player:isPC() end)
        if not ok or not isPc then return end
        local id = player:getID()
        if not seen[id] then
            seen[id] = true
            result[#result + 1] = player
        end
    end

    add(owner)
    local ok, party = pcall(function() return owner:getParty() end)
    if ok and party then
        for _, member in ipairs(party) do
            add(member)
        end
    end

    return result
end

local function announce(mob, state, message)
    if not message then return end

    local owner = ownerFor(state)
    if not owner then return end

    local prefix = string.format('[Abyssea: %s] ', state.cfg.label or safeName(mob):gsub('_', ' '))
    for _, player in ipairs(partyPCs(owner)) do
        pcall(function()
            if player:getZoneID() == mob:getZoneID() then
                player:printToPlayer(prefix .. message, xi.msg.channel.SYSTEM_1)
            end
        end)
    end
end

local function restoreVulnerability(mob, state)
    local vuln = state and state.vulnerability
    if not vuln then return end

    pcall(function()
        mob:addMod(xi.mod.DEF,  vuln.def or 0)
        mob:addMod(xi.mod.EVA,  vuln.eva or 0)
        mob:addMod(xi.mod.MDEF, vuln.mdef or 0)
    end)
    state.vulnerability = nil
end

local function openVulnerability(mob, state, reward)
    restoreVulnerability(mob, state)

    reward = reward or {}
    local tier = state.cfg.tier or 1
    local vuln =
    {
        def   = reward.def   or (200 + tier * 100),
        eva   = reward.eva   or (50  + tier * 50),
        mdef  = reward.mdef  or (20  + tier * 15),
        untilAt = now() + (reward.sec or 10),
    }

    pcall(function()
        mob:addMod(xi.mod.DEF,  -vuln.def)
        mob:addMod(xi.mod.EVA,  -vuln.eva)
        mob:addMod(xi.mod.MDEF, -vuln.mdef)
        mob:weaknessTrigger(reward.trigger or 2)
    end)
    state.vulnerability = vuln
end

local function removeEscalation(mob, state)
    if not state or (state.escalation or 0) <= 0 then return end

    local tier = state.cfg.tier or 1
    state.escalation = state.escalation - 1
    pcall(function()
        mob:addMod(xi.mod.ATT,  -(125 * tier))
        mob:addMod(xi.mod.MATT, -(40  * tier))
    end)
end

local function addEscalation(mob, state)
    local tier = state.cfg.tier or 1
    state.escalation = (state.escalation or 0) + 1
    pcall(function()
        mob:addMod(xi.mod.ATT, 125 * tier)
        mob:addMod(xi.mod.MATT, 40 * tier)
    end)
end

local function punishPlayer(mob, player, signature, tier)
    if not player then return end

    local fail = signature.failure or {}
    local damagePct = fail.damagePct or (8 + tier * 3)
    if damagePct > 0 then
        local damage = math.max(1, math.floor(player:getMaxHP() * damagePct / 100))
        pcall(function()
            player:takeDamage(damage, mob, xi.attackType.SPECIAL, xi.damageType.ELEMENTAL)
        end)
    end

    if fail.effect then
        pcall(function()
            player:addStatusEffect(fail.effect, fail.power or 1, 0, fail.duration or (4 + tier * 2))
        end)
    end
end

local function releaseFloor(mob, state)
    state.floorHpp = nil
end

local function counterSucceeded(mob, state, challenge)
    local signature = challenge.signature
    local player = ownerFor(state)
    if not player then return false end

    local kind = signature.kind
    if kind == 'turn' then
        return not player:isFacing(mob)
    elseif kind == 'face' then
        return player:isFacing(mob)
    elseif kind == 'rear' then
        return player:isBehind(mob, signature.angle or 48)
    elseif kind == 'near' then
        return player:checkDistance(mob) <= (signature.distance or 6)
    elseif kind == 'far' then
        return player:checkDistance(mob) >= (signature.distance or 12)
    elseif kind == 'move' then
        local dx = player:getXPos() - challenge.startX
        local dz = player:getZPos() - challenge.startZ
        return math.sqrt(dx * dx + dz * dz) >= (signature.distance or 8)
    elseif kind == 'hold' then
        return challenge.ownerDamage <= (signature.allowDamage or 0) and not challenge.wsUsed
    elseif kind == 'burst' then
        local required = math.floor(mob:getMaxHP() * (signature.damagePct or 3) / 100)
        return challenge.damageTaken >= required
    elseif kind == 'weaponskill' then
        return challenge.wsUsed
    elseif kind == 'highhp' then
        return player:getHPP() >= (signature.hpp or 65)
    elseif kind == 'lowhp' then
        return player:getHPP() <= (signature.hpp or 45)
    elseif kind == 'proc' then
        return challenge.procTriggered == true
    elseif kind == 'physical' then
        return challenge.physicalDamage > challenge.magicDamage
    elseif kind == 'magic' then
        return challenge.magicDamage > challenge.physicalDamage
    end

    -- Unknown mechanics fail closed so catalog mistakes are visible in testing.
    return false
end

local function finishChallenge(mob, state)
    local challenge = state.challenge
    if not challenge then return end

    local signature = challenge.signature
    if state.floorHpp then
        local player = ownerEntity(state)
        if player then
            player:setCharVar(
                string.format('AbyPhaseSecT%d', state.cfg.tier or 1),
                math.max(0, now() - challenge.startedAt))
        end
    end
    local success = counterSucceeded(mob, state, challenge)
    if success then
        announce(mob, state, signature.success or 'The opening is seized!')
        openVulnerability(mob, state, signature.reward)
        removeEscalation(mob, state)
    else
        announce(mob, state, signature.fail or 'The warning goes unanswered!')
        local player = ownerFor(state)
        punishPlayer(mob, player, signature, state.cfg.tier or 1)
        addEscalation(mob, state)
        if player then
            local tier = state.cfg.tier or 1
            local failVar = string.format('AbyFailT%d', tier)
            player:setCharVar(failVar, (player:getCharVar(failVar) or 0) + 1)
            if player:getHP() <= 0 then
                local deathVar = string.format('AbyMechDeathT%d', tier)
                player:setCharVar(deathVar, (player:getCharVar(deathVar) or 0) + 1)
            end
        end
    end

    state.challenge = nil
    releaseFloor(mob, state)
end

local function beginChallenge(mob, state, signature, floorHpp)
    if not signature or state.challenge then return end

    local owner = ownerFor(state)
    if not owner then return end

    state.floorHpp = floorHpp
    state.challenge =
    {
        signature      = signature,
        dueAt          = now() + (signature.delaySec or 5),
        startedAt      = now(),
        damageTaken    = 0,
        ownerDamage    = 0,
        physicalDamage = 0,
        magicDamage    = 0,
        wsUsed         = false,
        procTriggered  = false,
        startX         = owner:getXPos(),
        startZ         = owner:getZPos(),
    }

    announce(mob, state, signature.tell)
    pcall(function() mob:weaknessTrigger(signature.telegraphTrigger or 1) end)
end

local function triggerNextPhase(mob, state)
    if state.challenge then return end

    local phases = state.cfg.phases or {}
    local phase = phases[state.nextPhase or 1]
    if not phase or mob:getHPP() > phase.hp then return end

    state.nextPhase = (state.nextPhase or 1) + 1
    beginChallenge(mob, state, phase, phase.hp)
end

local function enforceFloor(mob, state)
    if not state.floorHpp then return end

    local floorHp = math.max(1, math.floor(mob:getMaxHP() * state.floorHpp / 100))
    if mob:getHP() < floorHp then
        mob:setHP(floorHp)
    end
end

local function pressureTick(mob, state, stamp)
    if stamp < state.pressureAt then return end

    local tier = state.cfg.tier or 1
    local stacks = state.pressureStacks or 0
    if stacks == 0 then
        announce(mob, state, state.cfg.pressureMessage or 'The abyss begins to close in!')
        local player = ownerEntity(state)
        if player then
            local tier = state.cfg.tier or 1
            local enrageVar = string.format('AbyEnrageT%d', tier)
            player:setCharVar(enrageVar, (player:getCharVar(enrageVar) or 0) + 1)
        end
    end

    state.pressureStacks = stacks + 1
    state.pressureAt = stamp + (state.cfg.pressureStepSec or 30)
    pcall(function()
        mob:addMod(xi.mod.ATT,  175 * tier)
        mob:addMod(xi.mod.MATT, 55  * tier)
        mob:addMod(xi.mod.HASTE_GEAR, 25)
    end)
end

local function combatTick(mob)
    local state = states[mob:getID()]
    if not state then return end

    local stamp = now()
    if state.vulnerability and stamp >= state.vulnerability.untilAt then
        restoreVulnerability(mob, state)
    end

    if state.challenge and stamp >= state.challenge.dueAt then
        finishChallenge(mob, state)
    elseif
        state.challenge and
        (state.challenge.signature.kind == 'move' or
            state.challenge.signature.kind == 'weaponskill') and
        counterSucceeded(mob, state, state.challenge)
    then
        finishChallenge(mob, state)
    end

    triggerNextPhase(mob, state)

    if
        not state.challenge and
        state.cfg.signature and
        state.nextSignatureAt and
        stamp >= state.nextSignatureAt
    then
        beginChallenge(mob, state, state.cfg.signature, nil)
        state.nextSignatureAt = stamp + (state.cfg.repeatSec or 45)
    end

    pressureTick(mob, state, stamp)
    enforceFloor(mob, state)
end

local function damageTaken(mob, amount, attacker, attackType)
    local state = states[mob:getID()]
    if not state then return end

    local challenge = state.challenge
    if challenge and amount and amount > 0 then
        challenge.damageTaken = challenge.damageTaken + amount
        local attackerIsPc = false
        pcall(function() attackerIsPc = attacker:isPC() end)
        if attackerIsPc and attacker:getID() == state.ownerId then
            challenge.ownerDamage = challenge.ownerDamage + amount
            -- Hold-fire signatures are true absorption windows, not merely a
            -- delayed pass/fail quiz. Trust and pet auto-attacks are ignored so
            -- a solo player can execute the mechanic without dismissing them.
            if challenge.signature.kind == 'hold' then
                pcall(function() mob:addHP(amount) end)
            end
        end
        if attackType == xi.attackType.PHYSICAL or attackType == xi.attackType.RANGED then
            challenge.physicalDamage = challenge.physicalDamage + amount
        else
            challenge.magicDamage = challenge.magicDamage + amount
        end

        enforceFloor(mob, state)
        if
            challenge.signature.kind == 'burst' and
            counterSucceeded(mob, state, challenge)
        then
            finishChallenge(mob, state)
            return
        end
    end

    enforceFloor(mob, state)
    triggerNextPhase(mob, state)
end

local function weaponskillTaken(user, mob)
    local state = states[mob:getID()]
    local userIsPc = false
    pcall(function() userIsPc = user:isPC() end)
    if
        state and
        state.challenge and
        userIsPc and
        user:getID() == state.ownerId
    then
        state.challenge.wsUsed = true
    end
end

function M.attach(mob, cfg, owner)
    if not mob or not cfg or not owner then return end

    M.cleanup(mob)

    local stamp = now()
    states[mob:getID()] =
    {
        cfg             = cfg,
        ownerId         = owner:getID(),
        startedAt       = stamp,
        nextPhase       = 1,
        nextSignatureAt = stamp + (cfg.firstSignatureSec or 20),
        pressureAt      = stamp + (cfg.pressureSec or 720),
        pressureStacks  = 0,
        escalation      = 0,
        procs            = {},
    }
    local state = states[mob:getID()]

    local hour = VanadielHour()
    local blueFamily = 'blunt'
    if hour >= 6 and hour < 14 then
        blueFamily = 'piercing'
    elseif hour >= 14 and hour < 22 then
        blueFamily = 'slashing'
    end
    announce(
        mob,
        state,
        string.format(
            'Abyssite hint — red: elemental WS; yellow: current/adjacent-day spell; blue: %s WS.',
            blueFamily))

    mob:addListener('COMBAT_TICK', LISTENERS[1], function(mobArg)
        combatTick(mobArg)
    end)
    mob:addListener('TAKE_DAMAGE', LISTENERS[2], function(mobArg, amount, attacker, attackType)
        damageTaken(mobArg, amount, attacker, attackType)
    end)
    mob:addListener('WEAPONSKILL_TAKE', LISTENERS[3], function(user, target)
        weaponskillTaken(user, target)
    end)
    mob:addListener('DEATH', LISTENERS[4], function(mobArg)
        local state = states[mobArg:getID()]
        local player = ownerEntity(state)
        if state and player then
            local duration = math.max(0, now() - state.startedAt)
            local tier = state.cfg.tier or 1
            player:setCharVar(string.format('AbyLastSecT%d', tier), duration)
            player:setCharVar(
                string.format('AbyKillsT%d', tier),
                (player:getCharVar(string.format('AbyKillsT%d', tier)) or 0) + 1)
        end
        M.cleanup(mobArg)
    end)
end

function M.onProc(mob, player, triggerType)
    if not mob then return end
    local state = states[mob:getID()]
    if not state then return end
    if state.procs[triggerType] then return end
    state.procs[triggerType] = true

    if state.challenge then
        state.challenge.procTriggered = true
    end

    local reward
    local message
    if triggerType == xi.abyssea.triggerType.RED then
        reward = { def = 450, eva = 150, mdef = 45, sec = 15, trigger = 2 }
        message = 'Ruby weakness shatters its escalation!'
    elseif triggerType == xi.abyssea.triggerType.YELLOW then
        reward = { def = 150, eva = 75, mdef = 80, sec = 12, trigger = 1 }
        message = 'Amber weakness suppresses its sorcery!'
        pcall(function() mob:addStatusEffect(xi.effect.SILENCE, 1, 0, 12) end)
    else
        reward = { def = 550, eva = 175, mdef = 20, sec = 12, trigger = 0 }
        message = 'Azure weakness suppresses its technique!'
        pcall(function() mob:addStatusEffect(xi.effect.AMNESIA, 1, 0, 12) end)
    end

    announce(mob, state, message)
    openVulnerability(mob, state, reward)
    removeEscalation(mob, state)

    local telemetryPlayer = ownerEntity(state)
    if telemetryPlayer then
        local suffix = triggerType == xi.abyssea.triggerType.RED and 'Red'
            or triggerType == xi.abyssea.triggerType.YELLOW and 'Yellow'
            or 'Blue'
        local procVar = 'AbyProc' .. suffix
        telemetryPlayer:setCharVar(procVar, (telemetryPlayer:getCharVar(procVar) or 0) + 1)
    end
end

function M.getState(mob)
    return mob and states[mob:getID()] or nil
end

function M.cleanup(mob)
    if not mob then return end

    local id = mob:getID()
    local state = states[id]
    if state then
        restoreVulnerability(mob, state)
        local tier = state.cfg.tier or 1
        local escalation = state.escalation or 0
        if escalation > 0 then
            pcall(function()
                mob:addMod(xi.mod.ATT,  -(125 * tier * escalation))
                mob:addMod(xi.mod.MATT, -(40  * tier * escalation))
            end)
        end
        local pressure = state.pressureStacks or 0
        if pressure > 0 then
            pcall(function()
                mob:addMod(xi.mod.ATT,        -(175 * tier * pressure))
                mob:addMod(xi.mod.MATT,       -(55  * tier * pressure))
                mob:addMod(xi.mod.HASTE_GEAR, -(25 * pressure))
            end)
        end
    end

    states[id] = nil
    for _, listener in ipairs(LISTENERS) do
        pcall(function() mob:removeListener(listener) end)
    end
end

return M
