-----------------------------------
-- !erenquesttest grant|revoke|status <player>
-- GM-only access control for the unreleased Eren transformation quest.
-- Access opens the quest gate; it never bypasses Fellow mastery or progression.
-----------------------------------
local catalog = require('modules/custom/lua/eren_quest_catalog')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ss',
}

local SYS = xi.msg.channel.SYSTEM_3

local function usage(gm)
    gm:printToPlayer('Usage: !erenquesttest <grant|revoke|status> <online player>', SYS)
end

commandObj.onTrigger = function(gm, action, playerName)
    action = type(action) == 'string' and action:lower() or ''
    if action ~= 'grant' and action ~= 'revoke' and action ~= 'status' then
        usage(gm)
        return
    end

    local target = playerName and GetPlayerByName(playerName) or nil
    if not target then
        gm:printToPlayer('[Eren Quest] That player is not online.', SYS)
        usage(gm)
        return
    end

    if action == 'grant' then
        target:setCharVar(catalog.vars.access, 1)
        gm:printToPlayer(string.format(
            '[Eren Quest] Tester access granted to %s. Full Fellow mastery is still required.',
            target:getName()), SYS)
        target:printToPlayer(
            '[Eren Quest] You have been granted test access to The Name Beyond the Ferry. A fully mastered Fellow is required.',
            SYS)
    elseif action == 'revoke' then
        if xi.erenQuest and xi.erenQuest.abort then
            xi.erenQuest.abort(target)
        end
        target:setCharVar(catalog.vars.access, 0)
        gm:printToPlayer(string.format(
            '[Eren Quest] Tester access revoked from %s. Existing quest progress was preserved.',
            target:getName()), SYS)
        target:printToPlayer('[Eren Quest] Your test access has been revoked. Existing progress was preserved.', SYS)
    else
        gm:printToPlayer(string.format(
            '[Eren Quest] %s: access=%s stage=%d unlocked=%s mastered=%s',
            target:getName(),
            catalog.hasAccess(target) and 'yes' or 'no',
            catalog.getStage(target),
            catalog.isUnlocked(target) and 'yes' or 'no',
            catalog.isMastered(target) and 'yes' or 'no'), SYS)
    end
end

return commandObj
