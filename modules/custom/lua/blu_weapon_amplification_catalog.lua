-----------------------------------
-- Native BLU main-hand damage amplification and ceilings.
-----------------------------------

local ambuscade = require('modules/custom/lua/ambuscade_weapons_catalog')
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')

-- FileWatcher dofile discards the return value. Mutate the cached table so a
-- reload cannot silently drop AOE_DAMAGE_CAP and leave the old ceilings live.
local CATALOG_KEY = 'modules/custom/lua/blu_weapon_amplification_catalog'
local catalog = package.loaded[CATALOG_KEY]
if type(catalog) ~= 'table' then
    catalog = {}
end
package.loaded[CATALOG_KEY] = catalog

catalog.DAMAGE_CAP_LOCAL_VAR = 'BlueSpellDamageCap'

-- Locked contract: splash hits of a BLU AoE stay at or below this.
-- The aimed-at mob uses the single-target weapon ceiling.
catalog.AOE_DAMAGE_CAP = 149999

-- Spell ceilings only. Weaponskills keep the shared 999k REMA/Prime path.
-- Multipliers stay so Relic needs setup to approach its cap and Aeonic
-- lands closer to its cap on a normal set.
catalog.TIERS =
{
    PRIME     = { multiplier = 105, cap = 999999 },
    AEONIC    = { multiplier =  60, cap = 750000 },
    MYTHIC    = { multiplier =  45, cap = 600000 },
    EMPYREAN  = { multiplier =  45, cap = 600000 },
    RELIC     = { multiplier =  30, cap = 400000 },
    AMBUSCADE = { multiplier =   9, cap =  99999 },
    ITEM_119  = { multiplier =   9, cap = 239997 },
    PRE_119   = { multiplier =   9, cap = 120000 },
}

catalog.WEAPON_TIERS =
{
    [21646] = 'PRIME',    -- Caliburnus
    [20695] = 'AEONIC',   -- Sequence
    [20688] = 'MYTHIC',   -- Tizona
    [20689] = 'EMPYREAN', -- Almace
    [20685] = 'RELIC',    -- Excalibur
}

local finalAmbuscadeIds = {}
for _, chain in ipairs(ambuscade.CHAINS) do
    finalAmbuscadeIds[chain.stages[#chain.stages]] = true
end

function catalog.classify(caster)
    local itemId = caster:getEquipID(xi.slot.MAIN) or 0
    local namedTier = catalog.WEAPON_TIERS[itemId]
    if namedTier then
        return namedTier, catalog.TIERS[namedTier]
    end

    if finalAmbuscadeIds[itemId] then
        return 'AMBUSCADE', catalog.TIERS.AMBUSCADE
    end

    local weapon = caster:getEquippedItem(xi.slot.MAIN)
    if weapon ~= nil and (weapon:getILvl() or 0) >= 119 then
        return 'ITEM_119', catalog.TIERS.ITEM_119
    end

    return 'PRE_119', catalog.TIERS.PRE_119
end

function catalog.getDamageMultiplier(caster)
    local _, tier = catalog.classify(caster)
    return tier.multiplier
end

function catalog.getDamageCap(caster)
    local _, tier = catalog.classify(caster)
    local cap = tier.cap
    local info = progression.getRemaPathInfo(caster:getEquipID(xi.slot.MAIN) or 0)
    if info and not info.final then
        cap = math.max(cap, progression.REMA_PRE_III_DAMAGE_CAP)
    end

    return cap
end

return catalog
