-----------------------------------
-- Unity Wanted T2/T3 encounter mechanics.
--
-- Dynamic Unity mobs do not load retail per-NM Lua scripts. This module gives
-- every upper-tier mark a recognizable, telegraphed combat signature while
-- retaining its native family skill/spell lists from mob_pools.
-----------------------------------
local M = {}

local profiles =
{
    -- Tier 2
    Muut = { kinds = { 'weaponskill', 'hold' }, tell = 'The legion closes ranks — break it with a weapon skill!', fail = 'Muut rallies the legion.' },
    Voso = { kinds = { 'move', 'far' }, tell = 'The earth buckles beneath you — move!', fail = 'Voso erupts through the fault.' },
    Beist = { kinds = { 'turn', 'magic' }, tell = 'Beist fixes you with a petrifying glare — turn away!', fail = 'The dragon gaze takes hold.' },
    Lumber_Jill = { kinds = { 'rear', 'physical' }, tell = 'Lumber Jill braces its shell — get behind it!', fail = 'The shell turns the assault.' },
    Largantua = { kinds = { 'far', 'magic' }, tell = 'Largantua draws the earth inward — retreat!', fail = 'The stone shockwave lands cleanly.' },
    Garbage_Gel = { kinds = { 'magic', 'physical' }, tell = 'Garbage Gel changes composition — answer with magic!', fail = 'The gel absorbs the wrong attack form.' },
    King_Uropygid = { kinds = { 'move', 'turn' }, tell = 'The king raises its venomous tail — keep moving!', fail = 'The venomous strike connects.' },
    Vedrfolnir = { kinds = { 'turn', 'far' }, tell = 'Vedrfolnir gathers a blinding gale — turn away!', fail = 'The gale tears through your guard.' },
    Glazemane = { kinds = { 'face', 'rear' }, tell = 'Glazemane begins a predatory charge — stand your ground!', fail = 'The charge scatters the hunt.' },
    Volatile_Cluster = { kinds = { 'far', 'hold' }, tell = 'The cluster swells toward detonation — get clear!', fail = 'The cluster detonates at full pressure.' },
    Strix = { kinds = { 'turn', 'magic' }, tell = 'Strix opens its baleful eyes — look away!', fail = 'The baleful stare finds its mark.' },
    Sovereign_Behemoth = { kinds = { 'move', 'far' }, tell = 'A meteor shadow forms overhead — move and spread!', fail = 'The sovereign meteor crashes down.' },
    Arke = { kinds = { 'rear', 'weaponskill' }, tell = 'Arke guards its breast — strike from behind!', fail = 'Arke answers with a crushing counter.' },
    Douma_Weapon = { kinds = { 'hold', 'magic' }, tell = 'Douma Weapon mirrors your aggression — hold attacks!', fail = 'The weapon completes its retaliation.' },
    Kubool_Jas_Mhuufya = { kinds = { 'magic', 'hold' }, tell = 'Mhuufya raises its reflecting plumage — stop attacking!', fail = 'Reflected force empowers the vigilant guard.' },
    Thuban = { kinds = { 'turn', 'move' }, tell = 'Thu’ban coils for a hypnotic gaze — turn away!', fail = 'The serpent gaze arrests the party.' },
    Tumult_Curator = { kinds = { 'weaponskill', 'burst' }, tell = 'The curator opens a brief seal — weapon skill now!', fail = 'The seal closes and turmoil rises.' },

    -- Tier 3
    Specter_Worm = { kinds = { 'move', 'magic' }, tell = 'Spectral earth gathers below — move!', fail = 'The phantom quake consumes the opening.' },
    Bakunawa = { kinds = { 'far', 'hold' }, tell = 'Bakunawa inhales the surrounding tide — retreat!', fail = 'The devouring current reaches you.' },
    Mephitas = { kinds = { 'move', 'physical' }, tell = 'Mephitas marks the ground with venom — relocate!', fail = 'The venom pool erupts.' },
    Vidmapire = { kinds = { 'turn', 'highhp' }, tell = 'Vidmapire begins a draining gaze — turn away!', fail = 'The vampire feeds on your weakness.' },
    Shedu = { kinds = { 'far', 'magic' }, tell = 'Shedu calls down a thunder field — spread out!', fail = 'The thunder field discharges.' },
    ['Azure-toothed_Clawberry'] = { kinds = { 'turn', 'weaponskill' }, tell = 'Clawberry prepares a grudge ritual — turn away!', fail = 'The ancient grudge is released.' },
    ['Centurio_XX-I'] = { kinds = { 'rear', 'physical' }, tell = 'Centurio aligns its antlion charge — take its rear!', fail = 'The antlion charge catches you.' },
    Wyvernhunter_Bambrox = { kinds = { 'move', 'weaponskill' }, tell = 'Bambrox sights a bombardment point — move!', fail = 'The goblin barrage saturates the area.' },
    Tolba = { kinds = { 'hold', 'physical' }, tell = 'Tolba raises an adamant guard — cease attacks!', fail = 'The adamant counter crushes forward.' },
    Ayapec = { kinds = { 'rear', 'magic' }, tell = 'Ayapec hardens its frontal shell — flank it!', fail = 'The hardened shell reflects the assault.' },
    Hidhaegg = { kinds = { 'burst', 'weaponskill' }, tell = 'A dragon egg begins to hatch — burst it down!', fail = 'The hatchling’s power joins Hidhaegg.' },
    Coca = { kinds = { 'turn', 'far' }, tell = 'Coca gathers a calcifying breath — turn and retreat!', fail = 'The calcifying breath washes over you.' },
    Grand_Grenade = { kinds = { 'far', 'burst' }, farDistance = 22, tell = 'Grand Grenade reaches critical pressure — get clear!', fail = 'The grenade reaches critical mass.' },
    Sarama = { kinds = { 'move', 'magic' }, tell = 'Sarama traces a volcanic line — move!', fail = 'The volcanic trail erupts.' },
    Azrael = { kinds = { 'hold', 'highhp' }, tell = 'Azrael weighs the living — preserve your strength!', fail = 'Azrael’s judgment falls.' },
    Carousing_Celine = { kinds = { 'magic', 'turn' }, tell = 'Celine releases bewitching pollen — answer with magic!', fail = 'The carousing pollen overwhelms the senses.' },
    Camahueto = { kinds = { 'face', 'physical' }, tell = 'Camahueto lowers its horns for a charge — face it!', fail = 'The horn charge breaks your stance.' },
    Borealis_Shadow = { kinds = { 'move', 'weaponskill' }, tell = 'The boreal shadow fixes on your position — move!', fail = 'The frozen shadow closes around you.' },
}

