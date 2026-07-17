-----------------------------------
-- Welcome_Moogle.lua
-- First-stop Bonanza Moogle at GM Home:
--   * one free starter kit per character, claimable at any level
--   * fixed-augment level-50 wares after the current main job reaches 50
--   * all wares cost 1,000 gil
--   * category navigation feeds the native buy/sell shop, so the client can
--     preview each item's normal equipment stats before purchase
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local catalog = require('modules/custom/lua/welcome_moogle_catalog')
local m       = Module:new('welcome_moogle')
local S       = xi.msg.channel.SYSTEM_3
local SAY     = xi.msg.channel.NS_SAY

local GIFT_VAR        = 'WelcomeMoogle_Gift'
local MIN_LEVEL       = 50
local SHOP_PAGE_SIZE  = 16
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

local function getMainJobName(player)
    local job = player:getMainJob()
    for name, jobId in pairs(xi.job) do
        if jobId == job then
            return name
        end
    end

    return tostring(job)
end

local function getEquippableItems(player, items)
    local result = {}
    for _, entry in ipairs(items or {}) do
        if player:canEquipItem(entry.id, false) then
            table.insert(result, entry)
        end
    end

    return result
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

showItems = function(player, categoryName, subcategoryName, page)
    local stock = catalog.wares[categoryName] and catalog.wares[categoryName][subcategoryName]
    if not stock then
        showMain(player)
        return
    end

    local items = getEquippableItems(player, stock)
    if #items == 0 then
        player:printToPlayer(
            string.format(
                "I don't have anything in %s for %s, kupo! Try another section or change jobs.",
                subcategoryName,
                getMainJobName(player)),
            S)
        showSubcategories(player, categoryName)
        return
    end

    page = page or 1
    local pages = math.max(1, math.ceil(#items / SHOP_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    local first = (page - 1) * SHOP_PAGE_SIZE + 1
    local last  = math.min(first + SHOP_PAGE_SIZE - 1, #items)
    local count = last - first + 1

    player:printToPlayer(string.format(
        'Browsing %s%s. Hover an item to inspect its native stats; every purchase includes its two fixed starter augments.',
        subcategoryName,
        pages > 1 and string.format(' (page %d/%d)', page, pages) or ''), S)

    player:timer(50, function(p)
        p:createShop(count)
        for index = first, last do
            local entry = items[index]
            local augments = {}
            for _, augment in ipairs(entry.augments) do
                table.insert(augments, { id = augment.id, value = augment.value })
            end

            p:addShopItem(entry.id, entry.price,
            {
                augmentKind    = xi.augment.kind.HAS_AUGMENTS,
                augmentSubKind = xi.augment.subKind.STANDARD,
                augments       = augments,
            })
        end
        p:sendMenu(xi.menuType.SHOP)
    end)
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
            player:printToPlayer(
                string.format(
                    'Showing only gear your current main job (%s) can equip. Change jobs to browse another set, kupo!',
                    getMainJobName(player)),
                S)
            showMain(player)
        end,
    })
    utils.unused(welcomeMoogle)
end)

return m
