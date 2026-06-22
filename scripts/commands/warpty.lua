-----------------------------------
-- !warpty
-- Warps all ONLINE party members to the party leader's current position/zone.
-- Run by any party member; the leader is determined automatically.
-- Cross-zone safe: members in a different zone get setPos with the zoneId arg.
--
-- HOW THE PARTY CHECK WORKS:
--   getParty() only returns ONLINE members (those loaded in memory on this server).
--   Using #getParty() <= 1 incorrectly fires when all other members are offline
--   (shows "not in a party" even though the player IS in one).
--   getLeaderID() returns the party/alliance ID if in a party, or the player's own
--   charID if solo — so getLeaderID() == getID() is the reliable "solo" test.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    -- Reliable in-party check: returns partyID (≠ charID) when in a party.
    if player:getLeaderID() == player:getID() then
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

    -- getParty() returns all currently-online members (cross-zone included).
    local party  = player:getParty()
    local warped = 0
    for _, member in ipairs(party) do
        if member and member:getID() ~= leaderID then
            local mzone    = member:getZoneID()
            local destZone = (mzone ~= lzone) and lzone or nil
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
