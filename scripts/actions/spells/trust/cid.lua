-----------------------------------
-- Trust: Cid
-- WAR/RNG. Club + gun. Berserk / Aggressor.
-- WS: True Strike / Hexa Strike / Fiery Tailings (AoE fire) / Critical Mass (fire).
-- Holds to 2500 TP to close skillchains. Berserk only when about to WS.
-- A-tier melee_dd (bruiser) power path.
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

    -- Fire WS lane (Critical Mass / Fiery Tailings); bruiser package is physical.
    mob:addMod(xi.mod.MATT, 200)
    mob:addMod(xi.mod.MACC, 120)
    mob:addMod(xi.mod.MAGIC_DAMAGE, 4500)
    -- Aggressive Aim–style RACC on Aggressor usage (flat representation of merits).
    mob:addMod(xi.mod.RACC, 60)
    mob:addMod(xi.mod.RATT, 40)

    -- Aggressor freely; Berserk saved until he is about to weaponskill.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    mob:addGambit(ai.t.SELF, {
        { ai.c.TP_GTE, 1000 },
        { ai.c.NOT_STATUS, xi.effect.BERSERK },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })

    -- Both melees and shoots (gun ~every 10s).
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 10)

    -- Save TP to close skillchains; dump by 2500.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
