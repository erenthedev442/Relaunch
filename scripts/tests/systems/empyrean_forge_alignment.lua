local forge = require('modules/custom/lua/empyrean_forge_catalog')
local rema  = require('modules/custom/lua/rema_ws_tier_catalog')

describe('Empyrean Forge identifier alignment', function()
    it('offers all final Empyrean weapons plus Ochain and Daurdabla', function()
        assert(#forge.weapons == 16)
        assert(forge.currencyId == 4061)
        assert(forge.cost == 2500)

        for index = 1, 14 do
            local forged = forge.weapons[index]
            local entry = rema.BY_ITEM_ID[forged.id]
            assert(entry ~= nil, string.format('Missing REMA entry for %s', forged.name))
            assert(entry.family == 'EMPYREAN')
            assert(entry.name == forged.name)
        end

        assert(forge.weapons[15].id == 11926)
        assert(forge.weapons[15].name == 'Ochain')
        assert(forge.weapons[16].id == 18839)
        assert(forge.weapons[16].name == 'Daurdabla')
        assert(rema.BY_ITEM_ID[11926] == nil)
        assert(rema.BY_ITEM_ID[18839] == nil)
    end)
end)
