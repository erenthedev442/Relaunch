-----------------------------------
-- Area: Bhaflau Thickets
--  NPC: Kamih Mapokhalam
-- 20 -30 597 z 52
-- Cutscenes 120-122 lock the client when the CS DAT is missing. Warp in/out
-- immediately instead of starting those events.
-----------------------------------
local ID = zones[xi.zone.BHAFLAU_THICKETS]
-----------------------------------
---@type TNpcEntity
local entity = {}

local function enterRuins(player)
    player:setPos(325.137, -3.999, -619.968, 0, 72) -- Alzadaal Undersea Ruins G-8
end

local function leaveRuins(player)
    player:setPos(14.186, -29.8, 590.427, 0, 52)
end

entity.onTrade = function(player, npc, trade)
    local count = trade:getItemCount()

    if
        count == 1 and
        trade:hasItemQty(xi.item.IMPERIAL_SILVER_PIECE, 1)
    then
        player:tradeComplete()
        enterRuins(player)
    elseif
        count == 3 and
        trade:hasItemQty(xi.item.IMPERIAL_MYTHRIL_PIECE, 3)
    then
        if player:hasKeyItem(xi.ki.MAP_OF_ALZADAAL_RUINS) then
            player:startEvent(147)
        else
            player:startEvent(146)
        end
    end
end

entity.onTrigger = function(player, npc)
    if player:getZPos() < 597 then
        if player:hasKeyItem(xi.ki.CAPTAIN_WILDCAT_BADGE) then
            player:messageSpecial(ID.text.YOU_HAVE_A_BADGE, xi.ki.CAPTAIN_WILDCAT_BADGE)
        end

        enterRuins(player)
    else
        leaveRuins(player)
    end
end

entity.onEventFinish = function(player, csid, option, npc)
    if csid == 146 then
        player:tradeComplete()
        npcUtil.giveKeyItem(player, xi.ki.MAP_OF_ALZADAAL_RUINS)
    end
end

return entity
