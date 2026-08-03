-----------------------------------
-- Trust: Lhe Lhangavo
-- S-tier MNK — Victory Smite / Asuran ASAP.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FOCUS }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FOCUS })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DODGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DODGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COUNTERSTANCE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.COUNTERSTANCE })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

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
