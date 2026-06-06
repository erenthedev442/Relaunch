-----------------------------------
-- Spell: Protected Aria
-----------------------------------
-- RETAIL FIDELITY NOTE
--   BRD song applying a Protect-like defensive buff. Retail mechanic is unclear (likely an event/Mog-Bonanza flavor song with placeholder effect); this implementation applies the PROTECT status effect tied to caster Singing skill.
-- TUNING
--   If Protected Aria turns out to be a stack-restricted song (only one of N per party), wire it through xi.spells.song.useSong's mutex logic. Default is a 5-min Protect with potency tied to Singing skill.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.PROTECT
    local skillLvl  = caster:getSkillLevel(xi.skill.SINGING)
    local potency   = math.floor(skillLvl / 4)
    local duration  = 300

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
