-----------------------------------
-- Trust: AAMR
-- Melee axe Ark Angel — Sharpshot/Barrage while building TP, ASAP axe WS in melee range.
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

    -- Barrage/Sharpshot only while under 1000 TP so axe WS can fire in melee range.
    mob:addGambit(ai.t.SELF, { { ai.c.TP_LT, 1000 }, { ai.c.NOT_STATUS, xi.effect.BARRAGE } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { { ai.c.TP_LT, 1000 }, { ai.c.NOT_STATUS, xi.effect.SHARPSHOT } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHARPSHOT })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
