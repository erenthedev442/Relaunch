-----------------------------------
-- Prime repeat-forge catalog
--
-- A repeat Prime requires the matching final Relic, Empyrean, Mythic/Ergon,
-- and Aeonic to be presented together. The four proof weapons are never
-- consumed; they only unlock the selected repeat recipe.
-----------------------------------
local forge = require('modules/custom/lua/weapon_forge_catalog')

local C =
{
    initialPrimeVar = 'WF_PrimeWeapon_Final',
    pendingVar      = 'PrimeRepeatPending',
    marks           = 5000,
    demonsId        = 9543,
    demonsName      = 'Demons Medal',
    demons          = 100,
    gil             = 250000000,
    oggbi =
    {
        x = 649.7283, y = 0.3000, z = 562.4038, rotation = 169,
        look = '0x0100030811101120113011401150006000700000',
    },
    apparition =
    {
        x = 645.1979, y = 0.3000, z = 567.9748, rotation = 37,
        look = 2680,
    },
    recipes = {},
}

local function finalsByType(chains)
    local result = {}
    for _, chain in ipairs(chains) do
        result[chain.type] = result[chain.type] or {}
        result[chain.type][#result[chain.type] + 1] =
        {
            id = chain.s3,
            name = chain.name,
        }
    end
    return result
end

local relics    = finalsByType(forge.relicChains)
local empyreans = finalsByType(forge.empyreanChains)
local mythics   = finalsByType(forge.mythicChains)

for index, chain in ipairs(forge.chains) do
    local recipe =
    {
        index      = index,
        weaponType = chain.type,
        prime      = chain.s3,
        relics     = relics[chain.type] or {},
        empyreans  = empyreans[chain.type] or {},
        mythics    = mythics[chain.type] or {},
        aeonics    =
        {
            { id = chain.aeonic.s3.id, name = chain.aeonic.s3.name },
        },
    }

    assert(#recipe.relics > 0, 'Prime repeat missing Relic for ' .. chain.type)
    assert(#recipe.empyreans > 0, 'Prime repeat missing Empyrean for ' .. chain.type)
    assert(#recipe.mythics > 0, 'Prime repeat missing Mythic for ' .. chain.type)

    C.recipes[index] = recipe
end

local function tradedOneOf(trade, choices)
    for _, item in ipairs(choices) do
        if trade:hasItemQty(item.id, 1) then return true end
    end
    return false
end

function C.tradeMatches(trade, recipe)
    return trade:getItemCount() == 4
        and tradedOneOf(trade, recipe.relics)
        and tradedOneOf(trade, recipe.empyreans)
        and tradedOneOf(trade, recipe.mythics)
        and tradedOneOf(trade, recipe.aeonics)
end

function C.requirementText(recipe)
    local function names(items)
        local result = {}
        for _, item in ipairs(items) do result[#result + 1] = item.name end
        return table.concat(result, '/')
    end

    return string.format('Relic: %s | Empyrean: %s | Mythic: %s | Aeonic: %s',
        names(recipe.relics), names(recipe.empyreans),
        names(recipe.mythics), names(recipe.aeonics))
end

return C
