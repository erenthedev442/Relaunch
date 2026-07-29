-----------------------------------
-- Commemoration_Moogle.lua
--
-- One-time, per-character first-level-99 reward:
--   * choose up to 48 augment catalysts, free of charge
--   * no more than 3 of any one catalyst
--   * choices are final (no refund/exchange path)
--
-- The entitlement unlocks when ANY job first reaches 99 and remains available
-- indefinitely. Reaching 99 on additional jobs does not create another grant.
-- Stock is sourced directly from augment_catalog.lua so this NPC cannot drift
-- from the Arcane Augmenter's accepted catalyst list.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local augmentCatalog = require('modules/custom/lua/augment_catalog')
local itemNames      = require('modules/custom/lua/augment_item_names')
local catalystBank   = require('modules/custom/lua/augment_catalyst_bank')
local m              = Module:new('commemoration_moogle')
local S              = xi.msg.channel.SYSTEM_3

local TOTAL_LIMIT       = 48
local ITEM_LIMIT        = 3
local CATEGORY_PAGE_SIZE = 4
local ITEM_PAGE_SIZE     = 3 -- long effect names must fit customMenu's byte limit

local TOTAL_VAR   = 'CommemCatalystTotal'
local WELCOME_VAR = 'CommemCatalystWelcomed'
local ITEM_PREFIX = 'CommemCat_'

local categoryNames =
{
    [1]  = 'Base Stats',
    [2]  = 'Melee',
    [3]  = 'Magic',
    [4]  = 'Defense',
    [5]  = 'Delays',
    [6]  = 'Duration',
    [7]  = 'Pets',
    [8]  = 'Potency',
    [9]  = 'Skills',
    [10] = 'EXP / Capacity',
    [11] = 'Job Utilities',
}

local categories = {}
for categoryId = 1, #categoryNames do
    categories[categoryId] =
    {
        id      = categoryId,
        name    = categoryNames[categoryId],
        entries = {},
    }
end

local function readableItemName(itemId)
    local name = itemNames[itemId] or string.format('catalyst_%d', itemId)
    name = name:gsub('_', ' ')
    return name:gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest
    end)
end

for itemId, definition in pairs(augmentCatalog) do
    local category = categories[definition.cat]
    if category then
        table.insert(category.entries,
        {
            itemId   = itemId,
            itemName = readableItemName(itemId),
            effect   = definition.label,
        })
    end
end

for _, category in ipairs(categories) do
    table.sort(category.entries, function(left, right)
        if left.effect == right.effect then
            return left.itemId < right.itemId
        end

        return left.effect < right.effect
    end)
end

local function hasLevel99(player)
    for jobId = 1, 22 do
        if (player:getJobLevel(jobId) or 0) >= 99 then
            return true
        end
    end

    return false
end

local function totalClaimed(player)
    return math.max(0, math.min(TOTAL_LIMIT, player:getCharVar(TOTAL_VAR) or 0))
end

local function itemVar(itemId)
    return ITEM_PREFIX .. tostring(itemId)
end

local function itemClaimed(player, itemId)
    return math.max(0, math.min(ITEM_LIMIT, player:getCharVar(itemVar(itemId)) or 0))
end

local function sendMenu(player, menu)
    local snapshot =
    {
        title       = menu.title,
        options     = menu.options,
        onCancelled = menu.onCancelled,
    }

    player:timer(30, function(p)
        p:customMenu(snapshot)
    end)
end

local showMain
local showCategories
local showCatalysts
local showConfirmation

local function showRules(player)
    local used = totalClaimed(player)
    player:printToPlayer(
        '[Commemoration] This is a one-time Legendary reward for reaching level 99 on your first job.', S)
    player:printToPlayer(string.format(
        '[Commemoration] Choose up to %d catalysts in total, with a maximum of %d of any one catalyst. All choices are free.',
        TOTAL_LIMIT, ITEM_LIMIT), S)
    player:printToPlayer(
        '[Commemoration] Selections are final: wrong choices cannot be refunded or exchanged. Pick carefully, kupo!', S)
    player:printToPlayer(
        '[Commemoration] Catalysts are bound to your character and cannot be traded, delivered, bazaared, or auctioned.', S)
    player:printToPlayer(string.format(
        '[Commemoration] Your progress: %d/%d selected; %d remain.',
        used, TOTAL_LIMIT, TOTAL_LIMIT - used), S)
    showMain(player)
