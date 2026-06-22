-----------------------------------
-- !warpty
-- Warps all party members to the party leader's current position/zone.
-- Run by any party member; the leader is determined automatically.
-- Cross-zone safe: members in a different zone get setPos with the zoneId arg.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local party = player:getParty()

    if not party or #party <= 1 then
        player:printToPlayer('You are not in a party.', xi.msg.channel.SYSTEM_3)
        return
    end

    local leaderID = player:getLeaderID()
    local leader   = GetPlayerByID(leaderID)

    if not leader then
        player:printToPlayer('Party leader is not online.', xi.msg.channel.SYSTEM_3)
        return
    end

    local lx   = leader:getXPos()
    local ly   = leader:getYPos()
    local lz   = leader:getZPos()
    local lrot = leader:getRotPos()
    local lzone = leader:getZoneID()

    local warped = 0
    for _, member in ipairs(party) do
        if member:getID() ~= leaderID then
            local destZone = (member:getZoneID() ~= lzone) and lzone or nil
            member:setPos(lx, ly, lz, lrot, destZone)
            warped = warped + 1
        end
    end

    player:printToPlayer(
        string.format('Warped %d party member%s to %s in %s.',
            warped,
            warped == 1 and '' or 's',
            leader:getName(),
            leader:getZoneName()),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
