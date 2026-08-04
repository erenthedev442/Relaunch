-----------------------------------
-- Shared implementation for Arciela II unique Trust TP moves.
-- Mode: 1 = Ascension (Light), 2 = Descension (Dark). nil = either.
-----------------------------------
local M = {}

local function modeAllows(mob, requiredMode)
    if not requiredMode then
        return true
    end

    return mob:getLocalVar('ArcielaMode') == requiredMode
end

---@param element xi.element
---@param damageType xi.damageType
---@param fTP number
---@param effect xi.effect|nil
---@param power number|nil
---@param duration number|nil
---@param restore boolean|nil
---@param requiredMode number|nil 1 Ascension / 2 Descension
function M.magical(element, damageType, fTP, effect, power, duration, restore, requiredMode)
    local skillObject = {}

    skillObject.onMobSkillCheck = function(target, mob, skill)
        if not modeAllows(mob, requiredMode) then
            return 1
        end

        return 0
    end

    skillObject.onMobWeaponSkill = function(mob, target, skill, action)
        if restore then
            mob:addHP(mob:getMaxHP() - mob:getHP())
            mob:addMP(mob:getMaxMP() - mob:getMP())
        end

        local params =
        {
            -- Hybrid A package owns weapon rating + MAGIC_DAMAGE curve.
            baseDamage     = mob:getWeaponDmg(),
            fTP            = { fTP, fTP * 1.1, fTP * 1.25 },
            element        = element,
            attackType     = xi.attackType.MAGICAL,
            damageType     = damageType,
            shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
            mnd_wSC        = 0.3,
            int_wSC        = 0.3,
        }

        local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
            if effect then
                xi.mobskills.mobStatusEffectMove(mob, target, effect, power or 1, 0, duration or 30)
            end
        end

        return info.damage
    end

    return skillObject
end

return M
