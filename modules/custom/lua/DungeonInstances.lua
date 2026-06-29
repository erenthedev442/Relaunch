-----------------------------------
-- Dungeon instance entry NPC
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/dungeon_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npc.zone))

local m = Module:new('dungeon_instances')

local function sendMenu(player, title, options)
    player:timer(30, function(p)
        p:customMenu({ title = title, options = options })
    end)
end

local function dismissTrusts(player)
    local party = player:getPartyWithTrusts()
    if not party then
        return
    end

    for _, member in ipairs(party) do
        if member:isTrust() then
            member:setHP(0)
        end
    end
end

local function collectParty(player)
    local members = {}
    for _, member in ipairs(player:getParty()) do
        if member:getObjType() == xi.objType.PC then
            table.insert(members, member)
        end
    end

    return members
end

local function validateParty(player)
    local leader = player:getPartyLeader()
    if leader and leader:getID() ~= player:getID() then
        return nil, 'Only the party leader can start a dungeon.'
    end

    local members = collectParty(player)
    for _, member in ipairs(members) do
        if member:getZoneID() ~= catalog.npc.zoneId then
            return nil, string.format('%s must be in GM Home.', member:getName())
        elseif member:checkDistance(player) > catalog.partyRange then
            return nil, string.format('%s is too far from the Dungeon Guide.', member:getName())
        elseif member:getInstance() or member:getLocalVar('DungeonInstancePending') ~= 0 then
            return nil, string.format('%s is already entering an instance.', member:getName())
        elseif member:getCharVar('DungeonActive') ~= 0 then
            -- They are standing at the entrance with no live instance pointer,
            -- so this is a stale marker from an abandoned/restarted run.
            member:setCharVar('DungeonActive', 0)
        end
    end

    return members
end

local function startDungeon(player, dungeon)
    local members, err = validateParty(player)
    if not members then
        player:printToPlayer('[Dungeon Guide] ' .. err, xi.msg.channel.SYSTEM_3)
        return
    end

    for _, member in ipairs(members) do
        member:setLocalVar('DungeonInstancePending', dungeon.instanceId)
        dismissTrusts(member)
    end

    player:printToPlayer(
        string.format('[Dungeon Guide] Opening a private %s for %d player(s)...', dungeon.label, #members),
        xi.msg.channel.SYSTEM_3)
    player:createInstance(dungeon.instanceId)

    -- A failed loader has no callback. Clear the transient lock so the party
    -- can retry instead of being stranded behind an "already entering" state.
    player:timer(15000, function(p)
        if not p:getInstance() then
            for _, member in ipairs(collectParty(p)) do
                if member:getLocalVar('DungeonInstancePending') == dungeon.instanceId then
                    member:setLocalVar('DungeonInstancePending', 0)
                end
            end

            p:printToPlayer('[Dungeon Guide] The dungeon failed to open. Please try again.', xi.msg.channel.SYSTEM_3)
        end
    end)
end

local function showConfirm(player, dungeon)
    sendMenu(player, 'Confirm Dungeon',
    {
        {
            'Start private ' .. dungeon.label,
            function(p) startDungeon(p, dungeon) end,
        },
        {
            'Cancel',
            function() end,
        },
    })
end

local showDungeonMenu
local dungeonsPerPage = 4

local function showCategoryMenu(player, category, page)
    local options = {}
    local pageCount = math.max(1, math.ceil(#category.dungeonKeys / dungeonsPerPage))
    local currentPage = math.min(math.max(page or 1, 1), pageCount)
    local firstIndex = (currentPage - 1) * dungeonsPerPage + 1
    local lastIndex = math.min(firstIndex + dungeonsPerPage - 1, #category.dungeonKeys)

    for index = firstIndex, lastIndex do
        local dungeonKey = category.dungeonKeys[index]
        local dungeon = catalog.dungeons[dungeonKey]
        local selectedDungeon = dungeon
        table.insert(options,
        {
            dungeon.label,
            function(p) showConfirm(p, selectedDungeon) end,
        })
    end

    if currentPage > 1 then
        table.insert(options,
        {
            '<< Prev',
            function(p) showCategoryMenu(p, category, currentPage - 1) end,
        })
    end

    if currentPage < pageCount then
        table.insert(options,
        {
            'Next >>',
            function(p) showCategoryMenu(p, category, currentPage + 1) end,
        })
    end

    table.insert(options,
    {
        'Back',
        function(p) showDungeonMenu(p) end,
    })

    sendMenu(player, string.format('%s %d/%d', category.label, currentPage, pageCount), options)
end

showDungeonMenu = function(player)
    local options = {}

    for _, category in ipairs(catalog.categories) do
        local selectedCategory = category
        table.insert(options,
        {
            category.label,
            function(p) showCategoryMenu(p, selectedCategory, 1) end,
        })
    end

    table.insert(options,
    {
        'How do dungeons work?',
        function(p)
            p:printToPlayer(
                '[Dungeon Guide] Your nearby party receives its own private copy. Other parties can run the same dungeon simultaneously without sharing monsters or progress.',
                xi.msg.channel.SYSTEM_3)
        end,
    })

    sendMenu(player, 'Dungeon Guide', options)
end

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npc.zone), function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Dungeon_Guide',
        packetName = string.format('%sDungeon Guide', xi.icon.STAR_LARGE),
        look       = 3021,
        x          = catalog.npc.x,
        y          = catalog.npc.y,
        z          = catalog.npc.z,
        rotation   = catalog.npc.rotation,
        widescan   = 1,

        onTrigger = function(player)
            showDungeonMenu(player)
        end,
    })
    utils.unused(npc)
end)

return m
