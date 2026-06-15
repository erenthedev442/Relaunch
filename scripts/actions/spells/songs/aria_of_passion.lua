-----------------------------------
-- Spell: Aria of Passion
-- Increases Physical Damage Limit for party members (DAMAGE_LIMITP).
-- Retail: BRD 99, ROV content, 8s cast / 24s recast / 2min duration.
-- Loughnashade equip condition is not enforced on this server.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local singingSkill = caster:getSkillLevel(xi.skill.SINGING)
    -- Base 8% + 1% per 60 skill, cap 20% (matches retail ~13-22% range)
    local power    = math.min(20, 8 + math.floor(singingSkill / 60))
    local duration = 120 -- 2 minutes

    if not target:addBardSong(caster, xi.effect.ARIA, power, 0, duration, caster:getID(), 0, 1) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.ARIA
end

return spellObject
