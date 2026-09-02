-----------------------------------
-- Area: Bhaflau Thickets
--  NPC: Hamta-Iramta
-- Type: Alzadaal Undersea Ruins
-- !pos -459.942 -20.048 -4.999 52
-- Cutscenes 134-136 lock the client when the CS DAT is missing. Warp in/out
-- immediately instead of starting those events.
-----------------------------------
local ID = zones[xi.zone.BHAFLAU_THICKETS]
-----------------------------------
---@type TNpcEntity
local entity = {}

local function isOutsideAlzadaal(player)
    return player:getYPos() <= -16.01
end

local function enterRuins(player)
    player:setPos(-115, -4, -620, 253, xi.zone.ALZADAAL_UNDERSEA_RUINS)
end

local function leaveRuins(player)
    player:setPos(-401.065, -9.633, 19.995, 0, 52)
end

entity.onTrade = function(player, npc, trade)
    if
        isOutsideAlzadaal(player) and
        trade:getItemCount() == 1 and
        trade:hasItemQty(xi.item.IMPERIAL_SILVER_PIECE, 1)
    then
        player:tradeComplete()
        enterRuins(player)
    end
end

entity.onTrigger = function(player, npc)
    if isOutsideAlzadaal(player) then
        if player:hasKeyItem(xi.ki.CAPTAIN_WILDCAT_BADGE) then
            player:messageSpecial(ID.text.YOU_HAVE_A_BADGE, xi.ki.CAPTAIN_WILDCAT_BADGE)
        end

        enterRuins(player)
    else
        leaveRuins(player)
    end
end

return entity
