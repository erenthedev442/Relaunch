-----------------------------------
-- Shared Teodor special auto-attack helpers
-- Variant A: cane slash (physical). B: dark explosion. C: silence AE.
-----------------------------------
local teodorAA = {}

local MS_SLASH   = 3628
local MS_DARK    = 3629
local MS_SILENCE = 3630

teodorAA.onMobSkillCheck = function(target, mob, skill)
    return 0
end

teodorAA.onMobWeaponSkill = function(mob, target, skill, action)
    local id = skill:getID()
    local params = {}
    params.primaryMessage = xi.msg.basic.HIT_DMG

    if id == MS_DARK then
        params.baseDamage         = mob:getWeaponDmg()
        params.fTP                = { 1.15, 1.15, 1.15 }
        params.element            = xi.element.DARK
        params.attackType         = xi.attackType.MAGICAL
        params.damageType         = xi.damageType.DARK
        params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
        params.skipMagicBonusDiff = true -- AA lane; MAGIC_DAMAGE stays on nukes/WS

        local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        end

        return info.damage
    end

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 1.0, 1.0, 1.0 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        if id == MS_SILENCE then
            xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SILENCE, 1, 0, 30)
        end
    end

    return info.damage
end

return teodorAA
