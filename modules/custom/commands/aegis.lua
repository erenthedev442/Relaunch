-----------------------------------
-- func: aegis
-- desc: Cast Divine Aegis (a PLD-only custom spell) on yourself: a Holy
--       shield that absorbs physical damage and cuts physical damage taken
--       by 20% for 30s, then detonates as a Holy AoE. Exposed as a command
--       because the client cannot hard-cast custom spell IDs.
--
-- Divine Aegis is a Legendary-only custom spell (ID 1020). The stock client
-- has no data for IDs >= 1020, so it cannot hard-cast it (you get "a command
-- error occurred"). This command runs the EXACT same server-side effect the
-- spell would, gated to match the spell's own rules: PLD 50 main job,
-- 80 MP, 120s recast, and the spell's "no overlap with Stoneskin" check.
--
-- The effect itself is reused straight from the spell file
-- (scripts/actions/spells/white/divine_aegis.lua) so the command and the
-- spell can never drift apart. onSpellCast(caster, target, spell) ignores
-- its target/spell args entirely (it is a pure self-buff), so we can call it
-- directly with (player, player, nil).
--
-- Lives in modules/custom/commands/ -> auto-registers as !aegis.
-----------------------------------
local gate        = require('modules/custom/lua/custom_spell_command')
local divineAegis = require('scripts/actions/spells/white/divine_aegis')

local cfg =
{
    name    = 'Divine Aegis',
    spellId = 1020,
    jobs    = { [xi.job.PLD] = 50 },
    reqText = 'PLD 50',
    mp      = 80,
    recast  = 120,
    cdVar   = 'cmdspell_aegis_cd',
}

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not gate.check(player, cfg) then
        return
    end

    -- Mirror the spell's onMagicCastingCheck: Divine Aegis cannot overlap an
    -- existing Stoneskin (its own shield IS a Stoneskin, hence the recast too).
    if player:hasStatusEffect(xi.effect.STONESKIN) then
        player:printToPlayer('Divine Aegis: no effect while Stoneskin is active.', xi.msg.channel.SYSTEM_3)
        return
    end

    divineAegis.onSpellCast(player, player, nil)
    gate.commit(player, cfg)
    player:printToPlayer('Divine Aegis: Holy shield raised -- detonates in 30s.', xi.msg.channel.SYSTEM_3)
end

return commandObj
