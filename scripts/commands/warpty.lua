-----------------------------------
-- !warpty
-- desc: Party leader only: pulls every online party member to the leader's
-- desc: position. Members already inside a different instance run are skipped
-- desc: and must leave that run first.
--
-- Derived from !bring: same zone -> instant WPOS snap; different zone -> zone transfer.
--
-- 2026-09-09 CRASH FIX (three xi_map ACCESS_VIOLATIONs in CZoneEntities::SpawnPCs):
-- the old version did `member:setInstance(leaderInst)` + same-zone `setPos` on
-- EVERY member. A member who was already placed inside a DIFFERENT live copy of
-- the same instance (Dynamis Divergence spawns one copy per creator) got its
-- PInstance re-pointed while still sitting in its own copy's character list.
-- On the resulting zone-out the engine removed the wrong character from the
-- wrong copy, left the member with a null zone pointer inside its real copy, and
-- that copy's next tick dereferenced it. Rules now:
--   * member inside the LEADER's copy            -> plain position snap, no re-bind
--   * member inside ANY OTHER instance run       -> skipped (told to leave it first)
--   * member outside any instance                -> bound to the leader's run and zoned in
--   * leader not in an instance                  -> unchanged !bring behaviour
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- True when `member` is physically inside `instance` (present in that copy's
-- character list). Two copies of the same instance share getID(), so the only
-- reliable "same copy" test is membership by character ID.
local function isInsideInstance(member, instance)
    local memberId = member:getID()
    for _, p in pairs(instance:getChars()) do
        if p:getID() == memberId then
            return true
        end
    end
    return false
end

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
    if player:getID() ~= leaderID then
        player:printToPlayer('Only the party leader can use !warpty.', xi.msg.channel.SYSTEM_3)
        return
    end

    local lx       = leader:getXPos()
    local ly       = leader:getYPos()
    local lz       = leader:getZPos()
    local lrot     = leader:getRotPos()
    local lzone    = leader:getZoneID()

    local travelGuard = require('modules/custom/lua/travel_guard')
    local inst = leader:getInstance()
    local warped = 0
    local skipped = {}
    for _, member in ipairs(player:getParty()) do
        if member and member:getID() ~= leaderID then
            local blocked = inst and
                lzone == xi.zone.MAQUETTE_ABDHALJS_LEGION_B and
                xi.ambuscade and
                xi.ambuscade.canEnter and
                not xi.ambuscade.canEnter(member)
            if not blocked and not travelGuard.refuseTravel(member) then
                if inst then
                    local memberInst = member:getInstance()
                    if memberInst and isInsideInstance(member, inst) then
                        -- Same copy as the leader: plain snap, never re-bind or re-zone.
                        member:setPos(lx, ly, lz, lrot)
                        warped = warped + 1
                    elseif memberInst then
                        -- Bound to (or inside) another run. Re-pointing them here is
                        -- what crashed the server; they have to leave that run first.
                        table.insert(skipped, member:getName())
                        member:printToPlayer(
                            string.format('%s tried to pull you with !warpty, but you are bound to another instance. Leave it first.', leader:getName()),
                            xi.msg.channel.SYSTEM_3)
                    else
                        -- Outside any instance: bind to the leader's run and zone in.
                        member:setInstance(inst)
                        member:setPos(lx, ly, lz, lrot, lzone)
                        warped = warped + 1
                    end
                else
                    -- Mirror !bring: cross-zone gets setPos with zone arg, same-zone
                    -- gets a plain snap.
                    if member:getZoneID() ~= lzone then
                        member:setPos(lx, ly, lz, lrot, lzone)
                    else
                        member:setPos(lx, ly, lz, lrot)
                    end
                    warped = warped + 1
                end
            end
        end
    end

    player:printToPlayer(
        string.format('Warped %d party member%s to %s in %s.',
            warped,
            warped == 1 and '' or 's',
            leader:getName(),
            leader:getZoneName()),
        xi.msg.channel.SYSTEM_3)

    if #skipped > 0 then
        player:printToPlayer(
            string.format('Skipped (bound to another instance run): %s.', table.concat(skipped, ', ')),
            xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
