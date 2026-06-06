-----------------------------------
-- Spell: Full Cure
-----------------------------------
-- RETAIL FIDELITY NOTE
--   Heals target to full HP in one cast. Retail Full Cure is a Trust-only spell used by the Trust 'Karaha-Baruha' to instantly top off a party member.
-- TUNING
--   No skill scaling needed -- the spell sets HP to max regardless of caster skill. If you want to add a damage-of-cure stat for logging, hook the difference between old and new HP and use `spell:setModifier(...)`.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local oldHP   = target:getHP()
    local maxHP   = target:getMaxHP()
    local healed  = maxHP - oldHP

    target:setHP(maxHP)
    spell:setMsg(xi.msg.basic.MAGIC_RECOVERS_HP)
    return healed
end

return spellObject
