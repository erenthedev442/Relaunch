-----------------------------------
-- Trust: Klara
-- WAR/WAR. Sword. No spells.
-- Abilities: Berserk, Warcry, Provoke (master <50% HP).
-- WS: Fast Blade / Vorpal Blade / Savage Blade / Temblor Blade (AoE).
-- Uses TP ASAP @1000. B-tier melee_dd (bruiser) power path.
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

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })

    -- Provoke when the player is in orange HP.
    mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

    -- Uses TP as soon as she gets it.
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
