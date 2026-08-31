local forge       = require('modules/custom/lua/mythic_forge_catalog')
local rema        = require('modules/custom/lua/rema_ws_tier_catalog')
local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

describe('Mythic Forge identifier alignment', function()
    it('offers every final mythic weapon from the main forge catalog', function()
        assert(#forge.weapons == #weaponForge.mythicChains)
        assert(forge.currencyId == 4060)
        assert(forge.cost == 3500)

        for index, chain in ipairs(weaponForge.mythicChains) do
            local forged = forge.weapons[index]
            assert(forged.id == chain.s3)
            assert(forged.name == chain.name)
        end
    end)

    it('maps forged damage mythics to REMA MYTHIC entries', function()
        for _, forged in ipairs(forge.weapons) do
            local entry = rema.BY_ITEM_ID[forged.id]
            assert(entry ~= nil, string.format('Missing REMA entry for %s', forged.name))
            assert(entry.family == 'MYTHIC')
            assert(entry.name == forged.name)
        end
    end)
end)
