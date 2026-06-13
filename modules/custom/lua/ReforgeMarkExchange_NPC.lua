-----------------------------------
-- ReforgeMarkExchange_NPC.lua
-- Lets players convert excess Reforge marks (AF/Relic/Empy) between
-- types at a 2:1 rate. Placed at Reisenjima Henge near the Gear Vendors.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/reforge_mark_exchange_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('reforge_mark_exchange')

-- Forward-declared: the NPC's onTrigger closure (and showExchangeMenu's option
-- closures) reference these before the definitions below, so they must exist as
-- upvalues first -- otherwise they bind to nil globals (the showExchangeMenu /
-- showBatchMenu nil-value crashes).
local showExchangeMenu, showBatchMenu

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = catalog.npcName,
        packetName = string.format('%sReforge Exchange', xi.icon.STAR_LARGE),
        look       = catalog.npcLook,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer('[Reforge Exchange] Convert excess Reforge marks at a 2:1 rate.', xi.msg.channel.SYSTEM_3)
            player:printToPlayer('[Reforge Exchange] AF->Relic: 2:1 | Relic->Empy: 2:1 | AF->Empy: 3:1', xi.msg.channel.SYSTEM_3)
            showExchangeMenu(player)
        end,
    })
end)

showExchangeMenu = function(player)
    local opts = {}
    for _, ex in ipairs(catalog.exchanges) do
        local haveFrom = player:getCharVar(ex.fromCv) or 0
        local maxBatch = math.floor(haveFrom / ex.rate)
        table.insert(opts, {
            string.format('%s  (have %d %s)', ex.label, haveFrom, ex.fromName),
            function(p) showBatchMenu(p, ex, maxBatch) end,
        })
    end
    table.insert(opts, { 'Close', function(p) end })
    local snapshot = { title = 'Reforge Mark Exchange', options = opts }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

showBatchMenu = function(player, ex, maxBatch)
    if maxBatch <= 0 then
        player:printToPlayer(string.format('[Reforge Exchange] Not enough %s.', ex.fromName), xi.msg.channel.SYSTEM_3)
        showExchangeMenu(player)
        return
    end
    local opts = {}
    for _, qty in ipairs(catalog.batchSizes) do
        if qty <= maxBatch then
            local cost = qty * ex.rate
            table.insert(opts, {
                string.format('Convert %d  (costs %d %s)', qty, cost, ex.fromName),
                function(p)
                    local have = p:getCharVar(ex.fromCv) or 0
                    if have < cost then
                        p:printToPlayer('[Reforge Exchange] Insufficient marks.', xi.msg.channel.SYSTEM_3)
                        return
                    end
                    p:setCharVar(ex.fromCv, have - cost)
                    local gain = p:getCharVar(ex.toCv) or 0
                    p:setCharVar(ex.toCv, gain + qty)
                    p:printToPlayer(
                        string.format('[Reforge Exchange] Converted %d %s -> %d %s.',
                            cost, ex.fromName, qty, ex.toName),
                        xi.msg.channel.SYSTEM_3)
                    showExchangeMenu(p)
                end,
            })
        end
    end
    table.insert(opts, { 'Back', function(p) showExchangeMenu(p) end })
    local snapshot = { title = string.format('Convert to %s', ex.toName), options = opts }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

return m
