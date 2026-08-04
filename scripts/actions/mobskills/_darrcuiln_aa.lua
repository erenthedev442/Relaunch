-----------------------------------
-- Shared Darrcuiln special auto-attack helpers
-----------------------------------
local M = {}

-- Physical-feel AA that cannot miss (magical hit path, no MAB). Scales with setDamage.
M.physical = function(damageType)
    local skillObject = {}

    skillObject.onMobSkillCheck = function(target, mob, skill)
        -- Melee AA only in range; roar handles out-of-range.
        if mob:checkDistance(target) > 7 then
            return 1
        end

        return 0
    end

    skillObject.onMobWeaponSkill = function(mob, target, skill, action)
        local params = {}

        params.baseDamage         = mob:getWeaponDmg()
        params.fTP                = { 1.0, 1.0, 1.0 }
        params.element            = xi.element.NONE
        params.attackType         = xi.attackType.MAGICAL
        params.damageType         = damageType
        params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
        params.primaryMessage     = xi.msg.basic.HIT_DMG
        params.skipMagicBonusDiff = true

        local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        end

        return info.damage
    end

    return skillObject
end

-- Roar: magical AA. Preferred / exclusive when target is out of melee range.
M.howl = function()
    local skillObject = {}

    skillObject.onMobSkillCheck = function(target, mob, skill)
        return 0
    end

    skillObject.onMobWeaponSkill = function(mob, target, skill, action)
        local params = {}

        -- Match claw/charge AA power; wind element only (MAB reserved for Howling Gust WS).
        params.baseDamage         = mob:getWeaponDmg()
        params.fTP                = { 1.0, 1.0, 1.0 }
        params.element            = xi.element.WIND
        params.attackType         = xi.attackType.MAGICAL
        params.damageType         = xi.damageType.WIND
        params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
        params.primaryMessage     = xi.msg.basic.HIT_DMG
        params.skipMagicBonusDiff = true

        local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        end

        return info.damage
    end

    return skillObject
end

return M