local states = {}
local listenerNames =
{
    fight   = 'UNITY_WANTED_MECHANIC_FIGHT',
    damage  = 'UNITY_WANTED_MECHANIC_DAMAGE',
    ws      = 'UNITY_WANTED_MECHANIC_WS',
    death   = 'UNITY_WANTED_MECHANIC_DEATH',
    despawn = 'UNITY_WANTED_MECHANIC_DESPAWN',
}

local function now()
    return GetSystemTime()
end

local function ownerFor(state)
    local player = state and GetPlayerByID(state.ownerId)
    return player and player:getHP() > 0 and player or nil
end

local function announce(state, message)
    local owner = ownerFor(state)
    if not owner or not message then return end

    local seen = {}
    local function notify(player)
        if
            player and
            not seen[player:getID()] and
            player:getZoneID() == owner:getZoneID()
        then
            seen[player:getID()] = true
            player:printToPlayer('[Unity: ' .. state.label .. '] ' .. message, xi.msg.channel.SYSTEM_1)
        end
    end

    notify(owner)
    for _, member in ipairs(owner:getParty()) do
        notify(member)
    end
end

local function challengeSucceeded(mob, state)
    local challenge = state.challenge
    local owner = ownerFor(state)
    if not challenge or not owner then return false end

    local kind = challenge.kind
    if kind == 'turn' then
        return not owner:isFacing(mob)
    elseif kind == 'face' then
        return owner:isFacing(mob)
    elseif kind == 'rear' then
        return owner:isBehind(mob, 48)
    elseif kind == 'near' then
        return owner:checkDistance(mob) <= 6
    elseif kind == 'far' then
        return owner:checkDistance(mob) >= (state.profile.farDistance or 12)
    elseif kind == 'move' then
        local dx = owner:getXPos() - challenge.startX
        local dz = owner:getZPos() - challenge.startZ
        return math.sqrt(dx * dx + dz * dz) >= 7
    elseif kind == 'hold' then
        return challenge.ownerDamage == 0 and not challenge.wsUsed
    elseif kind == 'burst' then
        return challenge.damage >= math.floor(mob:getMaxHP() * 0.02)
    elseif kind == 'weaponskill' then
        return challenge.wsUsed
    elseif kind == 'highhp' then
        return owner:getHPP() >= 70
    elseif kind == 'physical' then
        return challenge.physical > challenge.magic
    elseif kind == 'magic' then
        return challenge.magic > challenge.physical
    end

    return false
