-----------------------------------
-- !fellowname <name>
-- Give your Adventuring Fellow a custom (free-text) name. This is the ONLY
-- naming method -- it replaced the old preset name list.
--   * Letters and spaces only; max 15 characters.
--   * Runs through a language filter (see fellow_name.lua FN.PROFANITY).
--   * Persists across relog/zone and re-applies every time the Fellow is
--     summoned; if the Fellow is out, it renames instantly.
-----------------------------------
local FN = require('modules/custom/lua/fellow_name')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- all players
    parameters = 's',
}

commandObj.onTrigger = function(player, name)
    if not name or name == '' then
        player:printToPlayer(
            '[Fellow] Usage: !fellowname <name>  (letters and spaces only, max 15 chars).',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local ok, result = FN.apply(player, name)
    if not ok then
        player:printToPlayer('[Fellow] ' .. result, xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer(
        string.format('[Fellow] Name set to "%s". (Re)summon your Fellow if it does not update.', result),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
