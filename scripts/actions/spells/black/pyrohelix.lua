-----------------------------------
-- Spell: Pyrohelix
-- Deals fire damage that gradually reduces a target's HP.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local damage = xi.spells.damage.useDamageSpell(caster, target, spell)

    if damage > 0 then
        local power    = math.min(math.floor(damage * (100 + caster:getMod(xi.mod.HELIX_EFFECT)) / 100), 65535) -- FJB: HELIX_EFFECT(478) = % Helix dmg; 65535 = uint16 effect-power cap
        local duration = xi.spells.enfeebling.calculateDuration(caster, target, spell:getID(), xi.effect.HELIX, xi.skill.ELEMENTAL_MAGIC)
        local effect   = xi.effect.HELIX_FIRE or xi.effect.HELIX

        target:addStatusEffect(effect, { power = power, duration = duration, origin = caster, tick = 10, tier = 1 })
    end

    return damage
end

return spellObject
