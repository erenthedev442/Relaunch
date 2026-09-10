local forge       = require('modules/custom/lua/aeonic_forge_catalog')
local rema        = require('modules/custom/lua/rema_ws_tier_catalog')
local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

describe('Aeonic Forge identifier alignment', function()
    it('offers every final Aeonic weapon from the main forge catalog', function()
        assert(#forge.weapons == #weaponForge.chains + 2)
        assert(forge.currencyKey == 'escha_silt')
        assert(forge.cost == 100000)
        assert(weaponForge.aeonicBase.eschaBeads == 50000)
        assert(weaponForge.aeonicBase.hlRank == 5)

        for index, chain in ipairs(weaponForge.chains) do
            local forged = forge.weapons[index]
            assert(forged.id == chain.aeonic.s3.id)
            assert(forged.name == chain.aeonic.s3.name)
            assert(weaponForge.byId[chain.aeonic.base.id] == nil)
            assert(weaponForge.byId[chain.aeonic.s1.id] == nil)
            assert(weaponForge.byId[chain.aeonic.s2.id] == nil)
        end
    end)

    it('maps forged damage Aeonics to REMA AEONIC entries', function()
        for index = 1, #weaponForge.chains do
            local forged = forge.weapons[index]
            local entry = rema.BY_ITEM_ID[forged.id]
            assert(entry ~= nil, string.format('Missing REMA entry for %s', forged.name))
            assert(entry.family == 'AEONIC')
            assert(entry.name == forged.name)
        end
    end)

    it('keeps Srivatsa and Marsyas on the repeat path outside damage-WS tuning', function()
        local shield = forge.weapons[#weaponForge.chains + 1]
        local harp   = forge.weapons[#weaponForge.chains + 2]
        assert(shield.id == 26403)
        assert(shield.name == 'Srivatsa')
        assert(harp.id == 21398)
        assert(harp.name == 'Marsyas')
        assert(rema.BY_ITEM_ID[shield.id] == nil)
        assert(rema.BY_ITEM_ID[harp.id] == nil)
    end)
end)
