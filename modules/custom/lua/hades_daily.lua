-----------------------------------
-- hades_daily.lua
--
-- Hades daily quests. Five slots every UTC day, same board for everyone.
-- Kills and deliveries only mark progress. Soul Shards are paid when the
-- player talks to Hades and turns the ready tasks in. 150 only if all
-- five are turned in. Weekend shop is Hades variant 2 (look 2680, '......').
--
-- FROZEN HUB 2026-09-15: do not setPos/hide/rebind any hub NPC except the
-- weekend shop entity this file spawns. Never GetNPCByID-hijack 16959511/32.
--
-- Public API (same require cache as the Module loader):
--   hades.fire(player, eventType, meta)
--   hades.fireCustomKill(player, meta)  -- fans to in-zone alliance PCs
--   hades.formatStatus(player)
--   hades.getShards(player)
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/hades_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('hades_daily')
local hades = {}

local SLOT_COUNT = 5
local S = xi.msg.channel.SYSTEM_3

local function cvSlot(slot, field)
    return string.format('HD_S%d_%s', slot, field)
end

local function getProgress(player, slot)
    return player:getCharVar(cvSlot(slot, 'Prog')) or 0
end

local function isDone(player, slot)
    return (player:getCharVar(cvSlot(slot, 'Done')) or 0) == 1
end

local function currentDayId()
    return catalog.currentDayId()
end

-- Same board for the whole UTC day. Cache it so every mob death does
-- not rebuild five closures.
local cachedDayId
local cachedRev
local cachedQuests

local function todaysQuests()
    local dayId = currentDayId()
    local rev   = catalog.boardRev or 0
    if cachedDayId ~= dayId or cachedRev ~= rev or not cachedQuests then
        cachedDayId  = dayId
        cachedRev    = rev
        cachedQuests = catalog.todaysQuests(dayId)
    end
    return cachedQuests
end

local function resetDay(player)
    for slot = 1, SLOT_COUNT do
        player:setCharVar(cvSlot(slot, 'Prog'), 0)
        player:setCharVar(cvSlot(slot, 'Done'), 0)
    end
    player:setCharVar(catalog.cvEarned, 0)
    player:setCharVar(catalog.cvParcel, 0)
    player:setCharVar(catalog.cvDay, currentDayId())
end

local function isReady(player, slot, quest)
    if isDone(player, slot) then
        return false
    end
    return getProgress(player, slot) >= (quest and quest.target or 1)
end

local function readyCount(player, quests)
    local n = 0
    for slot = 1, SLOT_COUNT do
        if isReady(player, slot, quests[slot]) then
            n = n + 1
        end
    end
    return n
end

-- opts.init     = true  -> first talk / !hades may open today's board
-- opts.announce = false -> skip the rollover line
-- Returns false if this player has never used Hades and we must not
-- write CharVars or print. fire() / delivery hooks rely on that so a
-- random worm kill does not announce Hades to the whole server.
local function ensureDay(player, opts)
    opts = opts or {}
    local stored = player:getCharVar(catalog.cvDay) or 0
    local today  = currentDayId()
    if stored == today then
        return true
    end
    if stored == 0 and not opts.init then
        return false
    end
    local wasRollover = stored ~= 0
    resetDay(player)
    if wasRollover and opts.announce ~= false then
        player:printToPlayer(
            '[Hades] A new day. Five tasks await -- the dead keep their own calendar.',
            S)
    end
    return true
end

function hades.getShards(player)
    return player:getCharVar(catalog.currencyCv) or 0
end

local function payShards(player, amount)
    if not amount or amount <= 0 then
        return 0
    end
    local earned = player:getCharVar(catalog.cvEarned) or 0
    local room   = catalog.dailyCap - earned
    if room <= 0 then
        return 0
    end
    local grant = math.min(amount, room)
    player:setCharVar(catalog.cvEarned, earned + grant)
    player:setCharVar(catalog.currencyCv, hades.getShards(player) + grant)
    return grant
end

local function allDone(player)
    for slot = 1, SLOT_COUNT do
        if not isDone(player, slot) then
            return false
        end
    end
    return true
