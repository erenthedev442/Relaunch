-----------------------------------
-- Final Ambuscade weapon weaponskill tuning
--
-- Final Ambuscade weapons raise every weaponskill to a 99,999 soft ceiling.
-- The weapon's linked native WS then receives a 10% boost that may break that
-- ceiling, and is hard-capped at 149,999.
-----------------------------------
require('modules/module_utils')

local catalog = require('modules/custom/lua/ambuscade_ws_tuning_catalog')

xi.ambuscadeWsTuning         = xi.ambuscadeWsTuning or {}
xi.ambuscadeWsTuning.catalog = catalog

if xi.ambuscadeWsTuning.moduleInstalled then
    return Module:new('ambuscade_weaponskill_tuning_reload_guard')
end

local m = Module:new('ambuscade_weaponskill_tuning')

local function pack(...)
    return { n = select('#', ...), ... }
end

local activeCalculations = setmetatable({}, { __mode = 'k' })

local function getSkillchainCount(target)
    local effect = target and target:getStatusEffect(xi.effect.SKILLCHAIN)
    return effect and effect:getSubPower() or 0
end

local function getDolichenusMultiplier(attacker, target, slot)
    if
        slot ~= xi.slot.MAIN or
        attacker:getEquipID(xi.slot.MAIN) ~= catalog.ITEM.DOLICHENUS
    then
        return 100
    end

    return 100 + 3 * getSkillchainCount(target)
end

xi.ambuscadeWsTuning.getEntry = function(attacker, wsId, slot)
    if
        not attacker or
        not attacker:isPC() or
        (slot ~= xi.slot.MAIN and slot ~= xi.slot.RANGED)
    then
        return nil
    end

    return catalog.getEntry(attacker:getEquipID(slot), wsId, slot)
end

xi.ambuscadeWsTuning.withAmbuscadeEffects = function(attacker, target, wsId, slot, callback)
    if
        not attacker or
        not attacker:isPC() or
        (slot ~= xi.slot.MAIN and slot ~= xi.slot.RANGED) or
        activeCalculations[attacker]
    then
        return callback()
    end

    local itemId = attacker:getEquipID(slot)
    local finalWeapon = catalog.getFinalWeapon(itemId, slot)
    local linkedEntry = catalog.getEntry(itemId, wsId, slot)
    local dolichenusMultiplier = getDolichenusMultiplier(attacker, target, slot)
    if not finalWeapon and dolichenusMultiplier == 100 then
        return callback()
    end

    local priorCap       = attacker:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR)
    local priorBaseCap   = attacker:getLocalVar(catalog.BASE_DAMAGE_CAP_LOCAL_VAR)
    local priorMult      = attacker:getLocalVar(catalog.DAMAGE_MULT_LOCAL_VAR)
    local priorAoECap    = attacker:getLocalVar('AoEWsDamageCap')
    local priorStandard  = attacker:getLocalVar('StandardWsDamageCap')

    -- Soft ceiling for every WS on a final Ambuscade weapon. Linked WSs apply
    -- their 10% boost after this value in takeWeaponskillDamage.
    if finalWeapon then
        attacker:setLocalVar(catalog.BASE_DAMAGE_CAP_LOCAL_VAR, catalog.DAMAGE_CAP)
    end

    if linkedEntry then
        attacker:setLocalVar(
            catalog.DAMAGE_MULT_LOCAL_VAR,
            math.floor(catalog.DAMAGE_MULTIPLIER * dolichenusMultiplier / 100))
        attacker:setLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR, catalog.LINKED_DAMAGE_CAP)
        -- Raise the synchronous Standard/AoE ceilings so C++ HP delivery does
        -- not clip the post-boost linked WS back to 99,999.
        attacker:setLocalVar('StandardWsDamageCap', catalog.LINKED_DAMAGE_CAP)
        if priorAoECap > 0 then
            attacker:setLocalVar('AoEWsDamageCap', catalog.LINKED_AOE_DAMAGE_CAP)
        end
    else
        if dolichenusMultiplier ~= 100 then
            attacker:setLocalVar(catalog.DAMAGE_MULT_LOCAL_VAR, dolichenusMultiplier)
        end

        if finalWeapon then
            attacker:setLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR, catalog.DAMAGE_CAP)
            attacker:setLocalVar('StandardWsDamageCap', catalog.DAMAGE_CAP)
            if priorAoECap > 0 then
                attacker:setLocalVar('AoEWsDamageCap', catalog.AOE_DAMAGE_CAP)
            end
        end
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
        attacker:setLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR, priorCap)
        attacker:setLocalVar(catalog.BASE_DAMAGE_CAP_LOCAL_VAR, priorBaseCap)
        attacker:setLocalVar(catalog.DAMAGE_MULT_LOCAL_VAR, priorMult)
        attacker:setLocalVar('AoEWsDamageCap', priorAoECap)
        attacker:setLocalVar('StandardWsDamageCap', priorStandard)
    end)
    activeCalculations[attacker] = nil

    if not cleanupOk then
        error(string.format('Ambuscade WS effect cleanup failed: %s', cleanupErr), 0)
    end

    if not ok then
        error(err, 0)
    end

    return unpack(results, 1, results.n)
