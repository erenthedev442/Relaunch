local forge = require('modules/custom/lua/relic_forge_catalog')
local rema  = require('modules/custom/lua/rema_ws_tier_catalog')
local prime = require('modules/custom/lua/prime_ws_tuning_catalog')

describe('Relic Forge identifier alignment', function()
    it('forges the fourteen exact Relic 119 III damage items', function()
        assert(#forge.weapons == 16)

        for index = 1, 14 do
            local forged = forge.weapons[index]
            local entry = rema.BY_ITEM_ID[forged.id]
            assert(entry ~= nil, string.format('Missing REMA entry for %s', forged.name))
            assert(entry.family == 'RELIC')
            assert(entry.name == forged.name)
            assert(entry.enabled)
        end
    end)

    it('never reuses a Stage-5 Prime identifier', function()
        local primeIds = {}
        for _, entry in pairs(prime.PRIME_WS_TUNING) do
            primeIds[entry.itemId] = true
        end

        for _, forged in ipairs(forge.weapons) do
            assert(not primeIds[forged.id], string.format(
                '%s still collides with a Prime item ID %d', forged.name, forged.id))
        end
    end)

    it('keeps support Relics outside damage-WS tuning', function()
        assert(forge.weapons[15].name == 'Aegis')
        assert(forge.weapons[16].name == 'Gjallarhorn')
        assert(rema.BY_ITEM_ID[forge.weapons[15].id] == nil)
        assert(rema.BY_ITEM_ID[forge.weapons[16].id] == nil)
    end)
end)
