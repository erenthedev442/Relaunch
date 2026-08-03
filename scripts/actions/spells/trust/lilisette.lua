-----------------------------------
-- Trust: Lilisette
-- A-tier DNC — dagger WS ASAP (Rudra / Pyrrhic / Exenterator).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LILISETTE_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.NO_SAMBA, 0 }, { ai.r.JA, ai.s.BEST_SAMBA, xi.ja.DRAIN_SAMBA })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.LETHARGIC_DAZE_5 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.QUICKSTEP }, 25)
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 45 }, { ai.r.JA, ai.s.HIGHEST_WALTZ, xi.ja.CURING_WALTZ })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.WALTZABLE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HEALING_WALTZ })

    mob:addMod(xi.mod.ACC, 100)
    mob:addMod(xi.mod.ATT, 60)
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
