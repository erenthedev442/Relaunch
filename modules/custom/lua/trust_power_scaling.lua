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

    -- Multi-hit (DA/TA) and AA weapon rating scale flatter while leveling so
    -- S-tier melee (Darrcuiln TA etc.) doesn't wipe packs vs hybrid Matsui-P.
    -- Full package still lands at master 99 (p == 1).
    local multiP = p * p

    -- Tuned so master-99 medians sit near soft bands (C 8–10k … S 36–40k)
    -- before softclamp. ALL_WSDMG_ALL_HITS is a *percentage* (see weaponskills.lua).
    -- WEAPONSKILL_DAMAGE_BASE is per-wsID only and was a dead mod here.
    local dmg   = math.floor((12 + 210 * p) * t * attM)
    local att   = math.floor((30 + 720 * p) * t * attM)
    local acc   = math.floor((60 + 1000 * p) * t)
    local str   = math.floor((8 + 190 * p) * t * attM)
    local dex   = math.floor((8 + 170 * p) * t)
    local da    = math.floor((3 + 36 * multiP) * t * daM)
    local ta    = math.floor((1 + 18 * multiP) * t * daM)
    local haste = math.floor((200 + 2100 * p) * math.min(t, 1.05) * hasteM)
    local wsd   = math.floor((10 + 50 * p) * t * wsdM) -- % all-hits WSD
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
    mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, wsd)
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

local function applyTankPackage(mob, p, t, s, tier)
    -- AA sits under same-tier DD but must still chip enmity / build TP.
    -- C tanks: thinner AA/DEF so they hold hate without out-tanking B/A.
    local isC = tier == 'C'
    local aaScale = isC and 0.55 or 0.72
    local defScale = isC and 0.70 or 1.0
    applyMeleePackage(mob, p, t * aaScale, s)
    mob:addMod(xi.mod.HP, math.floor((50 + 1680 * p) * t * defScale))
    mob:addMod(xi.mod.MP, math.floor((30 + 720 * p) * t))
    mob:addMod(xi.mod.REFRESH, math.floor((1 + 6 * p) * t))
    mob:addMod(xi.mod.DEF, math.floor((20 + 520 * p) * t * defScale))
    mob:addMod(xi.mod.VIT, math.floor((5 + 175 * p) * t * defScale))
    mob:addMod(xi.mod.ENMITY, math.floor((10 + 150 * p) * t))
    mob:addMod(xi.mod.DMG, -math.floor((100 + 1700 * p) * math.min(t, 1.0) * defScale))
    mob:addMod(xi.mod.MEVA, math.floor((10 + 240 * p) * t))
    -- Keep C-tank Cure IV well under 600 (no big potency stack).
    if isC then
        mob:addMod(xi.mod.CURE_POTENCY, 5)
    end
end

local function applySupportPackage(mob, p, t, s, tier)
    applyMagePackage(mob, p, t * 0.55, s or catalog.STYLE.support)
    mob:addMod(xi.mod.MND, math.floor((5 + 195 * p) * t))
    mob:addMod(xi.mod.CHR, math.floor((5 + 145 * p) * t))
    -- C healers: modest cures only (no 600+ Cure IV).
    if tier == 'C' then
        mob:addMod(xi.mod.CURE_POTENCY, 8)
        mob:addMod(xi.mod.CURE_POTENCY_II, 4)
    else
        mob:addMod(xi.mod.CURE_POTENCY, math.floor((2 + 38 * p) * t))
        mob:addMod(xi.mod.CURE_POTENCY_II, math.floor((1 + 19 * p) * t))
    end
end

