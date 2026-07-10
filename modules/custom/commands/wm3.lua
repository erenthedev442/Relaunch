-----------------------------------
-- !wm3
-- Player warp to Game Master #3 in Escha - Ru'Aun (zone 289).
-- The four Game Masters were spread across the zone 2026-07-09; !wm1-!wm4 each
-- warp to one of them. Positions are read LIVE from game_master_catalog.lua
-- npcPositions, so !pos-tuning the catalog auto-updates these warps -- no coords
-- are hardcoded here. Siblings: !wm1 !wm2 !wm4. (!wavemaster lands at spot #1.)
-----------------------------------
local catalog = require('modules/custom/lua/game_master_catalog')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- all players
    parameters = '',
}

commandObj.onTrigger = function(player)
    local p = catalog.npcPositions and catalog.npcPositions[3]
    if not p then
        player:printToPlayer('[Game Master] Spot 3 is not configured, kupo.', xi.msg.channel.SYSTEM_3)
        return
    end
    player:setPos(p.x, p.y, p.z, p.rot or 0, catalog.npcPos.zoneId)
    player:printToPlayer('[Game Master] Warped to Game Master 3 (Escha - Ru\'Aun).', xi.msg.channel.SYSTEM_3)
end

return commandObj
