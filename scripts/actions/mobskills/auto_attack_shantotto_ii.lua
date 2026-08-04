-----------------------------------
-- Shantotto II Magical Auto-Attack
-- Damage type = element with lowest resistance rank on the target.
-- AA lane: no MAGIC_DAMAGE / MAB (spell EMD stays on nukes only).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local function weakestElement(target)
    local bestElem = xi.element.FIRE
    local bestRank = nil

    for elem = xi.element.FIRE, xi.element.DARK do
        local modId = xi.data.element.getElementalResistanceRankModifier(elem)
        local rank  = target:getMod(modId)
        if bestRank == nil or rank < bestRank then
            bestRank = rank
            bestElem = elem
        end
    end

    return bestElem
end

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local element = weakestElement(target)
    -- xi.element.FIRE=1 … DARK=8 → xi.damageType.FIRE=6 … DARK=13
    local dmgType = xi.damageType.ELEMENTAL + element
    local params  = {}

    params.baseDamage         = mob:getWeaponDmg()
    params.fTP                = { 1.0, 1.0, 1.0 }
    params.element            = element
    params.attackType         = xi.attackType.MAGICAL
    params.damageType         = dmgType
    params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.primaryMessage     = xi.msg.basic.HIT_DMG
    params.skipMagicBonusDiff = true

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
