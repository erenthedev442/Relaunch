-----------------------------------
-- trust_power_scaling.lua
-- Global trust combat scaling: master-level curve → ilvl115-class power at 99,
-- retail-relative tiers, hard outgoing damage caps.
--
-- Skips Adventuring Fellow (fellowApplied == 1).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')

local m = Module:new('trust_power_scaling')

local catalog = require('modules/custom/lua/trust_power_catalog')
local kits    = require('modules/custom/lua/trust_kit_library')

local function progressOf(masterLvl)
    masterLvl = math.max(1, math.min(99, masterLvl or 1))
    return (masterLvl / 99) ^ 1.25
end

local function tierMult(tier)
    return catalog.TIER_MULT[tier] or catalog.TIER_MULT.B
end

local function applyMeleePackage(mob, p, t)
    local dmg   = math.floor((55 + 165 * p) * t)
    local att   = math.floor((120 + 680 * p) * t)
    local acc   = math.floor((150 + 750 * p) * t)
    local str   = math.floor((40 + 160 * p) * t)
    local dex   = math.floor((30 + 140 * p) * t)
    local da    = math.floor((8 + 32 * p) * t)
    local ta    = math.floor((4 + 16 * p) * t)
    local haste = math.floor((800 + 1700 * p) * math.min(t, 1.05))
    local wsd   = math.floor((10 + 45 * p) * t)
    local store = math.floor((10 + 40 * p) * t)

    pcall(function() mob:setDamage(dmg) end)
    mob:addMod(xi.mod.ATT, att)
    mob:addMod(xi.mod.RATT, math.floor(att * 0.85))
    mob:addMod(xi.mod.ACC, acc)
    mob:addMod(xi.mod.RACC, math.floor(acc * 0.85))
    mob:addMod(xi.mod.STR, str)
    mob:addMod(xi.mod.DEX, dex)
    mob:addMod(xi.mod.DOUBLE_ATTACK, da)
    mob:addMod(xi.mod.TRIPLE_ATTACK, ta)
    mob:addMod(xi.mod.HASTE_GEAR, haste)
    mob:addMod(xi.mod.WEAPONSKILL_DAMAGE_BASE, wsd)
    mob:addMod(xi.mod.STORETP, store)
    mob:addMod(xi.mod.CRITHITRATE, math.floor((5 + 15 * p) * t))
    mob:addMod(xi.mod.CRIT_DMG_INCREASE, math.floor((5 + 20 * p) * t))
end

local function applyMagePackage(mob, p, t)
    local matt  = math.floor((80 + 360 * p) * t)
    local macc  = math.floor((100 + 400 * p) * t)
    local intd  = math.floor((50 + 180 * p) * t)
    local mdmg  = math.floor((2500 + 11000 * p) * t)
    local fc    = math.floor((35 + 45 * p) * math.min(t, 1.1))
    local mbb   = math.floor((20 + 40 * p) * t)

    mob:addMod(xi.mod.MATT, matt)
    mob:addMod(xi.mod.MACC, macc)
    mob:addMod(xi.mod.INT, intd)
    mob:addMod(xi.mod.MAGIC_DAMAGE, mdmg)
    mob:addMod(xi.mod.FASTCAST, math.min(80, fc))
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, mbb)
    mob:addMod(xi.mod.UFASTCAST, math.floor(fc * 0.25))
    mob:addMod(xi.mod.HASTE_MAGIC, math.floor((500 + 1000 * p) * t))
    mob:addMod(xi.mod.MP, math.floor((200 + 800 * p) * t))
    mob:addMod(xi.mod.REFRESH, math.floor((3 + 12 * p) * t))
end

