-----------------------------------
-- Omen instance runtime
--
-- Data:      modules/custom/lua/omen_catalog.lua
-- Mechanics: modules/custom/lua/omen_mechanics.lua (boss/mid-boss kits)
-- Entry:     modules/custom/lua/OmenNPCs.lua (Incantrix, Reisenjima)
-- Loader:    scripts/zones/Reisenjima_Henge/instances/omen.lua
--
-- ALL mutable run state lives in instance/entity localvars (numbers only):
-- the created instanceObject is shared by every concurrent Omen run of the
-- same template, exactly like dungeon_instance.lua. No Lua-side tables may
-- hold per-run state.
--
-- Floor numbering in localvar OmenFloor:
--   1, 2       trash gates
--   3          Glassy mid-boss
--   4          trash gate (families follow the mid-boss route)
--   5          Caturae (or Ou)
--   6          smaller-light bonus route (replaces 3-5)
--   7          bonus treasure floor (chance detour from 3 or 5 exits)
-----------------------------------
local catalog = require('modules/custom/lua/omen_catalog')
local partyHpScale = require('modules/custom/lua/party_hp_scale')

-- Hot-reloadable (same pattern as dungeon_instance.lua).
local runtime = package.loaded['modules/custom/lua/omen_instance']
if type(runtime) ~= 'table' then runtime = {} end

-- Same DE_ zone-cache collision as dungeon_instance.lua: unique script names
-- per copy, and death Lua uses the mob's live instance.
runtime.copySeq = tonumber(runtime.copySeq) or 0

-----------------------------------
-- Small helpers
-----------------------------------
local function forEachPlayer(instance, fn)
    for _, player in ipairs(instance:getChars()) do
        fn(player)
    end
end

local function announce(instance, message)
    forEachPlayer(instance, function(player)
        player:printToPlayer('[Omen] ' .. message, xi.msg.channel.SYSTEM_3)
    end)
end

local function fmtMinSec(seconds)
    return string.format('%d:%02d', math.floor(seconds / 60), seconds % 60)
end

local function leaveOmen(player, message)
    player:setCharVar('OmenActive', 0)
    player:setLocalVar('OmenInstancePending', 0)
    if message then
        player:printToPlayer('[Omen] ' .. message, xi.msg.channel.SYSTEM_3)
    end

    player:setPos(
        catalog.entry.exit.x,
        catalog.entry.exit.y,
        catalog.entry.exit.z,
        catalog.entry.exit.rotation,
        catalog.entry.zoneId)
end

local magicalWs = {}
for _, wsId in ipairs(catalog.magicalWsIds) do
    magicalWs[wsId] = true
end

-- Positions on a ring around the arena centre.
local function ringPosition(index, count, radius)
    local angle = (index - 1) * (2 * math.pi / math.max(count, 1))
    local cx    = catalog.arena.center.x
    local cz    = catalog.arena.center.z
    local x     = cx + radius * math.cos(angle)
    local z     = cz + radius * math.sin(angle)
    -- Face the centre (0-255 rotation; 0 = +x? close enough for ambience).
    local rot   = math.floor(((angle + math.pi) / (2 * math.pi)) * 256) % 256
    return x, catalog.arena.center.y, z, rot
end

local function addRunTime(instance, seconds)
    local limit = instance:getLocalVar('OmenLimitMs')
    limit = math.min(limit + seconds * 1000, catalog.time.cap * 1000)
    instance:setLocalVar('OmenLimitMs', limit)

    local remaining = math.floor((limit - instance:getLocalVar('OmenElapsedMs')) / 1000)
    announce(instance, string.format('Time extended. %s remains (cap %d minutes).',
        fmtMinSec(math.max(remaining, 0)), catalog.time.cap / 60))
end

-----------------------------------
-- Objective progress -> paragon job cards
-----------------------------------
local function awardObjectiveCredit(instance)
    forEachPlayer(instance, function(player)
        local progress = player:getCharVar('OmenObjectiveProgress') + 1

        if progress >= catalog.objectivesPerCard then
            local cardId = catalog.cardForJob(player:getMainJob())
            if cardId and player:getFreeSlotsCount() > 0 then
                player:addItem(cardId)
                player:printToPlayer('[Omen] You earned a paragon card for your efforts!', xi.msg.channel.SYSTEM_3)
                progress = 0
            elseif cardId then
                player:printToPlayer('[Omen] A paragon card awaits, but your inventory is full. It will arrive with your next objective.', xi.msg.channel.SYSTEM_3)
                progress = catalog.objectivesPerCard
            else
                progress = 0
            end
        end

        player:setCharVar('OmenObjectiveProgress', progress)
    end)
end

-----------------------------------
-- Bonus (additional) objectives
--
-- Localvars per slot i (1..10):
--   OmenBonus<i>Type   index into catalog.bonusObjectives
--   OmenBonus<i>Target required count
--   OmenBonus<i>Prog   current count
--   OmenBonus<i>Done   0 active / 1 complete / 2 expired
-----------------------------------
local function bonusVar(i, suffix)
    return string.format('OmenBonus%d%s', i, suffix)
end

