-----------------------------------
-- Area: Reisenjima (291)
-- NPC: Incantrix (Omen gatekeeper)
-- !pos -358.77 -440.69 -844.51 291
--
-- Retail: dispenses one Mystical Canteen per 20 Earth hours (banking up
-- to 3) and admits canteen-holders into Omen (Reisenjima Henge).
-- Relaunch QoL: she also bestows Phoenix's Blessing on level-99 heroes
-- directly (retail gates it behind Rhapsodies of Vana'diel).
--
-- Runtime: modules/custom/lua/omen_instance.lua
-- Data:    modules/custom/lua/omen_catalog.lua
-----------------------------------
local catalog     = require('modules/custom/lua/omen_catalog')
local remaCatalog = require('modules/custom/lua/rema_ws_tier_catalog')

---@type TNpcEntity
local entity = {}

-- REMA/Prime entry gate (owner 2026-07-12): every entrant must have BUILT one of
-- the server's ultimate weapons before Omen will open for them --
--   * any final (iLvl 119 III) Relic / Empyrean / Mythic or final Aeonic, owned
--     in ANY container (hasItem scans inventory, wardrobes, storage, and the
--     equipped slots), sourced from rema_ws_tier_catalog so the list never drifts, OR
--   * a claimed Prime (PrimeArmory stamps PW_WeaponClaimed = item_id on claim).
-- Ownership isn't consumed -- you keep fighting with the weapon you built.
local remaWeaponIds = {}
for _, w in ipairs(remaCatalog.WEAPONS) do
    remaWeaponIds[#remaWeaponIds + 1] = w.itemId
end

local function hasBuiltUltimateWeapon(player)
    if (player:getCharVar('PW_WeaponClaimed') or 0) ~= 0 then
        return true
    end
    for _, itemId in ipairs(remaWeaponIds) do
        if player:hasItem(itemId) then
            return true
        end
    end
    return false
end

local function accrueCanteens(player)
    local now    = os.time()
    local stamp  = player:getCharVar('OmenCanteenStamp')
    local banked = player:getCurrency(catalog.canteen.currency)

    if stamp == 0 then
        -- First visit: one canteen on the house, clock starts now.
        player:setCurrency(catalog.canteen.currency, math.min(banked + 1, catalog.canteen.maxBanked))
        player:setCharVar('OmenCanteenStamp', now)
        return
    end

    local earned = math.floor((now - stamp) / catalog.canteen.cooldown)
    if earned > 0 then
        local newBanked = math.min(banked + earned, catalog.canteen.maxBanked)
        player:setCurrency(catalog.canteen.currency, newBanked)

        if newBanked >= catalog.canteen.maxBanked then
            player:setCharVar('OmenCanteenStamp', now)
        else
            player:setCharVar('OmenCanteenStamp', stamp + earned * catalog.canteen.cooldown)
        end
    end
end

local function canteenStatusLine(player)
    local banked = player:getCurrency(catalog.canteen.currency)
    local stamp  = player:getCharVar('OmenCanteenStamp')
    local line   = string.format('Canteens in reserve: %d/%d.', banked, catalog.canteen.maxBanked)

    if banked < catalog.canteen.maxBanked and stamp > 0 then
        local nextIn = catalog.canteen.cooldown - (os.time() - stamp)
        if nextIn > 0 then
            line = line .. string.format(' Next in %dh%02dm.', math.floor(nextIn / 3600), math.floor((nextIn % 3600) / 60))
        end
    end

    return line
end

local function giveCanteen(player)
    if player:hasKeyItem(catalog.ki.canteen) then
        player:printToPlayer('[Incantrix] You already carry a mystical canteen. One per customer at a time!', xi.msg.channel.SYSTEM_3)
        return
    end

    local banked = player:getCurrency(catalog.canteen.currency)
    if banked <= 0 then
        player:printToPlayer('[Incantrix] The essence has not distilled yet. ' .. canteenStatusLine(player), xi.msg.channel.SYSTEM_3)
        return
    end

    player:setCurrency(catalog.canteen.currency, banked - 1)
    player:addKeyItem(catalog.ki.canteen)
    player:printToPlayer('[Incantrix] One mystical canteen, freshly filled! ' .. canteenStatusLine(player), xi.msg.channel.SYSTEM_3)
end

local function collectEntrants(player)
    local members = {}
    local group   = player:getAlliance() or { player }

    for _, member in ipairs(group) do
        if member:getObjType() == xi.objType.PC then
            table.insert(members, member)
        end
    end

    return members
end

local function validateEntry(player)
    local leader = player:getPartyLeader()
    if leader and leader:getID() ~= player:getID() then
        return nil, 'Only the party (or alliance) leader may open the way.'
    end

    local members = collectEntrants(player)
    if #members > catalog.maxMembers then
        return nil, string.format('No more than %d may enter.', catalog.maxMembers)
    end

    for _, member in ipairs(members) do
        if member:getZoneID() ~= catalog.entry.zoneId then
            return nil, string.format('%s must be here in Reisenjima.', member:getName())
        elseif member:checkDistance(player) > catalog.partyRange then
            return nil, string.format('%s is too far from the ingress.', member:getName())
        elseif not member:hasKeyItem(catalog.ki.blessing) then
            return nil, string.format('%s lacks Phoenix\'s blessing.', member:getName())
        elseif not member:hasKeyItem(catalog.ki.canteen) then
            return nil, string.format('%s lacks a mystical canteen.', member:getName())
        elseif not hasBuiltUltimateWeapon(member) then
            return nil, string.format('%s must first forge an ultimate weapon (Relic, Empyrean, Mythic, Aeonic, or Prime).', member:getName())
        elseif member:getInstance() or member:getLocalVar('OmenInstancePending') ~= 0 then
            return nil, string.format('%s is already bound to an instance.', member:getName())
        elseif member:getCharVar('OmenActive') ~= 0 then
            -- Stale marker from an abandoned run; clear it.
            member:setCharVar('OmenActive', 0)
        end
    end

    return members
end

local function enterOmen(player)
    local members, err = validateEntry(player)
    if not members then
        player:printToPlayer('[Incantrix] ' .. err, xi.msg.channel.SYSTEM_3)
        return
    end

    -- The canteens are drunk on the way in.
    for _, member in ipairs(members) do
        member:delKeyItem(catalog.ki.canteen)
        member:setLocalVar('OmenInstancePending', catalog.instanceId)
    end

    player:printToPlayer(string.format('[Incantrix] Opening the way for %d... may the moonbow light your path.', #members), xi.msg.channel.SYSTEM_3)
    player:createInstance(catalog.instanceId)

    -- Failed loaders have no callback; free the party to retry.
    player:timer(15000, function(p)
        if not p:getInstance() then
            for _, member in ipairs(collectEntrants(p)) do
                if member:getLocalVar('OmenInstancePending') == catalog.instanceId then
                    member:setLocalVar('OmenInstancePending', 0)
                    if not member:hasKeyItem(catalog.ki.canteen) then
                        member:addKeyItem(catalog.ki.canteen)
                    end
                end
            end

            p:printToPlayer('[Incantrix] The way would not open. Your canteens are returned -- try again.', xi.msg.channel.SYSTEM_3)
        end
    end)
end

entity.onTrigger = function(player, npc)
    accrueCanteens(player)

    local options = {}

    if not player:hasKeyItem(catalog.ki.blessing) then
        table.insert(options, {
            'Receive Phoenix\'s blessing',
            function(p)
                if p:getMainLvl() < 99 then
                    p:printToPlayer('[Incantrix] Phoenix favors only heroes of the highest caliber. (Level 99 required.)', xi.msg.channel.SYSTEM_3)
                    return
                end

                p:addKeyItem(catalog.ki.blessing)
                p:printToPlayer('[Incantrix] A portion of Phoenix\'s vim and vigor, entrusted to you. Guard it well.', xi.msg.channel.SYSTEM_3)
            end,
        })
    end

    table.insert(options, {
        'Receive a mystical canteen',
        function(p)
            giveCanteen(p)
        end,
    })

    table.insert(options, {
        'Enter Omen',
        function(p)
            enterOmen(p)
        end,
    })

    table.insert(options, {
        'What is Omen?',
        function(p)
            p:printToPlayer('[Incantrix] Beyond the ingress lie five gates. Clear each floor\'s trial to advance; ethereal ingresses grant more time (10 minutes to start, 50 at most).', xi.msg.channel.SYSTEM_3)
            p:printToPlayer('[Incantrix] Every soul needs Phoenix\'s blessing and a mystical canteen -- one canteen fills every 20 hours, and I\'ll bank up to three for you.', xi.msg.channel.SYSTEM_3)
            p:printToPlayer('[Incantrix] The Caturae at the summit guard scales and treasures. Collect all five of their beads and seek the smaller light... if you dare.', xi.msg.channel.SYSTEM_3)
            p:printToPlayer('[Incantrix] ' .. canteenStatusLine(p), xi.msg.channel.SYSTEM_3)
        end,
    })

    player:customMenu({
        title   = 'Incantrix',
        options = options,
    })
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
