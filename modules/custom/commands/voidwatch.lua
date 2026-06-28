 -----------------------------------
-- func: voidwatch
-- desc: Voidwatch-flavored rift battles. Open the menu, or tear a rift in the field.
--
-- Usage:
--   !voidwatch            open the Voidwatch menu (open rift / buy Voidstone / status)
--   !voidwatch open       tear open a rift where you stand (field zones only)
--   !voidwatch status     chat dump (tier / Voidstones / cruor)
--   !voidwatch cruor <n>  (GM) grant <n> cruor -- testing
--
-- Engine: modules/custom/lua/Voidwatch.lua (xi.voidwatch.*).
-- Lives in modules/custom/commands/ so it survives upstream merges.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'si',
}

local SYS = xi.msg.channel.SYSTEM_3

local function isGM(player)
    local ok, lvl = pcall(function() return player:getGMLevel() end)
    return ok and lvl ~= nil and lvl > 0
end

commandObj.onTrigger = function(player, sub, n)
    if not xi.voidwatch then
        player:printToPlayer('[Voidwatch] The Voidwatch system is not loaded yet. Try again shortly.', SYS)
        return
    end

    sub = (type(sub) == 'string') and sub:lower() or nil

    if sub == nil or sub == 'menu' then
        xi.voidwatch.menu(player)
    elseif sub == 'open' then
        xi.voidwatch.open(player)
    elseif sub == 'status' then
        xi.voidwatch.status(player)
    elseif sub == 'cruor' and isGM(player) then
        local amt = tonumber(n) or 1000
        xi.voidwatch.grantCruor(player, amt)
        player:printToPlayer(string.format('[Voidwatch] (GM) granted %d cruor.', amt), SYS)
    else
        player:printToPlayer('Usage: !voidwatch [menu | open | status]', SYS)
    end
end

return commandObj
