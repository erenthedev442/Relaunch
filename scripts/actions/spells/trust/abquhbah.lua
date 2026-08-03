-----------------------------------
-- Trust: Abquhbah
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
    mob:addGambit(ai.t.SELF, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
