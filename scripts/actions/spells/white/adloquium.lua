-----------------------------------
-- Spell: Adloquium
-----------------------------------
-- RETAIL FIDELITY NOTE
--   SCH stronger Stoneskin variant. Applies the Stoneskin effect at a higher power and longer duration than the base Stoneskin spell. Cannot stack with regular Stoneskin -- it overrides if active.
-- TUNING
--   Power formula: MND/2 + skill/4. Tune the divisors if it caps too high/low. The duration is 3min by default (vs Stoneskin's 5min); some retail data suggests SCH variants run shorter for balance.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.STONESKIN
    local skillLvl  = caster:getSkillLevel(spell:getSkillType())
    local mnd       = caster:getStat(xi.mod.MND)
    local potency   = math.floor(mnd / 2) + math.floor(skillLvl / 4)
    local duration  = 180

    if target:hasStatusEffect(effect) then
        target:delStatusEffect(effect)
    end

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
