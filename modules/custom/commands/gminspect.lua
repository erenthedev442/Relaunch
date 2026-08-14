-----------------------------------
-- !gminspect <player>
-- Read-only support summary for an online player.
-----------------------------------
local support = require('modules/custom/lua/gm_support')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

local function jobName(jobId)
    for name, id in pairs(xi.job) do
        if id == jobId then
            return name
        end
    end
    return tostring(jobId)
end

commandObj.onTrigger = function(gm, name)
    local target = support.resolvePlayer(gm, name)
    if not target then
        return
    end

    local sessions =
    {
        dungeon = (target:getCharVar('DungeonActive') or 0) > 0 or target:getInstance() ~= nil,
        wave    = xi._gm_sessions and xi._gm_sessions[target:getName()] ~= nil,
        tower   = xi._et_sessions and xi._et_sessions[target:getName()] ~= nil,
        gauntlet = xi._gauntlet_sessions and xi._gauntlet_sessions[target:getName()] ~= nil,
        apex    = xi._apex_sessions and xi._apex_sessions[target:getName()] ~= nil,
    }

    gm:printToPlayer(string.format('[GM Inspect] %s — %s',
        target:getName(), target:getZoneName() or ('Zone ' .. target:getZoneID())), support.channel)
    gm:printToPlayer(string.format(
        '  Job: %s%d/%s%d | Party: %d | Event: %s | Jail: %s',
        jobName(target:getMainJob()), target:getMainLvl(),
        jobName(target:getSubJob()), target:getSubLvl(),
        target:getPartySize(),
        target:isInEvent() and 'YES' or 'no',
        (target:getCharVar('inJail') or 0) > 0 and 'YES' or 'no'), support.channel)
    gm:printToPlayer(string.format(
        '  Hunt Marks: %d | Infamy: %d | Reforge: AF %d / Relic %d / Empy %d',
        target:getCharVar('HL_Points') or 0,
        target:getCharVar('Infamy') or 0,
        target:getCharVar('RF_AF_Marks') or 0,
        target:getCharVar('RF_Relic_Marks') or 0,
        target:getCharVar('RF_Empy_Marks') or 0), support.channel)
    gm:printToPlayer(string.format(
        '  Sessions: dungeon=%s wave=%s tower=%s gauntlet=%s apex=%s',
        sessions.dungeon and 'active' or '-',
        sessions.wave and 'active' or '-',
        sessions.tower and 'active' or '-',
        sessions.gauntlet and 'active' or '-',
        sessions.apex and 'active' or '-'), support.channel)
end

return commandObj
