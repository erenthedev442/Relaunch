-----------------------------------
-- Trust: Leonoyne
-- BLM/PLD Great Sword. Ice Spikes, Blizzaga I–III (favors III).
-- WS: Freezebite / Shockwave / Herculean Slash / Spine Chiller (rare Terror).
-- MP+25%, permanent Enblizzard (30+), physical hits → MP.
-- ASAP@1000 (no SC hold). Melees in. B-tier nuker (pressure) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SPINE_CHILLER = 2274

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.MPP, 25)
    mob:addMod(xi.mod.FASTCAST, 20)
    -- Land Blizzaga; lower tiers gate by level / available MP in GetBestAvailable.
    mob:addMod(xi.mod.MACC, 50)
    -- Physical damage taken → MP (retail convert).
    mob:addMod(xi.mod.ABSORB_PHYSDMG_TO_MP, 5)

    -- Permanent Enblizzard: 30+ ice on every hit even at low levels.
    local enDmg = math.max(30, math.floor(mob:getMainLvl() * 0.45))
    mob:addMod(xi.mod.ENSPELL, xi.element.ICE)
    mob:addMod(xi.mod.ENSPELL_DMG, enDmg)
    mob:addMod(xi.mod.ENSPELL_CHANCE, 100)

    -- GS AA (nuker package has no melee axes).
    mob:addMod(xi.mod.ACC, 50)
    mob:addMod(xi.mod.ATT, 60)
    mob:addMod(xi.mod.MAIN_DMG_RATING, 30)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.ICE_SPIKES }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ICE_SPIKES })
    -- Favors Blizzaga III (HIGHEST); lower tiers when level/MACC/MP gate.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BLIZZAGA }, 18)

    mob:addListener('WEAPONSKILL_USE', 'LEONOYNE_SPINE_CHILLER', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_SPINE_CHILLER then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Dump at 1000; RANDOM = ignore SC condition.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
