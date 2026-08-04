-----------------------------------
-- Dryad's Kiss
-- Trust: Rosulatia. Self Haste + strong Regen (level-scaled).
-- Yellow HP only (<75%).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if mob:getHPP() >= 75 then
        return 1
    end

    -- Don't refresh while already under a Dryad kiss.
    if mob:getLocalVar('rosuDryad') == 1 and mob:hasStatusEffect(xi.effect.REGEN) then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local lvl    = mob:getMainLvl()
    local regen  = math.max(10, math.floor(lvl * 1.25))
    local haste  = 1500
    local duration = 90

    xi.mobskills.mobBuffMove(mob, xi.effect.HASTE, haste, 0, duration)
    skill:setMsg(xi.mobskills.mobBuffMove(mob, xi.effect.REGEN, regen, 3, duration))
    mob:setLocalVar('rosuDryad', 1)

    return xi.effect.REGEN
end

return mobskillObject
