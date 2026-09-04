-----------------------------------
-- hades_daily.lua
--
-- Hades daily quests. Five slots every UTC day, same board for everyone.
-- Kills and deliveries only mark progress. Soul Shards are paid when the
-- player talks to Hades and turns the ready tasks in. 150 only if all
-- five are turned in. Weekend shop is a stub until the catalog lands.
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
local cachedQuests

local function todaysQuests()
    local dayId = currentDayId()
    if cachedDayId ~= dayId or not cachedQuests then
        cachedDayId  = dayId
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
        catalog.isShopOpen() and 'Shop (weekend)' or 'Shop (closed)',
        function(p)
            p:printToPlayer('[Hades] ' .. catalog.shopStatusLine(), S)
            p:printToPlayer(
                string.format('[Hades] You hold %d %s. Relic wares will cost %d.',
                    hades.getShards(p), catalog.currencyName, catalog.relicPrice),
                S)
            showRoot(p)
        end,
    }
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
            hades.fire(player, 'family_kill', { superFamily = superFamily })
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
for _, dest in ipairs(catalog.deliveries) do
    local scriptPath = string.format('scripts/zones/%s/npcs/%s', dest.zone, dest.npc)
    pcall(require, scriptPath)
    local hook = string.format('xi.zones.%s.npcs.%s.onTrigger', dest.zone, dest.npc)
    local npcName = dest.npc
    pcall(function()
        m:addOverride(hook, function(player, npc)
            pcall(function()
                hades.tryDeliver(player, npcName)
            end)
            super(player, npc)
        end)
    end)
end

-----------------------------------
-- NPC
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Hades',
        packetName = string.format('%sHades', xi.icon.MOON),
        look       = '0x0000720A00000000000000000000000000000000',
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, _)
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
                    '[Hades] The ferry is up. Turn in what you have finished. Wares are still being negotiated.',
                    S)
            else
                player:printToPlayer(
                    '[Hades] Bring me proof of the day\'s work. The shop waits until Saturday.',
                    S)
            end
            showRoot(player)
        end,
    })
    utils.unused(npc)
end)

m.fire           = hades.fire
m.fireCustomKill = hades.fireCustomKill
m.formatStatus   = hades.formatStatus
m.getShards      = hades.getShards
m.takeParcel     = hades.takeParcel
m.tryDeliver     = hades.tryDeliver
m.turnInReady    = hades.turnInReady
m.countRealPCs   = hades.countRealPCs

return m
