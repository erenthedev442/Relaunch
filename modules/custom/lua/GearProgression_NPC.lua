-----------------------------------
-- GearProgression_NPC.lua
-- Weapons-only vendor: spend seals earned from content to purchase tiered
-- weapons independently (no prior item needed).
-- Zone: Reisenjima_Henge (zone 292) - same zone as the Hunting League NPCs
-- so the player can hand in marks and shop in one place.
--
-- Seal currencies:
-- Seal currencies (loaded from catalog.seals at runtime - see catalog file
-- for the actual names and tier descriptions; main-menu labels below take
-- the first whitespace-delimited word of each seal name for compactness).
--
-- Menu flow:
--   Main menu (tier picker)
--     -> Tier menu (weapon-category picker, paginated)
--        -> Item menu (paginated weapon list, paginated)
--
-- To add weapons: edit gear_progression_catalog.lua only.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/gear_progression_catalog')

-- Resolve the zone script path from the catalog so the require + override
-- target stay in sync with catalog.zonePath. No more hardcoded zone names.
local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))
-----------------------------------
local m = Module:new('gear_progression_npc')

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- Purchase helper
    -----------------------------------
    local function purchase(player, sealDef, item)
        local sealId   = sealDef.id
        local sealName = sealDef.name

        if player:getItemCount(sealId) < item.cost then
            player:printToPlayer(
                string.format('You need %d %s to buy %s. (You do not have enough.)', item.cost, sealName, item.name),
                xi.msg.channel.SYSTEM_3
            )
            return
        end

        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('Your inventory is full! Free up a slot first.', xi.msg.channel.SYSTEM_3)
            return
        end

        player:delItem(sealId, item.cost)
        player:addItem({ id = item.id, quantity = 1 })
        player:printToPlayer(
            string.format('Purchased %s for %d %s!', item.name, item.cost, sealName),
            xi.msg.channel.SYSTEM_3
        )
    end

    -----------------------------------
    -- Build a paginated item list menu (weapons inside a chosen category)
    --
    -- NOTE: the customMenu prompt packet caps the title+options payload at
    -- 150 bytes. Page size, format, and per-row truncation below are tuned
    -- so the packet can't silently truncate the Back/Next buttons even if
    -- the catalog gains very long item names later.
    -----------------------------------
    local PAGE_SIZE     = 3
    local MAX_ITEM_NAME = 22  -- truncated with '*' if longer; protects the budget

    local function buildItemMenu(player, menu, sealDef, items, page, returnFunc)
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
            -- Seal name lives in the title; jobs are omitted from the menu
            -- label (the in-game item description has them) so 3 rows + nav
            -- buttons reliably fit the 150-byte customMenu cap.
            local label = string.format('%s  [%d]', name, item.cost)
            table.insert(options, {
                label,
                function(playerArg)
                    purchase(playerArg, sealDef, item)
                    buildItemMenu(playerArg, menu, sealDef, items, page, returnFunc)
                end,
            })
        end

        if totalPages > 1 then
            if page > 1 then
                table.insert(options, {
                    string.format('<< %d/%d', page - 1, totalPages),
                    function(playerArg)
                        buildItemMenu(playerArg, menu, sealDef, items, page - 1, returnFunc)
                    end,
                })
            end
            if page < totalPages then
                table.insert(options, {
                    string.format('%d/%d >>', page + 1, totalPages),
                    function(playerArg)
                        buildItemMenu(playerArg, menu, sealDef, items, page + 1, returnFunc)
                    end,
                })
            end
        end

        table.insert(options, { '<< Back', function(playerArg)
            returnFunc(playerArg)
        end })

        menu.title   = string.format('%s (%d/%d)', sealDef.name, page, totalPages)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Build the weapon-category menu (Swords / Daggers / Clubs / ...)
    --
    -- Replaces the old "slot picker" - since this NPC is weapons-only, the
    -- categories from the catalog become the top-level choice after picking
    -- a tier.  Paginated (5/page) so the menu stays under 150 bytes even if
    -- the catalog grows past the current 14 weapon types.
    -----------------------------------
    local CAT_PG_SZ = 5

    local function buildTierMenu(player, menu, tierKey, page, returnFunc)
        local tierData  = catalog[tierKey]
        local sealDef   = catalog.seals[tierKey]
        local sealCount = player:getItemCount(sealDef.id)

        -- Show only categories that have at least one item.
        local populated = {}
        for _, group in ipairs(tierData.weapons or {}) do
            if #group.items > 0 then
                table.insert(populated, group)
            end
        end

        local totalPages = math.max(1, math.ceil(#populated / CAT_PG_SZ))
        page = math.max(1, math.min(page or 1, totalPages))
        local startIdx = (page - 1) * CAT_PG_SZ + 1
        local endIdx   = math.min(startIdx + CAT_PG_SZ - 1, #populated)

        local options = {}

        if #populated == 0 then
            table.insert(options, { 'No weapons yet (catalog empty)', function() end })
        else
            for i = startIdx, endIdx do
                local grp = populated[i]
                table.insert(options, {
                    string.format('%s (%d)', grp.label, #grp.items),
                    function(playerArg)
                        buildItemMenu(playerArg, menu, sealDef, grp.items, 1, function(pp)
                            buildTierMenu(pp, menu, tierKey, page, returnFunc)
                        end)
                    end,
                })
            end
            if totalPages > 1 then
                if page > 1 then
                    table.insert(options, {
                        string.format('<< %d/%d', page - 1, totalPages),
                        function(playerArg)
                            buildTierMenu(playerArg, menu, tierKey, page - 1, returnFunc)
                        end,
                    })
                end
                if page < totalPages then
                    table.insert(options, {
                        string.format('%d/%d >>', page + 1, totalPages),
                        function(playerArg)
                            buildTierMenu(playerArg, menu, tierKey, page + 1, returnFunc)
                        end,
                    })
                end
            end
        end

        table.insert(options, { '<< Back', function(playerArg)
            returnFunc(playerArg)
        end })

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
    local menu = { title = 'Gear Progression', options = {} }

    local function buildMainMenu(player)
        -- Labels kept short: customMenu payload is capped at 150 bytes
        menu.title   = 'Weapons - Choose Tier'
        menu.options =
        {
            {
                string.format('[Bronze] Entry  (%d %s)',
                    player:getItemCount(catalog.seals.bronze.id),
                    catalog.seals.bronze.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    buildTierMenu(playerArg, menu, 'bronze', 1, buildMainMenu)
                end,
            },
            {
                string.format('[Silver] Mid  (%d %s)',
                    player:getItemCount(catalog.seals.silver.id),
                    catalog.seals.silver.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    buildTierMenu(playerArg, menu, 'silver', 1, buildMainMenu)
                end,
            },
            {
                string.format('[Gold] Endgame  (%d %s)',
                    player:getItemCount(catalog.seals.gold.id),
                    catalog.seals.gold.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    buildTierMenu(playerArg, menu, 'gold', 1, buildMainMenu)
                end,
            },
            {
                'Close',
                function(playerArg)
                    playerArg:printToPlayer('Come back when you have more seals!', xi.msg.channel.SYSTEM_3)
                end,
            },
        }
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- NPC Entity
    --   Position comes from catalog.vendorPos - single source of truth
    --   shared with the docgen. Adjust placement by editing
    --   gear_progression_catalog.lua only.
    -----------------------------------
    local _p = catalog.vendorPos
    local GearProgressionNPC = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Weapons_NPC',
        packetName = string.format('%sWeapons', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = _p.x,
        y          = _p.y,
        z          = _p.z,
        rotation   = _p.rot,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu to browse weapons!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(playerArg)
                buildMainMenu(playerArg)
            end)
        end,
    })
    utils.unused(GearProgressionNPC)
end)

return m
