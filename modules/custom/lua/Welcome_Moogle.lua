-----------------------------------
-- Welcome_Moogle.lua
-- First-stop Bonanza Moogle at GM Home:
--   * one free starter kit per character, claimable at any level
--   * fixed-augment level-50 wares after the current main job reaches 50
--   * all wares cost 1,000 gil
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local catalog = require('modules/custom/lua/welcome_moogle_catalog')
local m       = Module:new('welcome_moogle')
local S       = xi.msg.channel.SYSTEM_3
local SAY     = xi.msg.channel.NS_SAY

local GIFT_VAR        = 'WelcomeMoogle_Gift'
local MIN_LEVEL       = 50
local ITEM_PAGE_SIZE  = 4
local BONANZA_LOOK    = '0x0000D50300000000000000000000000000000000'

local function sendMenu(player, title, options)
    local snapshot = { title = title, options = options }
    player:timer(30, function(p)
        p:customMenu(snapshot)
    end)
end

local function hasStarterGift(player)
    return (player:getCharVar(GIFT_VAR) or 0) ~= 0
end

local function grantStarterGift(player)
    local missing = {}
    for _, gift in ipairs(catalog.starterGifts) do
        if not player:hasItem(gift.id) then
            table.insert(missing, gift)
        end
    end

    if player:getFreeSlotsCount() < #missing then
        player:printToPlayer(
            'Your inventory is too full for all three welcome gifts, kupo! Free up some space and click me again -- I will not forget!',
            SAY)
        return false
    end

    for _, gift in ipairs(missing) do
        if not player:addItem(gift.id, 1) then
            player:printToPlayer(
                'My welcome magic fizzled because your bags changed, kupo! Make room and click me again; any missing gifts are still reserved.',
                SAY)
            return false
        end
    end

    player:setCharVar(GIFT_VAR, 1)
    player:printToPlayer('*flutters pom-pom excitedly* Welcome to Legendary, kupo!', SAY)
    player:printToPlayer(
        "I'm the Welcome Moogle -- every new adventurer gets a little send-off from me!", SAY)
    player:printToPlayer(
        '*poof* Here you go: a Chocobo Shirt, Destrier Beret, and Echad Ring -- on the house, kupo!', SAY)

    if player:getMainLvl() < MIN_LEVEL then
        player:printToPlayer(
            "You're not quite ready for my wares yet, kupo... Come back when you reach level 50, and I'll have starter gear waiting for you!",
            SAY)
    else
        player:printToPlayer(
            "You're already level 50, kupo! Splendid! Click me again and I'll open my starter wares -- augments and all!",
            SAY)
    end

    return true
end

local showMain
local showSubcategories
local showItems
local showConfirmation

local function grantWare(player, entry, categoryName, subcategoryName, page)
    -- Revalidate every condition at purchase time so stale menu callbacks cannot
    -- bypass the level, inventory, ownership, or gil requirements.
    if player:getMainLvl() < MIN_LEVEL then
        player:printToPlayer(
            "You're not quite ready yet, kupo... Come back at level 50 and I'll open my wares for you!",
            SAY)
        return
    end

    if player:hasItem(entry.id) then
        player:printToPlayer(
            string.format("You already have %s, kupo! One is enough for now.", entry.name), S)
        showItems(player, categoryName, subcategoryName, page)
        return
    end

    if player:getGil() < entry.price then
        player:printToPlayer(
            string.format("You'll need %d gil for that, kupo!", entry.price), S)
        showItems(player, categoryName, subcategoryName, page)
        return
    end

    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer(
            'Your bags are stuffed, kupo! Make some room and try again.', S)
        showItems(player, categoryName, subcategoryName, page)
        return
    end

    local augments = {}
    for _, augment in ipairs(entry.augments) do
        table.insert(augments, { id = augment.id, value = augment.value })
    end

    local added = player:addItem({
        id = entry.id,
        exdata =
        {
            augmentKind    = xi.augment.kind.HAS_AUGMENTS,
            augmentSubKind = xi.augment.subKind.STANDARD,
            augments       = augments,
        },
    })

    if not added then
        player:printToPlayer(
            'My wrapping magic failed, kupo! No gil was charged; check your inventory and try again.', S)
        showItems(player, categoryName, subcategoryName, page)
        return
    end

    player:delGil(entry.price)
    player:printToPlayer(
        string.format('Pleasure doing business, kupo! %s is yours, with two starter augments!', entry.name), S)
    showItems(player, categoryName, subcategoryName, page)
end

showConfirmation = function(player, entry, categoryName, subcategoryName, page)
    local capturedEntry = entry
    sendMenu(player, string.format('%s - %d gil?', entry.name, entry.price),
    {
        {
            'Yes, please!',
            function(p)
                grantWare(p, capturedEntry, categoryName, subcategoryName, page)
            end,
        },
        {
            'No - go back',
            function(p)
                showItems(p, categoryName, subcategoryName, page)
            end,
        },
    })
end