end

local function claimCatalyst(player, entry, categoryId, page)
    local used      = totalClaimed(player)
    local itemCount = itemClaimed(player, entry.itemId)

    -- Revalidate every limit at the point the item is granted. This protects
    -- against stale/replayed menu responses and guarantees no extra allowance.
    if used >= TOTAL_LIMIT then
        player:printToPlayer(
            "You've already used up my wares, kupo! Your one-time reward is complete (48/48).", S)
        return
    end

    if itemCount >= ITEM_LIMIT then
        player:printToPlayer(string.format(
            'You have already selected the maximum of %d for %s, kupo! Choose another catalyst.',
            ITEM_LIMIT, entry.effect), S)
        showCatalysts(player, categoryId, page)
        return
    end

    if not catalystBank.depositDrop(player, entry.itemId, 1) then
        player:printToPlayer(
            'The Arcane Augmenter could not store that catalyst. Your allowance was not used.', S)
        showCatalysts(player, categoryId, page)
        return
    end

    used      = used + 1
    itemCount = itemCount + 1
    player:setCharVar(TOTAL_VAR, used)
    player:setCharVar(itemVar(entry.itemId), itemCount)
    player:printToPlayer(string.format(
        '[Commemoration] %s stored for %s. This choice is final. (%d/%d of this type; %d/%d total)',
        entry.itemName, entry.effect, itemCount, ITEM_LIMIT, used, TOTAL_LIMIT), S)

    if used >= TOTAL_LIMIT then
        player:printToPlayer(
            'Your one-time catalyst reward is complete -- 48/48, kupo! May your augments serve you well.', S)
        return
    end

    showCatalysts(player, categoryId, page)
end

showConfirmation = function(player, entry, categoryId, page)
    local count = itemClaimed(player, entry.itemId)
    player:printToPlayer(string.format(
        '[Commemoration] Selection: %s -> %s. This cannot be refunded or exchanged.',
        entry.itemName, entry.effect), S)

    sendMenu(player,
    {
        title = string.format('Claim %s? [%d/%d]', entry.effect:sub(1, 16), count, ITEM_LIMIT),
        options =
        {
            {
                'Yes - final choice',
                function(p)
                    claimCatalyst(p, entry, categoryId, page)
                end,
            },
            {
                'No - go back',
                function(p)
                    showCatalysts(p, categoryId, page)
                end,
            },
        },
    })
end

