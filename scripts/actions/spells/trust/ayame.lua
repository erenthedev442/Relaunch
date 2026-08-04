-----------------------------------
-- Trust: Ayame
-- SAM/SAM. Meditate, Hasso, Third Eye.
-- GK WS through Tachi: Kasha (+ Koki). Opens skillchains for the player via
-- SPECIAL_AYAME (reads master's last WS). Holds for master's 1000 TP / dumps at 3000.
-- C-tier weaponskill power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.AYAME_UC)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NAJI] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.GILGAMESH] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    -- Only when she pulls hate.
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Meditate only when the player has WS TP and she does not (recastId 134).
    mob:addListener('COMBAT_TICK', 'AYAME_MEDITATE', function(mobArg)
        if mobArg:hasRecast(xi.recast.ABILITY, 134) then
            return
        end

        local master = mobArg:getMaster()
        if master and master:getTP() >= 1000 and mobArg:getTP() < 1000 then
            mobArg:useJobAbility(xi.ja.MEDITATE, mobArg)
        end
    end)

    -- Open for the player (SPECIAL_AYAME). Holds until master/party has 1000 TP;
    -- at 3000 TP the trust controller always allows a WS.
    mob:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.SPECIAL_AYAME)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
