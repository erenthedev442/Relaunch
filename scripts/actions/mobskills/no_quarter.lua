-----------------------------------
-- No Quarter
-- Family: Humanoid (August)
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 3
    params.fTP            = { 0.35, 0.35, 0.35 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3
    -- TODO: Possible accuracy mod

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    -- End Daybreak aura (PDT / stats / Regen / Store TP)
    if mob:getLocalVar('DaybreakBuffActive') == 1 then
        local statBoost  = mob:getLocalVar('DaybreakStatBoost')
        local regenPower = mob:getLocalVar('DaybreakRegen')
        local storeTp    = mob:getLocalVar('DaybreakStoreTP')

        mob:setMod(xi.mod.DMGPHYS, 0)
        mob:delMod(xi.mod.STR, statBoost)
        mob:delMod(xi.mod.DEX, statBoost)
        mob:delMod(xi.mod.VIT, statBoost)
        mob:delMod(xi.mod.AGI, statBoost)
        mob:delMod(xi.mod.INT, statBoost)
        mob:delMod(xi.mod.MND, statBoost)
        mob:delMod(xi.mod.CHR, statBoost)
        mob:delMod(xi.mod.REGEN, regenPower)
        mob:delMod(xi.mod.STORETP, storeTp)

        mob:setLocalVar('DaybreakBuffActive', 0)
        mob:setLocalVar('DaybreakStatBoost', 0)
        mob:setLocalVar('DaybreakRegen', 0)
        mob:setLocalVar('DaybreakStoreTP', 0)
    else
        mob:setMod(xi.mod.DMGPHYS, 0)
    end

    mob:setLocalVar('DaybreakEndTime', GetSystemTime())
    skill:setFinalAnimationSub(0) -- wings off

    return info.damage
end

return mobskillObject
