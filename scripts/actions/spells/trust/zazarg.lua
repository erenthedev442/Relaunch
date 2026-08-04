-----------------------------------
-- Trust: Zazarg
-- MNK/MNK. Hand-to-Hand.
-- Abilities: Focus (when ACC soft vs target EVA).
-- WS: Howling Fist / Dragon Kick / Asuran Fists / Meteoric Impact.
-- Uses TP ASAP @1000. C-tier melee_dd (bruiser) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_FOCUS = 36

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Focus only when hit rate looks soft (high enemy evasion / low ACC).
    mob:addListener('COMBAT_TICK', 'ZAZARG_FOCUS', function(mobArg)
        local battleTarget = mobArg:getTarget()
        if not battleTarget then
            return
        end

        if
            not mobArg:hasStatusEffect(xi.effect.FOCUS) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FOCUS) and
            mobArg:getACC() < battleTarget:getEVA() + 40
        then
            mobArg:useJobAbility(xi.ja.FOCUS, mobArg)
        end
    end)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
