-----------------------------------
-- trust_power_scaling.lua
-- Global trust combat scaling: master-level curve → soft-band power at 99,
-- retail-relative tiers, hard outgoing caps + C++ softclamp / lv120 gate.
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
    -- Keep mid-levels clearly below endgame; full package only at 99.
    return (masterLvl / 99) ^ 1.35
end

local function tierMult(tier)
    return catalog.TIER_MULT[tier] or catalog.TIER_MULT.B
end

local function styleOf(entry)
    return catalog.styleWeights(entry and entry.style or 'standard')
end

local function applyMeleePackage(mob, p, t, s)
    s = s or catalog.STYLE.standard
    local attM   = s.att or 1
    local wsdM   = s.wsd or 1
    local hasteM = s.haste or 1
    local daM    = s.da or 1

    -- Tuned so master-99 medians sit near soft bands (C 14–20k … S 36–40k)
    -- before softclamp; DEF/EVA still matter. ACC stays generous for ≤120.
    local dmg   = math.floor((6 + 155 * p) * t * attM)
    local att   = math.floor((18 + 600 * p) * t * attM)
    local acc   = math.floor((50 + 950 * p) * t)
    local str   = math.floor((5 + 170 * p) * t * attM)
    local dex   = math.floor((5 + 150 * p) * t)
    local da    = math.floor((2 + 32 * p) * t * daM)
    local ta    = math.floor((1 + 16 * p) * t * daM)
    local haste = math.floor((200 + 2100 * p) * math.min(t, 1.05) * hasteM)
    local wsd   = math.floor((2 + 36 * p) * t * wsdM)
    local store = math.floor((2 + 42 * p) * t * wsdM)

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
    mob:addMod(xi.mod.CRITHITRATE, math.floor((2 + 18 * p) * t))
    mob:addMod(xi.mod.CRIT_DMG_INCREASE, math.floor((2 + 23 * p) * t * wsdM))
end

local function applyMagePackage(mob, p, t, s)
    s = s or catalog.STYLE.pressure
    local mattM = s.matt or 1
    local mdmgM = s.mdmg or 1
    local mbbM  = s.mbb or 1
    local fcM   = s.fc or 1
    local maccM = s.macc or 1

    -- Early MAGIC_DAMAGE stays tiny (leveling portion owns dunes). At 99, sit
    -- near soft bands so softclamp is a backstop, not the every-hit ceiling.
    local matt  = math.floor((10 + 340 * p) * t * mattM)
    local macc  = math.floor((25 + 540 * p) * t * maccM)
    local intd  = math.floor((5 + 190 * p) * t * mattM)
    local mdmg  = math.floor((5 + 7800 * (p ^ 1.75)) * t * mdmgM)
    local fc    = math.floor((10 + 70 * p) * math.min(t, 1.1) * fcM)
    local mbb   = math.floor((5 + 50 * p) * t * mbbM)

    mob:addMod(xi.mod.MATT, matt)
    mob:addMod(xi.mod.MACC, macc)
    mob:addMod(xi.mod.INT, intd)
    mob:addMod(xi.mod.MAGIC_DAMAGE, mdmg)
    mob:addMod(xi.mod.FASTCAST, math.min(80, fc))
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, mbb)
    mob:addMod(xi.mod.UFASTCAST, math.floor(fc * 0.25))
    mob:addMod(xi.mod.HASTE_MAGIC, math.floor((100 + 1400 * p) * t * fcM))
    mob:addMod(xi.mod.MP, math.floor((40 + 960 * p) * t))
    mob:addMod(xi.mod.REFRESH, math.floor((1 + 14 * p) * t))
end

local function applyTankPackage(mob, p, t, s)
    -- AA sits under same-tier DD but must still chip enmity / build TP.
    applyMeleePackage(mob, p, t * 0.72, s)
    -- HP/DEF stack with per-script HPP; keep package modest so A tanks aren't sponges.
    mob:addMod(xi.mod.HP, math.floor((50 + 1680 * p) * t))
    mob:addMod(xi.mod.MP, math.floor((30 + 720 * p) * t))
    mob:addMod(xi.mod.REFRESH, math.floor((1 + 6 * p) * t))
    mob:addMod(xi.mod.DEF, math.floor((20 + 520 * p) * t))
    mob:addMod(xi.mod.VIT, math.floor((5 + 175 * p) * t))
    mob:addMod(xi.mod.ENMITY, math.floor((10 + 150 * p) * t))
    mob:addMod(xi.mod.DMG, -math.floor((100 + 1700 * p) * math.min(t, 1.0)))
    mob:addMod(xi.mod.MEVA, math.floor((10 + 240 * p) * t))
end

local function applySupportPackage(mob, p, t, s)
    applyMagePackage(mob, p, t * 0.55, s or catalog.STYLE.support)
    mob:addMod(xi.mod.MND, math.floor((5 + 195 * p) * t))
    mob:addMod(xi.mod.CHR, math.floor((5 + 145 * p) * t))
    mob:addMod(xi.mod.CURE_POTENCY, math.floor((2 + 38 * p) * t))
    mob:addMod(xi.mod.CURE_POTENCY_II, math.floor((1 + 19 * p) * t))
end

