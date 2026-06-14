-----------------------------------
-- func: trustattack
-- desc: Sends all of YOUR summoned trusts to attack your currently selected
--       (cursor) target -- even before you engage. Select an enemy, then run
--       the command, e.g. from a one-line macro:  /console !trustattack
--
-- Why getCursorTarget() and not getTarget(): getTarget() returns your BATTLE
-- target, which only exists once you're engaged. getCursorTarget() returns
-- whatever you have selected right now (PChar->m_TargID), so this works
-- before you've swung at anything -- the whole point of the command.
--
-- Pure Lua, no rebuild. Engages only the caller's own trusts (a party can
-- hold several masters' trusts at once).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local target = player:getCursorTarget()

    if target == nil or not target:isMob() or not target:isAlive() then
        player:printToPlayer('[Trust Attack] Select a living enemy first, then use !trustattack.', xi.msg.channel.SYSTEM_3)
        return
    end

    local targID = target:getTargID()
    local myId   = player:getID()
    local sent   = 0

    for _, member in ipairs(player:getPartyWithTrusts()) do
        if member:isTrust() then
            local master = member:getMaster()
            if master ~= nil and master:getID() == myId then
                member:engage(targID)
                sent = sent + 1
            end
        end
    end

    if sent > 0 then
        player:printToPlayer(string.format('[Trust Attack] %d trust%s charging %s!',
            sent, sent == 1 and '' or 's', (target:getName():gsub('_', ' '))), xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer('[Trust Attack] You have no trusts summoned.', xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