local ROLE_APPLY =
{
    melee_dd  = function(mob, p, t, s, tier)
        applyMeleePackage(mob, p, t, s)
        -- Per-tier WS push so soft bands are reachable without softclamp-only ladders.
        -- Percentage-point extras on ALL_WSDMG_ALL_HITS (not flat base).
        -- MAIN_DMG_RATING also feeds AA — scale with p^2 so leveling AA tracks
        -- hybrid trusts (Matsui-P) instead of doubling them via S extras + TA.
        local multiP = p * p
        local wsdExtra =
        {
            C = math.floor(15 + 25 * p),
            B = math.floor(25 + 40 * p),
            A = math.floor(40 + 55 * p),
            S = math.floor(55 + 75 * p),
        }
        local ratingExtra =
        {
            C = math.floor(20 + 45 * multiP),
            B = math.floor(25 + 55 * multiP),
            A = math.floor(35 + 70 * multiP),
            S = math.floor(50 + 90 * multiP),
        }
        if wsdExtra[tier] then
            mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, wsdExtra[tier])
            mob:addMod(xi.mod.MAIN_DMG_RATING, ratingExtra[tier])
        end
    end,
    ranged_dd = function(mob, p, t, s, tier)
        applyMeleePackage(mob, p, t, s)
        mob:addMod(xi.mod.RATT, math.floor((20 + 520 * p) * t * ((s and s.att) or 1)))
        mob:addMod(xi.mod.RACC, math.floor((20 + 520 * p) * t))
        local multiP = p * p
        local wsdExtra =
        {
            C = math.floor(15 + 25 * p),
            B = math.floor(25 + 40 * p),
            A = math.floor(40 + 55 * p),
            S = math.floor(55 + 75 * p),
        }
        local ratingExtra =
        {
            C = math.floor(20 + 50 * multiP),
            B = math.floor(28 + 60 * multiP),
            A = math.floor(40 + 75 * multiP),
            S = math.floor(55 + 95 * multiP),
        }
        if wsdExtra[tier] then
            mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, wsdExtra[tier])
            mob:addMod(xi.mod.RANGED_DMG_RATING, ratingExtra[tier])
        end
    end,
    tank      = function(mob, p, t, s, tier) applyTankPackage(mob, p, t, s, tier) end,
    healer    = function(mob, p, t, s, tier) applySupportPackage(mob, p, t, s, tier) end,
    buffer    = function(mob, p, t, s, tier) applySupportPackage(mob, p, t, s, tier) end,
    nuker     = function(mob, p, t, s, tier)
        applyMagePackage(mob, p, t, s)
        -- Tier MDMG/MP so free nukes sit near soft bands; hard/MB caps stop spikes.
        local mdmgExtra =
        {
            C = math.floor(150 + 700 * p),
            B = math.floor(200 + 900 * p),
            A = math.floor(280 + 1200 * p),
            S = math.floor(350 + 1500 * p),
        }
        local mpExtra =
        {
            C = math.floor(80 + 400 * p),
            B = math.floor(100 + 500 * p),
            A = math.floor(120 + 600 * p),
            S = math.floor(150 + 700 * p),
        }
        local refExtra =
        {
            C = math.floor(3 + 8 * p),
            B = math.floor(4 + 10 * p),
            A = math.floor(5 + 12 * p),
            S = math.floor(6 + 14 * p),
        }
        if mdmgExtra[tier] then
            mob:addMod(xi.mod.MAGIC_DAMAGE, mdmgExtra[tier])
            mob:addMod(xi.mod.MP, mpExtra[tier])
            mob:addMod(xi.mod.REFRESH, refExtra[tier])
        end
    end,
    hybrid    = function(mob, p, t, s, tier)
        applyMeleePackage(mob, p, t * 0.85, s)
        applyMagePackage(mob, p, t * 0.85, s)
    end,
    utility   = function(mob, p, t, s, tier)
        applySupportPackage(mob, p, t * 0.75, s or catalog.STYLE.support, tier)
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
-- Per-hit ceiling — multi-hit AA (DA/TA) stacks on top, so S stays below the
-- old 18–30% band so a TA round can't delete a mob outright. Matsui-P is the
-- sole exception (TrustBypassLevelingHpPortion).
local LEVELING_PORTION_BPS =
{
    C = { 800,  1000 }, -- weaker:  8–10%
    B = { 1000, 1500 }, -- medium: 10–15%
    A = { 1200, 1800 }, -- strong: 12–18%
    S = { 1400, 2200 }, -- strong: 14–22% (TA round ~still under wipe)
}

-- Master-99 soft-target bands for WS/nukes (absolute damage). Softclamp in C++
-- compresses overshoots toward the hard cap so 40k is uncommon, not constant.
local SOFT_BAND =
{
    C = { 8000,  10000 },
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
    local tierCap = catalog.TIER_HARD_CAP and catalog.TIER_HARD_CAP[entry.tier]
    local cap = entry.cap or tierCap or catalog.DEFAULT_CAP or 40000
    mob:setLocalVar('EncounterOutgoingDamageCap', cap)
    -- MB hard cap defaults to tier hard. Only Shantotto II / Matsui-P override via mbCap/cap.
    if entry.mbCap and entry.mbCap > 0 then
        mob:setLocalVar('EncounterOutgoingDamageCapMB', entry.mbCap)
    else
        mob:setLocalVar('EncounterOutgoingDamageCapMB', cap)
    end

    local portion = LEVELING_PORTION_BPS[entry.tier] or LEVELING_PORTION_BPS.B
    mob:setLocalVar('TrustLevelingPortionBpsMin', portion[1])
    mob:setLocalVar('TrustLevelingPortionBpsMax', portion[2])

    local soft = entry.softBand or SOFT_BAND[entry.tier] or SOFT_BAND.B
    mob:setLocalVar('TrustSoftBandMin', soft[1])
    mob:setLocalVar('TrustSoftBandMax', soft[2])
    mob:setLocalVar('TrustDdRole', DD_ROLES[entry.role] and 1 or 0)
    -- Only Matsui-P stamps this. Every other trust keeps the pre-99 HP% clamp.
    mob:setLocalVar('TrustBypassLevelingHpPortion', entry.bypassLevelingPortion and 1 or 0)
    mob:setLocalVar('TrustSoftclampScale', entry.softclampScale or 0)
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

    local ok, err = pcall(roleFn, mob, p, t, s, entry.tier)
    if not ok then
        print(string.format('[trust_power_scaling] role package failed for spell %s: %s', tostring(spellId), tostring(err)))
    end

    -- Optional melee chip for support roles that still AA/WS (keeps cure path intact).
    if entry.meleeChip and entry.meleeChip > 0 then
        pcall(applyMeleePackage, mob, p, t * entry.meleeChip, catalog.STYLE.standard)
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
    -- Preserve the stock trust summon path. Calling caster:spawnTrust directly
    -- here was introduced by Round 5, the same change where Matsui-P began
    -- disconnecting clients during summon.
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
