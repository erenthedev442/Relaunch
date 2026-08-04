-----------------------------------
-- Uriel Blade
-- Family: Humanoid Sword Weaponskill (Valaineral Trust)
-- AoE light damage + Flash. Usable under 1000 TP via VAL_URIEL_CHECK gambit.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    mob:messageBasic(xi.msg.basic.READIES_WS, 0, xi.weaponskill.URIEL_BLADE)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Early Uriel (engage / enmity) often fires under 1000 TP — use 1000 fTP tier.
    local ftp = 4.5
    local tp  = skill:getTP()
    if tp >= 3000 then
        ftp = 7.5
    elseif tp >= 2000 then
        ftp = 6.0
    end

    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { ftp, ftp, ftp }
    params.element          = xi.element.LIGHT
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.LIGHT
    params.shadowBehavior   = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.MND
    params.dStatDefenderMod = xi.mod.MND

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.FLASH, 200, 0, 15)
    end

    return info.damage
end

return mobskillObject
