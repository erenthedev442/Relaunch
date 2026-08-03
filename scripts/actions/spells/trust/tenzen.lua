-----------------------------------
-- Trust: Tenzen
-- SAM starter — Amatsu WS, Hasso / Meditate / Hagakure / Third Eye, Save TP+400.
-- C-tier: power comes from trust_power_scaling (no script-level ATT/STR stack).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.TENZEN_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Tenzen
    if caster:getEminenceProgress(935) then
        xi.roe.onRecordTrigger(caster, 935)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.IROHA] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- Retail flavor only — combat power is applied by trust_power_scaling (C melee package).
    mob:addMod(xi.mod.SAVETP, 400)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MEDITATE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HAGAKURE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HAGAKURE })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Starter C DD: WS ASAP so he contributes without waiting on skillchains.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
