-----------------------------------
-- Legendary REMA native-weaponskill enhancement
--
-- This module is separate from the Prime implementation. It only recognizes
-- final weapons explicitly listed in rema_ws_tier_catalog.lua.
--
-- The normal WS formula already supports a WS-specific damage modifier at
-- xi.mod.WEAPONSKILL_DAMAGE_BASE + wsID. We add that modifier only around the
-- synchronous WS calculation call, then remove the exact amount immediately.
-- xpcall guarantees cleanup before a Lua error is rethrown. A WS interrupted
-- before reaching these calculation functions never receives the modifier.
-----------------------------------

require('modules/module_utils')

local catalog = require('modules/custom/lua/rema_ws_tier_catalog')

xi.remaWsTier         = xi.remaWsTier or {}
xi.remaWsTier.catalog = catalog

-- The module loader applies each registered override once. If this file is
-- explicitly re-executed in the same Lua state, return an override-free module
-- instead of registering the same wrappers again.
if xi.remaWsTier.moduleInstalled then
    return Module:new('rema_weaponskill_enhancement_reload_guard')
end

local m = Module:new('rema_weaponskill_enhancement')

local function pack(...)
    return { n = select('#', ...), ... }
end

local activeCalculations = setmetatable({}, { __mode = 'k' })

local function copyTable(values)
    if not values then
        return nil
    end

    local copy = {}
    for index, value in ipairs(values) do
        copy[index] = value
    end

    return copy
end

local function multiplyTables(nativeValues, tuningValues)
    local combined = {}
    for index, tuningValue in ipairs(tuningValues) do
        combined[index] = (nativeValues and nativeValues[index] or 1) * tuningValue
    end

    return combined
end

local function addTables(nativeValues, tuningValues)
    local combined = {}
    for index, tuningValue in ipairs(tuningValues) do
        combined[index] = (nativeValues and nativeValues[index] or 0) + tuningValue
    end

    return combined
end

local function maximumTables(nativeValues, tuningValues)
    local combined = {}
    for index, tuningValue in ipairs(tuningValues) do
        combined[index] = math.max(nativeValues and nativeValues[index] or 0, tuningValue)
    end

    return combined
end

local function copyAndTuneParams(wsParams, wsFtpScale, familyTuning, tunePhysical)
    if not wsParams then
        return wsParams
    end

    local tunedParams = {}
    for key, value in pairs(wsParams) do
        tunedParams[key] = value
    end

    if wsParams.ftpMod then
        tunedParams.ftpMod = copyTable(wsParams.ftpMod)
        local combinedFtpScale = wsFtpScale * familyTuning.ftpScale
        for index, value in ipairs(tunedParams.ftpMod) do
            tunedParams.ftpMod[index] = value * combinedFtpScale
        end
    end

    if tunePhysical then
        tunedParams.atkVaries      = multiplyTables(wsParams.atkVaries, familyTuning.attackScale)
        tunedParams.accVaries      = addTables(wsParams.accVaries, familyTuning.accuracyBonus)
        tunedParams.ignoredDefense = maximumTables(wsParams.ignoredDefense, familyTuning.ignoredDefense)
    end

    return tunedParams
end

xi.remaWsTier.getEntry = function(attacker, wsId, slot)
    if
        not attacker or
        not attacker:isPC() or
        (slot ~= xi.slot.MAIN and slot ~= xi.slot.RANGED)
    then
        return nil
    end

    return catalog.getEntry(attacker:getEquipID(slot), wsId, slot)
end

xi.remaWsTier.getBonusPercent = function(attacker, wsId, slot)
    local entry = xi.remaWsTier.getEntry(attacker, wsId, slot)
    if not entry then
        return 0
    end

    return catalog.getBonusPercent(entry.itemId, wsId, slot)
end

