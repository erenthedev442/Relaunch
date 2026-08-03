-----------------------------------
-- Spell: Adloquium
-- SCH enhancing: Regain 10 TP/tick for 180s (retail).
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    -- scripts/effects/regain.lua multiplies power by 10 → power 1 = 10 TP/tick.
    local power    = 1
    local duration = 180

    -- Duration gear / RDM composure-style mods do not apply to Adloquium on retail;
    -- keep a flat 180s (Accession still AOEs via the spell itself).
    if target:addStatusEffect(xi.effect.REGAIN, {
        power    = power,
        duration = duration,
        origin   = caster,
        tick     = 3,
    })
    then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.REGAIN
end

return spellObject
