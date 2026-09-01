-----------------------------------
-- Blue Magic utilities
-- Used for Blue Magic spells.
-----------------------------------
require('scripts/globals/combat/physical_utilities')
require('scripts/globals/combat/magic_hit_rate')
require('scripts/globals/magic')
require('scripts/globals/mobskills')
require('scripts/globals/spells/damage_spell')
-----------------------------------
xi = xi or {}
xi.spells = xi.spells or {}
xi.spells.blue = xi.spells.blue or {}
local standardMagic = require('modules/custom/lua/standard_magic_tuning_catalog')
local blueWeaponCatalog = require('modules/custom/lua/blu_weapon_amplification_catalog')
local bluSpellPower = require('modules/custom/lua/blu_spell_power_catalog')
local bluSharedEffects = require('modules/custom/lua/blu_shared_effects')
local levelingHpCap = require('modules/custom/lua/leveling_hp_cap')
-----------------------------------

-- The TP modifier (currently unused)
xi.spells.blue.tpMod =
{
    NONE          = 0,
    CRITICAL      = 1,
    DAMAGE        = 2,
    ACC           = 3,
    ATTACK        = 4,
    DURATION      = 5,
    EFFECT_CHANCE = 6,
}

-----------------------------------
-- Local functions
-----------------------------------

-- Get alpha (level-dependent multiplier on WSC)
local function calculateAlpha(level)
    if level <= 60 then
        return math.ceil(100 - level / 6) / 100
    elseif level <= 75 then
        return math.ceil(100 - (level - 40) / 2) / 100
    else
        return 0.83
    end
end

-- Get WSC
local function calculateWSC(attacker, params)
    local alpha  = calculateAlpha(attacker:getMainLvl())
    local wscSTR = attacker:getStat(xi.mod.STR) * params.str_wsc
    local wscDEX = attacker:getStat(xi.mod.DEX) * params.dex_wsc
    local wscVIT = attacker:getStat(xi.mod.VIT) * params.vit_wsc
    local wscAGI = attacker:getStat(xi.mod.AGI) * params.agi_wsc
    local wscINT = attacker:getStat(xi.mod.INT) * params.int_wsc
    local wscMND = attacker:getStat(xi.mod.MND) * params.mnd_wsc
    local wscCHR = attacker:getStat(xi.mod.CHR) * params.chr_wsc

    local wsc = (wscSTR + wscDEX + wscVIT + wscAGI + wscINT + wscMND + wscCHR) * alpha

    -- BLU "Blue Magic Effect" job point gift: bonus to the attribute value used by
    -- physical blue magic, weighted by the spell's stat coefficients so it scales
    -- like a real stat bump on whichever stats the spell uses.
    local bmBonus = attacker:getMod(xi.mod.BLUE_MAGIC_EFFECT)
    if bmBonus > 0 then
        wsc = wsc + bmBonus * (params.str_wsc + params.dex_wsc + params.vit_wsc + params.agi_wsc + params.int_wsc + params.mnd_wsc + params.chr_wsc) * alpha
    end

    return wsc
end

-- Get cRatio
local function calculatecRatio(ratio, atk_lvl, def_lvl)
    -- Get ratio with level penalty
    local levelcor = 0
    if atk_lvl < def_lvl then
        levelcor = 0.05 * (def_lvl - atk_lvl)
    end

    ratio = ratio - levelcor
    ratio = utils.clamp(ratio, 0, 2)

    -- Get cRatiomin
    local cratiomin = 0
    if ratio < 1.25 then
        cratiomin = 1.2 * ratio - 0.5
    elseif ratio >= 1.25 and ratio <= 1.5 then
        cratiomin = 1
    elseif ratio > 1.5 and ratio <= 2 then
        cratiomin = 1.2 * ratio - 0.8
    end

    -- Get cRatiomax
    local cratiomax = 0
    if ratio < 0.5 then
        cratiomax = 0.4 + 1.2 * ratio
    elseif ratio <= 0.833 and ratio >= 0.5 then
        cratiomax = 1
    elseif ratio <= 2 and ratio > 0.833 then
        cratiomax = 1.2 * ratio
    end

    -- Return data
    local cratio = {}
    if cratiomin < 0 then
        cratiomin = 0
    end

    cratio[1] = cratiomin
    cratio[2] = cratiomax

    return cratio
end

-- Get the fTP multiplier (by applying 2 straight lines between ftp0-ftp1500 and ftp1500-ftp3000)
local function calculatefTP(tp, ftp0, ftp1500, ftp3000)
    tp = utils.clamp(tp, 0, 3000)

    if tp >= 1500 then
        return ftp1500 + (ftp3000 - ftp1500) * (tp - 1500) / 1500
    else
        return ftp0 + (ftp1500 - ftp0) * tp / 1500
    end
end

-- Get fSTR
local function calculatefSTR(dSTR)
    local fSTR2 = 0

    if dSTR >= 12 then
        fSTR2 = dSTR + 4
    elseif dSTR >= 6 then
        fSTR2 = dSTR + 6
    elseif dSTR >= 1 then
        fSTR2 = dSTR + 7
    elseif dSTR >= -2 then
        fSTR2 = dSTR + 8
    elseif dSTR >= -7 then
        fSTR2 = dSTR + 9
    elseif dSTR >= -15 then
        fSTR2 = dSTR + 10
    elseif dSTR >= -21 then
        fSTR2 = dSTR + 12
    else
        fSTR2 = dSTR + 13
    end

    return fSTR2 / 2
