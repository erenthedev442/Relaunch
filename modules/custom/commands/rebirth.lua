-----------------------------------
-- !rebirth
-- Player shortcut to the Job Rebirth NPC. Mirrors !warp -> Progression Hubs.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local cfg = require('modules/custom/lua/job_rebirth_catalog')

commandObj.onTrigger = function(player)
    player:setPos(cfg.npcPos.x, cfg.npcPos.y, cfg.npcPos.z, cfg.npcPos.rot, cfg.npcZone)
end

return commandObj
