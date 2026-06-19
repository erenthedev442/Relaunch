-----------------------------------
-- !rebirth
-- GM-only command: warps the executor to the hidden Job Rebirth NPC
-- buried underground in RuLude Gardens (zone 243, y=-5).
-- Players cannot reach this spot; only GMs can trigger the NPC there.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

local cfg = require('modules/custom/lua/job_rebirth_catalog')

commandObj.onTrigger = function(player)
    player:setPos(cfg.npcPos.x, cfg.npcPos.y, cfg.npcPos.z, cfg.npcPos.rot, cfg.npcZone)
end

return commandObj