end

-- Get hitrate
local function calculateHitrate(attacker, target, bonusacc)
    -- your mainhand may not be a sword, so hit rate would vary here
    -- TODO: verify hit rate of physical blue magic with different weapons
    return xi.combat.physicalHitRate.getPhysicalHitRate(attacker, target, bonusacc + attacker:getMerit(xi.merit.PHYSICAL_POTENCY) * 2, xi.attackAnimation.RIGHT_ATTACK, false)
end

-- Get the effect of ecosystem correlation
local function calculateCorrelation(spellEcosystem, monsterEcosystem, merits)
    local effect = utils.getEcosystemStrengthBonus(spellEcosystem, monsterEcosystem) * 0.25

    if effect > 0 then -- merits don't impose a penalty, only a benefit in case of strength
        effect = effect + 0.001 * merits
    end

    return effect
end

-- Consecutive Elemental Damage Penalty. Most commonly known as "Nuke Wall".
-- NOTE: Duplicate of the same function in damage_spell.lua, until Blue magic gets rewritten.
local function calculateNukeWallFactor(target, spellElement, finalDamage)
    -- Initial check.
    if
        not target:isNM() or               -- Target is not an NM.
        spellElement <= xi.element.NONE or -- Action isn't elemental.
        finalDamage < 0                    -- Action heals target.
    then
        return 1
    end

    -----------------------------------
    -- Fetch current wall potency and math based on time and Ruake
    -----------------------------------
    local potency = 0
    local effect  = target:getStatusEffect(xi.effect.NUKE_WALL)

    if effect then
        -- Current nuke wall effect.
        potency = effect:getPower()

        -- Effect potency is reduced by 20% after 1 second and remains stable for the remaining time, unless refreshed.
        if effect:getTimeRemaining() <= 4000 then
            potency = utils.clamp(potency - 2000, 0, 4000) -- Potency is reduced by 2000 (20%) after first second has happened. Can't go below 0.
        end

        -- Rayke effect.
        if target:hasStatusEffect(xi.effect.RAYKE) then
            local raykeSubpower = target:getStatusEffect(xi.effect.RAYKE):getSubPower()

            -- current bit size of subPower is 16 bits, 4*4 = 16
            -- Step from 0 to 16 in increments of 4...
            for i = 0, 16, 4 do
                -- If element is bitpacked into rayke subeffect...
                if bit.band(bit.rshift(raykeSubpower, i), 0xF) == spellElement then
                    potency = math.floor(potency / 2)

                    break
                end
            end
        end

        target:delStatusEffectSilent(xi.effect.NUKE_WALL)
    end

    -----------------------------------
    -- Calculate new potency after this nuke and renew effect.
    -----------------------------------
    -- Calculate damage needed to reach the potency cap (4000). The lower the level, the easier to hit potency cap.
    local damageCap = target:getMainLvl() * 21 + 500

    -- Calculate new potency, based on existing potency and damage dealt (compared to mob level).
    local finalPotency = utils.clamp(math.floor(4000 * finalDamage / damageCap) + potency, 0, 4000)

    -- Renew status effect without messages.
    target:addStatusEffect(xi.effect.NUKE_WALL, { power = finalPotency, duration = 5, origin = target, icon = 0, subPower = spellElement })

    -----------------------------------
    -- We return JUST the factor based on previous nuke. This nuke only affects the next one.
    -----------------------------------
    return 1 - potency / 10000
end

local function takeBlueSpellDamage(caster, target, spell, damage, attackType, damageType, damageCap)
    if damageCap <= 0 then
        target:takeSpellDamage(caster, spell, damage, attackType, damageType)
        return
    end

    local capVar   = blueWeaponCatalog.DAMAGE_CAP_LOCAL_VAR
    local priorCap = caster:getLocalVar(capVar)
    caster:setLocalVar(capVar, damageCap)

    local ok, err = xpcall(
        function()
            target:takeSpellDamage(caster, spell, damage, attackType, damageType)
        end,
        function(message)
            return debug.traceback(message, 2)
        end)

    local cleanupOk, cleanupErr = pcall(function()
        caster:setLocalVar(capVar, priorCap)
    end)

    if not cleanupOk then
        error(string.format('Blue spell damage cap cleanup failed: %s', cleanupErr), 0)
    end

    if not ok then
        error(err, 0)
    end
end

local function finalizeStockSubjobDamage(caster, target, spell, damage, params, trickAttackTarget)
    damage = math.floor(damage * xi.settings.main.BLUE_POWER)

    local attackType = params.attackType or xi.attackType.NONE
    local damageType = params.damageType or xi.damageType.NONE
    local tpHits = params.tphitslanded or 0
    local extraTPGained =
        xi.combat.tp.calculateTPGainOnMagicalDamage(caster, target, damage) *
        math.max(tpHits - 1, 0)

    if attackType == xi.attackType.MAGICAL then
        local absorb  = xi.spells.damage.calculateAbsorption(target, spell:getElement(), true)
        local nullify = xi.spells.damage.calculateNullification(target, spell:getElement(), true, false)
        damage = math.floor(damage * absorb * nullify)

        if damage < 0 then
            target:takeSpellDamage(caster, spell, damage, attackType, damageType)
            target:addTP(extraTPGained)
            return damage
        end

        damage = utils.handleOneForAll(target, damage)
    end

    damage = utils.handlePhalanx(target, damage)
    damage = utils.handleStoneskin(target, damage)
    damage = levelingHpCap.apply(caster:getMainLvl(), target, damage)
    damage = target:checkDamageCap(damage)

    target:takeSpellDamage(caster, spell, damage, attackType, damageType)
    target:addTP(extraTPGained)

    if not target:isPC() then
        target:updateEnmityFromDamage(trickAttackTarget or caster, damage)
    end

    target:handleAfflatusMiseryDamage(damage)
    return damage