end

local function callPreservedOriginal(attacker, target, wsId, slot, original, ...)
    local args = pack(...)
    return xi.ambuscadeWsTuning.withAmbuscadeEffects(attacker, target, wsId, slot, function()
        return original(unpack(args, 1, args.n))
    end)
end

local function countEffects(entity, predicate)
    local count = 0
    for _, effect in pairs(entity:getStatusEffects()) do
        if predicate(effect:getEffectFlags()) then
            count = count + 1
        end
    end

    return count
end

local function withPhysicalWeaponTraits(attacker, target, tp, wsParams, callback)
    local itemId = attacker:getEquipID(xi.slot.MAIN)
    local attPercent = 0
    local critRate   = 0
    local params     = wsParams

    if itemId == catalog.ITEM.NAEGLING then
        attPercent = countEffects(attacker, function(flags)
            return bit.band(flags, bit.bor(xi.effectFlag.ERASABLE, xi.effectFlag.WALTZABLE)) == 0
        end)
    elseif itemId == catalog.ITEM.NANDAKA then
        local downgradeCount = countEffects(target, function(flags)
            return bit.band(flags, bit.bor(xi.effectFlag.ERASABLE, xi.effectFlag.WALTZABLE)) ~= 0
        end)
        local ignoredDefense = math.min(downgradeCount, 100) / 100
        params = {}
        for key, value in pairs(wsParams) do
            params[key] = value
        end

        params.ignoredDefense = { ignoredDefense, ignoredDefense, ignoredDefense }
    elseif itemId == catalog.ITEM.SHINING_ONE then
        critRate = math.min(15, math.floor(tp / 200))
        params = {}
        for key, value in pairs(wsParams) do
            params[key] = value
        end

        -- Shining One allows every polearm WS to crit, including WSs which
        -- normally have no "critical hit rate varies with TP" table.
        params.critVaries = params.critVaries or { 0, 0, 0 }
    end

    if attPercent > 0 then
        attacker:addMod(xi.mod.ATTP, attPercent)
    end

    if critRate > 0 then
        attacker:addMod(xi.mod.CRITHITRATE, critRate)
    end

    local results
    local ok, err = xpcall(
        function()
            results = pack(callback(params))
        end,
        function(message)
            return debug.traceback(message, 2)
        end)

    if critRate > 0 then
        attacker:delMod(xi.mod.CRITHITRATE, critRate)
    end

    if attPercent > 0 then
        attacker:delMod(xi.mod.ATTP, attPercent)
    end

    if not ok then
        error(err, 0)
    end

    return unpack(results, 1, results.n)
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
        local original = super
        return withPhysicalWeaponTraits(attacker, target, tp, wsParams, function(effectiveParams)
            return callPreservedOriginal(
                attacker, target, wsId, xi.slot.MAIN, original,
                attacker, target, wsId, effectiveParams, tp, action, primaryMsg, taChar)
        end)
    end)

m:addOverride('xi.weaponskills.doMagicWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        return callPreservedOriginal(
            attacker, target, wsId, xi.slot.MAIN, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        return callPreservedOriginal(
            attacker, target, wsId, xi.slot.RANGED, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg)
    end)

xi.ambuscadeWsTuning.moduleInstalled = true

return m