showCatalysts = function(player, categoryId, page)
    local category = categories[categoryId]
    if not category then
        showCategories(player, 1)
        return
    end

    page = page or 1
    local pages = math.max(1, math.ceil(#category.entries / ITEM_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))

    local first   = (page - 1) * ITEM_PAGE_SIZE + 1
    local last    = math.min(first + ITEM_PAGE_SIZE - 1, #category.entries)
    local options = {}

    for index = first, last do
        local entry         = category.entries[index]
        local selectedEntry = entry -- capture this row for its menu callback
        local count         = itemClaimed(player, entry.itemId)
        local label         = string.format('%s [%d/%d]', entry.effect:sub(1, 16), count, ITEM_LIMIT)
        table.insert(options,
        {
            label,
            function(p)
                if count >= ITEM_LIMIT then
                    p:printToPlayer(string.format(
                        'You have already selected 3 of %s, kupo!', selectedEntry.effect), S)
                    showCatalysts(p, categoryId, page)
                else
                    showConfirmation(p, selectedEntry, categoryId, page)
                end
            end,
        })
    end

    if page > 1 then
        table.insert(options, {
            string.format('<< %d/%d', page - 1, pages),
            function(p) showCatalysts(p, categoryId, page - 1) end,
        })
    end

    if page < pages then
        table.insert(options, {
            string.format('%d/%d >>', page + 1, pages),
            function(p) showCatalysts(p, categoryId, page + 1) end,
        })
    end

    table.insert(options, {
        '<< Categories',
        function(p) showCategories(p, 1) end,
    })

    sendMenu(player,
    {
        title = string.format('%s %d/%d', category.name, totalClaimed(player), TOTAL_LIMIT),
        options = options,
    })
end

showCategories = function(player, page)
    page = page or 1
    local pages = math.ceil(#categories / CATEGORY_PAGE_SIZE)
    page = math.max(1, math.min(page, pages))

    local first   = (page - 1) * CATEGORY_PAGE_SIZE + 1
    local last    = math.min(first + CATEGORY_PAGE_SIZE - 1, #categories)
    local options = {}

    for index = first, last do
        local category         = categories[index]
        local selectedCategory = category -- capture this row for its callback
        table.insert(options, {
            category.name,
            function(p) showCatalysts(p, selectedCategory.id, 1) end,
        })
    end

    if page > 1 then
        table.insert(options, {
            string.format('<< %d/%d', page - 1, pages),
            function(p) showCategories(p, page - 1) end,
        })
    end

    if page < pages then
        table.insert(options, {
            string.format('%d/%d >>', page + 1, pages),
            function(p) showCategories(p, page + 1) end,
        })
    end

    table.insert(options, { '<< Back', function(p) showMain(p) end })

    sendMenu(player,
    {
        title   = string.format('Choose carefully %d/%d', totalClaimed(player), TOTAL_LIMIT),
        options = options,
    })
end

showMain = function(player)
    local used = totalClaimed(player)
    if used >= TOTAL_LIMIT then
        player:printToPlayer(
            "You've already used up my wares, kupo! Your one-time reward is complete (48/48).", S)
        return
    end

    sendMenu(player,
    {
        title = string.format('First 99 Reward %d/%d', used, TOTAL_LIMIT),
        options =
        {
            { 'Choose catalysts', function(p) showCategories(p, 1) end },
            { 'Review the rules',  function(p) showRules(p) end },
            { 'Close',             function() end },
        },
    })
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local CommemorationMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Commemoration_Moogle',
        packetName = string.format('%sCommemoration Moogle', xi.icon.STAR_LARGE),
        look       = 2419,
        x          = 565.1539,
        y          =  -0.1621,
        z          = 546.6039,
        rotation   = 77,
        widescan   = 1,

        onTrigger = function(player, npc)
            if not hasLevel99(player) then
                player:printToPlayer(
                    'Welcome to Legendary, kupo! I keep a special one-time reward for adventurers who reach level 99 for the first time.', S)
                player:printToPlayer(
                    'Return when any job reaches level 99, and I shall open my catalyst wares to you!', S)
                return
            end

            local used = totalClaimed(player)
            if used >= TOTAL_LIMIT then
                player:printToPlayer(
                    "You've already used up my wares, kupo! Your one-time reward is complete (48/48).", S)
                return
            end

            if (player:getCharVar(WELCOME_VAR) or 0) == 0 then
                player:setCharVar(WELCOME_VAR, 1)
                player:printToPlayer(
                    'Congratulations on reaching your first level 99, kupo! You have earned a one-time choice of 48 free augment catalysts.', S)
                player:printToPlayer(
                    'You may select no more than 3 of any one catalyst. Your choices are final: nothing can be refunded or exchanged.', S)
                player:printToPlayer(
                    'All catalysts are character-bound and cannot be traded, delivered, bazaared, or auctioned.', S)
                player:printToPlayer(
                    'You may claim them now or return whenever you wish. Additional level-99 jobs do not grant another reward, so pick carefully!', S)
            else
                player:printToPlayer(string.format(
                    'Welcome back, kupo! You have selected %d/48 catalysts; %d remain. Maximum 3 of each, with no refunds.',
                    used, TOTAL_LIMIT - used), S)
            end

            showMain(player)
        end,
    })

    utils.unused(CommemorationMoogle)
end)

return m