end

local function finalizeBlueDamage(caster, target, spell, damage, params, trickAttackTarget)
    if bluSharedEffects.usesStockSubjobBehavior(caster) then
        return finalizeStockSubjobDamage(caster, target, spell, damage, params, trickAttackTarget)
    end

    damage = math.floor(damage * xi.settings.main.BLUE_POWER)

    local attackType = params.attackType or xi.attackType.NONE
    local damageType = params.damageType or xi.damageType.NONE
    local eligible   = standardMagic.isBlueDamageEligible(caster, target, spell, params)
    local damageCap  = eligible and standardMagic.getDamageCap(caster) or 0

    if attackType == xi.attackType.MAGICAL and not params.absorptionApplied then
        local absorb  = xi.spells.damage.calculateAbsorption(target, spell:getElement(), true)
        local nullify = xi.spells.damage.calculateNullification(target, spell:getElement(), true, false)
        damage = math.floor(damage * absorb * nullify)
        if damage < 0 then
            takeBlueSpellDamage(caster, target, spell, damage, attackType, damageType, damageCap)
            return damage
        end
    end

    if eligible and damage > 0 then
        local weapon  = standardMagic.getDamageMultiplier(caster, target, spell)
        local scaled  = bluSpellPower.getEffectiveWeaponMultiplier(weapon, spell)
        local premium = bluSpellPower.getDamageMultiplier(spell)
        damage = math.floor(damage * scaled * premium)
    end

    if attackType == xi.attackType.MAGICAL then
        damage = utils.handleOneForAll(target, damage)
    end

    damage = utils.handlePhalanx(target, damage)
    damage = utils.handleStoneskin(target, damage)
    damage = math.max(0, math.floor(damage))

    if damageCap > 0 then
        damage = math.min(damage, damageCap)
    end

    damage = math.min(damage, target:getHP())
    damage = levelingHpCap.apply(caster:getMainLvl(), target, damage)
    damage = target:checkDamageCap(damage)

    takeBlueSpellDamage(caster, target, spell, damage, attackType, damageType, damageCap)

    if not params.skipTpGain then
        local tpHits = params.tphitslanded or 0
        local extraTPGained =
            xi.combat.tp.calculateTPGainOnMagicalDamage(caster, target, damage) *
            math.max(tpHits - 1, 0)
        target:addTP(extraTPGained)
    end

    if not params.skipEnmity and not target:isPC() then
        target:updateEnmityFromDamage(trickAttackTarget or caster, damage)
    end

    target:handleAfflatusMiseryDamage(damage)
    return damage
end

-----------------------------------
-- Global functions
-----------------------------------

xi.spells.blue.isMainJob = bluSharedEffects.isMainJob
xi.spells.blue.usesStockSubjobBehavior = bluSharedEffects.usesStockSubjobBehavior
xi.spells.blue.calculateBlueCure = bluSharedEffects.calculateBlueCure
xi.spells.blue.applyBlueCure = bluSharedEffects.applyBlueCure

