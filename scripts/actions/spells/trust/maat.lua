-----------------------------------
-- Trust: Maat
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.MAAT_UC)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- On cooldown
    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MANTRA })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FOCUS }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FOCUS })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DODGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DODGE })

    mob:addListener('WEAPONSKILL_USE', 'MAAT_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == 3263 then -- Bear Killer
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:addMod(xi.mod.ACC, 100)
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
