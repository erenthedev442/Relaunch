-----------------------------------
-- Trust: Excenmille (S)
-- WAR/PLD. Great Sword. No spells.
-- Ability: Stag's Call (AoE Haste/Att/MAB 15%, 3 min / 5 min CD).
-- WS: Songbird Swoop / Gyre Strike (Paralyze) / Orcsbane (AoE) / Stag's Charge.
-- Uses WS ASAP at 1000 TP. Modest Regain (retail).
-- B-tier melee_dd (bruiser) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.EXCENMILLE)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail: "possess a form of Regain".
    mob:addMod(xi.mod.REGAIN, 30)

    -- Stag's Call: party buff ability, 5 minute recast (not a TP WS).
    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.MS, ai.s.SPECIFIC, 3291 }, 300)

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