xi.remaWsTier.getTunedParams = function(attacker, wsId, slot, wsParams, tunePhysical)
    local entry = xi.remaWsTier.getEntry(attacker, wsId, slot)
    if not entry then
        return wsParams
    end

    local ftpScale = catalog.getTuning(wsId)
    if not ftpScale then
        error(string.format('Missing REMA fTP tuning for enabled WS %d', wsId))
    end

    local familyTuning = catalog.getFamilyTuning(entry.family)
    if not familyTuning then
        error(string.format('Missing REMA family tuning for %s', entry.family))
    end

    return copyAndTuneParams(wsParams, ftpScale, familyTuning, tunePhysical ~= false)
end

xi.remaWsTier.withTemporaryBonus = function(attacker, wsId, slot, callback)
    local entry = xi.remaWsTier.getEntry(attacker, wsId, slot)
    if not entry or activeCalculations[attacker] then
        return callback()
    end

    local familyTuning = catalog.getFamilyTuning(entry.family)
    local bonusPercent = catalog.getBonusPercent(entry.itemId, wsId, slot)
    local magicAccBonus = entry.magic and familyTuning.magicAccBonus or 0
    local modId         = xi.mod.WEAPONSKILL_DAMAGE_BASE + wsId
    local priorValue    = attacker:getMod(modId)
    local priorMagicAcc = magicAccBonus > 0 and attacker:getMod(xi.mod.MACC) or 0
    local priorAoECap   = attacker:getLocalVar('AoEWsDamageCap')
    local priorWsCap    = attacker:getLocalVar('StandardWsDamageCap')

    attacker:addMod(modId, bonusPercent)
    attacker:setLocalVar('StandardWsDamageCap', catalog.NATIVE_DAMAGE_CAP)
    if magicAccBonus > 0 then
        attacker:addMod(xi.mod.MACC, magicAccBonus)
    end
    if priorAoECap > 0 and (slot == xi.slot.MAIN or slot == xi.slot.RANGED) then
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

    -- Restore the exact captured value rather than assuming the prior value was
    -- zero or relying on subtractive cleanup.
    local cleanupOk, cleanupErr = pcall(function()
        attacker:setMod(modId, priorValue)
        if magicAccBonus > 0 then
            attacker:setMod(xi.mod.MACC, priorMagicAcc)
        end
        attacker:setLocalVar('AoEWsDamageCap', priorAoECap)
        attacker:setLocalVar('StandardWsDamageCap', priorWsCap)
    end)
    activeCalculations[attacker] = nil

    if not cleanupOk then
        error(string.format('REMA WS modifier cleanup failed: %s', cleanupErr), 0)
    end

    if not ok then
        error(err, 0)
    end

    return unpack(results, 1, results.n)
end

xi.remaWsTier.callPreservedOriginal = function(attacker, wsId, slot, original, ...)
    local args = pack(...)

    return xi.remaWsTier.withTemporaryBonus(attacker, wsId, slot,
        function()
            return original(unpack(args, 1, args.n))
        end)
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
        -- Capture the module loader's preserved original before creating the
        -- callback. The reload guard above prevents this wrapper being applied
        -- to itself, so this call cannot recurse.
        local original    = super
        local tunedParams = xi.remaWsTier.getTunedParams(
            attacker, wsId, xi.slot.MAIN, wsParams, true)

        return xi.remaWsTier.callPreservedOriginal(
            attacker, wsId, xi.slot.MAIN, original,
            attacker, target, wsId, tunedParams, tp, action, primaryMsg, taChar)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original    = super
        local tunedParams = xi.remaWsTier.getTunedParams(
            attacker, wsId, xi.slot.RANGED, wsParams, true)

        return xi.remaWsTier.callPreservedOriginal(
            attacker, wsId, xi.slot.RANGED, original,
            attacker, target, wsId, tunedParams, tp, action, primaryMsg)
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

        local tunedParams = xi.remaWsTier.getTunedParams(
            attacker, wsId, slot, wsParams, false)

        return xi.remaWsTier.callPreservedOriginal(
            attacker, wsId, slot, original,
            attacker, target, wsId, tunedParams, tp, action, primaryMsg)
    end)

xi.remaWsTier.moduleInstalled = true

return m