local ROLE_APPLY =
{
    melee_dd  = function(mob, p, t, s) applyMeleePackage(mob, p, t, s) end,
    ranged_dd = function(mob, p, t, s)
        applyMeleePackage(mob, p, t, s)
        mob:addMod(xi.mod.RATT, math.floor((15 + 465 * p) * t * ((s and s.att) or 1)))
        mob:addMod(xi.mod.RACC, math.floor((15 + 465 * p) * t))
    end,
    tank      = applyTankPackage,
    healer    = applySupportPackage,
    buffer    = applySupportPackage,
    nuker     = applyMagePackage,
    hybrid    = function(mob, p, t, s)
        applyMeleePackage(mob, p, t * 0.85, s)
        applyMagePackage(mob, p, t * 0.85, s)
    end,
    utility   = function(mob, p, t, s)
        applySupportPackage(mob, p, t * 0.75, s or catalog.STYLE.support)
        applyMeleePackage(mob, p, t * 0.4, catalog.STYLE.standard)
    end,
    aura      = function(mob, p, t, s)
        mob:addMod(xi.mod.HP, math.floor((60 + 1440 * p) * t))
        mob:addMod(xi.mod.MEVA, math.floor((15 + 285 * p) * t))
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

-- Leveling HP-portion bands (basis points of mob max HP), by catalog tier.
-- Weaker / medium / strong (A slightly under S ceiling so rares still hit harder).
local LEVELING_PORTION_BPS =
{
    C = { 800,  1000 }, -- weaker:  8–10%
    B = { 1000, 1500 }, -- medium: 10–15%
    A = { 1000, 1800 }, -- strong: 10–18%
    S = { 1000, 2000 }, -- strong: 10–20%
}

-- Master-99 soft-target bands for WS/nukes (absolute damage). Softclamp in C++
-- compresses overshoots toward the hard cap so 40k is uncommon, not constant.
local SOFT_BAND =
{
    C = { 14000, 20000 },
    B = { 22000, 28000 },
    A = { 30000, 36000 },
    S = { 36000, 40000 },
}

local DD_ROLES =
{
    melee_dd  = true,
    ranged_dd = true,
    nuker     = true,
    hybrid    = true,
    tank      = true, -- still gated as DD for >120 falloff; supports are not
}

local function applyCaps(mob, entry)
    local cap = entry.cap or catalog.DEFAULT_CAP or 40000
    mob:setLocalVar('EncounterOutgoingDamageCap', cap)
    if entry.mbCap and entry.mbCap > 0 then
        mob:setLocalVar('EncounterOutgoingDamageCapMB', entry.mbCap)
    else
        mob:setLocalVar('EncounterOutgoingDamageCapMB', 0)
    end

    local portion = LEVELING_PORTION_BPS[entry.tier] or LEVELING_PORTION_BPS.B
    mob:setLocalVar('TrustLevelingPortionBpsMin', portion[1])
    mob:setLocalVar('TrustLevelingPortionBpsMax', portion[2])

    local soft = SOFT_BAND[entry.tier] or SOFT_BAND.B
    mob:setLocalVar('TrustSoftBandMin', soft[1])
    mob:setLocalVar('TrustSoftBandMax', soft[2])
    mob:setLocalVar('TrustDdRole', DD_ROLES[entry.role] and 1 or 0)
end

local function safeInjectKit(mob, kitName)
    if not kitName then
        return
    end

    local ok, err = pcall(function()
        kits.apply(mob, kitName)
    end)
    if not ok then
        print(string.format('[trust_power_scaling] kit inject failed: %s', tostring(err)))
    end
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

    -- Caps first so a later mod error can never leave a trust uncapped.
    applyCaps(mob, entry)

    local masterLvl = master:getMainLvl() or mob:getMainLvl() or 1
    local p = progressOf(masterLvl)
    local t = tierMult(entry.tier)
    local s = styleOf(entry)
    local roleFn = ROLE_APPLY[entry.role] or ROLE_APPLY.melee_dd

    local ok, err = pcall(roleFn, mob, p, t, s)
    if not ok then
        print(string.format('[trust_power_scaling] role package failed for spell %s: %s', tostring(spellId), tostring(err)))
    end

    pcall(function()
        mob:addMod(xi.mod.HP, math.floor((30 + 970 * p) * t))
        mob:addMod(xi.mod.EVA, math.floor((8 + 192 * p) * t))
    end)

    applyCaps(mob, entry)
    safeInjectKit(mob, entry.injectKit)

    mob:setLocalVar('TrustPowerScaled', 1)
end

m:addOverride('xi.trust.spawn', function(caster, spell)
    -- Spawn directly so we receive the entity. Party-search-after-super was
    -- unreliable and left trusts on the global 999999 ceiling.
    if not caster or not spell then
        return 0
    end

    local spellId = spell:getID()
    local trust = caster:spawnTrust(spellId)

    if caster.getEminenceProgress and caster:getEminenceProgress(932) then
        xi.roe.onRecordTrigger(caster, 932)
    end

    if not trust then
        trust = findSpawnedTrust(caster, spellId)
    end

    if trust then
        xi.trustPowerApply(trust, caster, spellId)
    else
        print(string.format('[trust_power_scaling] failed to resolve spawned trust for spell %s', tostring(spellId)))
    end

    return 0
end)

return m
