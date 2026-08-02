-----------------------------------
-- Trust: Shantotto II
-- MB-first nuker. Soft cap 40k; magic bursts may hit up to 79,999
-- (EncounterOutgoingDamageCapMB set by trust_power_scaling).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.SHANTOTTO)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 25)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Capstone nuker flavor on top of global scaler.
    mob:addMod(xi.mod.FASTCAST, 80)
    mob:addMod(xi.mod.UFASTCAST, 20)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 55)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_CAPPED, 40)
    mob:addMod(xi.mod.HASTE_MAGIC, 1500)

    -- Perfect hit rate on her typeless melee swings.
    mob:addMod(xi.mod.ACC, 1000)
    mob:setMobSkillAttack(1163)
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)

    mob:addListener('WEAPONSKILL_USE', 'SHANTOTTO_II_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == 3740 then -- Final Exam
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:addListener('MAGIC_USE', 'SHANTOTTO_II_MAGIC', function(mobArg, target, spell, action)
        if math.random(1, 100) <= 33 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_2)
        end
    end)

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