showItems = function(player, categoryName, subcategoryName, page)
    local items = catalog.wares[categoryName] and catalog.wares[categoryName][subcategoryName]
    if not items then
        showMain(player)
        return
    end

    page = page or 1
    local pages = math.max(1, math.ceil(#items / ITEM_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    local first = (page - 1) * ITEM_PAGE_SIZE + 1
    local last  = math.min(first + ITEM_PAGE_SIZE - 1, #items)
    local options = {}

    for index = first, last do
        local entry = items[index]
        local capturedEntry = entry
        table.insert(options,
        {
            entry.name,
            function(p)
                p:printToPlayer(string.format(
                    '%s -- %s / %s. Price: 1,000 gil.',
                    capturedEntry.name,
                    capturedEntry.augments[1].label,
                    capturedEntry.augments[2].label), S)
                showConfirmation(p, capturedEntry, categoryName, subcategoryName, page)
            end,
        })
    end

    if page > 1 then
        table.insert(options,
        {
            string.format('<< Page %d/%d', page - 1, pages),
            function(p) showItems(p, categoryName, subcategoryName, page - 1) end,
        })
    end

    if page < pages then
        table.insert(options,
        {
            string.format('Page %d/%d >>', page + 1, pages),
            function(p) showItems(p, categoryName, subcategoryName, page + 1) end,
        })
    end

    table.insert(options,
    {
        '<< Back',
        function(p) showSubcategories(p, categoryName) end,
    })

    sendMenu(player, string.format('%s %d/%d', subcategoryName, page, pages), options)
end

showSubcategories = function(player, categoryName)
    local options = {}
    for _, subcategoryName in ipairs(catalog.subcategoryOrder[categoryName] or {}) do
        local capturedSubcategory = subcategoryName
        table.insert(options,
        {
            capturedSubcategory,
            function(p)
                showItems(p, categoryName, capturedSubcategory, 1)
            end,
        })
    end

    table.insert(options, { '<< Back', function(p) showMain(p) end })
    sendMenu(player, string.format('%s - pick a section, kupo!', categoryName), options)
end

showMain = function(player)
    local options = {}
    for _, categoryName in ipairs(catalog.categoryOrder) do
        local capturedCategory = categoryName
        table.insert(options,
        {
            capturedCategory,
            function(p)
                showSubcategories(p, capturedCategory)
            end,
        })
    end
    table.insert(options, { 'Maybe next time, kupo!', function() end })
    sendMenu(player, 'Welcome Moogle - Starter Wares', options)
end

local function insertDecoration(zone, definition)
    local decoration = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = definition.name,
        look       = definition.look,
        x          = definition.x,
        y          = definition.y,
        z          = definition.z,
        rotation   = definition.rotation,
        widescan   = 0,
        onTrade    = function() end,
        onTrigger  = function() end,
    })
    decoration:hideName(true)
    decoration:setUntargetable(true)
    utils.unused(decoration)
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    -- Retail Bonanza Moogle appearance, framed by two colorful retail conquest
    -- standards. They provide the festive balloon-stall silhouette while staying
    -- untargetable so the Welcome Moogle remains the obvious click target.
    insertDecoration(zone,
    {
        name = 'Welcome_Standard_Red',
        look = '0x00002E0300000000000000000000000000000000',
        x = catalog.npc.x - 2.4, y = catalog.npc.y, z = catalog.npc.z + 0.5, rotation = 67,
    })
    insertDecoration(zone,
    {
        name = 'Welcome_Standard_Blue',
        look = '0x00002F0300000000000000000000000000000000',
        x = catalog.npc.x + 2.4, y = catalog.npc.y, z = catalog.npc.z - 0.5, rotation = 67,
    })

    local welcomeMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Welcome_Moogle',
        packetName = string.format('%sWelcome Moogle', xi.icon.STAR_LARGE),
        look       = BONANZA_LOOK,
        x          = catalog.npc.x,
        y          = catalog.npc.y,
        z          = catalog.npc.z,
        rotation   = catalog.npc.rot,
        widescan   = 1,

        onTrade = function(player)
            player:printToPlayer(
                'No trading needed, kupo! Just click me to claim your welcome kit or browse my wares.', SAY)
        end,

        onTrigger = function(player)
            if not hasStarterGift(player) then
                grantStarterGift(player)
                return
            end

            if player:getMainLvl() < MIN_LEVEL then
                player:printToPlayer(
                    'Welcome back, kupo! I remember you -- you already have your starter kit.', SAY)
                player:printToPlayer(
                    "You're not quite ready yet, kupo... Come back at level 50 and I'll open my wares for you!",
                    SAY)
                return
            end

            player:printToPlayer('Welcome back, kupo! Ready to browse my starter wares?', SAY)
            player:printToPlayer(
                'Everything is 1,000 gil -- bound to you, no trading, delivery, resale, or Auction House, kupo!', S)
            player:printToPlayer(
                'Each piece has two gentle starter augments -- a taste of the Arcane Augmenter waiting later!', S)
            showMain(player)
        end,
    })
    utils.unused(welcomeMoogle)
end)

return m
