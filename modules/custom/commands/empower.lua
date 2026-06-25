-----------------------------------
-- func: empower
-- desc: View your Spell & Skill Mastery -- Mastery Sigil balance, weapon-skill
--       and spell potency tiers, and owned trait riders. Upgrades are bought at
--       the Mastery Sage NPC in Leafallia (see SpellSkillMastery.lua).
--
-- Usage:
--   !empower            -- show your sigil balance + everything you own
--   !empower give <n>   -- (GM only) grant yourself <n> Mastery Sigils, for testing
--
-- Lives in modules/custom/commands/ -> auto-registers as !empower (hot-reloads).
-----------------------------------
local C   = require('modules/custom/lua/spell_skill_mastery_catalog')
local SYS = xi.msg.channel.SYSTEM_3

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

commandObj.onTrigger = function(player, sub, amt)
    sub = (sub or ''):lower()

    -- GM test faucet: !empower give <n>
    if sub == 'give' then
        if (player:getGMLevel() or 0) < 1 then
            player:printToPlayer('!empower give is GM-only.', SYS)
            return
        end
        local n = tonumber(amt) or 0
        if n <= 0 then
            player:printToPlayer('Usage: !empower give <amount>', SYS)
            return
        end
        local bal = (player:getCharVar(C.CURRENCY_VAR) or 0) + n
        player:setCharVar(C.CURRENCY_VAR, bal)
        player:printToPlayer(string.format('Granted %d %s (total %d).', n, C.CURRENCY_NAME, bal), SYS)
        return
    end

    -- Default: report. Prefer the module's shared report (kept in sync with the
    -- catalog); fall back to a bare balance line if the module has not loaded.
    if xi.spellSkillMastery and xi.spellSkillMastery.report then
        xi.spellSkillMastery.report(player)
    else
        player:printToPlayer(string.format('You hold %d %s. Visit the Mastery Sage in Leafallia to spend them.',
            player:getCharVar(C.CURRENCY_VAR) or 0, C.CURRENCY_NAME), SYS)
    end
end

return commandObj
