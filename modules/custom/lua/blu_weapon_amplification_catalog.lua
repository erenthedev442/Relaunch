-----------------------------------
-- Native BLU main-hand damage amplification and ceilings.
-----------------------------------

local ambuscade = require('modules/custom/lua/ambuscade_weapons_catalog')
local catalog = {}

catalog.DAMAGE_CAP_LOCAL_VAR = 'BlueSpellDamageCap'

catalog.TIERS =
{
    -- Second server-wide BLU pass: 3x the previous output and ceilings.
    PRIME     = { multiplier = 105, cap = 5249997 },
    AEONIC    = { multiplier =  60, cap = 2999997 },
    MYTHIC    = { multiplier =  45, cap = 2999997 },
    EMPYREAN  = { multiplier =  45, cap = 2999997 },
    RELIC     = { multiplier =  30, cap = 2999997 },
    AMBUSCADE = { multiplier =   9, cap =   99999 },
    ITEM_119  = { multiplier =   9, cap =  239997 },
    PRE_119   = { multiplier =   9, cap =  120000 },
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
