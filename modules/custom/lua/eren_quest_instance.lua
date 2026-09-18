-----------------------------------
-- The Name Beyond the Ferry -- private encounter runtime
--
-- One hybrid Ghelsba Outpost instance template hosts every quest encounter.
-- The selected encounter is copied into instance local state before zoning,
-- then dynamically builds its own waves.  Each copy is private to one player
-- and their Adventuring Fellow.
-----------------------------------
local catalog = require('modules/custom/lua/eren_quest_catalog')

local KEY = 'modules/custom/lua/eren_quest_instance'
local R = package.loaded[KEY]
if type(R) ~= 'table' then
    R = {}
end
package.loaded[KEY] = R

local SYS = xi.msg.channel.SYSTEM_3
local GROUP_ZONE = 210
local MOB_GROUPS = { 11360, 11361, 11363, 11364, 11365, 11366, 11367, 11368, 11369 }

R.copySequence = tonumber(R.copySequence) or 0
R.sessions = R.sessions or {}

local function say(player, text)
    player:printToPlayer('[Beyond the Ferry] ' .. text, SYS)
end

local function forEachPlayer(instance, fn)
    for _, player in ipairs(instance:getChars()) do
        if player:getObjType() == xi.objType.PC then
            fn(player)
        end
    end
end

local function ownerOf(entity)
    if not entity then
        return nil, nil
    end

    local isPc = false
    pcall(function() isPc = entity:isPC() end)
    if isPc then
        return entity, 'player'
    end

    local owner
    pcall(function() owner = entity:getMaster() end)
    if not owner then
        return nil, nil
    end

    local ownerIsPc = false
    pcall(function() ownerIsPc = owner:isPC() end)
    if not ownerIsPc then
        return nil, nil
    end

    local isFellow = false
    pcall(function() isFellow = entity:getLocalVar('fellowApplied') == 1 end)
    return owner, isFellow and 'fellow' or 'companion'
end

local function isGrouped(player)
    local grouped = false
    local inspectedParty = false
    pcall(function()
        local party = player:getParty()
        if party then
            inspectedParty = true
            for _, member in ipairs(party) do
                if member:getObjType() == xi.objType.PC and member:getID() ~= player:getID() then
                    grouped = true
                end
            end
        end
    end)
    if not inspectedParty then
        pcall(function() grouped = (player:getPartySize() or 1) > 1 end)
    end
    pcall(function()
        local alliance = player:getAlliance()
        if alliance then
            for _, member in ipairs(alliance) do
                if member:getObjType() == xi.objType.PC and member:getID() ~= player:getID() then
                    grouped = true
                end
            end
        end
    end)
    return grouped
end

local function dismissOrdinaryTrusts(player)
    local party = {}
    pcall(function() party = player:getPartyWithTrusts() or {} end)
    for _, member in ipairs(party) do
        pcall(function()
            if member:isTrust() and member:getLocalVar('fellowApplied') ~= 1 then
                local owner = member:getMaster()
                if owner then
                    owner:despawnTrust(member)
                end
            end
        end)
    end
end

local function hasOrdinaryTrust(player)
    local found = false
    local party = {}
    pcall(function() party = player:getPartyWithTrusts() or {} end)
    for _, member in ipairs(party) do
        pcall(function()
            if member:isTrust() and member:getLocalVar('fellowApplied') ~= 1 then
                found = true
            end
        end)
    end
    return found
end

local function restoreRole(player)
    local saved = player:getCharVar(catalog.vars.savedRole) or 0
    if saved > 0 then
        player:setCharVar('Fellow_Role', saved - 1)
        player:setCharVar(catalog.vars.savedRole, 0)
        if xi.fellow and xi.fellow.respawnIfOut then
            pcall(function() xi.fellow.respawnIfOut(player) end)
        end
    end
end

local function clearRunState(player)
    restoreRole(player)
    if (player:getLocalVar('ErenQuestDecay') or 0) == 1 then
        pcall(function() player:delStatusEffectSilent(xi.effect.DIA) end)
        player:setLocalVar('ErenQuestDecay', 0)
    end
    if (player:getLocalVar('ErenQuestBind') or 0) == 1 then
        pcall(function() player:delStatusEffectSilent(xi.effect.BIND) end)
        player:setLocalVar('ErenQuestBind', 0)
    end
    player:setCharVar(catalog.vars.encounter, 0)
    player:setCharVar(catalog.vars.pending, 0)
    player:setCharVar(catalog.vars.active, 0)
end

