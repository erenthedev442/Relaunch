-----------------------------------
-- !paragon   -- open the Paragon board menu (same as visiting the Paragon Sage NPC)
-----------------------------------
local cmdObj = {}

cmdObj.cmdprops = { permission = 0, parameters = '' }

cmdObj.onTrigger = function(player, args)
    local openMenu = xi._paragon_openMenu
    if not openMenu then
        player:printToPlayer('[paragon] Paragon module not loaded.', xi.msg.channel.SYSTEM_3)
        return
    end
    openMenu(player)
end

return cmdObj
