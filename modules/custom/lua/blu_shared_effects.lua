local bluSharedEffects = {}

local controlRules =
{
    [xi.effect.STUN] =
    {
        duration = 3,
        lockout  = 12,
    },
    [xi.effect.TERROR] =
    {
        duration = 5,
        lockout  = 20,
    },
    [xi.effect.PETRIFICATION] =
    {
        duration = 8,
        lockout  = 30,
    },
}

local function getControlLockoutVar(effect)
    return string.format('[BLU]ControlLockout:%u', effect)
end

bluSharedEffects.calculateBreathBase = function(caster, params)
    local hp        = caster:getHP()
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local vit       = caster:getStat(xi.mod.VIT)
    local statBase  = hp / 3 + 4 * blueSkill + 6 * vit

    -- Spell identity is an explicit constant. Never derive it from the
    -- caster's current HP/stats: doing so algebraically cancels the skill and
    -- VIT terms and makes focused breath sets ineffective.
    return statBase * (params.breathMultiplier or 1)
end

bluSharedEffects.calculateDrainBase = function(caster, params)
    local skillBase = math.floor(caster:getSkillLevel(xi.skill.BLUE_MAGIC) * 0.11)
    return math.floor(skillBase * params.dmgMultiplier)
end

bluSharedEffects.calculateDiffusionDuration = function(duration, meritValue)
    -- Merit values are stored in five-point steps. The first merit enables
    -- Diffusion; each additional merit adds 5% duration.
    local durationBonus = math.max(0, meritValue - 5)
    return duration + durationBonus * duration / 100
end

bluSharedEffects.preparePlayerControl = function(caster, target, effect, duration, now)
    if not caster:isPC() then
        return true, duration, nil
    end

    if effect == xi.effect.DOOM and target:isNM() then
        return false, duration, nil, 'nm_doom'
    end

    local rule = controlRules[effect]
    if not rule then
        return true, duration, nil
    end

    local lockoutVar = getControlLockoutVar(effect)
    if target:getLocalVar(lockoutVar) > now then
        return false, duration, nil, 'lockout'
    end

    return true, rule.duration, rule.lockout
end

bluSharedEffects.commitPlayerControl = function(target, effect, duration, lockout, now)
    if lockout then
        target:setLocalVar(getControlLockoutVar(effect), now + duration + lockout)
    end
end

return bluSharedEffects