end

local function completeSlot(player, slot, quest)
    player:setCharVar(cvSlot(slot, 'Done'), 1)
    player:setCharVar(cvSlot(slot, 'Prog'), quest.target)
    local granted = payShards(player, quest.points)
    player:printToPlayer(
        string.format('[Hades] Turned in: %s. +%d %s (total %d).',
            quest.label, granted, catalog.currencyName, hades.getShards(player)),
        S)

    if allDone(player) then
        local lifetime = (player:getCharVar(catalog.cvAllCleared) or 0) + 1
        player:setCharVar(catalog.cvAllCleared, lifetime)
        player:printToPlayer(
            string.format(
                '[Hades] All five tasks done. %d %s banked today. The dead take notice.',
                catalog.dailyCap, catalog.currencyName),
            S)
    end
end

function hades.countRealPCs(player)
    local n = 0
    local ok, members = pcall(function()
        return player:getAlliance()
    end)
    if not ok or not members or #members == 0 then
        return 1
    end
    local zoneId = player:getZoneID()
    for _, mem in ipairs(members) do
        if
            mem and
            mem.getObjType and
            mem:getObjType() == xi.objType.PC and
            not (mem.isTrust and mem:isTrust()) and
            mem:getZoneID() == zoneId
        then
            n = n + 1
        end
    end
    return math.max(n, 1)
end

function hades.fire(player, eventType, metadata)
    if player == nil or player:getObjType() ~= xi.objType.PC then
        return
    end
    if not ensureDay(player) then
        return
    end

    local quests = todaysQuests()
    for slot = 1, SLOT_COUNT do
        local quest = quests[slot]
        if
            quest and
            quest.eventType == eventType and
            not isDone(player, slot)
        then
            local matched = true
            if quest.matches then
                matched = quest.matches(metadata)
            end
            if matched then
                local current = getProgress(player, slot)
                if current < quest.target then
                    local newProg = current + 1
                    player:setCharVar(cvSlot(slot, 'Prog'), newProg)
                    if newProg >= quest.target then
                        player:printToPlayer(
                            string.format('[Hades] %s is ready. Speak to Hades to turn it in.',
                                quest.label),
                            S)
                    elseif quest.target > 1 and newProg % 5 == 0 then
                        player:printToPlayer(
                            string.format('[Hades] %s: %d / %d',
                                quest.label, newProg, quest.target),
                            S)
                    end
                end
            end
        end
    end
end

function hades.fireCustomKill(player, meta)
    if player == nil then
        return
    end
    if not ensureDay(player) then
        return
    end
    meta = meta or {}
    meta.realParty = hades.countRealPCs(player)

    local quest = todaysQuests()[5]
    if quest and quest.nameMatches and quest.nameMatches(meta) and meta.realParty < 3 then
        player:printToPlayer(
            '[Hades] That kill needs 3 real players in your alliance. Trusts do not count.',
            S)
        return
    end

    local ok, members = pcall(function()
        return player:getAlliance()
    end)
    if not ok or not members or #members == 0 then
        hades.fire(player, 'custom_nm', meta)
        return
    end

    local zoneId = player:getZoneID()
    for _, mem in ipairs(members) do
        if
            mem and
            mem.getObjType and
            mem:getObjType() == xi.objType.PC and
            not (mem.isTrust and mem:isTrust()) and
            mem:getZoneID() == zoneId
        then
            hades.fire(mem, 'custom_nm', meta)
        end
    end
end

function hades.takeParcel(player)
    ensureDay(player, { init = true })
    if isDone(player, 2) or isReady(player, 2, todaysQuests()[2]) then
        return false
    end
    if (player:getCharVar(catalog.cvParcel) or 0) >= 1 then
        return false
    end
    player:setCharVar(catalog.cvParcel, 1)
    local quest = todaysQuests()[2]
    player:printToPlayer(
        string.format('[Hades] The parcel is yours. Deliver it to %s.',
            quest and quest.label:gsub('^Parcel: ', '') or 'the named NPC'),
        S)
    return true
end

