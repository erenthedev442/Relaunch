-----------------------------------
-- Relaunch Prime weaponskill beta tuning
-----------------------------------

require('modules/module_utils')

local catalog = require('modules/custom/lua/prime_ws_tuning_catalog')

xi.primeWsTuning         = xi.primeWsTuning or {}
xi.primeWsTuning.catalog = catalog

if xi.primeWsTuning.moduleInstalled then
    return Module:new('prime_weaponskill_tuning_reload_guard')
end

local m = Module:new('prime_weaponskill_tuning')

local function copyAndScaleFtp(wsParams, ftpScale)
    if not wsParams or not wsParams.ftpMod or ftpScale == 1 then
        return wsParams
    end

    local tunedParams = {}
    for key, value in pairs(wsParams) do
        tunedParams[key] = value
    end

    tunedParams.ftpMod = {}
    for index, value in ipairs(wsParams.ftpMod) do
        tunedParams.ftpMod[index] = value * ftpScale
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

    return copyAndScaleFtp(wsParams, tuning.ftpScale)
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
        local original    = super
        local tunedParams = xi.primeWsTuning.getTunedParams(
            attacker, wsId, xi.slot.MAIN, wsParams)

        return original(
            attacker, target, wsId, tunedParams, tp, action, primaryMsg, taChar)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original    = super
        local tunedParams = xi.primeWsTuning.getTunedParams(
            attacker, wsId, xi.slot.RANGED, wsParams)

        return original(
            attacker, target, wsId, tunedParams, tp, action, primaryMsg)
    end)

xi.primeWsTuning.moduleInstalled = true

return m
