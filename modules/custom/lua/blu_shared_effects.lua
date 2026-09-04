-- FileWatcher dofile discards the return value. Mutate the cached table so a
-- reload cannot silently drop the custom-NM disable contract.
local CATALOG_KEY = 'modules/custom/lua/blu_shared_effects'
local bluSharedEffects = package.loaded[CATALOG_KEY]
if type(bluSharedEffects) ~= 'table' then
    bluSharedEffects = {}
end
package.loaded[CATALOG_KEY] = bluSharedEffects

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

-- Main-job BLU control: stun is always 5s on ordinary targets. Terror /
-- petrify are a full 25s on trash and overworld NMs. No reapplication lockout.
-- Custom-content NMs (Geas Fete, Abyssea, HTBF, Apex, and other marked
-- events) ignore every disabling BLU effect except Head Butt, which is a
-- guaranteed 3s stun.
local STUN_DURATION              = 5
local CUSTOM_NM_HEAD_BUTT_STUN   = 3
local HARD_CONTROL_DURATION      = 25

local disablingEffects =
{
    [xi.effect.STUN]                  = true,
    [xi.effect.TERROR]                = true,
    [xi.effect.PETRIFICATION]         = true,
    [xi.effect.GRADUAL_PETRIFICATION] = true,
    [xi.effect.SLEEP_I]               = true,
    [xi.effect.SLEEP_II]              = true,
    [xi.effect.BIND]                  = true,
    [xi.effect.CHARM_I]               = true,
    [xi.effect.CHARM_II]              = true,
    [xi.effect.AMNESIA]               = true,
}

local customContentZones =
{
    [xi.zone.ABYSSEA_KONSCHTAT]      = true,
    [xi.zone.ABYSSEA_TAHRONGI]       = true,
    [xi.zone.ABYSSEA_LA_THEINE]      = true,
    [xi.zone.ABYSSEA_ATTOHWA]        = true,
    [xi.zone.ABYSSEA_MISAREAUX]      = true,
    [xi.zone.ABYSSEA_VUNKERL]        = true,
    [xi.zone.ABYSSEA_ALTEPA]         = true,
    [xi.zone.ABYSSEA_GRAUBERG]       = true,
    [xi.zone.ABYSSEA_ULEGUERAND]     = true,
    [xi.zone.ABYSSEA_EMPYREAL_PARADOX] = true,
    [xi.zone.REISENJIMA]             = true,
    [xi.zone.REISENJIMA_HENGE]       = true,
    [xi.zone.REISENJIMA_SANCTORIUM]  = true,
}

local customContentVars =
{
    'GeasFeteMobSkillDamageCap',
    'GeasFeteOwnerId',
    'HTBFScaled',
    'OWS_EXCLUDE',
}

local function getControlLockoutVar(effect)
    return string.format('[BLU]ControlLockout:%u', effect)
end

bluSharedEffects.isApexMob = function(target)
    if not target or not target.getName then
        return false
    end

    local name = target:getName() or ''
    return name:find('^[Aa]pex[_%s%-]') ~= nil
end

bluSharedEffects.isDisablingControl = function(effect)
    return disablingEffects[effect] == true
end

-- Geas Fete, Abyssea NMs, HTBF, Apex, Voidspire/Gauntlet/Invasion-style
-- pops (NO_CAPACITY_POINTS / CHECK_AS_NM / battlefield), and other marked
-- custom events. Ordinary overworld NMs stay off this list.
bluSharedEffects.isCustomContentNm = function(target)
    if not target then
        return false
    end

    if target.isMob and not target:isMob() then
        return false
    end

    if bluSharedEffects.isApexMob(target) then
        return true
    end

    if target.getLocalVar then
        for i = 1, #customContentVars do
            if (target:getLocalVar(customContentVars[i]) or 0) > 0 then
                return true
            end
        end
    end

    if
        target.getMobMod and
        (
            (target:getMobMod(xi.mobMod.CHECK_AS_NM) or 0) > 0 or
            (target:getMobMod(xi.mobMod.NO_CAPACITY_POINTS) or 0) > 0
        )
    then
        return true
    end

    if
        target.isMobType and
        target:isMobType(xi.mobType.BATTLEFIELD)
    then
        return true
    end

    if
        target.isNM and
        target:isNM() and
        target.getZoneID and
        customContentZones[target:getZoneID()]
    then
        return true
    end

    return false
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