local function returnToHades(player, message)
    clearRunState(player)
    if message then
        say(player, message)
    end
    player:setPos(642.8, 0.3, 566.0, 96, catalog.entranceZone)
end

local function currentSession(instance)
    local ownerId = instance:getLocalVar('ErenOwnerId')
    return R.sessions[ownerId]
end

local function delay(instance, milliseconds, callback)
    local session = currentSession(instance)
    if not session or not session.owner then
        return
    end
    session.owner:timer(milliseconds, function()
        if currentSession(instance) == session and not session.finishing then
            callback()
        end
    end)
end

local function removeSession(instance)
    local ownerId = instance:getLocalVar('ErenOwnerId')
    R.sessions[ownerId] = nil
end

local function finish(instance)
    local session = currentSession(instance)
    if not session or session.finishing then
        return
    end
    session.finishing = true

    forEachPlayer(instance, function(player)
        local credited = session.definition.checkpoint ~= false and
            catalog.creditEncounter(player, session.encounterId)
        if session.definition.checkpoint == false then
            say(player, 'The corrective memory yields its lesson, but the memorial must still be reconstructed.')
        elseif credited then
            say(player, session.definition.label .. ' is complete. The memory holds.')
        else
            say(player, 'The encounter closed, but its quest state had already moved on.')
        end
        clearRunState(player)
    end)

    instance:setLocalVar('ErenReturnAtMs', instance:getLocalVar('ErenElapsedMs') + 8000)
    instance:complete()
end

local function fail(instance, reason)
    local session = currentSession(instance)
    if session and session.finishing then
        return
    end
    if session then
        session.finishing = true
    end
    instance:setLocalVar('ErenFailReason', reason or 1)
    instance:fail()
end

