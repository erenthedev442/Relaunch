-----------------------------------
-- Amatsu: Hanadoki
-- Family: Humanoid (Trust: Iroha / Iroha II)
-- Description: Magical Light damage.
-- Iroha: Impaction (Liquefaction chain). Iroha II (3734): Fragmentation + chance to Dispel.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.fTP            = { 2.0, 2.5, 3.0 }
    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        -- Iroha II: chance to Dispel.
        if skill:getID() == 3734 and math.random(1, 100) <= 40 then
            target:dispelStatusEffect()
        end
    end

    return info.damage
end

return mobskillObject