end

local function failureEffect(kind)
    if kind == 'turn' or kind == 'face' or kind == 'rear' then
        return xi.effect.PARALYSIS
    elseif kind == 'move' or kind == 'far' or kind == 'near' then
        return xi.effect.WEIGHT
    elseif kind == 'magic' then
        return xi.effect.SILENCE
    end

    return xi.effect.SLOW
end

local function instruction(kind, profile)
    local instructions =
    {
        turn        = 'Turn away before it resolves!',
        face        = 'Face the mark and hold your ground!',
        rear        = 'Move behind the mark!',
        near        = 'Close to melee range!',
        far         = string.format(
            'Retreat to at least %d yalms!',
            profile.farDistance or 12),
        move        = 'Leave your current position!',
        hold        = 'Stop attacking and do not weapon skill!',
        burst       = 'Deal at least 2% of its maximum HP!',
        weaponskill = 'Use a weapon skill!',
        highhp      = 'Recover above 70% HP!',
        physical    = 'Answer with more physical than magical damage!',
        magic       = 'Answer with more magical than physical damage!',
    }

    return instructions[kind] or 'React to the warning!'
end

local function finishChallenge(mob, state)
    local challenge = state.challenge
    if not challenge then return end

    if challengeSucceeded(mob, state) then
        announce(state, 'Counter successful — the mark is staggered!')
        pcall(function()
            mob:addStatusEffect(xi.effect.TERROR, { duration = 6, origin = ownerFor(state) })
            mob:addMod(xi.mod.DEF, -200)
            mob:addMod(xi.mod.MDEF, -100)
            mob:timer(10000, function(target)
                if target and not target:isDead() then
                    target:addMod(xi.mod.DEF, 200)
                    target:addMod(xi.mod.MDEF, 100)
                end
            end)
        end)
    else
        announce(state, state.profile.fail)
        local owner = ownerFor(state)
        if owner then
            pcall(function()
                owner:addStatusEffect(failureEffect(challenge.kind), {
                    power = state.tier == 3 and 30 or 20,
                    duration = state.tier == 3 and 20 or 15,
                    origin = mob,
                })
            end)
        end

        if state.failures < 3 then
            state.failures = state.failures + 1
            mob:addMod(xi.mod.ATT, state.tier == 3 and 300 or 200)
            mob:addMod(xi.mod.MATT, state.tier == 3 and 100 or 60)
        end
    end

    state.challenge = nil
end

local function beginChallenge(mob, state)
    if state.challenge then return end

    local owner = ownerFor(state)
    if not owner then return end

    state.signatureIndex = state.signatureIndex % #state.profile.kinds + 1
    state.challenge =
    {
        kind        = state.profile.kinds[state.signatureIndex],
        dueAt       = now() + (state.tier == 3 and 6 or 7),
        startX      = owner:getXPos(),
        startZ      = owner:getZPos(),
        damage      = 0,
        ownerDamage = 0,
        physical    = 0,
        magic       = 0,
        wsUsed      = false,
    }
    state.nextAt = now() + (state.tier == 3 and 35 or 45)
    local flavor = state.profile.tell:match('^(.-) —') or state.profile.tell
    announce(state, flavor .. ' — ' .. instruction(state.challenge.kind, state.profile))
    pcall(function() mob:weaknessTrigger(state.tier == 3 and 2 or 1) end)