-- Get the damage for a physical Blue Magic spell
xi.spells.blue.usePhysicalSpell = function(caster, target, spell, params)
    bluSharedEffects.applyStockSubjobParams(caster, spell, params)
    spell:setCritical(false)

    -----------------------
    -- Get final D value --
    -----------------------

    -- Initial D value
    local initialD = math.floor(caster:getSkillLevel(xi.skill.BLUE_MAGIC) * 0.11) * 2 + 3
    initialD       = utils.clamp(initialD, 0, params.duppercap)

    -- fSTR
    local fStr = calculatefSTR(caster:getStat(xi.mod.STR) - target:getStat(xi.mod.VIT))
    if fStr > 22 then
        if params.ignorefstrcap == nil then -- Smite of Rage / Grand Slam don't have this cap applied
            fStr = 22
        end
    end

    -- Multiplier, bonus WSC
    local multiplier = params.multiplier or 1
    local bonusWSC   = 0

    -- BLU AF3 bonus (triples the base WSC when it procs)
    if  math.random(1, 100) <= caster:getMod(xi.mod.AUGMENT_BLU_MAGIC) then
        bonusWSC = 2
    end

    -- Chain Affinity -- TODO: add 'Damage/Accuracy/Critical Hit Chance varies with TP'
    if caster:getStatusEffect(xi.effect.CHAIN_AFFINITY) then
        local tp   = caster:getTP() + caster:getMerit(xi.merit.ENCHAINMENT) -- Total TP available
        tp         = utils.clamp(tp, 0, 3000)
        multiplier = calculatefTP(tp, params.multiplier, params.tp150, params.tp300)
        bonusWSC   = bonusWSC + 1 -- Chain Affinity doubles base WSC
    end

    -- WSC
    local wsc = calculateWSC(caster, params)
    wsc       = wsc + wsc * bonusWSC -- Bonus WSC from AF3/CA

    -- Monster correlation
    local correlationMultiplier = calculateCorrelation(params.ecosystem, target:getEcosystem(), caster:getMerit(xi.merit.MONSTER_CORRELATION))

    -- Azure Lore
    if caster:getStatusEffect(xi.effect.AZURE_LORE) then
        multiplier = params.azuretp
    end

    -- Final D
    local finalD = math.floor(initialD + fStr + wsc)
    -- TODO: Implement ENHANCES_CHAIN_AFFINITY. Increase base damage of spell, but not limited to spell's damage cap
    -- ENHANCES_CHAIN_AFFINITY should also not modify skillchain damage

    ----------------------------------------------
    -- Get the possible pDIF range and hit rate --
    ----------------------------------------------

    if params.offcratiomod == nil then -- For all spells except Cannonball, which uses a DEF mod
        params.offcratiomod = caster:getStat(xi.mod.ATT)
    end

    params.offcratiomod = params.offcratiomod * (caster:getMerit(xi.merit.PHYSICAL_POTENCY) + 100) / 100
    params.bonusacc     = params.bonusacc == nil and 0 or params.bonusacc
    params.tphitslanded = 0

    -- params.critchance will only be non-nil if base critchance is passed from spell lua
    local nativecrit  = xi.combat.physical.calculateSwingCriticalRate(caster, target, 0, xi.slot.MAIN)
    params.critchance = params.critchance == nil and 0 or utils.clamp(params.critchance / 100 + nativecrit, 0.05, 0.95)

    local cratio  = calculatecRatio(params.offcratiomod / target:getStat(xi.mod.DEF), caster:getMainLvl(), target:getMainLvl())
    local hitrate = calculateHitrate(caster, target, params.bonusacc)

    -------------------------
    -- Perform the attacks --
    -------------------------

    local hitsdone          = 0
    local hitslanded        = 0
    local finaldmg          = 0
    local anyCrit           = false
    local sneakIsApplicable = false
    local trickAttackTarget = nil

    if spell:isAoE() == 0 and params.attackType ~= xi.attackType.RANGED then
        if
            caster:hasStatusEffect(xi.effect.SNEAK_ATTACK) and
            (caster:isBehind(target) or caster:hasStatusEffect(xi.effect.HIDE))
        then
            sneakIsApplicable = true
        end

        if caster:hasStatusEffect(xi.effect.TRICK_ATTACK) then
            trickAttackTarget = caster:getTrickAttackChar(target)
        end
    end

    while hitsdone < params.numhits do
        local chance = math.random()

        if
            sneakIsApplicable or
            chance <= hitrate
        then
            -- TODO: Check for shadow absorbs. Right now the whole spell will be absorbed by one shadow before it even gets here.

            -- Generate a random pDIF between min and max
            local pdif = math.random(cratio[1] * 1000, cratio[2] * 1000)
            pdif       = pdif / 1000

            local isCritical = sneakIsApplicable or math.random() < params.critchance
            if isCritical then
                pdif = pdif + 1
            end

            anyCrit = anyCrit or isCritical

            -- Add it to our final damage
            if hitsdone == 0 then
                finaldmg = finaldmg + finalD * (multiplier + correlationMultiplier) * pdif -- first hit gets full multiplier
            else
                finaldmg = finaldmg + finalD * (1 + correlationMultiplier) * pdif
            end

            hitslanded        = hitslanded + 1
            sneakIsApplicable = false

            -- Store number of hits that did > 0 damage
            if finaldmg > 0 then
                params.tphitslanded = params.tphitslanded + 1
            end
        end

        if params.attackType ~= xi.attackType.RANGED then
            caster:delStatusEffect(xi.effect.SNEAK_ATTACK)
            caster:delStatusEffect(xi.effect.TRICK_ATTACK)
        end

        hitsdone = hitsdone + 1
    end

    finaldmg = math.floor(finaldmg * xi.combat.damage.calculateDamageAdjustment(target, true, false, false, false))

    if hitslanded == 0 then
        spell:setMsg(xi.msg.basic.MAGIC_FAIL)
    end

    spell:setCritical(anyCrit)
    return xi.spells.blue.applySpellDamage(caster, target, spell, finaldmg, params, trickAttackTarget)
end

