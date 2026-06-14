-----------------------------------
-- Area: Southern San d'Oria
--  NPC: Rolandienne
-- Records of Eminence NPC -- DISABLED + HIDDEN on Legendary (FJB).
-- RoE enrollment/objectives AND the Sparks/Accolades shop are off in the 3 starting
-- capitals, and the NPC itself is hidden (status DISAPPEAR). Adoulin's Eternal Flame
-- is intentionally left active. Hides on spawn (every zone load) + live on hot-reload.
-----------------------------------
local NPC_ID = 17719638 -- Rolandienne @ Southern San d'Oria (zone 230)
---@type TNpcEntity
local entity = {}

entity.onSpawn = function(npc)
    npc:setStatus(xi.status.DISAPPEAR)
end

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    player:printToPlayer('Records of Eminence and the Sparks exchange are closed on Legendary.', xi.msg.channel.SYSTEM_3)
end

-- Hide the already-spawned NPC the instant this file hot-reloads, so it vanishes live
-- without a restart. No-op at boot (NPC not yet spawned -> onSpawn handles that).
-- pcall so a lookup hiccup can never break the file's cache.
pcall(function()
    local live = GetNPCByID(NPC_ID)
    if live then
        live:setStatus(xi.status.DISAPPEAR)
    end
end)

return entity
