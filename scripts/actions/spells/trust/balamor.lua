-----------------------------------
-- Trust: Balamor
-- DRK/BLM Defiant (Undead). Absorb-STAT only. No JAs.
-- WS: Feast of Arrows / Last Laugh / Regurgitated Swarm / Setting the Stage.
-- HP+40%, MP+100%. Dark magical auto-attacks. RANDOM TP, no skillchains.
-- A-tier hybrid (pressure) power path.
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

    -- Retail HP/MP package (family is already Undead / Defiant).
    mob:addMod(xi.mod.HPP, 40)
    mob:addMod(xi.mod.MPP, 100)
    -- Immune to Aspir; HP Drain is blocked by undead ecosystem on most drain moves.
    mob:addImmunity(xi.immunity.ASPIR)
    -- Special AA ignores Slow (and doesn't benefit from Haste/Sambas).
    mob:addImmunity(xi.immunity.SLOW)

    -- Absorb-STAT only (no Stun / Souleater / Last Resort — retail has no JAs).
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ABSORB }, 45)

    -- Dark elemental special auto-attacks (not physical GS swings).
    mob:setMobSkillAttack(2098)

    -- Uses TP randomly; does not try to skillchain.
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
