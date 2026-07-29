-----------------------------------
-- Final Ambuscade weapon linked-WS tuning
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

xi.ambuscadeWsTuning.withAmbuscadeEffects = function(attacker, wsId, slot, callback)
    local entry = xi.ambuscadeWsTuning.getEntry(attacker, wsId, slot)
    if not entry or activeCalculations[attacker] then
        return callback()
    end

    local priorCap    = attacker:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR)
    local priorMult   = attacker:getLocalVar(catalog.DAMAGE_MULT_LOCAL_VAR)
    local priorAoECap = attacker:getLocalVar('AoEWsDamageCap')
    attacker:setLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR, catalog.DAMAGE_CAP)
    attacker:setLocalVar(catalog.DAMAGE_MULT_LOCAL_VAR, catalog.DAMAGE_MULTIPLIER)
    if priorAoECap > 0 then
        attacker:setLocalVar('AoEWsDamageCap', catalog.AOE_DAMAGE_CAP)
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
        attacker:setLocalVar(catalog.DAMAGE_MULT_LOCAL_VAR, priorMult)
        attacker:setLocalVar('AoEWsDamageCap', priorAoECap)
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

local function callPreservedOriginal(attacker, wsId, slot, original, ...)
    local args = pack(...)
    return xi.ambuscadeWsTuning.withAmbuscadeEffects(attacker, wsId, slot, function()
        return original(unpack(args, 1, args.n))
    end)
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
        local original = super
        return callPreservedOriginal(
            attacker, wsId, xi.slot.MAIN, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
    end)

m:addOverride('xi.weaponskills.doMagicWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        return callPreservedOriginal(
            attacker, wsId, xi.slot.MAIN, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        return callPreservedOriginal(
            attacker, wsId, xi.slot.RANGED, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg)
    end)

xi.ambuscadeWsTuning.moduleInstalled = true

return m
