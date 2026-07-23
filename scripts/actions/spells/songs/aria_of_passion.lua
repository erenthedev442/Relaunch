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
    local singingSkill   = caster:getSkillLevel(xi.skill.SINGING)
    local instrumentSkill = 0
    local rangeType       = caster:getWeaponSkillType(xi.slot.RANGED)

    if rangeType == xi.skill.WIND_INSTRUMENT then
        instrumentSkill = caster:getSkillLevel(rangeType)
    elseif rangeType == xi.skill.STRING_INSTRUMENT then
        instrumentSkill = math.floor(caster:getSkillLevel(rangeType) / 2)
    end

    local combinedSkill = singingSkill + instrumentSkill
    local songBonus     = caster:getMod(xi.mod.ALL_SONGS_EFFECT)
    local basePower     = math.min(13, 8 + math.floor(combinedSkill / 180))
    local power         = math.floor(basePower * (1 + songBonus * 0.1) + 0.5)
    local duration      = math.floor(120 * (1 + songBonus * 0.1))

    if not target:addBardSong(caster, xi.effect.ARIA, power, 0, duration, caster:getID(), 0, 1) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.ARIA
end

return spellObject
