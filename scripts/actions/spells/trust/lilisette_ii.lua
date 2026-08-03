-----------------------------------
-- Trust: Lilisette II
-- A-tier DNC — dagger WS ASAP.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LILISETTE)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.NO_SAMBA, 0 }, { ai.r.JA, ai.s.BEST_SAMBA, xi.ja.DRAIN_SAMBA })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.LETHARGIC_DAZE_5 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.QUICKSTEP }, 25)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 45 }, { ai.r.JA, ai.s.HIGHEST_WALTZ, xi.ja.CURING_WALTZ })

    mob:addMod(xi.mod.ACC, 120)
    mob:addMod(xi.mod.ATT, 80)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
