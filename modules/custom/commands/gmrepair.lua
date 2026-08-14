-----------------------------------
-- !gmrepair <quest|mission> <status|add|complete|delete|clearvars>
--           <player> <log> <id> [reason]
-- Explicit, audited quest/mission repair for GM1 support.
-----------------------------------
local logHelpers = require('scripts/globals/log_ids')
local support = require('modules/custom/lua/gm_support')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'b',
}

local function usage(gm)
    gm:printToPlayer(
        'Usage: !gmrepair <quest|mission> <status|add|complete|delete|clearvars> <player> <log> <id> [reason]',
        support.channel)
end

local function resolveEntry(kind, logText, idText)
    if kind == 'quest' then
        local info = logHelpers.getQuestLogInfo(logText)
        if not info then
            return nil
        end
        local ids = xi.quest.id[xi.quest.area[info.quest_log]]
        local entryId = tonumber(idText) or (ids and ids[string.upper(idText)])
        return entryId and {
            log = info.quest_log,
            id = entryId,
            label = info.full_name,
            prefix = xi.quest.getVarPrefix(info.quest_log, entryId),
        } or nil
    elseif kind == 'mission' then
        local info = logHelpers.getMissionLogInfo(logText)
        if not info then
            return nil
        end
        local ids = xi.mission.id[xi.mission.area[info.mission_log]]
        local entryId = tonumber(idText) or (ids and ids[string.upper(idText)]) or _G[string.upper(idText)]
        return entryId and {
            log = info.mission_log,
            id = entryId,
            label = info.full_name,
            prefix = xi.mission.getVarPrefix(info.mission_log, entryId),
        } or nil
    end

    return nil
end

local function printStatus(gm, target, kind, entry)
    if kind == 'quest' then
        gm:printToPlayer(string.format(
            '[GM Repair] %s quest %s/%d status=%d',
            target:getName(), entry.label, entry.id,
            target:getQuestStatus(entry.log, entry.id)), support.channel)
    else
        gm:printToPlayer(string.format(
            '[GM Repair] %s mission %s/%d current=%d status=%d completed=%s',
            target:getName(), entry.label, entry.id,
            target:getCurrentMission(entry.log),
            target:getMissionStatus(entry.log),
            target:hasCompletedMission(entry.log, entry.id) and 'yes' or 'no'), support.channel)
    end

    local vars = target:getCharVarsWithPrefix(entry.prefix)
    local count = 0
    for name, value in pairs(vars) do
        gm:printToPlayer(string.format('  %s = %s', name, value), support.channel)
        count = count + 1
    end
    if count == 0 then
        gm:printToPlayer('  No related character variables.', support.channel)
    end
end

commandObj.onTrigger = function(gm, args)
    args = support.arguments(args, 'gmrepair')
    local kind, action, name, logText, idText, reason =
        (args or ''):match('^%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*(.-)%s*$')

    kind = kind and kind:lower() or nil
    action = action and action:lower() or nil
    local target = support.resolvePlayer(gm, name)
    local entry = logText and idText and resolveEntry(kind, logText, idText) or nil
    if not target or not entry then
        usage(gm)
        return
    end

    if action == 'status' then
        printStatus(gm, target, kind, entry)
        return
    end

    if action ~= 'add' and action ~= 'complete' and action ~= 'delete' and action ~= 'clearvars' then
        usage(gm)
        return
    end

    reason = support.requireReason(gm, reason)
    if not reason then
        return
    end

    if action == 'clearvars' then
        target:clearVarsWithPrefix(entry.prefix)
    elseif kind == 'quest' and action == 'add' then
        target:addQuest(entry.log, entry.id)
    elseif kind == 'quest' and action == 'complete' then
        target:completeQuest(entry.log, entry.id)
    elseif kind == 'quest' and action == 'delete' then
        target:delQuest(entry.log, entry.id)
    elseif kind == 'mission' and action == 'add' then
        target:addMission(entry.log, entry.id)
    elseif kind == 'mission' and action == 'complete' then
        target:completeMission(entry.log, entry.id)
    elseif kind == 'mission' and action == 'delete' then
        target:delMission(entry.log, entry.id)
    end

    local description = string.format('%s %s %s/%d', action, kind, entry.label, entry.id)
    target:printToPlayer(string.format('[GM Support] Repair applied: %s. Reason: %s', description, reason), support.channel)
    support.confirm(gm, target, description, reason)
end

return commandObj
