-----------------------------------
-- Relaunch Prime weaponskill pinnacle tuning
-----------------------------------

require('modules/module_utils')

local catalog = require('modules/custom/lua/prime_ws_tuning_catalog')
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')

xi.primeWsTuning         = xi.primeWsTuning or {}
xi.primeWsTuning.catalog = catalog

if xi.primeWsTuning.moduleInstalled then
    return Module:new('prime_weaponskill_tuning_reload_guard')
end

local m = Module:new('prime_weaponskill_tuning')

local function pack(...)
    return { n = select('#', ...), ... }
end

local activeCalculations = setmetatable({}, { __mode = 'k' })

local function copyAndTuneParams(wsParams, tuning)
    if not wsParams then
        return wsParams
    end

    local tunedParams = {}
    for key, value in pairs(wsParams) do
        tunedParams[key] = value
    end

    if wsParams.ftpMod then
        tunedParams.ftpMod = {}
        for index, value in ipairs(wsParams.ftpMod) do
            tunedParams.ftpMod[index] = value * tuning.ftpScale
        end
    end

    if tuning.ignoredDefense then
        tunedParams.ignoredDefense = {}
        for index, value in ipairs(tuning.ignoredDefense) do
            tunedParams.ignoredDefense[index] = value
        end
    end

    return tunedParams
end

xi.primeWsTuning.getEntry = function(attacker, wsId, slot)
    if
        not attacker or
        not attacker:isPC() or
        (slot ~= xi.slot.MAIN and slot ~= xi.slot.RANGED)
    then
        return nil
    end

    return catalog.getEntry(attacker:getEquipID(slot), wsId, slot)
end

xi.primeWsTuning.getTunedParams = function(attacker, wsId, slot, wsParams)
    local tuning = xi.primeWsTuning.getEntry(attacker, wsId, slot)
    if not tuning then
        return wsParams
    end

    return copyAndTuneParams(wsParams, tuning)
end

xi.primeWsTuning.withPrimeEffects = function(attacker, wsId, slot, callback)
    local tuning = xi.primeWsTuning.getEntry(attacker, wsId, slot)
    if not tuning or activeCalculations[attacker] then
        return callback()
    end

    local modId        = xi.mod.WEAPONSKILL_DAMAGE_BASE + wsId
    local priorMod     = attacker:getMod(modId)
    local capVar       = catalog.DAMAGE_CAP_LOCAL_VAR
    local priorCap     = attacker:getLocalVar(capVar)
    local priorAoECap  = attacker:getLocalVar('AoEWsDamageCap')
    local priorWsCap   = attacker:getLocalVar('StandardWsDamageCap')
    local primeCap     = progression.getPlayerPrimeDamageCap(
        attacker,
        catalog.getDamageCap(attacker:getMainJob()))

    attacker:addMod(modId, tuning.wsDamageBonus or catalog.WS_DAMAGE_BONUS)
    attacker:setLocalVar(capVar, primeCap)
    attacker:setLocalVar('StandardWsDamageCap', primeCap)
    if priorAoECap > 0 and slot == xi.slot.MAIN then
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
        attacker:setMod(modId, priorMod)
        attacker:setLocalVar(capVar, priorCap)
        attacker:setLocalVar('AoEWsDamageCap', priorAoECap)
        attacker:setLocalVar('StandardWsDamageCap', priorWsCap)
    end)
    activeCalculations[attacker] = nil

    if not cleanupOk then
        error(string.format('Prime WS effect cleanup failed: %s', cleanupErr), 0)
    end

    if not ok then
        error(err, 0)
    end

    return unpack(results, 1, results.n)
end

xi.primeWsTuning.callPreservedOriginal = function(attacker, wsId, slot, original, ...)
    local args = pack(...)

    return xi.primeWsTuning.withPrimeEffects(attacker, wsId, slot,
        function()
            return original(unpack(args, 1, args.n))
        end)
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
        local original    = super
        local tunedParams = xi.primeWsTuning.getTunedParams(
            attacker, wsId, xi.slot.MAIN, wsParams)

        return xi.primeWsTuning.callPreservedOriginal(
            attacker, wsId, xi.slot.MAIN, original,
            attacker, target, wsId, tunedParams, tp, action, primaryMsg, taChar)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original    = super
        local tunedParams = xi.primeWsTuning.getTunedParams(
            attacker, wsId, xi.slot.RANGED, wsParams)

        return xi.primeWsTuning.callPreservedOriginal(
            attacker, wsId, xi.slot.RANGED, original,
            attacker, target, wsId, tunedParams, tp, action, primaryMsg)
    end)

xi.primeWsTuning.moduleInstalled = true

return m