local function deliveryDest(npcName)
    for _, dest in ipairs(catalog.deliveries) do
        if dest.npc == npcName then
            return dest
        end
    end
    return nil
end

function hades.tryDeliver(player, npcName)
    if player == nil then
        return false
    end
    if
        (player:getCharVar(catalog.cvParcel) or 0) < 1 and
        (player:getCharVar(catalog.cvDay) or 0) == 0
    then
        return false
    end
    if not ensureDay(player) then
        return false
    end
    local quest = todaysQuests()[2]
    if not quest or isDone(player, 2) or isReady(player, 2, quest) then
        return false
    end
    if (player:getCharVar(catalog.cvParcel) or 0) < 1 then
        return false
    end
    if player:getZoneID() ~= quest.zoneId then
        return false
    end
    if quest.npc and npcName and npcName ~= quest.npc then
        return false
    end
    player:setCharVar(catalog.cvParcel, 2)

    local dest = deliveryDest(quest.npc)
    if dest and dest.say then
        local who = dest.speaker or dest.npc
        for _, line in ipairs(dest.say) do
            player:printToPlayer(string.format('%s : %s', who, line), S)
        end
    end

    hades.fire(player, 'delivery', { zoneId = player:getZoneID(), npc = quest.npc })
    return true
end

function hades.turnInReady(player)
    ensureDay(player, { init = true })
    local quests = todaysQuests()
    local turned = 0
    for slot = 1, SLOT_COUNT do
        if isReady(player, slot, quests[slot]) then
            completeSlot(player, slot, quests[slot])
            turned = turned + 1
        end
    end
    if turned == 0 then
        player:printToPlayer('[Hades] Nothing is ready. Finish a task, then return.', S)
    end
    return turned
end

local function slotMark(player, slot, quest)
    if isDone(player, slot) then
        return 'turned in'
    end
    if isReady(player, slot, quest) then
        return 'READY - talk to Hades'
    end
    if slot == 2 and (player:getCharVar(catalog.cvParcel) or 0) < 1 then
        return 'collect parcel at Hades'
    end
    local prog = math.min(getProgress(player, slot), quest.target)
    return string.format('%d/%d', prog, quest.target)
end

