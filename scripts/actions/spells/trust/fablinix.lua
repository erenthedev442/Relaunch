-----------------------------------
-- Trust: Fablinix
-- THF/RDM Goblin. Dagger melee + occasional crossbow.
-- Spells: Stun (interrupt), Enwater, Cure I–IV.
-- WS: Bomb Toss (AoE fire) / Goblin Rush.
-- Holds TP to close skillchains; dumps by 1500.
-- MP+250% via pool mod. B-tier hybrid (pressure) power path.
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
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MOOGLE] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- Interrupt TP moves / casting (Stun before RATTACK so crossbow delay doesn't eat windows).
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Tank orange/yellow first; party orange / asleep.
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.ENWATER }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ENWATER })

    -- Occasional crossbow (long delay can miss Stun if overused).
    mob:addGambit(ai.t.TARGET, { ai.c.RANDOM, 40 }, { ai.r.RATTACK, 0, 0 }, 45)

    -- Close skillchains; dump by 1500.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
