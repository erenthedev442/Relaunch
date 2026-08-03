-----------------------------------
-- Trust: Romaa Mihgo
-- THF/WAR — Feint / Aura Steal / SA / TA + sword WS / Cobra Clamp ASAP.
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

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FEINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FEINT })
    -- Aura Steal is a Steal trait, not a JA — use Steal to pull buffs when available.
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.STEAL })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SNEAK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SNEAK_ATTACK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.TRICK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TRICK_ATTACK })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