function hades.formatStatus(player)
    ensureDay(player, { init = true })
    local quests = todaysQuests()
    local lines =
    {
        string.format('>>> HADES OBJECTIVES  (talk to Hades to turn in) <<<'),
    }
    for slot = 1, SLOT_COUNT do
        local quest = quests[slot]
        lines[#lines + 1] = string.format('  [%d] %s  (%s)',
            quest.points, quest.label, slotMark(player, slot, quest))
        lines[#lines + 1] = '      ' .. quest.description
    end
    return lines
end

local hadesMenu = { title = 'Hades', options = {} }

local function showRoot(player)
    ensureDay(player, { init = true })
    local quests    = todaysQuests()
    local doneCount = 0
    for slot = 1, SLOT_COUNT do
        if isDone(player, slot) then
            doneCount = doneCount + 1
        end
    end
    local ready = readyCount(player, quests)
    local holdingParcel = (player:getCharVar(catalog.cvParcel) or 0) >= 1

    local opts = {}
    if ready > 0 then
        opts[#opts + 1] =
        {
            string.format('Turn in ready tasks (%d)', ready),
            function(p)
                hades.turnInReady(p)
                showRoot(p)
            end,
        }
    end
    if not isDone(player, 2) and not isReady(player, 2, quests[2]) and not holdingParcel then
        opts[#opts + 1] =
        {
            'Take today\'s parcel',
            function(p)
                hades.takeParcel(p)
                showRoot(p)
            end,
        }
    end
    opts[#opts + 1] =
    {
        'Today\'s tasks',
        function(p)
            for _, line in ipairs(hades.formatStatus(p)) do
                p:printToPlayer(line, S)
            end
            showRoot(p)
        end,
    }
    opts[#opts + 1] =
    {
        'Crate hold',
        function(p)
            catalog.showCrateHold(p, showRoot, false)
        end,
    }
    if
        xi.erenQuest and
        xi.erenQuest.shouldShowHades and
        xi.erenQuest.shouldShowHades(player)
    then
        opts[#opts + 1] =
        {
            'The Name Beyond the Ferry',
            function(p)
                xi.erenQuest.openHades(p)
            end,
        }
    end
    opts[#opts + 1] = { 'Close', function(_) end }

    hadesMenu.title   = string.format('Hades  %d/5 turned in', doneCount)
    hadesMenu.options = opts
    local snapshot = { title = hadesMenu.title, options = hadesMenu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Family + open-world boss kills
-----------------------------------
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    pcall(function()
        if
            player == nil or
            player:getObjType() ~= xi.objType.PC or
            mob == nil or
            mob:getObjType() ~= xi.objType.MOB or
            (player:getCharVar(catalog.cvDay) or 0) == 0
        then
            return
        end

        local superFamily = 0
        pcall(function()
            superFamily = mob:getSuperFamily() or 0
        end)
        if superFamily > 0 then
            -- Capped players farming lv10 fish: CheckMob vs HiPCLvl is Too Weak,
            -- so checkKillCredit is false and the family slot does not move.
            if player.checkKillCredit and player:checkKillCredit(mob) then
                hades.fire(player, 'family_kill', { superFamily = superFamily })
            else
                pcall(function()
                    if (player:getLocalVar('HD_WeakFam') or 0) ~= 0 then
                        return
                    end
                    if not ensureDay(player) then
                        return
                    end
                    local quest = todaysQuests()[1]
                    if
                        quest and
                        quest.eventType == 'family_kill' and
                        quest.matches and
                        quest.matches({ superFamily = superFamily })
                    then
                        player:setLocalVar('HD_WeakFam', 1)
                        player:printToPlayer(
                            '[Hades] Too weak. That family only counts when the kill yields experience.',
                            S)
                    end
                end)
            end
        end

        hades.fire(player, 'boss_kill', {
            name   = mob:getName(),
            zoneId = mob:getZoneID() or player:getZoneID(),
        })
    end)
end)

-----------------------------------
-- Delivery: talking to today's town NPC
-----------------------------------
-- Static NPCs send getName() without the isRenamed 0x01 prefix. Classic
-- DAT rows still show Ostalie / Zhikkom. ToAU (Chayaya, Gavrie, Nanaroon),
-- WotG, and SoA IDs often have no client name row, so the plate is "NPC".
local function applyDeliveryName(npc, dest)
    if not npc or not dest then
        return
    end
    local display = dest.speaker or dest.npc
    pcall(function()
        npc:hideName(false)
        npc:renameEntity(display, true)
    end)
end

local function applyDeliveryNames()
    for _, dest in ipairs(catalog.deliveries) do
        if dest.npcId then
            applyDeliveryName(GetNPCByID(dest.npcId), dest)
        end
    end
end

for _, dest in ipairs(catalog.deliveries) do
    local thisDest = dest
    local npcName = dest.npc
    local npcId = dest.npcId
    local scriptPath = string.format('scripts/zones/%s/npcs/%s', dest.zone, dest.npc)
    pcall(require, scriptPath)
    local hook = string.format('xi.zones.%s.npcs.%s.onTrigger', dest.zone, dest.npc)
    pcall(function()
        m:addOverride(hook, function(player, npc)
            applyDeliveryName(npc, thisDest)
            pcall(function()
                hades.tryDeliver(player, npcName)
            end)
            super(player, npc)
        end)
    end)

    local zonePath = string.format('scripts/zones/%s/Zone', dest.zone)
    pcall(require, zonePath)
    local zoneHook = string.format('xi.zones.%s.Zone.onInitialize', dest.zone)
    pcall(function()
        m:addOverride(zoneHook, function(zone)
            super(zone)
            applyDeliveryName(GetNPCByID(npcId), thisDest)
        end)
    end)
end

-----------------------------------
-- NPCs: talking Daily Hades (look 2674, dailies) + silent 2680 shop ('......')
-- NE beach is only those two plus Oggbi. Never hide Oggbi, never GetNPCByID
-- a boot-stale dynamic id, never park a body on the plaza Alexander sentinels.
-----------------------------------
local NE_BEACH_X = 600
local DAILY_LOOK = catalog.dailyLook or 2674

local function entityAlive(ent)
    local ok = false
    pcall(function()
        ok = ent ~= nil
            and ent:isValidEntity()
            and ent:getStatus() ~= xi.status.DISAPPEAR
    end)
    return ok
end

local function isOggbiEntity(ent)
    local name = ''
    pcall(function()
        name = tostring(ent:getName() or '')
    end)
    return name:find('Oggbi', 1, true) ~= nil
end

local function isNeBeach(ent)
    local ok = false
    pcall(function()
        ok = ent.getXPos and ent:getXPos() > NE_BEACH_X
    end)
    return ok
end

local function hideEntity(ent)
    pcall(function()
        ent:setStatus(xi.status.DISAPPEAR)
    end)
end

local function eachNeBeachEntity(zone, fn)
    if not zone then
        return
    end
    local function walk(ok, list)
        if not ok or type(list) ~= 'table' then
            return
        end
        for _, ent in pairs(list) do
            local objtype
            pcall(function()
                objtype = ent:getObjType()
            end)
            if ent and objtype == xi.objType.NPC and isNeBeach(ent) and not isOggbiEntity(ent) then
                fn(ent)
            end
        end
    end
    if zone.getNPCs then
        walk(pcall(function()
            return zone:getNPCs()
        end))
    end
end

local function modelId(ent)
    local look = 0
    pcall(function()
        look = ent:getModelId() or 0
    end)
    return look
end

local function openSecondForm(player)
    catalog.sayShopSilence(player)
    if catalog.isShopOpen() then
        catalog.showShop(player, nil, true)
    else
        catalog.showCrateHold(player, nil, true)
    end
end

local function showDailyHades(player)
    ensureDay(player, { init = true })
    if (player:getCharVar(catalog.cvMet) or 0) == 0 then
        player:setCharVar(catalog.cvMet, 1)
        for _, line in ipairs(catalog.intro) do
            player:printToPlayer(string.format('Hades : %s', line), S)
        end
    end
    for _, line in ipairs(hades.formatStatus(player)) do
        player:printToPlayer(line, S)
    end
    if catalog.isShopOpen() then
        player:printToPlayer(
            '[Hades] The ferry is up. Turn in what you have finished. The second form keeps the wares of souls who have perished. Seek him.',
            S)
    else
        player:printToPlayer(
            '[Hades] Bring me proof of the day\'s work. The silent one opens only when the weekend keeps.',
            S)
    end
    showRoot(player)
end

local function restoreVisible(ent)
    if not ent then
        return
    end
    pcall(function()
        ent:setStatus(xi.status.NORMAL)
    end)
    pcall(function()
        ent:setUntargetable(false)
    end)
end

local function restoreOggbi()
    local zone = GetZone(catalog.npcPos.zoneId)
    if not zone then
        return
    end
    local oggbiPos = require('modules/custom/lua/prime_repeat_catalog').oggbi
    local names = { 'Oggbi', 'Oggbi_Prime_Repeat', 'DE_Oggbi_Prime_Repeat' }
    if zone.queryEntitiesByName then
        for _, name in ipairs(names) do
            local ents = zone:queryEntitiesByName(name)
            if type(ents) == 'table' then
                for _, ent in pairs(ents) do
                    restoreVisible(ent)
                    pcall(function()
                        ent:hideName(false)
                        ent:setPos(oggbiPos.x, oggbiPos.y, oggbiPos.z, oggbiPos.rotation)
                        if oggbiPos.race then
                            ent:setLook({ race = oggbiPos.race, face = oggbiPos.face })
                        end
                        if type(oggbiPos.gear) == 'table' then
                            for _, piece in ipairs(oggbiPos.gear) do
                                ent:setModelId(piece[1], piece[2])
                            end
                        end
                    end)
                end
            end
        end
    end
end

local function despawnWrongShopBodies()
    if xi.hades_shop_entity then
        hideEntity(xi.hades_shop_entity)
        xi.hades_shop_entity = nil
    end
    local zone = GetZone(catalog.npcPos.zoneId)
    if not zone then
        return
    end
    -- Only the NE beach. Hide leftover Hades v2 (2680) bodies -- named
    -- '......' clones AND the old unnamed placement. Daily Hades is 2674
    -- and is left alone. Oggbi is skipped in eachNeBeachEntity.
    eachNeBeachEntity(zone, function(ent)
        local look = modelId(ent)
        if look == DAILY_LOOK then
            return
        end
        local pname = ''
        pcall(function()
            pname = tostring(ent:getPacketName() or ent:getName() or '')
        end)
        -- Leftover unnamed 2680 (and any nameless clone) on this beach only.
        if look == catalog.shopLook or pname == '' or pname == 'DE_' then
            hideEntity(ent)
        end
    end)
end

local function bindDailyNpc(npc)
    if not npc then
        return false
    end
    restoreVisible(npc)
    pcall(function()
        npc:hideName(false)
        npc:setUntargetable(false)
        npc:removeListener('HADES_DAILY')
        npc:setPos(catalog.npcPos.x, catalog.npcPos.y, catalog.npcPos.z, catalog.npcPos.rotation)
        npc:setModelId(DAILY_LOOK)
    end)
    npc:addListener('ON_TRIGGER', 'HADES_DAILY', function(player, _)
        showDailyHades(player)
    end)
    xi.hades_daily_entity = npc
    return true
end

local function findDailyHades(zone)
    if entityAlive(xi.hades_daily_entity) and modelId(xi.hades_daily_entity) == DAILY_LOOK then
        return xi.hades_daily_entity
    end
    local found = nil
    eachNeBeachEntity(zone, function(ent)
        if not found and modelId(ent) == DAILY_LOOK then
            found = ent
        end
    end)
    return found
end

local function spawnDailyHades(zone)
    local pos = catalog.npcPos
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Hades',
        packetName = 'Hades',
        look       = DAILY_LOOK,
        x          = pos.x,
        y          = pos.y,
        z          = pos.z,
        rotation   = pos.rotation,
        widescan   = 1,
        onTrigger  = function(player, _)
            showDailyHades(player)
        end,
    })
    if npc then
        bindDailyNpc(npc)
        print('[hades_daily] spawned Daily Hades look 2674 on the NE pad')
    end
    return npc
end

local function placeDailyHades()
    local zone = GetZone(catalog.npcPos.zoneId)
    if not zone then
        return
    end
    local existing = findDailyHades(zone)
    if existing then
        bindDailyNpc(existing)
        return
    end
    spawnDailyHades(zone)
end

local function spawnSilentShop(zone)
    local pos = catalog.shopNpcPos
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = '......',
        packetName = '......',
        look       = catalog.shopLook,
        x          = pos.x,
        y          = pos.y,
        z          = pos.z,
        rotation   = pos.rotation,
        widescan   = 1,
        onTrigger  = function(player, _)
            openSecondForm(player)
        end,
    })
    if npc then
        pcall(function()
            npc:hideName(false)
            npc:setUntargetable(false)
            npc:setModelId(catalog.shopLook)
        end)
        xi.hades_shop_entity = npc
    end
    return npc
end

local function placeSilentShop()
    local zone = GetZone(catalog.npcPos.zoneId)
    if not zone then
        return
    end
    despawnWrongShopBodies()
    spawnSilentShop(zone)
end

local function applyLiveNpcs()
    restoreOggbi()
    placeDailyHades()
    placeSilentShop()
    applyDeliveryNames()
end

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    restoreOggbi()
    placeDailyHades()
    placeSilentShop()
end)

pcall(applyLiveNpcs)

m.fire           = hades.fire
m.fireCustomKill = hades.fireCustomKill
m.formatStatus   = hades.formatStatus
m.getShards      = hades.getShards
m.takeParcel     = hades.takeParcel
m.tryDeliver     = hades.tryDeliver
m.turnInReady    = hades.turnInReady
m.countRealPCs   = hades.countRealPCs

return m
