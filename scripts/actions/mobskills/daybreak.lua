-----------------------------------
-- Daybreak
-- Family: Humanoid (August)
-- When August's HP drops below 66%, he uses Daybreak if available:
-- partial HP/MP restore, TP reset, wings (animation sub 5).
-- -50% PDT, full Erase, stats boost, Regen, Store TP.
-- Removed after No Quarter (cooldown starts then).
-- Type: Magical
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 7, 7, 7 }
    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    local lvl    = mob:getMainLvl()
    local hpHeal = lvl * 7
    local mpHeal = lvl * 7

    mob:eraseAllStatusEffect()
    mob:addHP(hpHeal)
    mob:addMP(mpHeal)
    mob:setTP(0)
    mob:setLocalVar('DaybreakUsed', 1)

    -- Aura: PDT / stats / Regen / Store TP (cleared on No Quarter)
    if mob:getLocalVar('DaybreakBuffActive') == 0 then
        local statBoost = math.max(5, math.floor(lvl * 0.25))
        local regenPower = math.max(3, math.floor(lvl / 10))
        local storeTp    = 15

        mob:setMod(xi.mod.DMGPHYS, -5000) -- -50% PDT
        mob:addMod(xi.mod.STR, statBoost)
        mob:addMod(xi.mod.DEX, statBoost)
        mob:addMod(xi.mod.VIT, statBoost)
        mob:addMod(xi.mod.AGI, statBoost)
        mob:addMod(xi.mod.INT, statBoost)
        mob:addMod(xi.mod.MND, statBoost)
        mob:addMod(xi.mod.CHR, statBoost)
        mob:addMod(xi.mod.REGEN, regenPower)
        mob:addMod(xi.mod.STORETP, storeTp)

        mob:setLocalVar('DaybreakBuffActive', 1)
        mob:setLocalVar('DaybreakStatBoost', statBoost)
        mob:setLocalVar('DaybreakRegen', regenPower)
        mob:setLocalVar('DaybreakStoreTP', storeTp)
    end

    skill:setFinalAnimationSub(5) -- wings / SPECIAL_AUGUST gate

    return info.damage
end

return mobskillObject
