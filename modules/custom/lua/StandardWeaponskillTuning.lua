-----------------------------------
-- Level-scaled baseline tuning for ordinary player weaponskills.
--
-- Final REMA, Prime and Ambuscade weapon/native-WS pairs are explicitly
-- excluded and continue through their existing private tuning modules.
-----------------------------------
require('modules/module_utils')

local catalog      = require('modules/custom/lua/standard_ws_tuning_catalog')
local remaCatalog  = require('modules/custom/lua/rema_ws_tier_catalog')
local primeCatalog = require('modules/custom/lua/prime_ws_tuning_catalog')
local ambuCatalog  = require('modules/custom/lua/ambuscade_ws_tuning_catalog')

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

local function specialEntry(attacker, wsId, slot)
    local itemId = attacker:getEquipID(slot)
    return remaCatalog.getEntry(itemId, wsId, slot) or
        primeCatalog.getEntry(itemId, wsId, slot) or
        ambuCatalog.getEntry(itemId, wsId, slot)
end

-- An AoE WS earns its premium ceiling from the final-stage weapon equipped in
-- the main hand, even when the WS is not that weapon's linked/native WS.
local premiumMainhandAoECaps = {}
for _, entry in ipairs(ambuCatalog.entries) do
    if entry.slot == xi.slot.MAIN then
        premiumMainhandAoECaps[entry.itemId] = ambuCatalog.AOE_DAMAGE_CAP
    end
end

for itemId, entry in pairs(remaCatalog.BY_ITEM_ID) do
    if entry.enabled and entry.slot == xi.slot.MAIN then
        premiumMainhandAoECaps[itemId] = remaCatalog.AOE_DAMAGE_CAP
    end
end

for _, entry in pairs(primeCatalog.PRIME_WS_TUNING) do
    if entry.slot == xi.slot.MAIN then
        premiumMainhandAoECaps[entry.itemId] = primeCatalog.AOE_DAMAGE_CAP
    end
end

local function getPremiumAoECap(attacker)
    if attacker:getLocalVar('AoEWsDamageCap') <= 0 then
        return 0
    end

    return premiumMainhandAoECaps[attacker:getEquipID(xi.slot.MAIN)] or 0
end

xi.standardWsTuning.isEligible = function(attacker, target, wsId, slot, wsParams)
    return
        attacker ~= nil and
        target ~= nil and
        attacker:isPC() and
        target:isMob() and
        not (wsParams and wsParams.isJump) and
        specialEntry(attacker, wsId, slot) == nil
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
    local premiumAoECap  = getPremiumAoECap(attacker)
    if premiumAoECap > damageCap then
        damageCap = premiumAoECap
        attacker:setLocalVar('AoEWsDamageCap', premiumAoECap)
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
        return callPreservedOriginal(
            attacker, target, wsId, xi.slot.MAIN, wsParams, false, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg, taChar)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, wsParams, tp, action, primaryMsg)
        local original = super
        return callPreservedOriginal(
            attacker, target, wsId, xi.slot.RANGED, wsParams, false, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg)
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

        return callPreservedOriginal(
            attacker, target, wsId, slot, wsParams, true, original,
            attacker, target, wsId, wsParams, tp, action, primaryMsg)
    end)

xi.standardWsTuning.moduleInstalled = true

return m
