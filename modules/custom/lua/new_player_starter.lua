-----------------------------------
-- new_player_starter.lua
-- One-time starter gift on a character's very first login.
-- Grants 300,000 gil to ease the early-game economy barrier
-- on a freshly wiped server where players start from nothing.
--
-- CharVar:
--   Starter_Gift  - 1 once the gift has been given; never fires again.
-----------------------------------
require('modules/module_utils')

local m = Module:new('new_player_starter')

local STARTER_GIL    = 300000
local CV_GIFT        = 'Starter_Gift'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if isLogin and (player:getCharVar(CV_GIFT) or 0) == 0 then
        player:setCharVar(CV_GIFT, 1)
        player:addGil(STARTER_GIL)
        player:timer(3500, function(p)
            p:printToPlayer(
                string.format('[Welcome] Starting gift: %d gil. Good luck out there!', STARTER_GIL),
                xi.msg.channel.SYSTEM_3)
        end)
    end
end)

return m
