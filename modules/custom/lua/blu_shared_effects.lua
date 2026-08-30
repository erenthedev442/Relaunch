local bluSharedEffects = {}

-- Parameters changed by 8a23b88cd2 for spells available at the /BLU level
-- cap.  A player using BLU as a subjob receives these pre-retune values; main
-- BLU and non-PC spell users keep the live retune.
local stockSubjobParams =
{
    [513] = { power = 6, duration = 45 }, -- Venom Shell
    [519] = { multiplier = 1.375, tp150 = 1.375, tp300 = 1.375, azuretp = 1.375, duppercap = 27, str_wsc = 0.2, mnd_wsc = 0.2 },
    [521] = { dmgMultiplier = 3.5, attribute = false }, -- MP Drainkiss
    [522] = { multiplier = 1.625, tMultiplier = 1, int_wsc = 0.2, mnd_wsc = 0.1 },
    [524] = { multiplier = 1, tMultiplier = 1, int_wsc = 0.2 },
    [527] = { multiplier = 1.5, tp150 = 2.25, tp300 = 2.5, azuretp = 2.53125, duppercap = 35, str_wsc = 0.2, dex_wsc = 0.2 },
    [529] = { multiplier = 1, tp150 = 1, tp300 = 1, azuretp = 1, duppercap = 21, chr_wsc = 0.3 },
    [532] = { multiplier = 1.5625, tMultiplier = 1, int_wsc = 0.3, mnd_wsc = 0.1 },
    [534] = { multiplier = 2, tMultiplier = 1, chr_wsc = 0.3 },
    [536] = { hpMod = 10, lvlMod = 1.25 },
    [537] = { power = 10, duration = 60 },
    [539] = { multiplier = 1.5, tp150 = 1.5, tp300 = 1.5, azuretp = 1.5, duppercap = 41, dex_wsc = 0.2, int_wsc = 0.2 },
    [541] = { dmgMultiplier = 3.5, attribute = false },
    [542] = { dmgMultiplier = 5, attribute = false },
    [543] = { multiplier = 2, tp150 = 2, tp300 = 2, azuretp = 2, duppercap = 45, str_wsc = 0.2, int_wsc = 0.2 },
    [544] = { multiplier = 1.5, tMultiplier = 1, int_wsc = 0.3 },
    [545] = { multiplier = 1.5, tp150 = 1.5, tp300 = 1.5, azuretp = 1.5, duppercap = 49, dex_wsc = 0.5 },
    [551] = { multiplier = 1.125, tp150 = 1.125, tp300 = 1.125, azuretp = 1.125, duppercap = 11, vit_wsc = 0.3 },
    [555] = { hpMod = 6, lvlMod = 1.875 },
    [567] = { multiplier = 1.25, tp150 = 1.625, tp300 = 2, azuretp = 2.125, duppercap = 19, agi_wsc = 0.3 },
    [569] = { multiplier = 1.125, tp150 = 1.125, tp300 = 1.125, azuretp = 1.125, duppercap = 39, agi_wsc = 0.3 },
    [570] = { dmgMultiplier = 3, attribute = false },
    [572] = { power = 9, duration = 30 },
    [575] = { duration = 3 },
    [577] = { multiplier = 1, tp150 = 1, tp300 = 1, azuretp = 1, duppercap = 9, str_wsc = 0.1, dex_wsc = 0.1 },
    [582] = { power = 1 },
    [584] = { duration = 60 },
    [587] = { multiplier = 1.4375, tp150 = 1.4375, tp300 = 1.4375, azuretp = 1.4375, duppercap = 23, dex_wsc = 0.3 },
    [594] = { multiplier = 1.5, tp150 = 1.5, tp300 = 1.5, azuretp = 1.5, duppercap = 39, str_wsc = 0.35 },
    [596] = { multiplier = 2.25, tp150 = 2.25, tp300 = 2.25, azuretp = 2.25, duppercap = 37, str_wsc = 0.2, agi_wsc = 0.2 },
    [597] = { multiplier = 1.5, tp150 = 1.5, tp300 = 1.5, azuretp = 1.5, duppercap = 11, vit_wsc = 0.3 },
    [599] = { multiplier = 1.75, tp150 = 1.75, tp300 = 1.75, azuretp = 1.75, duppercap = 15, int_wsc = 0.2 },
    [603] = { multiplier = 1.84, tp150 = 1.84, tp300 = 1.84, azuretp = 1.84, duppercap = 11, agi_wsc = 0.3 },
    [606] = { power = 30, duration = 30 },
    [618] = { multiplier = 1.375, tMultiplier = 1, int_wsc = 0.2 },
    [620] = { multiplier = 2, tp150 = 2, tp300 = 2, azuretp = 2, duppercap = 17, str_wsc = 0.3 },
    [622] = { multiplier = 1, tp150 = 1, tp300 = 1, azuretp = 1, duppercap = 33, vit_wsc = 0.3 },
    [623] = { multiplier = 1.75, tp150 = 2.125, tp300 = 2.25, azuretp = 2.375, duppercap = 17, str_wsc = 0.2, int_wsc = 0.2 },
    [626] = { multiplier = 1.625, tMultiplier = 1, int_wsc = 0.2 },
    [638] = { multiplier = 2, tp150 = 2, tp300 = 2, azuretp = 2, duppercap = 17, agi_wsc = 0.3 },
}

