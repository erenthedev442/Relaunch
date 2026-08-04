-----------------------------------
-- Trust: Ingrid
-- WHM/WHM Club. Haste, Banish I–III, Cursna.
-- WS: Seraph Strike / Judgment / Hexa Strike.
-- Undead Killer; Banish vs Undead flavor. ~100 TP/hit.
-- Melees in. CLOSER@1500. Extreme Cursna priority (Doom/Curse).
-- Haste on master always + melee jobs. Cycles Banish (highest→lowest).
-- B-tier hybrid (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.INGRID_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail Undead Killer; Banish-vs-undead +10 (28/256) has no dedicated mod.
    mob:addMod(xi.mod.UNDEAD_KILLER, 15)
    -- Club delay 240 → ~100 TP/hit.
    mob:addMod(xi.mod.STORETP, 50)
    mob:addMod(xi.mod.ACC, 40)
    mob:addMod(xi.mod.MACC, 30)

    -- Extreme priority: Cursna for Doom / Curse.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    -- Haste: master regardless of job, then other melee jobs.
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })
    mob:addGambit(ai.t.MELEE, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    -- Cycle Banish highest → lowest (HIGHEST = Banish III when available).
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BANISH }, 25)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Hold to close SC; dump at 1500.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
