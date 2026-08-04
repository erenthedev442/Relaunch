-----------------------------------
-- Start from Scratch
-- Trust Teodor (3631): erase debuffs, dark aura, consumes TP.
-- Script-gated; not used from the random WS picker.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3631

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if skill:getID() == MS_TRUST and mob:getLocalVar('teoScratch') == 0 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:setLocalVar('teoScratch', 0)
    mob:setTP(0)
    mob:delStatusEffectsByFlag(xi.effectFlag.WALTZABLE, false)
    mob:delStatusEffectsByFlag(xi.effectFlag.ERASABLE, false)

    -- Dark aura: shadows + regen; AI holds to 2000 for Hemocladis.
    mob:setLocalVar('teoAura', 1)
    xi.mobskills.mobBuffMove(mob, xi.effect.COPY_IMAGE, 1, 0, 180, 0, 3)
    xi.mobskills.mobBuffMove(mob, xi.effect.REGEN, math.max(1, math.floor(mob:getMainLvl() / 3)), 3, 180)

    skill:setMsg(xi.msg.basic.NONE)
    return 0
end

return mobskillObject
