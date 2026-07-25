-----------------------------------
-- !geas [page]
--
-- Shows the player's missing Geas Fete roster with each NM's live ??? camp
-- position and zone. The Geas Fete Warden offers clickable camp warps.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'i',
}

local PAGE_SIZE = 8

commandObj.onTrigger = function(player, requestedPage)
    local S = xi.msg.channel.SYSTEM_3
    if not xi.geasFete or not xi.geasFete.missing then
        player:printToPlayer('[Geas Fete] The roster service is unavailable.', S)
        return
    end

    local missing = xi.geasFete.missing(player)
    local total = xi.geasFete.uniqueNmCount or 0
    local cleared = math.max(0, total - #missing)
    if #missing == 0 then
        player:printToPlayer(string.format(
            '[Geas Fete] Roster complete: %d/%d unique NMs defeated.',
            cleared, total), S)
        return
    end

    local pages = math.max(1, math.ceil(#missing / PAGE_SIZE))
    local page = math.max(1, math.min(tonumber(requestedPage) or 1, pages))
    local first = (page - 1) * PAGE_SIZE + 1
    local last = math.min(#missing, first + PAGE_SIZE - 1)

    player:printToPlayer(string.format(
        '[Geas Fete] Progress %d/%d. Missing %d. Page %d/%d:',
        cleared, total, #missing, page, pages), S)
    for index = first, last do
        local entry = missing[index]
        player:printToPlayer(string.format(
            '  %s - Pos %s - %s',
            entry.fullName, xi.geasFete.positionText(entry), entry.zoneName), S)
    end
    if page < pages then
        player:printToPlayer(string.format('  Next: !geas %d', page + 1), S)
    end
    player:printToPlayer('  Talk to any Geas Fete Warden for direct camp warps.', S)
end

return commandObj
