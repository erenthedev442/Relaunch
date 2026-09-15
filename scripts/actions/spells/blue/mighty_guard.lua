-----------------------------------
-- Spell: Mighty Guard
-- Short Unbridled party window: modest Regen, Magic Defense, Haste, and
-- a small damage-taken cut. Not a 3-5 minute immunity kit.
-- Spell cost: 299 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Light)
-- Blue Magic Points: 0 (Unbridled)
-- Stat Bonus: none (Unbridled)
-- Level: 99
-- Casting Time: 3.5 seconds
-- Recast Time: 30 seconds
-- Duration: 60 seconds
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

-- Keep this on its own effect. Applying Haste / Defense Boost as
-- separate statuses fails when a stronger Cocoon or Erratic Flutter is
-- already up, so the party kept 75% DEF + 30% Haste and still received
-- Magic Defense and Regen 30 for three minutes.
spellObject.DURATION = 60
spellObject.REGEN    = 8
spellObject.MDEF     = 5
spellObject.HASTE    = 1000 -- 10%, addMod so it does not clobber Flutter

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, spellObject.DURATION)

    if not target:addStatusEffect(xi.effect.MIGHTY_GUARD, {
        power    = spellObject.REGEN,
        subPower = spellObject.MDEF,
        tier     = spellObject.HASTE,
        duration = duration,
        origin   = caster,
    })
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.MIGHTY_GUARD
end

return spellObject