local function mobPosition(index)
    local center = catalog.encounterPos.center
    local positions =
    {
        { center.x,      center.y, center.z,      center.rot },
        { center.x + 5,  center.y, center.z + 5,  160 },
        { center.x + 5,  center.y, center.z - 5,   96 },
        { center.x - 4,  center.y, center.z + 7,  192 },
        { center.x - 4,  center.y, center.z - 7,   64 },
        { center.x + 10, center.y, center.z,      128 },
    }
    return positions[((index - 1) % #positions) + 1]
end

local function applyStats(mob, hp, level, boss)
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
    mob:setMaxHP(hp)
    mob:setHP(hp)
    mob:setMod(xi.mod.ATT, boss and 6000 or 4300)
    mob:setMod(xi.mod.ACC, boss and 3400 or 2800)
    mob:setMod(xi.mod.DEF, boss and 4300 or 3000)
    mob:setMod(xi.mod.MDEF, boss and 2300 or 1500)
    mob:setMod(xi.mod.MEVA, boss and 1800 or 1200)
    mob:setMod(xi.mod.REGAIN, boss and 150 or 75)
    mob:setLocalVar('ErenQuestLevel', level)
end

local function newMob(instance, session, spec)
    R.copySequence = R.copySequence + 1
    local pos = spec.pos or mobPosition(#session.entities + 1)
    local scriptName = string.format('EQ_%u_%u', session.ownerId, R.copySequence)
    local mob = instance:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = spec.groupId or MOB_GROUPS[((R.copySequence - 1) % #MOB_GROUPS) + 1],
        groupZoneId          = GROUP_ZONE,
        name                 = scriptName,
        packetName           = spec.name,
        x                    = pos[1],
        y                    = pos[2],
        z                    = pos[3],
        rotation             = pos[4] or 128,
        minLevel             = spec.level or session.definition.level,
        maxLevel             = spec.level or session.definition.level,
        skillList            = spec.skillList or 0,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobFight = function(fighting, target)
            local live = currentSession(instance)
            if not live or live.finishing then
                return
            end

            if spec.onFight then
                spec.onFight(fighting, target, live)
            end
        end,

        onMobDeath = function(deadMob, killer)
            local live = currentSession(instance)
            if not live or live.finishing or deadMob:getLocalVar('EQDeathHandled') == 1 then
                return
            end
            deadMob:setLocalVar('EQDeathHandled', 1)

            if spec.requiredSource then
                local required = math.floor(deadMob:getMaxHP() * (spec.requiredPct or 30) / 100)
                if deadMob:getLocalVar('EQRequiredDamage') < required then
                    say(live.owner, string.format(
                        '%s fell before %s completed their part. The memory rejects the result.',
                        deadMob:getPacketName(),
                        spec.requiredSource == 'fellow' and 'the Fellow' or 'the player'))
                    fail(instance, 12)
                    return
                end
            end
            if spec.validateDeath and not spec.validateDeath(deadMob, live) then
                fail(instance, 13)
                return
            end

            if spec.onDeath then
                spec.onDeath(deadMob, killer, live)
            elseif live.onMobDeath then
                live.onMobDeath(deadMob, killer)
            end
        end,
    })

    if not mob then
        fail(instance, 2)
        return nil
    end

    mob:setSpawn(pos[1], pos[2], pos[3], pos[4] or 128)
    mob:spawn()
    applyStats(mob, spec.hp or session.definition.hp, spec.level or session.definition.level, spec.boss)
    if spec.model then
        mob:setModelId(spec.model)
    end
    if spec.size then
        mob:setModelSize(spec.size)
    end
    if spec.regen then
        mob:setMod(xi.mod.REGEN, spec.regen)
    end
    mob:addEnmity(session.owner, 30000, 30000)
    if spec.requiredSource then
        local required = spec.requiredSource
        mob:addListener('TAKE_DAMAGE', 'EQ_SOURCE_' .. tostring(mob:getID()), function(target, amount, attacker)
            local owner, kind = ownerOf(attacker)
            if owner and owner:getName() == session.ownerName and kind == required then
                target:setLocalVar('EQRequiredDamage',
                    target:getLocalVar('EQRequiredDamage') + math.max(0, amount or 0))
            end
        end)
    end
    if spec.onSpawn then
        spec.onSpawn(mob, session)
    end

    session.entities[#session.entities + 1] = mob
    return mob
end

local function alive(entity)
    if not entity then
        return false
    end
    local hp = 0
    return pcall(function() hp = entity:getHP() end) and hp > 0
end

local function spawnWaveSequence(instance, session, waves, finalText)
    local waveIndex = 0
    local remaining = 0

    local function nextWave()
        local live = currentSession(instance)
        if not live or live.finishing then
            return
        end

        waveIndex = waveIndex + 1
        local wave = waves[waveIndex]
        if not wave then
            if finalText then
                forEachPlayer(instance, function(player) say(player, finalText) end)
            end
            finish(instance)
            return
        end

        remaining = #wave
        forEachPlayer(instance, function(player)
            say(player, string.format('Wave %d/%d: %s', waveIndex, #waves, wave.text or 'The echo advances.'))
        end)
        for _, spec in ipairs(wave) do
            local original = spec.onDeath
            spec.onDeath = function(mob, killer, liveSession)
                if original then
                    original(mob, killer, liveSession)
                end
                remaining = remaining - 1
                if remaining <= 0 then
                    if wave.onClear then
                        wave.onClear(liveSession)
                    end
                    delay(instance, 2000, nextWave)
                end
            end
            newMob(instance, session, spec)
        end
        if wave.onStart then
            wave.onStart(live)
        end
    end

    session.onMobDeath = function()
        remaining = remaining - 1
        if remaining <= 0 then
            delay(instance, 2000, nextWave)
        end
    end
    nextWave()
end

local function basicWaves(instance, session, names, perWave)
    local waves = {}
    for index, name in ipairs(names) do
        local wave = { text = name }
        for mobIndex = 1, (perWave or 1) do
            wave[#wave + 1] =
            {
                name = name .. (perWave and perWave > 1 and (' ' .. mobIndex) or ''),
                hp = math.floor(session.definition.hp / math.max(1, perWave or 1)),
                boss = index == #names and (perWave or 1) == 1,
            }
        end
        waves[#waves + 1] = wave
    end
    spawnWaveSequence(instance, session, waves)
end

local function spawnDiscernment(instance, session)
    local trueShade
    local falseKilled = 0
    local specs =
    {
        { name = 'Silent Shade', trueOne = false },
        { name = 'Shade of the North Star', trueOne = true, boss = true, requiredSource = 'fellow', requiredPct = 25 },
        { name = 'Hollow Shade', trueOne = false },
    }

    for _, spec in ipairs(specs) do
        local entry = spec
        entry.hp = entry.trueOne and session.definition.hp or math.floor(session.definition.hp * 0.35)
        entry.onDeath = function(_, _, live)
            if entry.trueOne then
                say(live.owner, 'The Hunter marked what was real. The false silhouettes collapse.')
                finish(instance)
            else
                falseKilled = falseKilled + 1
                if alive(trueShade) then
                    trueShade:setHP(math.min(trueShade:getMaxHP(), trueShade:getHP() + math.floor(trueShade:getMaxHP() * 0.25)))
                end
                say(live.owner, 'A false shade breaks. The true memory drinks its strength.')
                if falseKilled >= 2 then
                    say(live.owner, 'Only the shade named for the north star carries Eren\'s footprint.')
                end
            end
        end
        local spawned = newMob(instance, session, entry)
        if entry.trueOne then
            trueShade = spawned
        end
    end
end

local function spawnBond(instance, session)
    local phase = 1

    local function roomThree()
        phase = 3
        say(session.owner, 'Room three: break the crossing anchors while your Fellow holds the route.')
        basicWaves(instance, session, { 'First Crossing Anchor', 'Second Crossing Anchor', 'Heart of the Passage' }, 1)
    end

    local function roomTwo()
        phase = 2
        say(session.owner, 'Room two: the linked keepers must fall within ten seconds of one another.')
        local deadAt = nil
        local deadCount = 0
        local generation = 0

        local function spawnPair()
            generation = generation + 1
            local thisGeneration = generation
            deadAt = nil
            deadCount = 0
            for index = 1, 2 do
                newMob(instance, session, {
                    name = index == 1 and 'Keeper of Breath' or 'Keeper of Blood',
                    hp = session.definition.hp,
                    boss = true,
                    onDeath = function()
                        if thisGeneration ~= generation then
                            return
                        end
                        deadCount = deadCount + 1
                        if deadCount == 1 then
                            deadAt = os.time()
                            say(session.owner, 'The surviving keeper strains against the link. Ten seconds!')
                            delay(instance, 10000, function()
                                if
                                    currentSession(instance) == session and
                                    not session.finishing and
                                    thisGeneration == generation and
                                    deadCount == 1
                                then
                                    say(session.owner, 'The link reforms. The second room resets.')
                                    generation = generation + 1
                                    for _, entity in ipairs(session.entities) do
                                        if alive(entity) then
                                            entity:setHP(0)
                                        end
                                    end
                                    delay(instance, 2000, spawnPair)
                                end
                            end)
                        elseif deadCount == 2 and os.time() - (deadAt or 0) <= 10 then
                            delay(instance, 2500, roomThree)
                        end
                    end,
                })
            end
        end
        spawnPair()
    end

    local remaining = 2
    local playerWard = newMob(instance, session, {
        name = 'Ward of the Living',
        hp = session.definition.hp,
        boss = true,
        requiredSource = 'player',
        requiredPct = 40,
        onDeath = function()
            remaining = remaining - 1
            if remaining == 0 and phase == 1 then
                delay(instance, 2500, roomTwo)
            end
        end,
    })
    local fellowWard = newMob(instance, session, {
        name = 'Ward of the Bond',
        hp = session.definition.hp,
        boss = true,
        requiredSource = 'fellow',
        requiredPct = 40,
        onDeath = function()
            remaining = remaining - 1
            if remaining == 0 and phase == 1 then
                delay(instance, 2500, roomTwo)
            end
        end,
    })
    utils.unused(playerWard, fellowWard)
    say(session.owner, 'Room one: you must deal at least 40% of one ward; your Fellow must deal at least 40% of the other.')
end

local function spawnEren(instance, session)
    local aspectNames =
    {
        'Aspect of Resolve',
        'Aspect of Guardianship',
        'Aspect of Discernment',
        'Aspect of Insight',
        'Aspect of Fury',
        'Aspect of Mercy',
    }
    local waves = {}
    for _, name in ipairs(aspectNames) do
        waves[#waves + 1] =
        {
            text = name .. ' remembers you.',
            { name = name, hp = math.floor(session.definition.hp * 0.32), boss = true },
        }
    end
    waves[#waves + 1] =
    {
        text = 'Eren binds your Fellow. Break both soul chains.',
        onStart = function(live)
            local fellow = xi.fellow and xi.fellow.getTrust and xi.fellow.getTrust(live.owner)
            if fellow then
                fellow:addStatusEffect(xi.effect.BIND, 1, 0, 120)
            end
        end,
        onClear = function(live)
            local fellow = xi.fellow and xi.fellow.getTrust and xi.fellow.getTrust(live.owner)
            if fellow then
                fellow:delStatusEffectSilent(xi.effect.BIND)
            end
        end,
        { name = 'Soul Chain of Fear', hp = math.floor(session.definition.hp * 0.28), requiredSource = 'player', requiredPct = 50 },
        { name = 'Soul Chain of Oblivion', hp = math.floor(session.definition.hp * 0.28), requiredSource = 'player', requiredPct = 50 },
    }
    waves[#waves + 1] =
    {
        text = 'Now the player is bound. Trust the one who has crossed every memory beside you.',
        onStart = function(live)
            live.owner:setLocalVar('ErenQuestBind', 1)
            live.owner:addStatusEffect(xi.effect.BIND, 1, 0, 120)
        end,
        onClear = function(live)
            live.owner:delStatusEffectSilent(xi.effect.BIND)
            live.owner:setLocalVar('ErenQuestBind', 0)
        end,
        {
            name = 'Eren, Unwhole',
            hp = session.definition.hp,
            boss = true,
            model = 2674,
            skillList = 485,
            size = 2,
            requiredSource = 'fellow',
            requiredPct = 20,
        },
    }
    spawnWaveSequence(instance, session, waves,
        'Eren lowers his hands. "I feared restoration because I would erase another soul. You have shown me a bond that survives change."')
end

local function spawnCrossing(instance, session)
    local waves =
    {
        {
            text = 'The nameless dead press against the first gate.',
            { name = 'Uncrossed Sorrow', hp = 420000 },
            { name = 'Uncrossed Anger', hp = 420000 },
            { name = 'Uncrossed Fear', hp = 420000 },
        },
        {
            text = 'Two chains divide the living from the remembered.',
            { name = 'Chain of the Living', hp = 1200000, requiredSource = 'player', requiredPct = 50 },
            { name = 'Chain of the Remembered', hp = 1200000, requiredSource = 'fellow', requiredPct = 50 },
        },
        {
            text = 'The Last Uncrossed takes the shape of Eren\'s guilt.',
            {
                name = 'The Last Uncrossed',
                hp = session.definition.hp,
                boss = true,
                size = 3,
                onFight = function(mob)
                    local fellow = xi.fellow and xi.fellow.getTrust and xi.fellow.getTrust(session.owner)
                    local close = fellow and session.owner:checkDistance(fellow) <= 10
                    mob:setMod(xi.mod.REGEN, close and 0 or 8000)
                    if not close and mob:getLocalVar('EQFarWarning') == 0 then
                        mob:setLocalVar('EQFarWarning', 1)
                        say(session.owner, 'The Last Uncrossed feeds on the distance between you. Stand within ten yalms of your Fellow.')
                        mob:timer(8000, function(entity) entity:setLocalVar('EQFarWarning', 0) end)
                    end
                    local pct = mob:getHPP()
                    if pct <= 65 and mob:getLocalVar('EQCrossing65') == 0 then
                        mob:setLocalVar('EQCrossing65', 1)
                        say(session.owner, 'The crossing shudders. Stay close to your Fellow; the link shares what would break one soul alone.')
                        session.owner:addStatusEffect(xi.effect.PHYSICAL_SHIELD, 1, 0, 12)
                    elseif pct <= 30 and mob:getLocalVar('EQCrossing30') == 0 then
                        mob:setLocalVar('EQCrossing30', 1)
                        say(session.owner, 'Hades: "Together. Break the final hold together."')
                    end
                end,
            },
        },
    }
    spawnWaveSequence(instance, session, waves,
        'The manifestation opens its hands. The trapped souls pass through it, and Eren\'s oldest failure finally ends.')
end

local function spawnScenario(instance, session)
    local id = session.encounterId
    local definition = session.definition
    say(session.owner, definition.label .. ' begins. Failure loses no items or progress already banked.')

    if id == 1 then
        basicWaves(instance, session, { 'The First Lamp', 'The Broken Oath', 'Memorial Remorse' }, 1)
    elseif id == 2 then
        basicWaves(instance, session, { 'Memory Assailants', 'Frozen Doubt', 'The Promise Kept' }, 2)
    elseif id == 3 then
        basicWaves(instance, session, { 'The Trace-Eater' }, 1)
    elseif id == 4 then
        basicWaves(instance, session, { 'Those Eren Carried', 'Those Eren Lost', 'The Footprint That Remained' }, 2)
    elseif id == 5 then
        basicWaves(instance, session, { 'The Order Remembered' }, 1)
    elseif id == 10 then
        spawnWaveSequence(instance, session, {
            { text = 'Control the executioner and open the ward.', { name = 'Memory Executioner', hp = 2000000, boss = true } },
            {
                text = 'The Vanguard sees the breach. Only your Fellow can break the gate.',
                { name = 'Warded Gate', hp = definition.hp, boss = true, requiredSource = 'fellow' },
            },
        })
    elseif id == 11 then
        local warden
        local soulsRemaining = 3
        warden = newMob(instance, session, {
            name = 'Remembrance Warden',
            hp = definition.hp * 2,
            boss = true,
            regen = 5000,
            onSpawn = function(mob)
                local fellow = xi.fellow and xi.fellow.getTrust and xi.fellow.getTrust(session.owner)
                if fellow then
                    mob:addEnmity(fellow, 60000, 60000)
                end
            end,
            onFight = function(mob, target)
                local owner, kind = ownerOf(target)
                if owner and owner:getName() == session.ownerName and kind == 'fellow' then
                    mob:setLocalVar('EQBulwarkHeld', mob:getLocalVar('EQBulwarkHeld') + 1)
                end
            end,
            onDeath = function()
                say(session.owner, 'The Warden was meant to be held, not destroyed. The memory collapses.')
                fail(instance, 14)
            end,
        })
        for index = 1, 3 do
            newMob(instance, session, {
                name = 'Bound Soul ' .. index,
                hp = 1000000,
                requiredSource = 'player',
                requiredPct = 30,
                onDeath = function()
                    soulsRemaining = soulsRemaining - 1
                    if soulsRemaining == 0 then
                        if alive(warden) and warden:getLocalVar('EQBulwarkHeld') >= 5 then
                            say(session.owner, 'The Bulwark holds. All three souls are released behind its shield.')
                            finish(instance)
                        else
                            say(session.owner, 'The souls opened, but the Bulwark did not hold the Warden long enough.')
                            fail(instance, 14)
                        end
                    end
                end,
            })
        end
        say(session.owner, 'The Bulwark must hold the Warden while you release all three bound souls. Do not kill the Warden.')
    elseif id == 12 then
        spawnDiscernment(instance, session)
    elseif id == 13 then
        spawnWaveSequence(instance, session, {
            {
                text = 'The Magus must shatter all four elemental seals with its own attacks.',
                { name = 'Flame Seal', hp = 1000000, requiredSource = 'fellow' },
                { name = 'Frost Seal', hp = 1000000, requiredSource = 'fellow' },
                { name = 'Gale Seal', hp = 1000000, requiredSource = 'fellow' },
                { name = 'Stone Seal', hp = 1000000, requiredSource = 'fellow' },
            },
            {
                text = 'The shared ward reforms. Break the confluence together.',
                { name = 'Confluence Ward I', hp = 1000000 },
                { name = 'Confluence Ward II', hp = 1000000 },
                { name = 'Confluence Ward III', hp = 1000000 },
                { name = 'Confluence Ward IV', hp = 1000000 },
            },
        })
    elseif id == 14 then
        local woundMob = newMob(instance, session, {
            name = 'The Regenerating Devourer',
            hp = definition.hp,
            boss = true,
            regen = 9000,
            onFight = function(mob)
                local open = math.floor(os.time() / 12) % 2 == 1
                local wasOpen = mob:getLocalVar('EQWoundOpen') == 1
                if open ~= wasOpen then
                    mob:setLocalVar('EQWoundOpen', open and 1 or 0)
                    mob:setMod(xi.mod.REGEN, open and 0 or 9000)
                    say(session.owner, open and 'The wound opens—press the Berserker\'s attack!' or 'The wound seals and the Devourer begins to regenerate.')
                end
            end,
            requiredSource = 'fellow',
            requiredPct = 30,
            onDeath = function() finish(instance) end,
        })
        if woundMob then
            say(session.owner, 'The Devourer can only be outpaced while its wound is open.')
        end
    elseif id == 15 then
        session.owner:setLocalVar('ErenQuestDecay', 1)
        session.owner:addStatusEffect(xi.effect.DIA, 25, 3, 180)
        spawnWaveSequence(instance, session, {
            {
                text = 'Crossing decay begins. The Oracle must sustain you while both partners close the first rifts.',
                { name = 'First Rift I', hp = 1500000, requiredSource = 'fellow', requiredPct = 20 },
                { name = 'First Rift II', hp = 1500000, requiredSource = 'player', requiredPct = 20 },
            },
            {
                text = 'The decay deepens. Close the second pair.',
                { name = 'Second Rift I', hp = 1500000, requiredSource = 'fellow', requiredPct = 20 },
                { name = 'Second Rift II', hp = 1500000, requiredSource = 'player', requiredPct = 20 },
            },
            {
                text = 'Mercy is not surrender. End the decay together.',
                { name = 'Crossing Decay I', hp = 1500000, requiredSource = 'fellow', requiredPct = 20 },
                { name = 'Crossing Decay II', hp = 1500000, requiredSource = 'player', requiredPct = 20 },
            },
        })
    elseif id == 20 then
        spawnBond(instance, session)
    elseif id == 30 then
        spawnEren(instance, session)
    elseif id == 40 then
        spawnCrossing(instance, session)
    else
        fail(instance, 3)
    end
end

function R.start(player, encounterId)
    encounterId = tonumber(encounterId)
    catalog.reconcile(player)
    local definition = encounterId and catalog.encounters[encounterId] or nil
    if not definition or not catalog.encounterAvailable(player, encounterId) then
        return false, 'That encounter is not available at your current quest stage.'
    elseif player:getInstance() then
        return false, 'You are already inside an instance.'
    end

    dismissOrdinaryTrusts(player)
    if isGrouped(player) then
        return false, 'Leave your party or alliance. These memories admit only you and your Fellow.'
    end

    player:setCharVar(catalog.vars.encounter, encounterId)
    player:setCharVar(catalog.vars.pending, catalog.instanceId)
    player:setCharVar(catalog.vars.active, 0)

    if definition.role then
        local currentRole = player:getCharVar('Fellow_Role') or 0
        player:setCharVar(catalog.vars.savedRole, currentRole + 1)
        player:setCharVar('Fellow_Role', catalog.roleIndex[definition.role])
        if xi.fellow and xi.fellow.respawnIfOut then
            pcall(function() xi.fellow.respawnIfOut(player) end)
        end
        say(player, string.format('This memory calls for the %s role. Your previous role will return afterward.', definition.role))
    end

    say(player, 'Opening a private crossing...')
    player:createInstance(catalog.instanceId)
    player:timer(15000, function(p)
        if
            not p:getInstance() and
            (p:getCharVar(catalog.vars.pending) or 0) == catalog.instanceId
        then
            returnToHades(p, 'The private crossing failed to open. Nothing was consumed.')
        end
    end)
    return true
end

function R.abort(player)
    local instance = player:getInstance()
    if instance and (player:getCharVar(catalog.vars.active) or 0) == catalog.instanceId then
        fail(instance, 4)
        return true
    end
    if
        (player:getCharVar(catalog.vars.pending) or 0) ~= 0 or
        (player:getCharVar(catalog.vars.encounter) or 0) ~= 0
    then
        clearRunState(player)
        return true
    end
    return false
end

function R.recover(player)
    catalog.reconcile(player)
    if not player:getInstance() and (
        (player:getCharVar(catalog.vars.pending) or 0) ~= 0 or
        (player:getCharVar(catalog.vars.active) or 0) ~= 0 or
        (player:getCharVar(catalog.vars.savedRole) or 0) ~= 0)
    then
        local needsReturn = player.getZoneID and player:getZoneID() ~= catalog.entranceZone
        clearRunState(player)
        say(player, 'An abandoned quest encounter was cleaned up. Banked memories were preserved.')
        if needsReturn then
            player:timer(500, function(p)
                p:setPos(642.8, 0.3, 566.0, 96, catalog.entranceZone)
            end)
        end
        return true
    end
    return false
end

local instanceObject = R.instanceObject
if type(instanceObject) ~= 'table' then
    instanceObject = {}
end
R.instanceObject = instanceObject

instanceObject.onInstanceCreatedCallback = function(player, instance)
    if not instance then
        clearRunState(player)
        say(player, 'The private crossing could not be created.')
        return
    end

    local encounterId = player:getCharVar(catalog.vars.encounter) or 0
    if
        (player:getCharVar(catalog.vars.pending) or 0) ~= catalog.instanceId or
        not catalog.encounterAvailable(player, encounterId)
    then
        instance:fail()
        clearRunState(player)
        return
    end

    instance:setLocalVar('ErenEncounter', encounterId)
    instance:setLocalVar('ErenOwnerId', player:getID())
    player:setInstance(instance)
    player:setCharVar(catalog.vars.active, catalog.instanceId)
    player:setCharVar(catalog.vars.pending, 0)
    player:setPos(0, 0, 0, 0, catalog.instanceZone)
end

instanceObject.onInstanceCreated = function(instance)
    local encounterId = instance:getLocalVar('ErenEncounter')
    local ownerId = instance:getLocalVar('ErenOwnerId')
    local definition = catalog.encounters[encounterId]
    if not definition then
        instance:fail()
        return
    end

    local session =
    {
        owner = nil,
        ownerId = ownerId,
        ownerName = nil,
        encounterId = encounterId,
        definition = definition,
        entities = {},
        finishing = false,
        spawnStarted = false,
    }
    R.sessions[ownerId] = session
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()
    local encounterId = player:getCharVar(catalog.vars.encounter) or 0
    local definition = catalog.encounters[encounterId]
    local session = instance and currentSession(instance) or nil
    if not definition or not session or session.encounterId ~= encounterId then
        if instance then
            fail(instance, 9)
        end
        return
    end

    session.owner = player
    session.ownerId = player:getID()
    session.ownerName = player:getName()
    dismissOrdinaryTrusts(player)

    local attempts = 0
    local function waitForFellow(p)
        if currentSession(instance) ~= session or session.finishing or session.spawnStarted then
            return
        end

        dismissOrdinaryTrusts(p)
        if catalog.hasLivingFellow(p) then
            session.spawnStarted = true
            spawnScenario(instance, session)
            return
        end

        attempts = attempts + 1
        if attempts == 1 and xi.fellow and xi.fellow.ensureSummonedForInstance then
            pcall(function() xi.fellow.ensureSummonedForInstance(p) end)
        end
        if attempts >= 30 then
            say(p, 'Your Fellow could not cross into the private arena. The encounter will close safely.')
            fail(instance, 10)
            return
        end
        p:timer(500, waitForFellow)
    end

    player:timer(500, waitForFellow)
    say(player, string.format('%s. Time limit: %d minutes. Use !erenquest abort to leave.',
        definition.label, definition.time))
end

instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
    instance:setLocalVar('ErenElapsedMs', elapsed)
    if instance:completed() then
        if
            elapsed >= instance:getLocalVar('ErenReturnAtMs') and
            instance:getLocalVar('ErenReturnDispatched') == 0
        then
            instance:setLocalVar('ErenReturnDispatched', 1)
            forEachPlayer(instance, function(player)
                returnToHades(player, 'The crossing returns you to Hades.')
            end)
            removeSession(instance)
        end
        return
    end

    local session = currentSession(instance)
    if not session then
        if elapsed > 10000 then
            instance:fail()
        end
        return
    end
    if not session.owner then
        if elapsed > 20000 then
            fail(instance, 11)
        end
        return
    end
    local resolvedOwner = GetPlayerByID(session.ownerId)
    if not resolvedOwner then
        local emptySince = instance:getLocalVar('ErenEmptySinceMs')
        if emptySince == 0 then
            instance:setLocalVar('ErenEmptySinceMs', elapsed)
        elseif elapsed - emptySince > 30000 then
            fail(instance, 8)
        end
        return
    end
    session.owner = resolvedOwner

    if elapsed >= session.definition.time * 60 * 1000 then
        fail(instance, 5)
        return
    end

    if elapsed % 3000 < 1000 then
        if not catalog.hasAccess(session.owner) or not catalog.isMastered(session.owner) then
            fail(instance, 6)
            return
        elseif isGrouped(session.owner) then
            fail(instance, 6)
            return
        elseif hasOrdinaryTrust(session.owner) then
            dismissOrdinaryTrusts(session.owner)
            say(session.owner, 'Ordinary trusts cannot enter these memories.')
            fail(instance, 6)
            return
        elseif session.spawnStarted and not catalog.hasLivingFellow(session.owner) then
            fail(instance, 7)
            return
        end
    end

    if #instance:getChars() == 0 then
        local emptySince = instance:getLocalVar('ErenEmptySinceMs')
        if emptySince == 0 then
            instance:setLocalVar('ErenEmptySinceMs', elapsed)
        elseif elapsed - emptySince > 30000 then
            fail(instance, 8)
        end
    else
        instance:setLocalVar('ErenEmptySinceMs', 0)
    end
end

instanceObject.onInstanceComplete = function(instance)
    forEachPlayer(instance, function(player)
        say(player, 'Victory. The memory is now part of the bond.')
    end)
end

instanceObject.onInstanceFailure = function(instance)
    forEachPlayer(instance, function(player)
        returnToHades(player, 'The memory closes. Retry when you and your Fellow are ready; completed checkpoints remain.')
    end)
    removeSession(instance)
end

R.onInstanceZoneIn = function(player, instance)
    local pos = catalog.encounterPos.player
    player:setPos(pos.x, pos.y, pos.z, pos.rot)
end

R.onInstanceLoadFailed = function()
    return catalog.entranceZone
end

return R
