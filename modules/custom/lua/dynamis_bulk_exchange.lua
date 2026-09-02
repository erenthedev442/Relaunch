-----------------------------------
-- dynamis_bulk_exchange.lua
--
-- Backup hook for the goblin exchangers. The live conversion lives in
-- dynamis_currency_exchange.lua and is also called from dynamis.lua so a
-- missed module override cannot leave 90/100 trades silent again.
--
-- Each override needs its own wrapper. applyOverride binds `super` via
-- setfenv; sharing one function would make every hook call the last NPC.
-----------------------------------
require('modules/module_utils')

local exchange = require('modules/custom/lua/dynamis_currency_exchange')

local m = Module:new('dynamis_bulk_exchange')

local function wrap()
    return function(player, npc, trade)
        if exchange.tryExchange(player, npc, trade) then
            return
        end

        super(player, npc, trade)
    end
end

m:addOverride('xi.dynamis.hourglassAndCurrencyExchangeNPCOnTrade', wrap())
m:addOverride('xi.zones.Beadeaux.npcs.Haggleblix.onTrade', wrap())
m:addOverride('xi.zones.Castle_Oztroja.npcs.Antiqix.onTrade', wrap())
m:addOverride('xi.zones.Davoi.npcs.Lootblox.onTrade', wrap())

return m
