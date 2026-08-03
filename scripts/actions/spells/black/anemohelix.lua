-----------------------------------
-- Spell: Anemohelix
-- Deals wind damage that gradually reduces target's HP.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local damage = xi.spells.damage.useDamageSpell(caster, target, spell) -- Gets nuke power and sets messages.

    -- Can't apply if absorbed or nullified.
    if damage > 0 then
        local power    = math.min(math.floor(damage * (100 + caster:getMod(xi.mod.HELIX_EFFECT)) / 100), 9999) -- DoT tick caps at 9999 when nuke reaches that
        local duration = xi.spells.enfeebling.calculateDuration(caster, target, spell:getID(), xi.effect.HELIX, xi.skill.ELEMENTAL_MAGIC)

        target:addStatusEffect(xi.effect.HELIX_WIND or xi.effect.HELIX, { power = power, duration = duration, origin = caster, tick = 10, tier = 1 })
    end

    return damage
end

return spellObject
