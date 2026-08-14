-----------------------------------
-- !gmkeyitem <add|remove> <player> <keyItemId|KEY_NAME> <reason>
-- Audited key-item repair for GM1 support.
-----------------------------------
local support = require('modules/custom/lua/gm_support')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'b',
}

commandObj.onTrigger = function(gm, args)
    args = support.arguments(args, 'gmkeyitem')
    local action, name, keyText, reason =
        (args or ''):match('^%s*(%S+)%s+(%S+)%s+(%S+)%s+(.+)$')
    local keyId = keyText and (tonumber(keyText) or xi.ki[string.upper(keyText)]) or nil

    if (action ~= 'add' and action ~= 'remove') or not keyId or keyId < 1 then
        gm:printToPlayer(
            'Usage: !gmkeyitem <add|remove> <player> <keyItemId|KEY_NAME> <reason>',
            support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not reason or not target then
        return
    end

    if action == 'add' then
        if target:hasKeyItem(keyId) then
            gm:printToPlayer(string.format('[GM Key Item] %s already has key item %d.', target:getName(), keyId), support.channel)
            return
        end

        target:addKeyItem(keyId)
        target:printToPlayer(string.format(
            '[GM Support] Restored key item %d. Reason: %s', keyId, reason), support.channel)
        support.confirm(gm, target, string.format('added key item %d', keyId), reason)
        return
    end

    if not target:hasKeyItem(keyId) then
        gm:printToPlayer(string.format('[GM Key Item] %s does not have key item %d.', target:getName(), keyId), support.channel)
        return
    end

    target:delKeyItem(keyId)
    target:printToPlayer(string.format(
        '[GM Support] Removed key item %d. Reason: %s', keyId, reason), support.channel)
    support.confirm(gm, target, string.format('removed key item %d', keyId), reason)
end

return commandObj