-- Get the damage for a magical Blue Magic spell. Called from spell scripts.
xi.spells.blue.useMagicalSpell = function(caster, target, spell, params)
    bluSharedEffects.applyStockSubjobParams(caster, spell, params)
    -- In individual magical spells, don't use params.effect for the added effect
    -- This would affect the resistance check for damage here
    -- We just want that to affect the resistance check for the added effect
    -- Use params.addedEffect instead

    -- Initial values
    local initialD   = utils.clamp(caster:getMainLvl() + 2, 0, params.duppercap)
    params.skillType = xi.skill.BLUE_MAGIC

    -- WSC
    local wsc           = calculateWSC(caster, params)
    local wscMultiplier = 1

    -- BLU AF3 bonus (triples the base WSC when it procs)
    if math.random(1, 100) <= caster:getMod(xi.mod.AUGMENT_BLU_MAGIC) then
        wscMultiplier = wscMultiplier + 1
    end

    if caster:hasStatusEffect(xi.effect.BURST_AFFINITY) then
        wscMultiplier = wscMultiplier + 1 + caster:getMod(xi.mod.ENHANCES_BURST_AFFINITY) / 100
    end

    wsc = wsc * wscMultiplier -- Bonus WSC from AF3/BA

    -- INT/MND/CHR dmg bonuses
    -- BLU "Blue Magic Effect" job point gift also boosts magical blue magic:
    -- add the attribute-value bonus to the caster's stat in the dStat spread.
    params.diff     = (caster:getStat(params.attribute) + caster:getMod(xi.mod.BLUE_MAGIC_EFFECT)) - target:getStat(params.attribute)
    local statBonus = params.diff * params.tMultiplier

    -- Azure Lore
    local azureBonus = 0
    if caster:getStatusEffect(xi.effect.AZURE_LORE) then
        azureBonus = params.azureBonus or 0
    end

    -- Monster correlation
    local correlationMultiplier = calculateCorrelation(params.ecosystem, target:getEcosystem(), caster:getMerit(xi.merit.MONSTER_CORRELATION))

    -- Data
    local spellId            = spell:getID()
    local spellElement       = spell:getElement()
    local spellGroup         = spell:getSpellGroup()
    local skillType          = xi.skill.BLUE_MAGIC
    local _, skillchainCount = xi.magicburst.formMagicBurst(target, spellElement) -- External function. Not present in magic.lua.
    local standardMacc       = 0
    if standardMagic.isBlueDamageEligible(caster, target, spell, params) then
        standardMacc = -standardMagic.getMagicAccuracyPenalty(caster, target)
    end

    -- Final D value
    local finalDamage    = (initialD + wsc) * (params.multiplier + azureBonus + correlationMultiplier) + statBonus

    finalDamage = math.floor(finalDamage * bluSharedEffects.clampMagicResist(caster, xi.combat.magicHitRate.calculateResistRate(
        caster, target, spellGroup, skillType, 0, spellElement,
        params.attribute, 0, standardMacc)))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateElementalStaffBonus(caster, spellElement))
    finalDamage = math.floor(finalDamage * bluSharedEffects.getElementalDamageFactor(caster, target, spellElement))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateDayAndWeather(caster, spellElement, false))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateMagicBonusDiff(caster, target, spellId, skillType, spellElement, 0))

    if
        caster:hasStatusEffect(xi.effect.BURST_AFFINITY) or
        caster:hasStatusEffect(xi.effect.AZURE_LORE)
    then
        if skillchainCount > 0 then
            finalDamage = math.floor(finalDamage * xi.spells.damage.calculateIfMagicBurst(target, spellElement, skillchainCount))
            finalDamage = math.floor(finalDamage * xi.spells.damage.calculateIfMagicBurstBonus(caster, target, spellId, skillType, spellElement))

            spell:setMsg(spell:getMagicBurstMessage()) -- "Magic Burst!"

            caster:triggerRoeEvent(xi.roeTrigger.MAGIC_BURST)
        end

        caster:delStatusEffectSilent(xi.effect.BURST_AFFINITY)
    end

    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateEbullienceMultiplier(caster, spellGroup))

    -- The stock pipeline applied BLUE_POWER here and again in applySpellDamage.
    -- Preserve that legacy contract for /BLU even if the setting changes from 1.
    if bluSharedEffects.usesStockSubjobBehavior(caster) then
        finalDamage = math.floor(finalDamage * xi.settings.main.BLUE_POWER)
    end

    return xi.spells.blue.applySpellDamage(caster, target, spell, finalDamage, params, nil)
end

-- Spell script Helper function.
xi.spells.blue.useDrainSpell = function(caster, target, spell, params, damageCap, mpDrain)
    bluSharedEffects.applyStockSubjobParams(caster, spell, params)
    damageCap = bluSharedEffects.getDrainCap(caster, spell, damageCap)
    local finalDamage = 0

    -- Early returns
    if
        xi.spells.damage.calculateAbsorption(target, spell:getElement(), true) ~= 1 or
        xi.spells.damage.calculateNullification(target, spell:getElement(), true, false) ~= 1 or
        target:isUndead()
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)

        return 0
    end

    -- Base damage. HP-drain spell contracts fold their relevant caster stat
    -- scaling into dmgMultiplier; MP Drainkiss deliberately keeps its utility
    -- contract on this same unmodified path.
    finalDamage = bluSharedEffects.calculateDrainBase(caster, params)
    if damageCap > 0 then
        finalDamage = utils.clamp(finalDamage, 0, damageCap)
    end

    -- Data
    local spellId            = spell:getID()
    local spellElement       = spell:getElement()
    local spellGroup         = spell:getSpellGroup()
    local skillType          = xi.skill.BLUE_MAGIC
    local _, skillchainCount = xi.magicburst.formMagicBurst(target, spellElement) -- External function. Not present in magic.lua.

    finalDamage = math.floor(finalDamage * bluSharedEffects.clampMagicResist(caster, xi.combat.magicHitRate.calculateResistRate(caster, target, spellGroup, skillType, 0, spellElement, params.attribute, 0, 0)))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateElementalStaffBonus(caster, spellElement))
    finalDamage = math.floor(finalDamage * bluSharedEffects.getElementalDamageFactor(caster, target, spellElement))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateDayAndWeather(caster, spellElement, false))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateMagicBonusDiff(caster, target, spellId, skillType, spellElement, 0))

    if
        caster:hasStatusEffect(xi.effect.BURST_AFFINITY) or
        caster:hasStatusEffect(xi.effect.AZURE_LORE)
    then
        if skillchainCount > 0 then
            finalDamage = math.floor(finalDamage * xi.spells.damage.calculateIfMagicBurst(target, spellElement, skillchainCount))
            finalDamage = math.floor(finalDamage * xi.spells.damage.calculateIfMagicBurstBonus(caster, target, spellId, skillType, spellElement))

            spell:setMsg(spell:getMagicBurstMessage()) -- "Magic Burst!"

            caster:triggerRoeEvent(xi.roeTrigger.MAGIC_BURST)
        end

        caster:delStatusEffectSilent(xi.effect.BURST_AFFINITY)
    end

    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateEbullienceMultiplier(caster, spellGroup))
    finalDamage = math.floor(finalDamage * xi.combat.damage.calculateDamageAdjustment(target, false, true, false, false))

    local stockSubjob = bluSharedEffects.usesStockSubjobBehavior(caster)
    if stockSubjob then
        finalDamage = math.floor(finalDamage * xi.settings.main.BLUE_POWER)
    end

    -- MP drain
    if mpDrain then
        finalDamage = utils.clamp(finalDamage, 0, target:getMP())

        target:delMP(finalDamage)
        caster:addMP(finalDamage)

        return finalDamage
    end

    if stockSubjob then
        finalDamage = utils.clamp(utils.handlePhalanx(target, finalDamage), 0, 131071)
        finalDamage = utils.clamp(utils.handleOneForAll(target, finalDamage), 0, 131071)
        finalDamage = utils.clamp(utils.handleStoneskin(target, finalDamage), -131071, 131071)
        finalDamage = utils.clamp(finalDamage, 0, target:getHP())
        finalDamage = levelingHpCap.apply(caster:getMainLvl(), target, finalDamage)
        finalDamage = target:checkDamageCap(finalDamage)

        target:takeSpellDamage(
            caster, spell, finalDamage, xi.attackType.MAGICAL,
            xi.damageType.ELEMENTAL + spell:getElement())
        if not target:isPC() then
            target:updateEnmityFromDamage(caster, finalDamage)
        end

        target:handleAfflatusMiseryDamage(finalDamage)
        caster:addHP(finalDamage)
        return finalDamage
    end

    params.attackType        = xi.attackType.MAGICAL
    params.damageType        = xi.damageType.ELEMENTAL + spell:getElement()
    params.absorptionApplied = true
    params.skipTpGain        = true
    finalDamage = finalizeBlueDamage(caster, target, spell, finalDamage, params, nil)
    caster:addHP(finalDamage)

    return finalDamage
