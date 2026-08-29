-----------------------------------
-- Native BLU main-hand damage amplification and ceilings.
-----------------------------------

local ambuscade = require('modules/custom/lua/ambuscade_weapons_catalog')
local catalog = {}

catalog.DAMAGE_CAP_LOCAL_VAR = 'BlueSpellDamageCap'

catalog.TIERS =
{
    PRIME     = { multiplier = 35, cap = 1749999 },
    AEONIC    = { multiplier = 20, cap =  999999 },
    MYTHIC    = { multiplier = 15, cap =  999999 },
    EMPYREAN  = { multiplier = 15, cap =  999999 },
    RELIC     = { multiplier = 10, cap =  999999 },
    AMBUSCADE = { multiplier =  3, cap =   99999 },
    ITEM_119  = { multiplier =  3, cap =   79999 },
    PRE_119   = { multiplier =  3, cap =   40000 },
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
    return tier.cap
end

return catalog
