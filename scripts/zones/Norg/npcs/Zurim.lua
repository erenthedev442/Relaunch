-----------------------------------
-- Area: Norg
--  NPC: Zurim
-- Domain Invasion points shop -- DISABLED + HIDDEN on Legendary.
-- The i119 Voluspa / Hervor / Heidrek / Angantyr / Merlinic / Chironic /
-- abjuration stock is sold by the Domain Quartermaster (Hunt Marks) instead.
-- Hides on spawn (every zone load) + live on hot-reload.
-----------------------------------
local NPC_ID = 17809552 -- Zurim @ Norg (zone 252)
---@type TNpcEntity
local entity = {}

entity.onSpawn = function(npc)
    npc:setStatus(xi.status.DISAPPEAR)
end

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    player:printToPlayer(
        'Zurim is not available. Domain Invasion gear is sold by the Domain Quartermaster.',
        xi.msg.channel.SYSTEM_3
    )
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

pcall(function()
    local live = GetNPCByID(NPC_ID)
    if live then
        live:setStatus(xi.status.DISAPPEAR)
    end
end)

return entity