end

-- Breath-type blue magic spells.
xi.spells.blue.useBreathSpell = function(caster, target, spell, params)
    bluSharedEffects.applyStockSubjobParams(caster, spell, params)
    -- Early return.
    if
        params.isConal and               -- Conal breath spells
        not target:isInfront(caster, 32) -- Conal check (45° cone)
    then
        return 0
    end

    -- Initial damage
    local dmg = bluSharedEffects.calculateBreathBase(caster, params)

    -- Parameters
    local spellId      = spell:getID() or 0
    local spellFamily  = spell:getSpellFamily() or 0
    local spellElement = spell:getElement() or 0
    local attackType   = params.attackType or xi.attackType.NONE
    local damageType   = params.damageType or xi.damageType.NONE

    -- Multipliers
    local correlationMultiplier       = 1 + calculateCorrelation(params.ecosystem, target:getEcosystem(), caster:getMerit(xi.merit.MONSTER_CORRELATION))
    local breathSDT                   = 1 + caster:getMod(xi.mod.BREATH_DMG_DEALT) / 100
    local absorb                      = xi.spells.damage.calculateAbsorption(target, spellElement, false)
    local nullify                     = xi.spells.damage.calculateNullification(target, spellElement, false, true)
    local targetMagicDamageAdjustment = xi.combat.damage.calculateDamageAdjustment(target, false, false, false, true)
    local elementalStaffBonus         = xi.spells.damage.calculateElementalStaffBonus(caster, spellElement)
    local elementalAffinityBonus      = xi.spells.damage.calculateElementalAffinityBonus(caster, spellElement)
    local resistTier                  = bluSharedEffects.clampMagicResist(caster, xi.combat.magicHitRate.calculateResistRate(caster, target, spellFamily, xi.skill.BLUE_MAGIC, 0, spellElement, 0, 0, 0))
    local additionalResistTier        = xi.spells.damage.calculateAdditionalResistTier(caster, target, spellElement)
    local elementalSDT                = xi.combat.damage.magicalElementSDT(target, spellElement)
    local dayAndWeather               = xi.spells.damage.calculateDayAndWeather(caster, spellElement, false)
    local magicBonusDiff              = xi.spells.damage.calculateMagicBonusDiff(caster, target, spellId, xi.skill.BLUE_MAGIC, spellElement, 0)
    local skillTypeMultiplier         = xi.spells.damage.calculateSkillTypeMultiplier(xi.skill.BLUE_MAGIC)
    local ninFutaeBonus               = xi.spells.damage.calculateNinFutaeBonus(caster, xi.skill.BLUE_MAGIC)
    local ninjutsuMultiplier          = xi.spells.damage.calculateNinjutsuMultiplier(caster, target, xi.skill.BLUE_MAGIC)
    local scarletDeliriumMultiplier   = xi.combat.damage.scarletDeliriumMultiplier(caster)
    local areaOfEffectResistance      = xi.spells.damage.calculateAreaOfEffectResistance(target, spell)

    dmg = math.floor(dmg * correlationMultiplier)
    dmg = math.floor(dmg * breathSDT)
    dmg = math.floor(dmg * absorb)
    dmg = math.floor(dmg * nullify)
    dmg = math.floor(dmg * targetMagicDamageAdjustment)
    dmg = math.floor(dmg * elementalStaffBonus)
    dmg = math.floor(dmg * elementalAffinityBonus)
    dmg = math.floor(dmg * resistTier)
    if not bluSharedEffects.usesUnresistedMagic(caster) then
        dmg = math.floor(dmg * additionalResistTier)
    end
    dmg = math.floor(dmg * bluSharedEffects.getElementalDamageFactor(caster, target, spellElement, elementalSDT))
    dmg = math.floor(dmg * dayAndWeather)
    dmg = math.floor(dmg * magicBonusDiff)
    dmg = math.floor(dmg * skillTypeMultiplier)
    dmg = math.floor(dmg * ninFutaeBonus)
    dmg = math.floor(dmg * ninjutsuMultiplier)
    dmg = math.floor(dmg * scarletDeliriumMultiplier)
    dmg = math.floor(dmg * areaOfEffectResistance)
    if not bluSharedEffects.usesUnresistedMagic(caster) then
        dmg = math.floor(dmg * calculateNukeWallFactor(target, spellElement, dmg))
    end

    -- Handle Magic Absorb message and HP recovery.
    if dmg < 0 then
        dmg = target:addHP(-dmg)
        spell:setMsg(xi.msg.basic.MAGIC_RECOVERS_HP)

        return dmg
    end

    dmg = math.floor(target:handleSevereDamage(dmg, false))

    if bluSharedEffects.usesStockSubjobBehavior(caster) then
        if dmg > 0 then
            dmg = utils.clamp(utils.handlePhalanx(target, dmg), 0, 131071)
            dmg = utils.clamp(utils.handleOneForAll(target, dmg), 0, 131071)
            dmg = utils.clamp(utils.handleStoneskin(target, dmg), -131071, 131071)
            dmg = utils.clamp(dmg, 0, target:getHP())
            dmg = levelingHpCap.apply(caster:getMainLvl(), target, dmg)
            dmg = target:checkDamageCap(dmg)
        end

        target:takeSpellDamage(caster, spell, dmg, attackType, damageType)
        local tpHits = params.tphitslanded or 0
        local extraTPGained =
            xi.combat.tp.calculateTPGainOnMagicalDamage(caster, target, dmg) *
            math.max(tpHits - 1, 0)
        target:addTP(extraTPGained)
        target:handleAfflatusMiseryDamage(dmg)
        target:updateEnmityFromDamage(caster, dmg)
        return dmg
    end

    params.attackType        = attackType
    params.damageType        = damageType
    params.absorptionApplied = true
    return finalizeBlueDamage(caster, target, spell, dmg, params, nil)
