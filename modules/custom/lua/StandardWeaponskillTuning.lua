-----------------------------------
-- Level-scaled baseline tuning for ordinary player weaponskills.
--
-- Final REMA and Prime native WS stay on this curve unless their private
-- modules have already marked the swing tuned (they then zero the multiplier
-- and raise the cap). That keeps Catastrophe from falling below Entropy on
-- the same Apocalypse when the Relic wrapper does not apply. Final Ambuscade
-- weapons keep this progression multiplier on every WS, with Ambuscade's own
-- module supplying the 99,999 / linked-149,999 ceilings and linked 10% boost.
-- Odyssey 119s stay on this curve with a 349,999 single-target ceiling.
-- Splash matches finished REMA at 149,999.
-- Finished REMA native WS stay on their private wrapper. Other WS on those
-- sticks keep this curve and a 500,000 single-target ceiling. Splash uses
-- the shared 40k / 80k / 99k / 149k / 199k ladder (149,999 on finished REMA).
-- Prime is unchanged.
-----------------------------------
require('modules/module_utils')

local catalog     = require('modules/custom/lua/standard_ws_tuning_catalog')
local ambuCatalog = require('modules/custom/lua/ambuscade_ws_tuning_catalog')

xi.standardWsTuning         = xi.standardWsTuning or {}
xi.standardWsTuning.catalog = catalog

if xi.standardWsTuning.moduleInstalled then
    return Module:new('standard_weaponskill_tuning_reload_guard')
end

local m = Module:new('standard_weaponskill_tuning')

local function pack(...)
    return { n = select('#', ...), ... }
end

local activeCalculations = setmetatable({}, { __mode = 'k' })

-- Splash-only. C++ stamps AoEWsDamageCap on non-primary hits; the aimed-at
-- target keeps the single-target ceiling. Use the same ladder as magic -ga
-- and pet splash so off-native REMA cannot inherit the 500,000 ST cap.
local function getPremiumAoECap(attacker)
    if attacker:getLocalVar('AoEWsDamageCap') <= 0 then
        return 0
    end

    return catalog.getPlayerSplashDamageCap(attacker)
end

xi.standardWsTuning.isEligible = function(attacker, target, wsId, slot, wsParams)
    -- Native REMA/Prime pairs used to skip this curve and rely on their
    -- private fTP wrappers. If that wrapper does not run, Catastrophe (etc.)
    -- does vanilla 2.75 fTP while Entropy on the same Apocalypse still gets
    -- 13x and hits 99,999. Keep the ordinary curve unless those wrappers have
    -- already marked the swing as tuned; they then zero the multiplier.
    return
        attacker ~= nil and
        target ~= nil and
        attacker:isPC() and
        target:isMob() and
        not (wsParams and wsParams.isJump) and
        attacker:getLocalVar('RemaWsTuned') == 0 and
        attacker:getLocalVar('PrimeWsTuned') == 0
end