local function setupBonusObjectives(instance, count, window)
    local members = math.min(#instance:getChars(), 6)
    local n       = math.max(members, 1)

    -- Fisher-Yates over objective indexes so a floor never repeats a type.
    local order = {}
    for i = 1, #catalog.bonusObjectives do
        order[i] = i
    end

    for i = #order, 2, -1 do
        local j = math.random(i)
        order[i], order[j] = order[j], order[i]
    end

    count = math.min(count, #catalog.bonusObjectives)
    instance:setLocalVar('OmenBonusCount', count)
    instance:setLocalVar('OmenBonusWindow', window)
    instance:setLocalVar('OmenBonusStart', 0) -- arms on first engage

    for i = 1, count do
        local def    = catalog.bonusObjectives[order[i]]
        local target = def.target or (def.mult * n)

        instance:setLocalVar(bonusVar(i, 'Type'), order[i])
        instance:setLocalVar(bonusVar(i, 'Target'), target)
        instance:setLocalVar(bonusVar(i, 'Prog'), 0)
        instance:setLocalVar(bonusVar(i, 'Done'), 0)
    end
end

local function describeBonusObjective(instance, i)
    local def    = catalog.bonusObjectives[instance:getLocalVar(bonusVar(i, 'Type'))]
    local target = instance:getLocalVar(bonusVar(i, 'Target'))

    if def.mult == 0 then
        return def.text
    end

    return string.format(def.text, target)
end

local function armBonusObjectives(instance)
    if
        instance:getLocalVar('OmenBonusCount') == 0 or
        instance:getLocalVar('OmenBonusStart') ~= 0
    then
        return
    end

    instance:setLocalVar('OmenBonusStart', math.max(instance:getLocalVar('OmenElapsedMs'), 1))

    local window = instance:getLocalVar('OmenBonusWindow')
    announce(instance, string.format('Additional objectives (%s):', fmtMinSec(window)))
    for i = 1, instance:getLocalVar('OmenBonusCount') do
        announce(instance, string.format('  %d. %s', i, describeBonusObjective(instance, i)))
    end
end

-- Bump every active bonus objective whose tracker matches `trackerId`.
local function bumpBonus(instance, trackerId, amount)
    local count = instance:getLocalVar('OmenBonusCount')
    if count == 0 or instance:getLocalVar('OmenBonusStart') == 0 then
        return
    end

    for i = 1, count do
        if instance:getLocalVar(bonusVar(i, 'Done')) == 0 then
            local def = catalog.bonusObjectives[instance:getLocalVar(bonusVar(i, 'Type'))]
            if def.id == trackerId then
                local progress = instance:getLocalVar(bonusVar(i, 'Prog')) + (amount or 1)
                instance:setLocalVar(bonusVar(i, 'Prog'), progress)

                local target = instance:getLocalVar(bonusVar(i, 'Target'))
                if progress >= target then
                    instance:setLocalVar(bonusVar(i, 'Done'), 1)
                    announce(instance, string.format('Objective complete: %s!', describeBonusObjective(instance, i)))
                    awardObjectiveCredit(instance)
                elseif def.mult ~= 0 and (target - progress) <= 3 then
                    announce(instance, string.format('%s -- %d to go.', describeBonusObjective(instance, i), target - progress))
                end
            end
        end
    end
end

local function expireBonusObjectives(instance)
    local count = instance:getLocalVar('OmenBonusCount')
    local start = instance:getLocalVar('OmenBonusStart')
    if count == 0 or start == 0 or instance:getLocalVar('OmenBonusExpired') == 1 then
        return
    end

    local window = instance:getLocalVar('OmenBonusWindow') * 1000
    if instance:getLocalVar('OmenElapsedMs') - start < window then
        return
    end

    instance:setLocalVar('OmenBonusExpired', 1)

    local missed = 0
    for i = 1, count do
        if instance:getLocalVar(bonusVar(i, 'Done')) == 0 then
            instance:setLocalVar(bonusVar(i, 'Done'), 2)
            missed = missed + 1
        end
    end

    if missed > 0 then
        announce(instance, string.format('The window for additional objectives closes. %d went unfinished.', missed))
    end
end

-----------------------------------
-- Objective/combat tracking listeners (attached per spawned mob)
-----------------------------------
local function attachTrackingListeners(mob, instance)
    mob:addListener('ENGAGE', 'OMEN_ENGAGE', function(mobArg, target)
        armBonusObjectives(instance)
    end)

    mob:addListener('ABILITY_TAKE', 'OMEN_JA', function(user, target, ability, action)
        if user and user:isPC() then
            bumpBonus(instance, 'ja', 1)
        end
    end)

    mob:addListener('MAGIC_TAKE', 'OMEN_MAGIC', function(target, caster, spell)
        if not caster or not caster:isPC() or not spell then
            return
        end

        bumpBonus(instance, 'spell', 1)

        -- Magic burst detection mirrors the resolution core uses: the
        -- skillchain resonance on the target must match the spell element.
        local burstTier = 0
        if spell.getElement then
            burstTier = xi.magicburst.formMagicBurst(target, spell:getElement())
        end

        if burstTier and burstTier > 0 then
            bumpBonus(instance, 'magicBurst', 1)
            target:setLocalVar('OmenLastSpellBurst', 1)
        else
            target:setLocalVar('OmenLastSpellBurst', 0)
        end
    end)

    mob:addListener('WEAPONSKILL_TAKE', 'OMEN_WS', function(user, target, skill, tp, action)
        if not user or not user:isPC() or not skill then
            return
        end

        bumpBonus(instance, 'ws', 1)

        if magicalWs[skill:getID()] then
            bumpBonus(instance, 'elemWs', 1)
        else
            bumpBonus(instance, 'physWs', 1)
        end

        -- Flag so the follow-up TAKE_DAMAGE can classify big weaponskills.
        target:setLocalVar('OmenWsFlag', 1)

        -- Skillchain detection: the resonance effect's chain count moves
        -- when this weapon skill actually formed a chain.
        local resonance = target:getStatusEffect(xi.effect.SKILLCHAIN)
        if resonance then
            local chainCount = resonance:getSubPower()
            if chainCount >= 1 and chainCount ~= target:getLocalVar('OmenChainMark') then
                target:setLocalVar('OmenChainMark', chainCount)
                bumpBonus(instance, 'skillchain', 1)
            end
        else
            target:setLocalVar('OmenChainMark', 0)
        end
    end)

    mob:addListener('CRITICAL_TAKE', 'OMEN_CRIT', function(mobArg, attacker)
        if attacker and attacker:isPC() then
            bumpBonus(instance, 'crit', 1)
        end
    end)

    mob:addListener('TAKE_DAMAGE', 'OMEN_DMG', function(mobArg, amount, attacker, attackType, damageType)
        armBonusObjectives(instance)

        if not attacker or not attacker:isPC() or not amount or amount <= 0 then
            return
        end

        if attackType == xi.attackType.PHYSICAL then
            if mobArg:getLocalVar('OmenWsFlag') == 1 then
                mobArg:setLocalVar('OmenWsFlag', 0)
                if amount >= 30000 then
                    bumpBonus(instance, 'bigWs', 1)
                end
            elseif amount >= 2000 then
                bumpBonus(instance, 'bigHit', 1)
            end
        elseif attackType == xi.attackType.MAGICAL then
            if mobArg:getLocalVar('OmenWsFlag') == 1 then
                -- Magical weaponskill damage.
                mobArg:setLocalVar('OmenWsFlag', 0)
                if amount >= 30000 then
                    bumpBonus(instance, 'bigWs', 1)
                end
            elseif mobArg:getLocalVar('OmenLastSpellBurst') == 1 then
                if amount >= 30000 then
                    bumpBonus(instance, 'bigBurst', 1)
                end
            elseif amount >= 15000 then
                bumpBonus(instance, 'bigNuke', 1)
            end
        end
    end)
end

-----------------------------------
-- Boss / mid-boss payouts
-----------------------------------
local function rate(instance, fraction)
    return math.random() < math.min(fraction * catalog.dropRateMultiplier, 1.0)
end

local function payoutMidboss(instance, deadMob, player)
    local index = instance:getLocalVar('OmenMidboss')
    local def   = catalog.midbosses[index]
    if not def then
        return
    end

    player:addTreasure(def.crystal.id, deadMob)
    player:addTreasure(def.gear[math.random(#def.gear)].id, deadMob)
    announce(instance, string.format('%s dissolves, leaving spoils behind.', def.name))
end

local function payoutCaturae(instance, deadMob, player, bossIndex)
    local def = catalog.bosses[bossIndex]
    if not def then
        return
    end

    -- Guaranteed: scale + moonbow material; chance of a second scale.
    player:addTreasure(def.scale.id, deadMob)
    player:addTreasure(def.moonbow.id, deadMob)
    if rate(instance, catalog.rates.bossExtraScale) then
        player:addTreasure(def.scale.id, deadMob)
    end

    for _, accessory in ipairs(def.accessories) do
        if rate(instance, catalog.rates.bossAccessory) then
            player:addTreasure(accessory.id, deadMob)
        end
    end

    if rate(instance, catalog.rates.bossBody) then
        player:addTreasure(def.body.id, deadMob)
        announce(instance, 'An exceptionally rare treasure enters the pool!')
    end

    -- Bead key items for everyone (Ou's price of admission).
    forEachPlayer(instance, function(member)
        if not member:hasKeyItem(def.bead) then
            member:addKeyItem(def.bead)
        end
        member:printToPlayer(string.format('[Omen] You obtain %s\'s bead.', def.name), xi.msg.channel.SYSTEM_3)
    end)

    awardObjectiveCredit(instance) -- boss kills count toward cards
end

local function payoutOu(instance, deadMob, player)
    local def = catalog.ou

    for _, material in ipairs(def.moonbow) do
        player:addTreasure(material.id, deadMob)
    end

    for _, accessory in ipairs(def.accessories) do
        if rate(instance, catalog.rates.ouAccessory) then
            player:addTreasure(accessory.id, deadMob)
        end
    end

    if rate(instance, catalog.rates.ouHands) then
        player:addTreasure(def.hands[math.random(#def.hands)].id, deadMob)
        announce(instance, 'A Regal treasure enters the pool!')
    end

    for _, scaleId in ipairs(def.scales) do
        if rate(instance, catalog.rates.ouScale) then
            player:addTreasure(scaleId, deadMob)
        end
    end

    awardObjectiveCredit(instance)
end

-----------------------------------
-- Runtime creation
-----------------------------------
runtime.create = function()
    local instanceObject = {}

    -- Forward declarations (spawn/advance recurse through death handlers).
    local spawnFloor
    local showIngress

    -----------------------------------
    -- Mob spawning
    -----------------------------------
    local function spawnOmenMob(instance, params)
        local copySeq = instance:getLocalVar('OmenCopySeq')
        local mob = instance:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = params.groupId,
            groupZoneId          = catalog.zoneId,
            name                 = string.format('%s_c%u', params.name, copySeq),
            packetName           = params.name,
            x                    = params.x,
            y                    = params.y,
            z                    = params.z,
            rotation             = params.rot or 0,
            minLevel             = params.level,
            maxLevel             = params.level,
            detection            = xi.detects.SIGHT_AND_HEARING,
            isAggroable          = true,
            releaseIdOnDisappear = true,

            onMobDeath = function(deadMob, player, optParams)
                local live = deadMob:getInstance()
                if not live then
                    return
                end
                instanceObject.onOmenMobDeath(live, deadMob, player, optParams)
            end,
        })

        if not mob then
            return nil
        end

        mob:setLocalVar('OmenKind', params.kind)
        mob:setSpawn(params.x, params.y, params.z, params.rot or 0)
        mob:spawn()
        mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
        mob:setMobMod(xi.mobMod.NO_DROPS, 1) -- payouts are catalogue-driven
        mob:setMobMod(xi.mobMod.NO_MOVE, 0)
        mob:setMaxHP(params.hp)
        mob:setHP(params.hp)
        partyHpScale.afterCustomHp(mob, instance)

        attachTrackingListeners(mob, instance)

        if params.mechanics then
            local mechanics = require('modules/custom/lua/omen_mechanics')
            mechanics.attach(mob, params.mechanics, instance)
        end

        return mob
    end

    local function despawnFloorMobs(instance)
        for _, mob in ipairs(instance:getMobs()) do
            if mob and mob:getLocalVar('OmenKind') ~= 0 and mob:getHP() > 0 then
                DespawnMob(mob:getID(), instance)
            end
        end
    end

    -- kind: 1 = sweetwater, 2 = transcended
    -- Sweetwater mobs are dealt in CONTIGUOUS BLOCKS per family (retail: 7
    -- tigers then 7 flies), Transcended round-robin (1 per family).
    local function spawnTrashSet(instance, families, sweetwaterCount, transcendedCount, exactSpawns)
        local total     = sweetwaterCount + transcendedCount
        local spawned   = 0
        local perFamily = math.ceil(sweetwaterCount / #families)

        for i = 1, sweetwaterCount do
            local family = families[math.min(math.floor((i - 1) / perFamily) + 1, #families)]
            local groups = catalog.families[family]
            local x, y, z, rot

            if exactSpawns and catalog.floorOneSpawns.sweetwater[i] then
                local p = catalog.floorOneSpawns.sweetwater[i]
                x, y, z, rot = p[1], p[2], p[3], p[4]
            else
                x, y, z, rot = ringPosition(i, total, catalog.arena.mobRadius)
            end

            if spawnOmenMob(instance, {
                groupId = groups[1],
                x = x, y = y, z = z, rot = rot,
                level = catalog.levels.sweetwater,
                hp    = catalog.hp.sweetwater,
                kind  = 1,
            }) then
                spawned = spawned + 1
            end
        end

        for i = 1, transcendedCount do
            local family = families[((i - 1) % #families) + 1]
            local groups = catalog.families[family]
            local x, y, z, rot

            if exactSpawns and catalog.floorOneSpawns.transcended[i] then
                local p = catalog.floorOneSpawns.transcended[i]
                x, y, z, rot = p[1], p[2], p[3], p[4]
            else
                x, y, z, rot = ringPosition(i, transcendedCount, catalog.arena.mobRadius - 4)
            end

            if spawnOmenMob(instance, {
                groupId = groups[2],
                x = x, y = y, z = z, rot = rot,
                level = catalog.levels.transcended,
                hp    = catalog.hp.transcended,
                kind  = 2,
            }) then
                spawned = spawned + 1
            end
        end

        return spawned
    end

    -----------------------------------
    -- Main objectives
    -----------------------------------
    local function rollMainObjective(instance)
        local pool = 0
        for _, def in ipairs(catalog.mainObjectives) do
            pool = pool + def.weight
        end

        local roll = math.random(pool)
        for index, def in ipairs(catalog.mainObjectives) do
            roll = roll - def.weight
            if roll <= 0 then
                return index, def
            end
        end

        return 1, catalog.mainObjectives[1]
    end

    local function announceMainObjective(instance, def)
        local text = def.text
        if def.count then
            text = string.format(def.text, def.count)
        end

        announce(instance, 'Floor objective: ' .. text)
    end

    local function setupMainObjective(instance)
        local index, def = rollMainObjective(instance)
        instance:setLocalVar('OmenMainType', index)

        if def.id == 'specificKill' then
            -- Secretly mark one living floor mob.
            local candidates = {}
            for _, mob in ipairs(instance:getMobs()) do
                if mob and mob:getHP() > 0 and mob:getLocalVar('OmenKind') ~= 0 then
                    table.insert(candidates, mob:getID())
                end
            end

            if #candidates > 0 then
                instance:setLocalVar('OmenSecretTarget', candidates[math.random(#candidates)])
            else
                instance:setLocalVar('OmenMainDone', 1)
            end
        elseif def.id == 'sweetwaterKill' then
            instance:setLocalVar('OmenMainRemaining', def.count)
        elseif def.id == 'free' then
            instance:setLocalVar('OmenMainDone', 1)
        end

        announceMainObjective(instance, def)

        if instance:getLocalVar('OmenMainDone') == 1 then
            showIngress(instance)
        end
    end

    local function completeMainObjective(instance)
        if instance:getLocalVar('OmenMainDone') == 1 then
            return
        end

        instance:setLocalVar('OmenMainDone', 1)
        announce(instance, 'The floor objective is complete! An ethereal ingress materialises.')
        awardObjectiveCredit(instance)
        showIngress(instance)
    end

    local function checkMainObjective(instance, deadMob)
        if instance:getLocalVar('OmenMainDone') == 1 then
            return
        end

        local def  = catalog.mainObjectives[instance:getLocalVar('OmenMainType')]
        local kind = deadMob:getLocalVar('OmenKind')
        if not def then
            return
        end

        if def.id == 'specificKill' then
            if deadMob:getID() == instance:getLocalVar('OmenSecretTarget') then
                completeMainObjective(instance)
            end
        elseif def.id == 'sweetwaterKill' then
            if kind == 1 then
                local remaining = instance:getLocalVar('OmenMainRemaining') - 1
                instance:setLocalVar('OmenMainRemaining', remaining)
                if remaining <= 0 then
                    completeMainObjective(instance)
                else
                    announce(instance, string.format('%d Sweetwater monsters remain for the floor objective.', remaining))
                end
            end
        elseif def.id == 'transcendedAll' then
            if instance:getLocalVar('OmenAliveTR') == 0 then
                completeMainObjective(instance)
            end
        elseif def.id == 'killAll' then
            if instance:getLocalVar('OmenAliveTotal') == 0 then
                completeMainObjective(instance)
            end
        end
    end

    -----------------------------------
    -- Floors
    -----------------------------------
    local function floor4Families(instance)
        local floorDef = catalog.floors[4]
        local midboss  = catalog.midbosses[instance:getLocalVar('OmenMidboss')]

        if math.random() < floorDef.alternateChance then
            return floorDef.familiesAlternate[math.random(#floorDef.familiesAlternate)]
        end

        return floorDef.familiesByRoute[midboss and midboss.key or 'craver']
    end

    spawnFloor = function(instance, floorNumber)
        instance:setLocalVar('OmenFloor', floorNumber)
        instance:setLocalVar('OmenMainDone', 0)
        instance:setLocalVar('OmenMainType', 0)
        instance:setLocalVar('OmenSecretTarget', 0)
        instance:setLocalVar('OmenBonusCount', 0)
        instance:setLocalVar('OmenBonusExpired', 0)
        instance:setLocalVar('OmenIngressUp', 0)

        if floorNumber == 1 or floorNumber == 2 or floorNumber == 4 then
            local floorDef = catalog.floors[floorNumber]
            local families = floorDef.families or floor4Families(instance)

            announce(instance, string.format('-- %s --', floorDef.label))

            local spawned = spawnTrashSet(instance, families, floorDef.sweetwater, floorDef.transcended, floorDef.exactSpawns)
            local transcended = floorDef.transcended

            instance:setLocalVar('OmenAliveTotal', spawned)
            instance:setLocalVar('OmenAliveTR', transcended)
            instance:setLocalVar('OmenAliveSW', spawned - transcended)

            setupBonusObjectives(instance, floorDef.bonusCount, floorDef.bonusWindow)
            setupMainObjective(instance)

            if instance:getLocalVar('OmenBonusCount') > 0 then
                announce(instance, string.format(
                    '%d additional objectives await -- they begin the moment battle is joined.',
                    instance:getLocalVar('OmenBonusCount')))
            end
        elseif floorNumber == 3 then
            local index = math.random(#catalog.midbosses)
            local def   = catalog.midbosses[index]
            instance:setLocalVar('OmenMidboss', index)

            announce(instance, string.format('-- %s --', catalog.floors[3].label))
            announce(instance, string.format('%s bars the way!', def.name))

            local mob = spawnOmenMob(instance, {
                groupId   = def.group,
                x         = catalog.arena.bossPos.x,
                y         = catalog.arena.bossPos.y,
                z         = catalog.arena.bossPos.z,
                rot       = catalog.arena.bossPos.rotation,
                level     = catalog.levels.midboss,
                hp        = catalog.hp.midboss,
                kind      = 3,
                mechanics = def.key,
            })

            instance:setLocalVar('OmenAliveTotal', mob and 1 or 0)
            if not mob then
                instance:fail()
            end
        elseif floorNumber == 5 then
            local bossIndex = instance:getLocalVar('OmenBossPick')
            local def       = bossIndex == 6 and catalog.ou or catalog.bosses[bossIndex]

            announce(instance, string.format('-- %s --', catalog.floors[5].label))
            announce(instance, string.format('%s descends!', def.name))

            local mob = spawnOmenMob(instance, {
                groupId   = def.group,
                x         = catalog.arena.bossPos.x,
                y         = catalog.arena.bossPos.y,
                z         = catalog.arena.bossPos.z,
                rot       = catalog.arena.bossPos.rotation,
                level     = bossIndex == 6 and catalog.levels.ou or catalog.levels.caturae,
                hp        = bossIndex == 6 and catalog.hp.ou or catalog.hp.caturae,
                kind      = 4,
                mechanics = def.key,
            })

            instance:setLocalVar('OmenAliveTotal', mob and 1 or 0)
            if not mob then
                instance:fail()
            end
        elseif floorNumber == 6 then
            local routeDef = catalog.bonusRoute

            announce(instance, string.format('-- %s --', routeDef.label))
            announce(instance, string.format(
                'A trial of endurance: fell all %d creatures. The one who opened the way must stand at the final blow.',
                routeDef.total))

            instance:setLocalVar('OmenRoute', 1)
            instance:setLocalVar('OmenWaveRemaining', routeDef.total)
            instance:setLocalVar('OmenWave', 0)

            setupBonusObjectives(instance, routeDef.bonusCount, routeDef.bonusWindow)
            instanceObject.spawnBonusWave(instance)
        elseif floorNumber == 7 then
            announce(instance, '-- A hidden vault! --')
            announce(instance, 'Gleaming caskets stand in a silent circle. Take what is yours.')
            instanceObject.spawnCaskets(instance)
            showIngress(instance)
        end
    end

    instanceObject.spawnBonusWave = function(instance)
        local routeDef  = catalog.bonusRoute
        local wave      = instance:getLocalVar('OmenWave') + 1
        local total     = routeDef.total
        local spawnedSoFar = (wave - 1) * routeDef.waveSize
        local toSpawn   = math.min(routeDef.waveSize, total - spawnedSoFar)

        if toSpawn <= 0 then
            return
        end

        instance:setLocalVar('OmenWave', wave)

        local alive = 0
        for i = 1, toSpawn do
            local family = routeDef.families[((spawnedSoFar + i - 1) % #routeDef.families) + 1]
            local groups = catalog.families[family]
            local x, y, z, rot = ringPosition(i, toSpawn, catalog.arena.mobRadius)

            if spawnOmenMob(instance, {
                groupId = groups[1],
                x = x, y = y, z = z, rot = rot,
                level = catalog.levels.bonusFloor,
                hp    = catalog.hp.bonusFloor,
                kind  = 1,
            }) then
                alive = alive + 1
            end
        end

        instance:setLocalVar('OmenAliveTotal', alive)
        announce(instance, string.format('Wave %d -- %d foes. %d remain in all.',
            wave, alive, instance:getLocalVar('OmenWaveRemaining')))
    end

    -----------------------------------
    -- Treasure caskets (floor 7)
    -----------------------------------
    instanceObject.spawnCaskets = function(instance)
        for i = 1, catalog.caskets.count do
            local x, y, z, rot = ringPosition(i, catalog.caskets.count, catalog.arena.mobRadius - 4)

            instance:insertDynamicEntity({
                objtype  = xi.objType.NPC,
                name     = 'Treasure_Casket',
                look     = 2359, -- treasure casket model
                x        = x,
                y        = y,
                z        = z,
                rotation = rot,

                onTrigger = function(player, npc)
                    if npc:getLocalVar('OmenCasketUsed') == 1 then
                        player:printToPlayer('[Omen] The casket is empty.', xi.msg.channel.SYSTEM_3)
                        return
                    end

                    npc:setLocalVar('OmenCasketUsed', 1)

                    local pool = 0
                    for _, line in ipairs(catalog.caskets.loot) do
                        pool = pool + line.weight
                    end

                    local roll   = math.random(pool)
                    local chosen = catalog.caskets.loot[1]
                    for _, line in ipairs(catalog.caskets.loot) do
                        roll = roll - line.weight
                        if roll <= 0 then
                            chosen = line
                            break
                        end
                    end

                    if chosen.gil then
                        player:addGil(chosen.gil)
                        player:printToPlayer(string.format('[Omen] You find %d gil!', chosen.gil), xi.msg.channel.SYSTEM_3)
                    elseif chosen.item == 'card' then
                        local cardId = catalog.cardForJob(player:getMainJob())
                        if cardId then
                            player:addItem(cardId)
                            player:printToPlayer('[Omen] You find a paragon card!', xi.msg.channel.SYSTEM_3)
                        end
                    elseif chosen.item == 'scale' then
                        local scales = catalog.ou.scales
                        player:addItem(scales[math.random(#scales)])
                        player:printToPlayer('[Omen] You find a gleaming scale!', xi.msg.channel.SYSTEM_3)
                    elseif chosen.item == 'canteen' then
                        if not player:hasKeyItem(catalog.ki.canteen) then
                            player:addKeyItem(catalog.ki.canteen)
                            player:printToPlayer('[Omen] You find a mystical canteen!', xi.msg.channel.SYSTEM_3)
                        else
                            player:addGil(10000)
                            player:printToPlayer('[Omen] You find 10,000 gil!', xi.msg.channel.SYSTEM_3)
                        end
                    else
                        -- Random moonbow material lines reroll across the set.
                        local itemId = chosen.item
                        if itemId >= 4077 and itemId <= 4081 then
                            itemId = 4076 + math.random(5)
                        end

                        player:addItem(itemId)
                        player:printToPlayer('[Omen] You claim a treasure!', xi.msg.channel.SYSTEM_3)
                    end

                    npc:setStatus(xi.status.DISAPPEAR)
                end,
            })
        end
    end

    -----------------------------------
    -- Ethereal ingress (floor advancement)
    -----------------------------------
    local function advanceFrom(instance, floorNumber, choice)
        instance:setLocalVar('OmenIngressUp', 0)
        despawnFloorMobs(instance)

        if floorNumber == 1 then
            addRunTime(instance, catalog.time.perFloor)
            spawnFloor(instance, 2)
        elseif floorNumber == 2 then
            if choice == 'smaller' then
                addRunTime(instance, catalog.time.smallerLight)
                spawnFloor(instance, 6)
            else
                addRunTime(instance, catalog.time.perFloor)
                spawnFloor(instance, 3)
            end
        elseif floorNumber == 3 then
            addRunTime(instance, catalog.time.perFloor)
            if math.random() < catalog.rates.bonusFloor then
                instance:setLocalVar('OmenAfterTreasure', 4)
                spawnFloor(instance, 7)
            else
                spawnFloor(instance, 4)
            end
        elseif floorNumber == 4 then
            addRunTime(instance, catalog.time.perFloor)
            spawnFloor(instance, 5)
        elseif floorNumber == 6 then
            -- Ou (choice == 'ou') or the run ends at the rampart.
            if choice == 'ou' then
                addRunTime(instance, catalog.time.perFloor)

                -- The price: every member's beads are consumed.
                forEachPlayer(instance, function(member)
                    for _, beadKi in pairs(catalog.ki.beads) do
                        if member:hasKeyItem(beadKi) then
                            member:delKeyItem(beadKi)
                        end
                    end
                end)
                announce(instance, 'The five beads dissolve into the ingress... something colossal stirs.')

                instance:setLocalVar('OmenBossPick', 6)
                spawnFloor(instance, 5)
            end
        elseif floorNumber == 7 then
            local nextFloor = instance:getLocalVar('OmenAfterTreasure')
            if nextFloor == 4 then
                spawnFloor(instance, 4)
            else
                instanceObject.beginExit(instance)
            end
        end
    end

    local function ouEligible(instance, player)
        if instance:getLocalVar('OmenRouteComplete') ~= 1 then
            return false, 'The rampart\'s trial is unfinished.'
        end

        if instance:getLocalVar('OmenLeaderAliveAtEnd') ~= 1 then
            return false, 'The one who opened the way did not stand at the final blow.'
        end

        local leader = GetPlayerByID(instance:getLocalVar('OmenLeaderId'))
        if not leader or leader:getInstance() ~= instance then
            return false, 'The one who opened the way is gone.'
        end

        for _, beadKi in pairs(catalog.ki.beads) do
            if not leader:hasKeyItem(beadKi) then
                return false, 'The one who opened the way lacks the five beads.'
            end
        end

        return true
    end

    showIngress = function(instance)
        if instance:getLocalVar('OmenIngressUp') == 1 then
            return
        end

        instance:setLocalVar('OmenIngressUp', 1)

        local floorNumber = instance:getLocalVar('OmenFloor')

        instance:insertDynamicEntity({
            objtype  = xi.objType.NPC,
            name     = 'Ethereal_Ingress',
            look     = 2492,
            x        = catalog.arena.ingressPos.x,
            y        = catalog.arena.ingressPos.y,
            z        = catalog.arena.ingressPos.z,
            rotation = catalog.arena.ingressPos.rotation,

            onTrigger = function(player, npc)
                if instance:getLocalVar('OmenIngressUp') == 0 then
                    return
                end

                local isInitiator = player:getID() == instance:getLocalVar('OmenLeaderId')
                local options     = {}

                local function step(choice)
                    return function(p)
                        if instance:getLocalVar('OmenIngressUp') == 0 then
                            return
                        end
                        if p:getID() ~= instance:getLocalVar('OmenLeaderId') then
                            p:printToPlayer('[Omen] Only the one who opened the way may choose.', xi.msg.channel.SYSTEM_3)
                            return
                        end

                        npc:setStatus(xi.status.DISAPPEAR)
                        advanceFrom(instance, instance:getLocalVar('OmenFloor'), choice)
                    end
                end

                if floorNumber == 1 then
                    table.insert(options, { 'Step through (+10 minutes)', step() })
                elseif floorNumber == 2 then
                    table.insert(options, { 'Follow the larger light (+10 minutes)', step('larger') })
                    table.insert(options, { 'Follow the smaller light (+30 minutes)', step('smaller') })
                elseif floorNumber == 3 then
                    table.insert(options, { 'Step through (+10 minutes)', step() })
                elseif floorNumber == 4 then
                    for index, boss in ipairs(catalog.bosses) do
                        local bossIndex = index
                        table.insert(options, {
                            'Challenge ' .. boss.name,
                            function(p)
                                if p:getID() ~= instance:getLocalVar('OmenLeaderId') then
                                    p:printToPlayer('[Omen] Only the one who opened the way may choose.', xi.msg.channel.SYSTEM_3)
                                    return
                                end

                                instance:setLocalVar('OmenBossPick', bossIndex)
                                npc:setStatus(xi.status.DISAPPEAR)
                                advanceFrom(instance, 4)
                            end,
                        })
                    end
                elseif floorNumber == 5 then
                    table.insert(options, {
                        'Depart',
                        function(p)
                            npc:setStatus(xi.status.DISAPPEAR)
                            instanceObject.beginExit(instance)
                        end,
                    })
                elseif floorNumber == 6 then
                    local eligible, why = ouEligible(instance, player)
                    if eligible then
                        table.insert(options, { 'Offer the five beads... (Ou)', step('ou') })
                    elseif why and isInitiator then
                        player:printToPlayer('[Omen] ' .. why, xi.msg.channel.SYSTEM_3)
                    end

                    table.insert(options, {
                        'Depart',
                        function(p)
                            npc:setStatus(xi.status.DISAPPEAR)
                            instanceObject.beginExit(instance)
                        end,
                    })
                elseif floorNumber == 7 then
                    table.insert(options, { 'Continue', step() })
                end

                table.insert(options, { 'Stand back', function() end })

                player:timer(30, function(p)
                    p:customMenu({ title = 'Ethereal Ingress', options = options })
                end)
            end,
        })

        announce(instance, 'An ethereal ingress shimmers at the heart of the platform.')
    end

    -----------------------------------
    -- Deaths
    -----------------------------------
    instanceObject.onOmenMobDeath = function(instance, deadMob, player, optParams)
        if instance:completed() or instance:failed() then
            return
        end

        -- Core dispatches once per nearby member; count each death once.
        if deadMob:getLocalVar('OmenDeathCounted') ~= 0 then
            -- Still let the killer dispatch run payouts below exactly once
            -- via the same guard, so nothing here.
            return
        end

        -- Payouts must act on a player-attributed dispatch; wait for one.
        if not player or not player:isPC() then
            return
        end

        deadMob:setLocalVar('OmenDeathCounted', 1)

        local kind  = deadMob:getLocalVar('OmenKind')
        local alive = math.max(instance:getLocalVar('OmenAliveTotal') - 1, 0)
        instance:setLocalVar('OmenAliveTotal', alive)

        if kind == 1 then
            instance:setLocalVar('OmenAliveSW', math.max(instance:getLocalVar('OmenAliveSW') - 1, 0))
            bumpBonus(instance, 'kill', 1)
        elseif kind == 2 then
            instance:setLocalVar('OmenAliveTR', math.max(instance:getLocalVar('OmenAliveTR') - 1, 0))
            bumpBonus(instance, 'kill', 1)
        end

        local floorNumber = instance:getLocalVar('OmenFloor')

        if floorNumber == 6 then
            -- Bonus route bookkeeping.
            local routeRemaining = math.max(instance:getLocalVar('OmenWaveRemaining') - 1, 0)
            instance:setLocalVar('OmenWaveRemaining', routeRemaining)

            if routeRemaining == 0 then
                instance:setLocalVar('OmenRouteComplete', 1)

                -- Ou demands the opener stand at the final blow.
                local leader = GetPlayerByID(instance:getLocalVar('OmenLeaderId'))
                if leader and leader:getInstance() == instance and leader:getHP() > 0 then
                    instance:setLocalVar('OmenLeaderAliveAtEnd', 1)
                end

                announce(instance, 'The rampart falls silent. The trial is complete!')
                awardObjectiveCredit(instance)
                showIngress(instance)
            elseif alive == 0 then
                instanceObject.spawnBonusWave(instance)
            elseif routeRemaining <= 5 then
                announce(instance, string.format('%d foes remain.', routeRemaining))
            end

            return
        end

        if kind == 3 then
            payoutMidboss(instance, deadMob, player)
            awardObjectiveCredit(instance)
            announce(instance, 'The way forward opens.')
            showIngress(instance)
            return
        end

        if kind == 4 then
            local bossIndex = instance:getLocalVar('OmenBossPick')
            if bossIndex == 6 then
                payoutOu(instance, deadMob, player)
                announce(instance, 'Ou, the Prime Caturae, is defeated. A legend falls!')
            else
                payoutCaturae(instance, deadMob, player, bossIndex)
                announce(instance, 'The Caturae is defeated!')
            end

            -- Chance of the hidden vault on the way out.
            if math.random() < catalog.rates.bonusFloor then
                instance:setLocalVar('OmenAfterTreasure', 99) -- exit afterwards
                despawnFloorMobs(instance)
                spawnFloor(instance, 7)
            else
                showIngress(instance)
            end

            return
        end

        checkMainObjective(instance, deadMob)
    end

    -----------------------------------
    -- Exit / completion
    -----------------------------------
    instanceObject.beginExit = function(instance)
        if instance:completed() then
            return
        end

        local elapsedSeconds = math.floor(instance:getLocalVar('OmenElapsedMs') / 1000)
        instance:setLocalVar('OmenKickAt', elapsedSeconds + 20)
        instance:setLocalVar('OmenLastCountdown', 21)
        instance:complete()
    end

    -----------------------------------
    -- Engine hooks
    -----------------------------------
    instanceObject.onInstanceCreated = function(instance)
        runtime.copySeq = runtime.copySeq + 1
        instance:setLocalVar('OmenCopySeq', runtime.copySeq)
        instance:setLocalVar('OmenLimitMs', catalog.time.start * 1000)
        math.randomseed(os.time() + instance:getID())
        spawnFloor(instance, 1)
    end

    instanceObject.onInstanceCreatedCallback = function(player, instance)
        if not instance then
            player:setLocalVar('OmenInstancePending', 0)
            return
        end

        instance:setLocalVar('OmenLeaderId', player:getID())

        local alliance = player:getAlliance() or { player }
        local registered = 0

        for _, member in ipairs(alliance) do
            if
                member:getObjType() == xi.objType.PC and
                member:getZoneID() == catalog.entry.zoneId and
                member:getLocalVar('OmenInstancePending') == catalog.instanceId
            then
                member:setInstance(instance)
                member:setCharVar('OmenActive', catalog.instanceId)
                member:setLocalVar('OmenInstancePending', 0)
                registered = registered + 1
            end
        end

        if registered == 0 then
            instance:fail()
            return
        end

        for _, member in ipairs(alliance) do
            if member:getInstance() == instance then
                member:setPos(0, 0, 0, 0, catalog.zoneId)
            end
        end
    end

    instanceObject.afterInstanceRegister = function(player)
        local instance = player:getInstance()
        if not instance then
            return
        end

        partyHpScale.maybeResyncInstance(instance)

        player:printToPlayer(
            string.format('[Omen] The trial begins. You have %d minutes -- ethereal ingresses grant more.',
                catalog.time.start / 60),
            xi.msg.channel.SYSTEM_3)
    end

    instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
        instance:setLocalVar('OmenElapsedMs', elapsed)
        partyHpScale.maybeResyncInstance(instance)

        if instance:completed() then
            local remaining = instance:getLocalVar('OmenKickAt') - math.floor(elapsed / 1000)
            if remaining <= 0 then
                forEachPlayer(instance, function(player)
                    leaveOmen(player, 'The trial is over. You return to Reisenjima.')
                end)
                return
            end

            if remaining <= 5 and instance:getLocalVar('OmenLastCountdown') ~= remaining then
                instance:setLocalVar('OmenLastCountdown', remaining)
                announce(instance, string.format('Departing in %d...', remaining))
            end

            return
        end

        if instance:failed() then
            return
        end

        -- Leash: this arena is one platform; pull back anyone drifting
        -- toward the void / zone geometry we cannot vouch for.
        forEachPlayer(instance, function(player)
            local dx = player:getXPos() - catalog.arena.center.x
            local dz = player:getZPos() - catalog.arena.center.z
            if dx * dx + dz * dz > catalog.arena.leash * catalog.arena.leash then
                player:setPos(
                    catalog.arena.entryPos.x,
                    catalog.arena.entryPos.y,
                    catalog.arena.entryPos.z,
                    catalog.arena.entryPos.rotation)
                player:printToPlayer('[Omen] An unseen force draws you back to the trial grounds.', xi.msg.channel.SYSTEM_3)
            end
        end)

        expireBonusObjectives(instance)

        -- Dynamic time limit.
        local limit = instance:getLocalVar('OmenLimitMs')
        if elapsed >= limit then
            announce(instance, 'Time has run out...')
            instance:fail()
            return
        end

        -- Warnings at 5:00 / 1:00 / 0:30 / 0:10 remaining.
        local remaining = math.floor((limit - elapsed) / 1000)
        for _, mark in ipairs({ 300, 60, 30, 10 }) do
            if remaining <= mark and instance:getLocalVar('OmenWarned' .. mark) == 0 then
                instance:setLocalVar('OmenWarned' .. mark, 1)
                announce(instance, string.format('%s remaining!', fmtMinSec(remaining)))
            elseif remaining > mark then
                instance:setLocalVar('OmenWarned' .. mark, 0)
            end
        end

        local emptySince = instance:getWipeTime()
        if emptySince ~= 0 and elapsed - emptySince >= 30 * 1000 then
            instance:fail()
        end
    end

    instanceObject.onInstanceFailure = function(instance)
        forEachPlayer(instance, function(player)
            leaveOmen(player, 'The trial ends. You return to Reisenjima.')
        end)
    end

    instanceObject.onInstanceComplete = function(instance)
        -- beginExit() already messaged; nothing further.
    end

    return instanceObject
end

return runtime
