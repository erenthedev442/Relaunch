local forge       = require('modules/custom/lua/aeonic_forge_catalog')
local rema        = require('modules/custom/lua/rema_ws_tier_catalog')
local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

describe('Aeonic Forge identifier alignment', function()
    it('offers every final Aeonic weapon from the main forge catalog', function()
        assert(#forge.weapons == #weaponForge.chains)
        assert(forge.currencyKey == 'escha_silt')
        assert(forge.cost == 50000)
        assert(weaponForge.aeonicBase.eschaBeads == 50000)
        assert(weaponForge.aeonicBase.hlRank == 5)

        for index, chain in ipairs(weaponForge.chains) do
            local forged = forge.weapons[index]
            assert(forged.id == chain.aeonic.s3.id)
            assert(forged.name == chain.aeonic.s3.name)
            assert(chain.aeonic.base.id ~= chain.s1.id)
            assert(chain.aeonic.s1.id ~= chain.s1.id)
            assert(chain.aeonic.s2.id ~= chain.s2.id)
        end
    end)

    it('maps forged Aeonic weapons to REMA AEONIC entries', function()
        for _, forged in ipairs(forge.weapons) do
            local entry = rema.BY_ITEM_ID[forged.id]
            assert(entry ~= nil, string.format('Missing REMA entry for %s', forged.name))
            assert(entry.family == 'AEONIC')
            assert(entry.name == forged.name)
        end
    end)
end)
