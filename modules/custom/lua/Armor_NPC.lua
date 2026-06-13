-----------------------------------
-- Armor_NPC.lua
-- Endgame armor vendor: spend medals to purchase BiS armor for the 5
-- main slots. Optional extra-drop requirements per tier or per item
-- are supported via catalog.goldExtraDrop and per-row `drop = {...}`.
-- Zone: Reisenjima_Henge (same row as Hub/Spawner/Weapons NPCs).
--
-- Seal currencies (shared with the Weapons NPC):
-- Seal currencies (loaded from catalog.seals at runtime - see catalog file
-- for the actual names and tier descriptions; main-menu labels below take
-- the first whitespace-delimited word of each seal name for compactness).
--
-- Menu flow:
--   Main menu (tier picker)
--     -> Tier menu (slot picker: Head / Body / Hands / Legs / Feet)
--        -> Item menu (paginated armor list)
--
-- To add gear: edit armor_catalog.lua only.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/armor_catalog')
local sealBank = require('modules/custom/lua/hl_seal_currency')

-- Resolve the zone script path from the catalog so the require + override
-- target stay in sync with catalog.zonePath. No more hardcoded zone names.
local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))
-----------------------------------
local m = Module:new('armor_npc')

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- Resolve the extra-drop requirement for an item.
    -- Per-row `drop = {id, qty}` overrides the tier default.
    -- Bronze/Silver tiers have no default extra drop.
    -----------------------------------
    local function getExtraDrop(tierKey, item)
        if item.drop then return item.drop end
        if tierKey == 'gold' then return catalog.goldExtraDrop end
        return nil
    end

    -----------------------------------
    -- Purchase helper
    -----------------------------------
    local function purchase(player, tierKey, sealDef, item)
        local seals = player:getItemCount(sealDef.id)
        if seals < item.cost then
            player:printToPlayer(
                string.format('Need %d %s (you have %d), kupo!', item.cost, sealDef.name, seals),
                xi.msg.channel.SYSTEM_3
            )
            return
        end

        local extra = getExtraDrop(tierKey, item)
        if extra then
            local owned = player:getItemCount(extra.id)
            if owned < extra.qty then
                player:printToPlayer(
                    string.format('Also need %d x %s (you have %d), kupo!',
                        extra.qty, extra.name or string.format('item %d', extra.id), owned),
                    xi.msg.channel.SYSTEM_3
                )
                return
            end
        end

        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('Inventory full! Free a slot first, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end

        -- Consume seals (and any extra) across EVERY stack and container the
        -- balance check counts. The old delItem() only hit the first stack of
        -- main inventory and silently removed nothing on a multi-stack/wrong-
        -- container miss, handing out free gear. Give the item only if the
        -- medals were actually taken.
        if not sealBank.take(player, sealDef.id, item.cost) then
            player:printToPlayer('Could not take your seals - move them into your inventory and retry, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        if extra and not sealBank.take(player, extra.id, extra.qty) then
            player:addItem({ id = sealDef.id, quantity = item.cost }) -- refund the seals to keep it atomic
            player:printToPlayer('Could not take the required extra item, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        player:addItem({ id = item.id, quantity = 1 })

        local extraStr = extra and string.format(' + %d %s', extra.qty, extra.name or 'item') or ''
        player:printToPlayer(
            string.format('Purchased %s for %d %s%s!', item.name, item.cost, sealDef.name, extraStr),
            xi.msg.channel.SYSTEM_3
        )
    end

    -----------------------------------
    -- Build a paginated item list menu
    -----------------------------------
    -- 4 items/page with name cap 17 keeps the worst-case menu under the
    -- 150-byte cap: title (~23) + 4*(17 + " [99]" = 24) + 2 nav (8 ea) +
    -- back (9) ~ 144 bytes.
    local PAGE_SIZE     = 4
    local MAX_ITEM_NAME = 17

    local function buildItemMenu(player, menu, tierKey, sealDef, items, page, returnFunc)
        local totalPages = math.max(1, math.ceil(#items / PAGE_SIZE))
        page = math.max(1, math.min(page, totalPages))

        local startIdx = (page - 1) * PAGE_SIZE + 1
        local endIdx   = math.min(startIdx + PAGE_SIZE - 1, #items)

        local options = {}

        for i = startIdx, endIdx do
            local item = items[i]
            local name = item.name
            if #name > MAX_ITEM_NAME then
                name = name:sub(1, MAX_ITEM_NAME - 1) .. '*'
            end
            -- "*" marker on rows that need an extra drop in addition to seals
            local marker = getExtraDrop(tierKey, item) and ' *' or ''
            local label  = string.format('%s  [%d]%s', name, item.cost, marker)
            table.insert(options, {
                label,
                function(playerArg)
                    purchase(playerArg, tierKey, sealDef, item)
                    buildItemMenu(playerArg, menu, tierKey, sealDef, items, page, returnFunc)
                end,
            })
        end

        if totalPages > 1 then
            if page > 1 then
                table.insert(options, {
                    string.format('<< %d/%d', page - 1, totalPages),
                    function(playerArg)
                        buildItemMenu(playerArg, menu, tierKey, sealDef, items, page - 1, returnFunc)
                    end,
                })
            end
            if page < totalPages then
                table.insert(options, {
                    string.format('%d/%d >>', page + 1, totalPages),
                    function(playerArg)
                        buildItemMenu(playerArg, menu, tierKey, sealDef, items, page + 1, returnFunc)
                    end,
                })
            end
        end

        table.insert(options, { '<< Back', function(playerArg) returnFunc(playerArg) end })

        menu.title   = string.format('%s (%d/%d)', sealDef.name, page, totalPages)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Build the slot picker (Head / Body / Hands / Legs / Feet)
    -- 5 slots, no pagination needed.
    -----------------------------------
    local SLOT_ORDER = { 'head', 'body', 'hands', 'legs', 'feet' }
    local SLOT_LABEL = { head = 'Head', body = 'Body', hands = 'Hands', legs = 'Legs', feet = 'Feet' }

    local function buildSlotMenu(player, menu, tierKey, returnFunc)
        local tierData  = catalog[tierKey]
        local sealDef   = catalog.seals[tierKey]
        local sealCount = player:getItemCount(sealDef.id)
        local options   = {}

        for _, slotKey in ipairs(SLOT_ORDER) do
            local items = tierData[slotKey] or {}
            if #items > 0 then
                table.insert(options, {
                    string.format('%s (%d)', SLOT_LABEL[slotKey], #items),
                    function(playerArg)
                        buildItemMenu(playerArg, menu, tierKey, sealDef, items, 1, function(pp)
                            buildSlotMenu(pp, menu, tierKey, returnFunc)
                        end)
                    end,
                })
            end
        end

        -- Tier-level hint about the extra Gold drop requirement.
        if tierKey == 'gold' and catalog.goldExtraDrop then
            table.insert(options, {
                string.format('Info: also needs %s', catalog.goldExtraDrop.name or 'extra drop'),
                function(p)
                    p:printToPlayer(
                        string.format('Gold items also require %d x %s (a "*" marks each entry).',
                            catalog.goldExtraDrop.qty, catalog.goldExtraDrop.name or 'extra drop'),
                        xi.msg.channel.SYSTEM_3)
                    buildSlotMenu(p, menu, tierKey, returnFunc)
                end,
            })
        end

        table.insert(options, { '<< Back', function(playerArg) returnFunc(playerArg) end })

        menu.title = string.format('[%s] %d %s',
            tierKey:sub(1,1):upper() .. tierKey:sub(2),
            sealCount,
            sealDef.name)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Main menu (tier picker)
    -----------------------------------
    local menu = { title = 'Armor', options = {} }

    local function buildMainMenu(player)
        menu.title   = 'Armor - Choose Tier'
        menu.options =
        {
            {
                string.format('[Bronze] Entry  (%d %s)',
                    player:getItemCount(catalog.seals.bronze.id),
                    catalog.seals.bronze.name:match('^(%S+)') or 'seals'),
                function(playerArg) buildSlotMenu(playerArg, menu, 'bronze', buildMainMenu) end,
            },
            {
                string.format('[Silver] Mid  (%d %s)',
                    player:getItemCount(catalog.seals.silver.id),
                    catalog.seals.silver.name:match('^(%S+)') or 'seals'),
                function(playerArg) buildSlotMenu(playerArg, menu, 'silver', buildMainMenu) end,
            },
            {
                string.format('[Gold] BiS  (%d %s)',
                    player:getItemCount(catalog.seals.gold.id),
                    catalog.seals.gold.name:match('^(%S+)') or 'seals'),
                function(playerArg) buildSlotMenu(playerArg, menu, 'gold', buildMainMenu) end,
            },
            {
                '[TEST] Preview shop',
                function(playerArg)
                    -- SPIKE: open the FFXI shop GUI (item icons + stat previews)
                    -- for the first non-empty Bronze slot, priced in bronze seals,
                    -- to verify the engine patch + that the client allows the seal
                    -- purchase. Remove once the NPCs are converted for real.
                    local items
                    for _, slotKey in ipairs({ 'body', 'head', 'hands', 'legs', 'feet' }) do
                        local list = catalog.bronze and catalog.bronze[slotKey]
                        if list and #list > 0 then
                            items = list
                            break
                        end
                    end
                    if not items then
                        playerArg:printToPlayer('No bronze items configured to test.', xi.msg.channel.SYSTEM_3)
                        return
                    end
                    local sealId = catalog.seals.bronze.id
                    playerArg:timer(50, function(p)
                        p:createShop(#items)
                        for _, it in ipairs(items) do
                            p:addShopItem(it.id, it.cost)
                        end
                        p:setShopCurrency(sealId)
                        p:sendMenu(xi.menuType.SHOP)
                    end)
                end,
            },
            {
                'Close',
                function(playerArg) playerArg:printToPlayer('Come back for more gear!', xi.msg.channel.SYSTEM_3) end,
            },
        }
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- NPC Entity
    --   Position comes from catalog.vendorPos - single source of truth
    --   shared with the docgen. Continues the +3 X-offset row alongside
    --   Hub / Spawner / Weapons NPCs. Adjust placement by editing
    --   armor_catalog.lua only.
    -----------------------------------
    local _p = catalog.vendorPos
    local ArmorNPC = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Armor_NPC',
        packetName = string.format('%sArmor', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = _p.x,
        y          = _p.y,
        z          = _p.z,
        rotation   = _p.rot,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu to browse armor!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(playerArg)
                buildMainMenu(playerArg)
            end)
        end,
    })
    utils.unused(ArmorNPC)
end)

return m
