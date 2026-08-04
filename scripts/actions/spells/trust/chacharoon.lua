-----------------------------------
-- Trust: Chacharoon
-- THF/RNG Qiqirn. No spells / JAs.
-- WS: Sharp Eye (conal Gravity II + Def Down) / Tripe Gripe (Amnesia + Atk Boost) /
--     Pocket Sand (conal earth + Blind).
-- HP/MP-10%. Very low delay, low base damage. Occasional throwing RATTACK.
-- WS at 1000 TP. B-tier utility (support) power path — not a DPS trust.
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

    mob:addMod(xi.mod.HPP, -10)
    mob:addMod(xi.mod.MPP, -10)
    -- Stick-and-rocks: fast swings, low hit. Retail also notes Triple Attack.
    mob:addMod(xi.mod.TRIPLE_ATTACK, 15)

    -- Occasional throwing ranged attack (rocks).
    mob:addGambit(ai.t.TARGET, { ai.c.RANDOM, 40 }, { ai.r.RATTACK, 0, 0 }, 20)

    -- Uses weapon skills at 1000 TP; status kit, pick randomly.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
