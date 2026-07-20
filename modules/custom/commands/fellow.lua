 -----------------------------------
-- func: fellow
-- desc: Summon, dismiss, or change the Adventuring Fellow's combat mode.
--       Upgrades and customization live at the Fellow Officer in zone 44.
--
-- Usage:
--   !fellow            open the Fellow menu
--   !fellow summon     call your Fellow      (also in the menu)
--   !fellow dismiss    send it to rest       (also in the menu)
--
-- Engine lives in modules/custom/lua/fellow_companion.lua (xi.fellow.*).
-- Lives in modules/custom/commands/ so it survives upstream merges.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local SYS = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, sub)
    if not xi.fellow then
        player:printToPlayer('[Fellow] The Fellow system is not loaded yet. Try again shortly.', SYS)
        return
    end

    sub = (type(sub) == 'string') and sub:lower() or nil

    if sub == nil or sub == 'menu' then
        xi.fellow.openMenu(player)
    elseif sub == 'summon' then
        xi.fellow.summon(player)
    elseif sub == 'dismiss' then
        xi.fellow.dismiss(player)
    else
        player:printToPlayer('Usage: !fellow [menu | summon | dismiss]', SYS)
    end
end

return commandObj
