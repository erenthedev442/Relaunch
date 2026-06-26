 -----------------------------------
-- func: fellow
-- desc: Opens the Adventuring Fellow menu (summon/dismiss, allocate stat points,
--       choose role, view status). Your Fellow is a personal companion ANY job
--       can summon; it levels from your kills and you build it as you like.
--
-- Usage:
--   !fellow            open the Fellow menu
--   !fellow summon     call your Fellow      (also in the menu)
--   !fellow dismiss    send it to rest       (also in the menu)
--   !fellow status     chat dump of level / XP / points / allocation
--   !fellow points <n> (GM) grant <n> stat points  -- testing
--   !fellow xp <n>     (GM) grant <n> XP            -- testing
--
-- Engine lives in modules/custom/lua/fellow_companion.lua (xi.fellow.*).
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
    elseif sub == 'status' then
        xi.fellow.status(player)
    elseif sub == 'points' and isGM(player) then
        local amt = tonumber(n) or 10
        xi.fellow.grantPoints(player, amt)
        player:printToPlayer(string.format('[Fellow] (GM) granted %d stat points.', amt), SYS)
    elseif sub == 'xp' and isGM(player) then
        local amt = tonumber(n) or 100
        xi.fellow.addXp(player, amt)
    else
        player:printToPlayer('Usage: !fellow [menu | summon | dismiss | status]', SYS)
    end
end

return commandObj
