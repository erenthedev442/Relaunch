-----------------------------------
-- disable_dealer_moogle.lua
--
-- Dealer Moogles are disabled server-wide (Port Sandy/Bastok/Windy + Chocobo
-- Circuit). The retail Dealer Moogle trades Mog Kupons for gear up to and
-- including iL119 III Relic/Mythic/Empyrean and all 16 Aeonic weapons (Kupon
-- W-A119 -> Godhands et al.). On this retail-like relaunch, REMA/Aeonic weapons
-- are meant to be EARNED through content, not vended from a coupon, so the NPC
-- is switched off entirely rather than left armed for a leaked coupon.
--
-- Pure Lua override module (loaded from custom/lua/); takes effect on the next
-- map restart. Handler names verified against scripts/globals/dealer_moogle.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/dealer_moogle')

local m = Module:new('disable_dealer_moogle')

local SYS = xi.msg.channel.SYSTEM_3
local MSG = 'The Dealer Moogle is not available on this server.'

local function notify(player)
    if player then
        player:printToPlayer(MSG, SYS)
    end
end

xi.dealerMoogle.onTrade = function(player, _npc, _trade)
    notify(player)
end

xi.dealerMoogle.onTrigger = function(player, _npc)
    notify(player)
end

xi.dealerMoogle.onEventUpdate = function(_player, _csid, _option, _npc)
end

xi.dealerMoogle.onEventFinish = function(player, _csid, _option, _npc)
    notify(player)
end

return m