end

-- Apply spell damage
xi.spells.blue.applySpellDamage = function(caster, target, spell, dmg, params, trickAttackTarget)
    return finalizeBlueDamage(caster, target, spell, dmg, params, trickAttackTarget)
end

-- Get the duration of an enhancing Blue Magic spell
xi.spells.blue.calculateDurationWithDiffusion = function(caster, duration)
    if caster:hasStatusEffect(xi.effect.DIFFUSION) then
        local merits = caster:getMerit(xi.merit.DIFFUSION)

        if merits > 0 then
            duration = bluSharedEffects.calculateDiffusionDuration(duration, merits)
        end

        caster:delStatusEffect(xi.effect.DIFFUSION)
    end

    return duration
end

-- Perform an enfeebling Blue Magic spell
xi.spells.blue.useEnfeeblingSpell = function(caster, target, spell, params)
    bluSharedEffects.applyStockSubjobParams(caster, spell, params)
    local spellElement = spell:getElement()
    local effect       = params.effect
    local tier         = params.tier or 0
    local controlAllowed
    local controlDuration
    local controlLockout
    local controlReason
    local fixedControlDuration

    -- Early return: Out of cone.
    if
        params.isConal and
        not target:isInfront(caster, 32)
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return effect
    end

    -- Early return: Out of gaze.
    if
        params.isGaze and
        (not target:isFacing(caster) or not caster:isFacing(target))
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return effect
    end

    controlAllowed, controlDuration, controlLockout, controlReason, fixedControlDuration =
        bluSharedEffects.preparePlayerControl(caster, target, effect, params.duration, GetSystemTime())
    if not controlAllowed then
        local resultMessage =
            controlReason == 'nm_doom' and xi.msg.basic.MAGIC_COMPLETE_RESIST or xi.msg.basic.MAGIC_NO_EFFECT
        spell:setMsg(resultMessage)
        return effect
    end

    -- Early return: Target is immune.
    if xi.data.statusEffect.isTargetImmune(target, effect, spellElement) then
        spell:setMsg(xi.msg.basic.MAGIC_COMPLETE_RESIST)
        return effect
    end

    -- Early return: Trait nullification trigger.
    if
        not bluSharedEffects.usesUnresistedMagic(caster) and
        xi.data.statusEffect.isTargetResistant(caster, target, effect)
    then
        spell:setModifier(xi.msg.actionModifier.RESIST)
        spell:setMsg(xi.msg.basic.MAGIC_RESIST)
        return effect
    end

    -- Early return: Target already has an status effect that nullifies current.
    if xi.data.statusEffect.isEffectNullified(target, effect, tier) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return effect
    end

    -- Early return: Regular resist.
    local stockSubjob = bluSharedEffects.usesStockSubjobBehavior(caster)
    local resist = bluSharedEffects.clampMagicResist(caster, xi.combat.magicHitRate.calculateResistRate(
        caster, target, 0, xi.skill.BLUE_MAGIC, 0, spellElement,
        stockSubjob and xi.mod.INT or params.attribute or xi.mod.INT,
        stockSubjob and 0 or effect, 0))
    if resist < params.resistThreshold then
        spell:setMsg(xi.msg.basic.MAGIC_RESIST)
        return effect
    end

    local effectDuration = fixedControlDuration and controlDuration or math.floor(controlDuration * resist)
    local effectParams =
    {
        power    = params.power,
        duration = effectDuration,
        origin   = caster,
        tick     = params.tick,
    }

    if target:addStatusEffect(effect, effectParams) then
        bluSharedEffects.commitPlayerControl(target, effect, effectDuration, controlLockout, GetSystemTime())

        -- Add "Magic Burst!" message
        local _, skillchainCount = xi.magicburst.formMagicBurst(target, spellElement) -- External function. Not present in magic.lua.

        if skillchainCount > 0 then
            spell:setMsg(xi.msg.basic.MAGIC_BURST_ENFEEB_IS)
            caster:triggerRoeEvent(xi.roeTrigger.MAGIC_BURST)
        else
            spell:setMsg(xi.msg.basic.MAGIC_ENFEEB_IS)
        end
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return effect
end