local function applyTankPackage(mob, p, t)
    applyMeleePackage(mob, p, t * 0.55)
    mob:addMod(xi.mod.HP, math.floor((400 + 2600 * p) * t))
    mob:addMod(xi.mod.DEF, math.floor((100 + 500 * p) * t))
    mob:addMod(xi.mod.VIT, math.floor((40 + 160 * p) * t))
    mob:addMod(xi.mod.ENMITY, math.floor((40 + 120 * p) * t))
    mob:addMod(xi.mod.DMG, -math.floor((500 + 1500 * p) * math.min(t, 1.0)))
    mob:addMod(xi.mod.MEVA, math.floor((50 + 200 * p) * t))
end

local function applySupportPackage(mob, p, t)
    applyMagePackage(mob, p, t * 0.55)
    mob:addMod(xi.mod.MND, math.floor((40 + 160 * p) * t))
    mob:addMod(xi.mod.CHR, math.floor((30 + 120 * p) * t))
    mob:addMod(xi.mod.CURE_POTENCY, math.floor((10 + 30 * p) * t))
    mob:addMod(xi.mod.CURE_POTENCY_II, math.floor((5 + 15 * p) * t))
end

local ROLE_APPLY =
{
    melee_dd  = function(mob, p, t) applyMeleePackage(mob, p, t) end,
    ranged_dd = function(mob, p, t)
        applyMeleePackage(mob, p, t)
        mob:addMod(xi.mod.RATT, math.floor((80 + 400 * p) * t))
        mob:addMod(xi.mod.RACC, math.floor((80 + 400 * p) * t))
    end,
    tank      = applyTankPackage,
    healer    = applySupportPackage,
    buffer    = applySupportPackage,
    nuker     = applyMagePackage,
    hybrid    = function(mob, p, t)
        applyMeleePackage(mob, p, t * 0.85)
        applyMagePackage(mob, p, t * 0.85)
    end,
    utility   = function(mob, p, t)
        applySupportPackage(mob, p, t * 0.75)
        applyMeleePackage(mob, p, t * 0.4)
    end,
    aura      = function(mob, p, t)
        -- Cornelia-style: survivability only; auras come from the script.
        mob:addMod(xi.mod.HP, math.floor((300 + 1200 * p) * t))
        mob:addMod(xi.mod.MEVA, math.floor((80 + 220 * p) * t))
    end,
}

local function findSpawnedTrust(caster, spellId)
    local party = caster:getPartyWithTrusts()
    if not party then
        return nil
    end

    for _, member in pairs(party) do
        if member:getObjType() == xi.objType.TRUST and member:getTrustID() == spellId then
            return member
        end
    end

    return nil
end

function xi.trustPowerApply(mob, master, spellId)
    if not mob or not master then
        return
    end

    if mob:getLocalVar('fellowApplied') == 1 then
        return
    end

    if mob:getLocalVar('TrustPowerScaled') == 1 then
        return
    end

    local entry = catalog.get(spellId) or { role = 'melee_dd', tier = 'B' }
    local masterLvl = master:getMainLvl() or mob:getMainLvl() or 1
    local p = progressOf(masterLvl)
    local t = tierMult(entry.tier)
    local roleFn = ROLE_APPLY[entry.role] or ROLE_APPLY.melee_dd

    roleFn(mob, p, t)

    -- Universal floors so every trust stays relevant.
    mob:addMod(xi.mod.HP, math.floor((150 + 850 * p) * t))
    mob:addMod(xi.mod.EVA, math.floor((40 + 160 * p) * t))

    local cap = entry.cap or catalog.DEFAULT_CAP
    mob:setLocalVar('EncounterOutgoingDamageCap', cap)
    if entry.mbCap and entry.mbCap > 0 then
        mob:setLocalVar('EncounterOutgoingDamageCapMB', entry.mbCap)
    end

    if entry.injectKit then
        kits.apply(mob, entry.injectKit)
    end

    mob:setLocalVar('TrustPowerScaled', 1)
end

m:addOverride('xi.trust.spawn', function(caster, spell)
    local result = super(caster, spell)
    if caster and spell then
        local spellId = spell:getID()
        local trust = findSpawnedTrust(caster, spellId)
        if trust then
            xi.trustPowerApply(trust, caster, spellId)
        end
    end

    return result
end)

return m