xi.standardWsTuning.withStandardEffects = function(
    attacker, target, wsId, slot, wsParams, magicAccuracy, callback)
    if
        not xi.standardWsTuning.isEligible(attacker, target, wsId, slot, wsParams) or
        activeCalculations[attacker]
    then
        return callback()
    end

    local multiplierVar  = catalog.DAMAGE_MULTIPLIER_LOCAL_VAR
    local capVar         = catalog.DAMAGE_CAP_LOCAL_VAR
    local accuracyMod    = magicAccuracy and xi.mod.MACC or xi.mod.WSACC
    local priorMultiplier = attacker:getLocalVar(multiplierVar)
    local priorCap       = attacker:getLocalVar(capVar)
    local priorAoECap    = attacker:getLocalVar('AoEWsDamageCap')
    local priorAcc       = attacker:getMod(accuracyMod)
    local penalty        = catalog.getAccuracyPenalty(
        attacker:getMainLvl(), target:getMainLvl())
    local multiplier     = catalog.getWeaponskillMultiplier(attacker, target, slot)
    local damageCap      = catalog.getWeaponskillCap(attacker, slot)
    -- Odyssey 119s: ordinary JP curve, 349,999 single-target cap, no Ambu
    -- floor/boost. Splash is raised later via getPlayerSplashDamageCap
    -- (149,999, same as finished REMA).
    if catalog.isOdysseyWeapon(attacker:getEquipID(slot)) then
        damageCap = catalog.ODYSSEY_DAMAGE_CAP
    end

    -- Final Ambuscade weapons use a 99,999 ceiling on every WS. The linked
    -- native WS may later break that soft ceiling via Ambuscade's 10% boost.
    if
        not catalog.isOdysseyWeapon(attacker:getEquipID(slot)) and
        ambuCatalog.isFinalWeapon(attacker:getEquipID(slot), slot)
    then
        damageCap = math.max(damageCap, ambuCatalog.DAMAGE_CAP)
    end

    -- Pre-119 III REMA matches Ambuscade (99,999). The native WS is 149,999
    -- until the weapon is finished. Finished Relic / Empy / Mythic / Aeonic
    -- keep their private native wrapper; every other single-target WS on that
    -- stick can climb to 500,000. Splash stays on getPlayerSplashDamageCap.
    local remaInfo = catalog.getRemaPathInfo(attacker:getEquipID(slot))
    if remaInfo then
        if not remaInfo.final then
            if remaInfo.wsId == wsId and remaInfo.slot == slot then
                damageCap = math.max(damageCap, catalog.REMA_PRE_III_NATIVE_WS_CAP)
            else
                damageCap = math.max(damageCap, catalog.REMA_PRE_III_DAMAGE_CAP)
            end
        else
            damageCap = math.max(damageCap, catalog.REMA_OFF_NATIVE_DAMAGE_CAP)
            damageCap = catalog.getPlayerRemaDamageCap(attacker, damageCap)
        end
    end

    local premiumAoECap  = getPremiumAoECap(attacker)
    if premiumAoECap > 0 then
        if premiumAoECap > damageCap then
            damageCap = premiumAoECap
        end
        if premiumAoECap > attacker:getLocalVar('AoEWsDamageCap') then
            attacker:setLocalVar('AoEWsDamageCap', premiumAoECap)
        end
    end

    attacker:setLocalVar(multiplierVar, math.floor(multiplier * 1000 + 0.5))
    attacker:setLocalVar(capVar, damageCap)
    if penalty > 0 then
        attacker:addMod(accuracyMod, -penalty)
    end
    activeCalculations[attacker] = true

    local results
    local ok, err = xpcall(
        function()
            results = pack(callback())
        end,
        function(message)
            return debug.traceback(message, 2)
        end)

    local cleanupOk, cleanupErr = pcall(function()
        attacker:setLocalVar(multiplierVar, priorMultiplier)
        attacker:setLocalVar(capVar, priorCap)
        attacker:setLocalVar('AoEWsDamageCap', priorAoECap)
        attacker:setMod(accuracyMod, priorAcc)
    end)
    activeCalculations[attacker] = nil

    if not cleanupOk then
        error(string.format('Standard WS modifier cleanup failed: %s', cleanupErr), 0)
    end

    if not ok then
        error(err, 0)
    end

    return unpack(results, 1, results.n)
end

local function callPreservedOriginal(
    attacker, target, wsId, slot, wsParams, magicAccuracy, original, ...)
    local args = pack(...)
    return xi.standardWsTuning.withStandardEffects(
        attacker, target, wsId, slot, wsParams, magicAccuracy,
        function()
            return original(unpack(args, 1, args.n))
        end)
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
        local original = super
        local tuned = catalog.applyOdysseyFtp(attacker, xi.slot.MAIN, wsParams)
        return callPreservedOriginal(
            attacker, target, wsId, xi.slot.MAIN, tuned, false, original,
            attacker, target, wsId, tuned, tp, action, primaryMsg, taChar)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        local tuned = catalog.applyOdysseyFtp(attacker, xi.slot.RANGED, wsParams)
        return callPreservedOriginal(
            attacker, target, wsId, xi.slot.RANGED, tuned, false, original,
            attacker, target, wsId, tuned, tp, action, primaryMsg)
    end)

m:addOverride('xi.weaponskills.doMagicWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        local slot = xi.slot.MAIN
        if
            wsParams.skill == xi.skill.ARCHERY or
            wsParams.skill == xi.skill.MARKSMANSHIP
        then
            slot = xi.slot.RANGED
        end

        local tuned = catalog.applyOdysseyFtp(attacker, slot, wsParams)
        return callPreservedOriginal(
            attacker, target, wsId, slot, tuned, true, original,
            attacker, target, wsId, tuned, tp, action, primaryMsg)
    end)

xi.standardWsTuning.moduleInstalled = true

return m
