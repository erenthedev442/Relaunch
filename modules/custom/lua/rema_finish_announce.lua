-----------------------------------
-- Server-wide shout when a player finishes a 119 III REMA / Prime.
-----------------------------------
local M = {}

M.FAMILY_LABEL =
{
    relic    = 'Relic',
    empyrean = 'Empyrean',
    mythic   = 'Mythic',
    aeonic   = 'Aeonic',
    prime    = 'Prime',
}

local STAR = '\129\154'

function M.familyLabel(family)
    return M.FAMILY_LABEL[string.lower(family or '')] or 'REMA'
end

function M.message(playerName, family, weaponName)
    return string.format(
        '%s %s has completed %s %s (119 III)! %s',
        STAR,
        playerName or '',
        M.familyLabel(family),
        weaponName or '',
        STAR)
end

function M.broadcast(player, family, weaponName)
    if not player or not weaponName or weaponName == '' then
        return false
    end

    local name = ''
    pcall(function()
        name = player:getName() or ''
    end)
    if name == '' then
        return false
    end

    local msg = M.message(name, family, weaponName)
    local sent = false
    pcall(function()
        player:printToArea(msg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
        sent = true
    end)
    return sent
end

return M
