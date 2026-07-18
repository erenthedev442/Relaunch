-----------------------------------
-- Reforge native NM combat behaviors
--
-- Dynamic entities inherit their pool and TP list, but they do not load the
-- retail zone mob script. This module ports only portable combat behavior:
-- no zone doors, titles, drops, fixed mob IDs, or retail spawn conditions.
-----------------------------------

local M = {}

local GROUP =
{
    KIRIN    = 11400,
    BYAKKO   = 11401,
    SEIRYU   = 11402,
    SUZAKU   = 11403,
    GENBU    = 11404,
    TINNIN   = 11409,
    BRIAREUS = 11410,
    IRATHAM  = 11411,
}

local jobSpecialMixin = require('scripts/mixins/job_special')

local additionalElements =
{
    [GROUP.GENBU]  = xi.element.WATER,
    [GROUP.SUZAKU] = xi.element.FIRE,
    [GROUP.SEIRYU] = xi.element.WIND,
    [GROUP.BYAKKO] = xi.element.LIGHT,
}

local mercurialEffects =
{
    [ 111] = { skill =  664 },
    [ 222] = { skill =  665 },
    [ 333] = { skill =  665 },
    [ 444] = { skill =  667 },
    [ 555] = { skill = 1636 },
    [ 666] = { skill = 1636 },
    [ 777] = { skill = 2576 },
    [ 888] = { skill = 2578 },
    [ 999] = { skill = 2578 },
    [1111] = { skill = 2578, meikyo = true },
}

function M.mixinsFor(groupId)
    -- Kirin is intentionally excluded: retail wires a fixed-ID avatar before
    -- Astral Flow. A dynamic arena copy has no safe pet offset to summon.
    if groupId >= GROUP.BYAKKO and groupId <= GROUP.GENBU or groupId == GROUP.TINNIN then
        return { jobSpecialMixin }
    end

    return nil
end

function M.genbuAttackAtHpp(baseAttack, hpp)
    return baseAttack + (100 - hpp) * 10
end

function M.irathamSpellListAtHpp(hpp)
    if hpp < 20 then
        return 155
    elseif hpp < 50 then
        return 154
    end

    return 153
end

local function regenerateTinninHead(mob, animationSub)
    mob:setLocalVar('RF_TinninHeadAt', os.time() + math.random(90, 210))
    mob:setAnimationSub(animationSub - 1)

    local multiplier = 0.05
    if animationSub == 1 and mob:getLocalVar('RF_TinninHead3Regen') == 0 then
        mob:setLocalVar('RF_TinninHead3Regen', 1)
        multiplier = 0.25
    elseif animationSub == 2 and mob:getLocalVar('RF_TinninHead2Regen') == 0 then
        mob:setLocalVar('RF_TinninHead2Regen', 1)
        multiplier = 0.25
    end

    mob:addHP(mob:getMaxHP() * multiplier)
end

function M.attach(mob, groupId)
    mob:setLocalVar('RF_NativeGroup', groupId)

    if additionalElements[groupId] then
        mob:setMobMod(xi.mobMod.ADD_EFFECT, 1)
    end

    if groupId == GROUP.GENBU then
        mob:setLocalVar('RF_GenbuBaseATT', mob:getMod(xi.mod.ATT))
        mob:setMod(xi.mod.DOUBLE_ATTACK, 10)
        mob:setMod(xi.mod.COUNTER, 20)
    elseif groupId == GROUP.SUZAKU then
        mob:setMobMod(xi.mobMod.MAGIC_COOL, 35)
        mob:setMagicCastingEnabled(false)
        mob:timer(math.random(5000, 10000), function(mobArg)
            if mobArg then
                mobArg:setMagicCastingEnabled(true)
            end
        end)
    elseif groupId == GROUP.SEIRYU then
        mob:setMobMod(xi.mobMod.MAGIC_COOL, 35)
        mob:setMod(xi.mod.REGAIN, 450)
        mob:setMagicCastingEnabled(false)
        mob:timer(math.random(5000, 10000), function(mobArg)
            if mobArg then
                mobArg:setMagicCastingEnabled(true)
            end
        end)
        mob:addListener('EFFECT_LOSE', 'RF_SEIRYU_HF', function(mobArg, effect)
            if effect:getEffectType() == xi.effect.HUNDRED_FISTS then
                mobArg:setMagicCastingEnabled(true)
                mobArg:setMobAbilityEnabled(true)
            end
        end)
    elseif groupId == GROUP.BYAKKO then
        mob:setMagicCastingEnabled(false)
        mob:timer(math.random(5000, 10000), function(mobArg)
            if mobArg then
                mobArg:setMagicCastingEnabled(true)
            end
        end)
    elseif groupId == GROUP.KIRIN then
        -- Preserve Kirin's relentless native TP cadence without importing its
        -- fixed-zone god-add IDs into the shared multi-station arena.
        mob:setMod(xi.mod.REGAIN, 1000)
        mob:setMagicCastingEnabled(false)
        mob:timer(5000, function(mobArg)
            if mobArg then
                mobArg:setMagicCastingEnabled(true)
            end
        end)
    elseif groupId == GROUP.TINNIN then
        -- Keep Reforge's full-HP apex profile, but restore the native head-loss,
        -- head-regrowth, draw-in TP pressure, and chained breath behavior.
        mob:setLocalVar('RF_TinninHeadAt', os.time() + math.random(90, 210))
        mob:setLocalVar('RF_TinninCrits', 0)
        mob:setLocalVar('RF_TinninCritThreshold', math.random(10, 30))
        mob:setLocalVar('RF_TinninHead2Regen', 0)
        mob:setLocalVar('RF_TinninHead3Regen', 0)
    end