-- Perform a curative Blue Magic spell
xi.spells.blue.useCuringSpell = function(caster, target, spell, params)
    local power    = getCurePowerOld(caster)
    local divisor  = params.divisor0
    local constant = params.constant0

    if power > params.powerThreshold2 then
        divisor  = params.divisor2
        constant = params.constant2
    elseif power > params.powerThreshold1 then
        divisor  = params.divisor1
        constant = params.constant1
    end

    local final = getCureFinal(caster, spell, getBaseCureOld(power, divisor, constant), params.minCure, true)
    final       = final + final * target:getMod(xi.mod.CURE_POTENCY_RCVD) / 100
    final       = final * xi.settings.main.CURE_POWER
    final       = utils.clamp(final, 0, target:getMaxHP() - target:getHP())

    target:addHP(final)
    target:wakeUp()
    caster:updateEnmityFromCure(target, final)

    if target:getID() == spell:getPrimaryTargetID() then
        spell:setMsg(xi.msg.basic.MAGIC_RECOVERS_HP)
    else
        spell:setMsg(xi.msg.basic.SELF_HEAL_SECONDARY)
    end

    return final
end

xi.spells.blue.applyBlueAdditionalEffect = function(caster, target, params, effectTable)
    -- Sanitize parameters.
    local element = params.damageType and params.damageType - 5 or 0
    local stat    = params.attribute and params.attribute or xi.mod.INT
    if params.attackType == xi.attackType.BREATH then
        stat = 0
    end

    local stockSubjob = bluSharedEffects.usesStockSubjobBehavior(caster)
    local stockResist = 0
    if stockSubjob then
        -- Pre-retune additional effects shared one general BLU resistance roll.
        stockResist = xi.combat.magicHitRate.calculateResistRate(
            caster, target, 0, xi.skill.BLUE_MAGIC, 0, element, stat, 0, 0)
    end

    for entry = 1, #effectTable do
        local effect   = effectTable[entry][1]
        local power    = effectTable[entry][2]
        local tick     = effectTable[entry][3]
        local duration = effectTable[entry][4]
        local controlAllowed, controlDuration, controlLockout, _, fixedControlDuration =
            bluSharedEffects.preparePlayerControl(caster, target, effect, duration, GetSystemTime())
        local resist = stockResist
        if controlAllowed and not stockSubjob then
            resist = bluSharedEffects.clampMagicResist(caster, xi.combat.magicHitRate.calculateResistRate(
                caster, target, 0, xi.skill.BLUE_MAGIC, 0, element, stat, effect, 0))
        end

        if
            controlAllowed and
            resist > 0.25 and
            not xi.data.statusEffect.isTargetImmune(target, effect, element) and
            (
                bluSharedEffects.usesUnresistedMagic(caster) or
                not xi.data.statusEffect.isTargetResistant(caster, target, effect)
            ) and
            not xi.data.statusEffect.isEffectNullified(target, effect, 0)
        then
            local effectDuration = fixedControlDuration and controlDuration or math.floor(controlDuration * resist)
            local effectParams =
            {
                power    = power,
                duration = effectDuration,
                origin   = caster,
                tick     = tick,
            }

            if target:addStatusEffect(effect, effectParams) then
                bluSharedEffects.commitPlayerControl(target, effect, effectDuration, controlLockout, GetSystemTime())
            end
        end
    end
end

--[[
+-------+
| NOTES |
+-------+
- Spell values (multiplier, TP, D, WSC, TP etc) from:
    - https://www.bg-wiki.com/ffxi/Calculating_Blue_Magic_Damage
    - https://ffxiclopedia.fandom.com/wiki/Calculating_Blue_Magic_Damage
    - BG-wiki spell pages
    - Blue Gartr threads with data, such as
        https://www.bluegartr.com/threads/37619-Blue-Mage-Best-thread-ever?p=5832112&viewfull=1#post5832112
        https://www.bluegartr.com/threads/37619-Blue-Mage-Best-thread-ever?p=5437135&viewfull=1#post5437135
        https://www.bluegartr.com/threads/107650-Random-Question-Thread-XXIV-Occupy-the-RQT?p=4906565&viewfull=1#post4906565
    - When values were absent, spell values were decided based on Blue Gartr threads and Wiki page discussions.
    - Assumed INT as the main magic accuracy modifier for physical spells' additional effects (when no data was found).
]]--
