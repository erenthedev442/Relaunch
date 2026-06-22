-----------------------------------
-- !warpty
-- Brings all online party members to the party leader's current position.
-- Derived from !bring: same zone → instant WPOS snap; different zone → zone transfer.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- "In a party" = party size > 1. Do NOT use getLeaderID()==getID(): in a
    -- party getLeaderID() returns the PartyID, which IS the leader's charID, so
    -- the PARTY LEADER's getLeaderID() equals getID() and the old check falsely
    -- told the leader "you are not in a party" (the reported bug).
    if player:getPartySize() <= 1 then
        player:printToPlayer('You are not in a party.', xi.msg.channel.SYSTEM_3)
        return
    end

    local leader = player:getPartyLeader()
    if not leader then
        player:printToPlayer('Party leader is not online.', xi.msg.channel.SYSTEM_3)
        return
    end

    local leaderID = leader:getID()
    local lx       = leader:getXPos()
    local ly       = leader:getYPos()
    local lz       = leader:getZPos()
    local lrot     = leader:getRotPos()
    local lzone    = leader:getZoneID()

    local warped = 0
    for _, member in ipairs(player:getParty()) do
        if member and member:getID() ~= leaderID then
            -- Mirror !bring: cross-zone gets setPos with zone arg, same-zone gets plain snap.
            if member:getZoneID() ~= lzone then
                member:setPos(lx, ly, lz, lrot, lzone)
            else
                member:setPos(lx, ly, lz, lrot)
            end
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
