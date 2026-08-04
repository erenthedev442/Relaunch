-----------------------------------
-- trust_cipher_drops.lua
--
-- Award trust spell unlocks from content NM kills (direct learn — no ciphers).
-- Catalog: modules/custom/lua/trust_cipher_drop_catalog.lua
--
-- Call from each content system's death/reward path with an explicit system
-- tag — NEVER match on mob name alone (Kirin/Briareus/Aquarius collide).
--
--   local trustDrops = require('modules/custom/lua/trust_cipher_drops')
--   pcall(function() trustDrops.tryAward(player, nmName, 'hl') end)
--
-- Systems: 'hl' | 'unity' | 'geas' | 'reforge' | 'abyssea' | 'gauntlet'
-----------------------------------
local catalog = require('modules/custom/lua/trust_cipher_drop_catalog')

local M = {}

local SYS = xi.msg.channel.SYSTEM_3

local function awardDirect(player, entry)
    if player:hasSpell(entry.spellId) then
        return false, 'known'
    end

    if not xi.trustGrant or not xi.trustGrant.grantSpell then
        return false, 'no_gate'
    end

    if not xi.trustGrant.grantSpell(player, entry.spellId) then
        return false, 'grant_failed'
    end

    player:printToPlayer(
        string.format('[Trust] You learned the Alter Ego: %s!', entry.trustName),
        SYS)
    return true, 'spell'
end

--- Try to award a trust unlock for this content kill.
--- @return boolean awarded, string|nil reason
function M.tryAward(player, nmName, system)
    if player == nil or nmName == nil or system == nil then
        return false, 'bad_args'
    end

    if player:getObjType() ~= xi.objType.PC then
        return false, 'not_pc'
    end

    local entry = catalog.lookup(system, nmName)
    if not entry then
        return false, 'no_entry'
    end

    local pct = entry.dropPct or 0
    if pct <= 0 then
        return false, 'no_rate'
    end

    if math.random(100) > pct then
        return false, 'miss'
    end

    return awardDirect(player, entry)
end

--- Force a roll that always succeeds (GM / test). Still respects known-spell skip.
function M.forceAward(player, nmName, system)
    if player == nil or nmName == nil or system == nil then
        return false, 'bad_args'
    end

    local entry = catalog.lookup(system, nmName)
    if not entry then
        return false, 'no_entry'
    end

    return awardDirect(player, entry)
end

return M