end

local function combatTick(mob)
    local state = states[mob:getID()]
    if not state then return end

    if state.challenge and now() >= state.challenge.dueAt then
        finishChallenge(mob, state)
    elseif not state.challenge and now() >= state.nextAt then
        beginChallenge(mob, state)
    end
end

local function damageTaken(mob, amount, attacker, attackType)
    local state = states[mob:getID()]
    local challenge = state and state.challenge
    if not challenge or not amount or amount <= 0 then return end

    challenge.damage = challenge.damage + amount
    if attackType == xi.attackType.PHYSICAL or attackType == xi.attackType.RANGED then
        challenge.physical = challenge.physical + amount
    else
        challenge.magic = challenge.magic + amount
    end

    local attackerIsPc = false
    pcall(function() attackerIsPc = attacker:isPC() end)
    if attackerIsPc and attacker:getID() == state.ownerId then
        challenge.ownerDamage = challenge.ownerDamage + amount
    end
end

local function weaponskillTaken(user, mob)
    local state = states[mob:getID()]
    if
        state and
        state.challenge and
        user:isPC() and
        user:getID() == state.ownerId
    then
        state.challenge.wsUsed = true
    end
end

function M.cleanup(mob)
    if not mob then return end

    states[mob:getID()] = nil
    for _, name in pairs(listenerNames) do
        pcall(function() mob:removeListener(name) end)
    end
end

function M.applyDifficulty(mob, nm, difficulty)
    local d = difficulty and difficulty[nm.tier]
    if not mob or not d then return end

    mob:setUntargetable(false)
    if d.hp then
        mob:setMaxHP(d.hp)
        mob:setHP(d.hp)
    end
    if d.att     then mob:addMod(xi.mod.ATT,           d.att)  end
    if d.acc     then mob:addMod(xi.mod.ACC,           d.acc)  end
    if d.macc    then mob:addMod(xi.mod.MACC,          d.macc) end
    if d.matt    then mob:addMod(xi.mod.MATT,          d.matt) end
    if d.def     then mob:addMod(xi.mod.DEF,           d.def)  end
    if d.eva     then mob:addMod(xi.mod.EVA,           d.eva)  end
    if d.regain  then mob:addMod(xi.mod.REGAIN,        d.regain) end
    if d.da      then mob:addMod(xi.mod.DOUBLE_ATTACK, d.da)  end
    if d.ta and d.ta > 0 then mob:addMod(xi.mod.TRIPLE_ATTACK, d.ta) end
    if d.dmgMult then mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, d.dmgMult) end
    if d.mdef      then mob:addMod(xi.mod.MDEF,       d.mdef)      end
    if d.meva      then mob:addMod(xi.mod.MEVA,       d.meva)      end
    if d.str       then mob:addMod(xi.mod.STR,        d.str)       end
    if d.dex       then mob:addMod(xi.mod.DEX,        d.dex)       end
    if d.hasteGear then mob:addMod(xi.mod.HASTE_GEAR, d.hasteGear) end
end

function M.attach(mob, nm, owner)
    local profile = nm and profiles[nm.name]
    if not mob or not profile or not owner then return end

    M.cleanup(mob)
    states[mob:getID()] =
    {
        ownerId       = owner:getID(),
        label         = nm.label,
        tier          = nm.tier,
        profile       = profile,
        signatureIndex = 0,
        nextAt        = now() + (nm.tier == 3 and 15 or 20),
        failures      = 0,
    }

    mob:addListener('COMBAT_TICK', listenerNames.fight, combatTick)
    mob:addListener('TAKE_DAMAGE', listenerNames.damage, damageTaken)
    mob:addListener('WEAPONSKILL_TAKE', listenerNames.ws, weaponskillTaken)
    mob:addListener('DEATH', listenerNames.death, M.cleanup)
    mob:addListener('DESPAWN', listenerNames.despawn, M.cleanup)
end

function M.hasProfile(name)
    return profiles[name] ~= nil
end

function M.profileCount()
    local count = 0
    for _, profile in pairs(profiles) do
        if type(profile) == 'table' then
            count = count + 1
        end
    end
    return count
end

M.profiles = profiles

return M
