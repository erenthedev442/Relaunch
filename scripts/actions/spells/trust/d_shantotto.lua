-----------------------------------
-- Trust: D Shantotto
-- Kit provided by trust_kit_library (nuker) via trust_power_scaling.
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
    -- Extra FC for MB windows on top of global scaler.
    mob:addMod(xi.mod.FASTCAST, 40)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 25)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
