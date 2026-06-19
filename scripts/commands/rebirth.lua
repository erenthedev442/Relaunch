-----------------------------------
-- !rebirth
-- Player command: warps the caller to the Job Rebirth NPC, which sits
-- underground in RuLude Gardens (zone 243, y=-5). The NPC is unreachable
-- on foot, so this command is how every player reaches Job Rebirth.
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
