-----------------------------------
-- func: provenance  (DISABLED)
-- desc: Overrides scripts/commands/provenance.lua to DISABLE the !provenance
--       warp. Lives in modules/custom/commands/ so it HOT-RELOADS (no restart)
--       and takes precedence over the stock command (same pattern as !shop).
--       The stock command (warp to zone 222) is left intact; this just shadows it.
--
--       To RE-ENABLE: delete this file (then a map restart, since removing a
--       module command file does not hot-unload), or restore the warp in
--       onTrigger below.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:printToPlayer('The !provenance command is currently disabled.', xi.msg.channel.SYSTEM_3)
end

return commandObj
