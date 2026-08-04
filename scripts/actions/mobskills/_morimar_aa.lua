-----------------------------------
-- Shared Morimar special auto-attack helpers
-- Magical hit path so spikes/samba don't apply; scales with setDamage.
-----------------------------------
local M = {}

M.physical = function()
    local skillObject = {}

    skillObject.onMobSkillCheck = function(target, mob, skill)
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
        params.damageType         = xi.damageType.SLASHING
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
