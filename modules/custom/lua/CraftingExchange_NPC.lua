-----------------------------------
-- CraftingExchange_NPC.lua
--
-- An NPC at GM Home that accepts HQ crafted items in exchange for
-- Hunt Marks, giving crafters a valued outlet in the Legendary
-- progression ecosystem. Catalog-driven: add items to
-- crafting_exchange_catalog.lua to expand the exchange list.
--
-- Architecture:
--   * Player trades ONE HQ item to the NPC.
--   * NPC looks up the item in the catalog.
--   * If found, confirms the exchange: item is consumed, marks awarded.
--   * Daily cap per item enforced via CharVars.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/crafting_exchange_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('crafting_exchange')

-- Build fast lookup: itemId -> catalog entry
local exchangeByItemId = {}
for _, entry in ipairs(catalog.exchanges) do
    exchangeByItemId[entry.itemId] = entry
end

-- ───────── Day / daily cap helpers ─────────────────────────────────────────

local function currentDayId()
    return tonumber(os.date('!%Y%j'))
end

local function cvDay(itemId)
    return catalog.cvDayPrefix .. itemId .. catalog.cvDaySuffix
end

local function cvCount(itemId)
    return catalog.cvDayPrefix .. itemId .. catalog.cvCountSuffix
end

local function getTodayCount(player, itemId)
    local day   = player:getCharVar(cvDay(itemId)) or 0
    local today = currentDayId()
    if day ~= today then return 0 end
    return player:getCharVar(cvCount(itemId)) or 0
end

local function recordTrade(player, itemId)
    local today = currentDayId()
    player:setCharVar(cvDay(itemId), today)
    local count = getTodayCount(player, itemId)
    player:setCharVar(cvCount(itemId), count + 1)
end

-- ───────── Trade handler ─────────────────────────────────────────────────────

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)

    -- NPC model: Elvaan merchant look (same as Armor/Accessory vendors)
    local NPC_LOOK = catalog.npcLook or 2430

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = catalog.npcName or 'Crafting Exchange',
        packetName = string.format('%sCraft Exchange', xi.icon.STAR_LARGE),
        look       = 166,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer(
                '[Crafting Exchange] Trade me one HQ synthesis result for Hunt Marks!',
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer(
                '[Crafting Exchange] ' .. catalog.skillNote,
                xi.msg.channel.SYSTEM_3)
        end,

        onTrade = function(player, npc, trade)
            -- Expect exactly 1 item traded
            local count = 0
            local tradedId = nil
            local tradedQty = nil
            for slot = 0, 7 do
                local tradeItem = trade:getItem(slot)
                if tradeItem then
                    count = count + 1
                    tradedId  = tradeItem:getID()
                    tradedQty = trade:getSlotQty(slot) or 1
                end
            end

            if count ~= 1 then
                player:printToPlayer(
                    '[Crafting Exchange] Trade exactly 1 item at a time, please.',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            local entry = exchangeByItemId[tradedId]
            if entry == nil then
                player:printToPlayer(
                    '[Crafting Exchange] That item is not on our exchange list.',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            -- Daily cap check
            if entry.maxPerDay then
                local todayCount = getTodayCount(player, tradedId)
                if todayCount >= entry.maxPerDay then
                    player:printToPlayer(
                        string.format('[Crafting Exchange] Daily limit reached for %s (%d/%d today).',
                            entry.name, todayCount, entry.maxPerDay),
                        xi.msg.channel.SYSTEM_3)
                    return
                end
            end

            -- Accept trade (consume item)
            trade:confirmSlot(0)
            trade:confirmTrade()

            -- Award marks
            local marks = entry.reward.marks or 0
            if marks > 0 then
                local current = player:getCharVar('HL_Points') or 0
                player:setCharVar('HL_Points', current + marks)
            end

            -- Track daily cap
            recordTrade(player, tradedId)

            player:printToPlayer(
                string.format('[Crafting Exchange] Accepted %s! +%d Hunt Marks.  (Daily: %d/%s)',
                    entry.name, marks,
                    getTodayCount(player, tradedId),
                    entry.maxPerDay and tostring(entry.maxPerDay) or 'unlimited'),
                xi.msg.channel.SYSTEM_3)

            -- Provisioners' League crafting credit. Lazy + guarded so
            -- the exchange works even if the league module is absent.
            local okLg, lg = pcall(require, 'modules/custom/lua/ProvisionersLeague')
            if okLg and lg and lg.onCraftTurnIn then
                pcall(function() lg.onCraftTurnIn(player, marks) end)
            end
        end,
    })
end)

return m
