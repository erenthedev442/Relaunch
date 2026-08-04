-----------------------------------
-- Oisoya
-- Family: Humanoid (Tenzen / Trust: Tenzen II)
-- Namas Arrow variant (Light / Distortion). Identical enmity CE/VE on Trust.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if mob:getObjType() == xi.objType.TRUST then
        return 0
    end

    if
        (mob:getAnimationSub() == 5 or
        mob:getAnimationSub() == 6) and
        mob:getLocalVar('[Tenzen]ShouldOisoya') == 1
    then
        return 0
    end

    return 1
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local isTrust = mob:getObjType() == xi.objType.TRUST
    local rangedDmg = mob:getRangedDmg()

    -- Trust: ranged rating feeds B-tier path. Story Tenzen keeps weapon dmg.
    params.baseDamage       = (isTrust and rangedDmg > 0) and rangedDmg or mob:getWeaponDmg()
    params.numHits          = 1
    -- Namas-class fTP; B soft-band / softclamp own the ceiling.
    params.fTP              = { 4.125, 4.125, 4.125 }
    params.attackType       = xi.attackType.RANGED
    params.damageType       = xi.damageType.PIERCING
    params.shadowBehavior   = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.accuracyModifier = { 100, 100, 100 }
    params.skipParry        = true
    params.skipGuard        = true
    params.skipBlock        = true
    if not isTrust then
        params.attackMultiplier = { 2.75, 2.75, 2.75 }
        params.fTP              = { 5.5, 5.5, 5.5 }
    end

    local info = xi.mobskills.mobRangedMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        info.damage = target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        -- Namas Arrow enmity (overrideCE 160 / overrideVE 480).
        if isTrust and info.damage > 0 then
            mob:lowerEnmity(target, 85)
            target:addEnmity(mob, 160, 480)
        end
    end

    return info.damage
end

return mobskillObject