local stockSubjobDrainCaps =
{
    [521] = 165,
    [541] = 0,
    [542] = 0,
    [570] = 0,
}

local controlRules =
{
    [xi.effect.STUN] =
    {
        duration = 5,
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

local TRASH_CONTROL_DURATION = 25

local function getControlLockoutVar(effect)
    return string.format('[BLU]ControlLockout:%u', effect)
end

local function checksAsImpossibleToGauge(target)
    return
        target:isNM() or
        target:isMobType(xi.mobType.BATTLEFIELD) or
        target:getMobMod(xi.mobMod.CHECK_AS_NM) > 0
end

bluSharedEffects.isMainJob = function(caster)
    return caster:getMainJob() == xi.job.BLU
end

bluSharedEffects.usesStockSubjobBehavior = function(caster)
    return
        caster:isPC() and
        not bluSharedEffects.isMainJob(caster) and
        caster:getSubJob() == xi.job.BLU
end

bluSharedEffects.applyStockSubjobParams = function(caster, spell, params)
    if not bluSharedEffects.usesStockSubjobBehavior(caster) then
        return params
    end

    local stock = stockSubjobParams[spell:getID()]
    if stock then
        for key, value in pairs(stock) do
            if value == false then
                params[key] = nil
            else
                params[key] = value
            end
        end
    end

    return params
end

bluSharedEffects.getDrainCap = function(caster, spell, currentCap)
    if not bluSharedEffects.usesStockSubjobBehavior(caster) then
        return currentCap
    end

    return stockSubjobDrainCaps[spell:getID()] or currentCap
end

bluSharedEffects.calculateBreathBase = function(caster, params)
    if bluSharedEffects.usesStockSubjobBehavior(caster) then
        local damage = caster:getHP() / params.hpMod
        if params.lvlMod > 0 then
            damage = damage + caster:getMainLvl() / params.lvlMod
        end

        return damage
    end

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
        return true, duration, nil, nil, false
    end

    -- All custom BLU control behavior is a main-job identity bonus.
    -- /BLU retains the spell's original duration and resistance behavior.
    if caster:getMainJob() ~= xi.job.BLU then
        return true, duration, nil, nil, false
    end

    if effect == xi.effect.DOOM and target:isNM() then
        return false, duration, nil, 'nm_doom', false
    end

    local rule = controlRules[effect]
    if not rule then
        return true, duration, nil, nil, false
    end

    -- Cleave packs get a reliable control window and no reapplication lockout.
    -- NMs, battlefield mobs, and CHECK_AS_NM targets retain the short,
    -- resist-scaled control profiles below.
    if not checksAsImpossibleToGauge(target) then
        return true, TRASH_CONTROL_DURATION, nil, nil, true
    end

    local lockoutVar = getControlLockoutVar(effect)
    if target:getLocalVar(lockoutVar) > now then
        return false, duration, nil, 'lockout', false
    end

    return true, rule.duration, rule.lockout, nil, false
end

bluSharedEffects.commitPlayerControl = function(target, effect, duration, lockout, now)
    if lockout then
        target:setLocalVar(getControlLockoutVar(effect), now + duration + lockout)
    end
end

return bluSharedEffects
