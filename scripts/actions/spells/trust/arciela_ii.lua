-----------------------------------
-- Trust: Arciela II
-- Kit provided by trust_kit_library (nuker) via trust_power_scaling.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ARCIELA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    mob:addMod(xi.mod.FASTCAST, 60)
    mob:addMod(xi.mod.UFASTCAST, 15)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 45)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