end

local function tickBriareus(mob)
    local mercurialDamage = mob:getLocalVar('MERCURIAL_STRIKE_DAMAGE')
    local effect = mercurialEffects[mercurialDamage]
    if effect then
        mob:setLocalVar('CUE_MOVE', effect.skill)
        if effect.meikyo then
            mob:useMobAbility(xi.mobSkill.MEIKYO_SHISUI_1)
        end

        mob:setLocalVar('MERCURIAL_STRIKE_DAMAGE', 0)
    end

    if mob:hasStatusEffect(xi.effect.MEIKYO_SHISUI) then
        mob:setTP(3000)
    end
end

local function tickTinnin(mob, target)
    if mob:checkDistance(target) >= mob:getMeleeRange(target) * 2 then
        if utils.drawIn(target, { position = mob:getPos() }) then
            mob:addTP(3000)
        end
    end

    local animationSub = mob:getAnimationSub()
    if animationSub > 0 and os.time() >= mob:getLocalVar('RF_TinninHeadAt') then
        regenerateTinninHead(mob, animationSub)

        if bit.band(mob:getBehavior(), xi.behavior.NO_TURN) > 0 then
            mob:setBehavior(bit.band(mob:getBehavior(), bit.bnot(xi.behavior.NO_TURN)))
        end

        mob:useMobAbility(xi.mobSkill.BAROFIELD)
    end
end

function M.tick(mob, target, groupId)
    if groupId == GROUP.GENBU then
        local baseAttack = mob:getLocalVar('RF_GenbuBaseATT')
        mob:setMod(xi.mod.ATT, M.genbuAttackAtHpp(baseAttack, mob:getHPP()))
        mob:setMod(xi.mod.REGAIN, mob:getHPP() < 50 and 80 or 0)
    elseif groupId == GROUP.SEIRYU then
        mob:setMod(xi.mod.REGAIN, mob:getHPP() < 50 and 700 or 450)
    elseif groupId == GROUP.BRIAREUS then
        tickBriareus(mob)
    elseif groupId == GROUP.IRATHAM then
        mob:setMobMod(xi.mobMod.SPELL_LIST, M.irathamSpellListAtHpp(mob:getHPP()))
    elseif groupId == GROUP.TINNIN then
        tickTinnin(mob, target)
    end
end

function M.roam(mob, groupId)
    if groupId ~= GROUP.TINNIN then
        return
    end

    local animationSub = mob:getAnimationSub()
    if animationSub > 0 and os.time() >= mob:getLocalVar('RF_TinninHeadAt') then
        regenerateTinninHead(mob, animationSub)
    end
end

function M.chooseMobSkill(mob, groupId)
    if groupId ~= GROUP.BRIAREUS then
        return 0
    end

    local cueMove = mob:getLocalVar('CUE_MOVE')
    mob:setLocalVar('CUE_MOVE', 0)
    if mob:hasStatusEffect(xi.effect.MEIKYO_SHISUI) then
        return 2578
    end

    return cueMove
end

function M.onWeaponSkill(mob, target, skill, groupId)
    local skillId = skill:getID()

    if groupId == GROUP.SEIRYU and skillId == xi.mobSkill.HUNDRED_FISTS_1 then
        mob:setMagicCastingEnabled(false)
        mob:setMobAbilityEnabled(false)
    elseif groupId == GROUP.TINNIN then
        if target == mob:getTarget() and skillId == xi.mobSkill.BAROFIELD then
            mob:useMobAbility(xi.mobSkill.POLAR_BLAST)
        elseif
            target == mob:getTarget() and
            skillId == xi.mobSkill.POLAR_BLAST and
            mob:getAnimationSub() == 0
        then
            mob:useMobAbility(xi.mobSkill.PYRIC_BLAST)
        elseif skillId == xi.mobSkill.PYRIC_BULWARK or skillId == xi.mobSkill.POLAR_BULWARK then
            mob:useMobAbility(xi.mobSkill.NERVE_GAS)
        end
    end
end

function M.onCriticalHit(mob, groupId)
    if groupId ~= GROUP.TINNIN or mob:getAnimationSub() == 2 then
        return
    end

    local criticals = mob:getLocalVar('RF_TinninCrits') + 1
    if criticals >= mob:getLocalVar('RF_TinninCritThreshold') then
        criticals = 0
        mob:setAnimationSub(mob:getAnimationSub() + 1)
        mob:setLocalVar('RF_TinninHeadAt', os.time() + math.random(90, 210))
        mob:setLocalVar('RF_TinninCritThreshold', math.random(10, 30))
    end

    mob:setLocalVar('RF_TinninCrits', criticals)
end

function M.onAdditionalEffect(mob, target, damage, groupId)
    local element = additionalElements[groupId]
    if not element then
        return
    end

    return xi.combat.action.executeAddEffectDamage(mob, target, {
        chance         = 100,
        attackType     = xi.attackType.MAGICAL,
        magicalElement = element,
        basePower      = math.floor(damage / 2),
        actorStat      = xi.mod.INT,
    })
end

return M
