-----------------------------------
-- Trust: Gadalar
-- BLM/BLM Scythe. Firaga I–III, Blaze Spikes.
-- WS: Spinning Scythe / Spiral Hell / Vorpal Scythe / Salamander Flame (favored).
-- MP+25%, MAB+25, physical hits → MP (ABSORB_PHYSDMG_TO_MP).
-- Favors Firaga III (HIGHEST Firaga). ASAP@1000; Salamander last (HIGHEST opener).
-- B-tier nuker (pressure) — no kit inject (kit would disable AA).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SALAMANDER = 2089

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.RUGHADJEEN] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.NAJELITH] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.ZAZARG] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.MIHLI_ALIAPOH] = xi.trust.messageOffset.TEAMWORK_4,
    })

    mob:addMod(xi.mod.MPP, 25)
    mob:addMod(xi.mod.MATT, 25)
    -- Physical damage taken → MP (retail convert).
    mob:addMod(xi.mod.ABSORB_PHYSDMG_TO_MP, 5)
    mob:addMod(xi.mod.FASTCAST, 20)
    mob:addMod(xi.mod.MACC, 40)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BLAZE_SPIKES }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLAZE_SPIKES })
    -- Firaga family only; HIGHEST = Firaga III when available (lower tiers by level/MACC gate).
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FIRAGA }, 18)

    mob:addListener('WEAPONSKILL_USE', 'GADALAR_SALAMANDER', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_SALAMANDER then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- ASAP; HIGHEST opener = last list entry (Salamander Flame).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