bluSharedEffects.usesUnresistedMagic = function(caster)
    return caster:isPC() and bluSharedEffects.isMainJob(caster)
end

bluSharedEffects.clampMagicResist = function(caster, resist)
    if bluSharedEffects.usesUnresistedMagic(caster) then
        return 1
    end

    return resist
end

-- Main-job BLU elemental damage: weak 1.25, neutral 1.00, resist / same 0.10.
-- /BLU and non-PC casters keep stock SDT. Absorb stays on the absorb path.
bluSharedEffects.ELEMENT_WEAK     = 1.25
bluSharedEffects.ELEMENT_NEUTRAL  = 1.00
bluSharedEffects.ELEMENT_RESIST   = 0.10

bluSharedEffects.getElementMatchupFromSDT = function(sdt)
    if not sdt then
        return bluSharedEffects.ELEMENT_NEUTRAL
    end

    if sdt < 1 then
        return bluSharedEffects.ELEMENT_RESIST
    elseif sdt > 1 then
        return bluSharedEffects.ELEMENT_WEAK
    end

    return bluSharedEffects.ELEMENT_NEUTRAL
end

bluSharedEffects.getElementMatchup = function(target, spellElement)
    if
        not spellElement or
        spellElement < xi.element.FIRE or
        spellElement > xi.element.DARK
    then
        return bluSharedEffects.ELEMENT_NEUTRAL
    end

    return bluSharedEffects.getElementMatchupFromSDT(xi.combat.damage.magicalElementSDT(target, spellElement))
end

bluSharedEffects.getElementalDamageFactor = function(caster, target, spellElement, stockSDT)
    if bluSharedEffects.usesUnresistedMagic(caster) then
        return bluSharedEffects.getElementMatchup(target, spellElement)
    end

    return stockSDT or xi.combat.damage.magicalElementSDT(target, spellElement)
end

-- Investment heals: skill, MND, and Cure Potency. No giant flat 900.
bluSharedEffects.calculateBlueCure = function(caster, target, params)
    params = params or {}
    local skill    = caster:getSkillLevel(xi.skill.BLUE_MAGIC) or 0
    local mnd      = caster:getStat(xi.mod.MND) or 0
    local potency  = ((caster:getMod(xi.mod.CURE_POTENCY) or 0) + (caster:getMod(xi.mod.CURE_POTENCY_II) or 0)) / 100
    potency        = math.max(0, math.min(potency, 0.80))
    local received = 0
    if target and target.getMod then
        received = (target:getMod(xi.mod.CURE_POTENCY_RCVD) or 0) / 100
    end

    local heal = (params.base or 0) +
        (params.skill or 0.30) * skill * (params.scale or 1) +
        (params.mnd or 1.50) * mnd * (params.scale or 1)

    if (params.hp or 0) > 0 then
        heal = heal + caster:getMaxHP() * params.hp
    end

    heal = heal * (1 + potency) * (1 + received)
    if params.cap then
        heal = math.min(heal, params.cap)
    end

    return math.max(0, math.floor(heal))
end

bluSharedEffects.applyBlueCure = function(caster, target, params)
    local missing = target:getMaxHP() - target:getHP()
    local cure    = math.min(bluSharedEffects.calculateBlueCure(caster, target, params), missing)
    target:addHP(cure)
    caster:updateEnmityFromCure(target, cure)
    return cure
end

bluSharedEffects.preparePlayerControl = function(caster, target, effect, duration, now, spellId)
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

    if
        bluSharedEffects.isDisablingControl(effect) and
        bluSharedEffects.isCustomContentNm(target)
    then
        if
            effect == xi.effect.STUN and
            spellId == xi.magic.spell.HEAD_BUTT
        then
            return true, CUSTOM_NM_HEAD_BUTT_STUN, nil, nil, true
        end

        return false, duration, nil, 'custom_nm_disable', false
    end

    if effect == xi.effect.STUN then
        return true, STUN_DURATION, nil, nil, true
    end

    if
        effect == xi.effect.TERROR or
        effect == xi.effect.PETRIFICATION
    then
        return true, HARD_CONTROL_DURATION, nil, nil, true
    end

    return true, duration, nil, nil, false
end

bluSharedEffects.commitPlayerControl = function(target, effect, duration, lockout, now)
    if lockout then
        target:setLocalVar(getControlLockoutVar(effect), now + duration + lockout)
    end
end

return bluSharedEffects
