local catalog = require('modules/custom/lua/weapon_forge_catalog')
local gates = require('modules/custom/lua/weapon_forge_gates')

describe('Weapon Forge catalog and gate integrity', function()
    it('keeps every Prime and Aeonic chain complete with unique item IDs', function()
        local ids = {}

        assert(#catalog.chains == 14)
        for _, chain in ipairs(catalog.chains) do
            assert(chain.s1 and chain.s2 and chain.s3 and chain.aeonic)
            for _, item in ipairs({
                chain.s1, chain.s2, chain.s3, chain.aeonic.base, chain.aeonic.s3,
            }) do
                assert(item.id > 0 and item.name ~= '')
                assert(not ids[item.id], string.format('duplicate weapon ID %d', item.id))
                ids[item.id] = true
            end
        end
    end)

    it('uses the intended live Prime costs', function()
        assert(catalog.costs.toStage2.hlRank == 5)
        assert(catalog.costs.toStage2.medals.id == 9541)
        assert(catalog.costs.toStage2.medals.qty == 50)
        assert(catalog.costs.toStage3.hlRank == 5)
        assert(catalog.costs.toStage3.medals.id == 9543)
        assert(catalog.costs.toStage3.medals.qty == 100)
        assert(catalog.costs.toStage3.reforgeMarks == 30000)
        assert(catalog.costs.toStage3.gil == 750000000)
    end)

    it('requires a prior final weapon before entering the Prime path', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        local ok, gate = gates.checkGate(player, 'prime', 0)
        assert(not ok)
        assert(gate ~= nil)

        vars.WF_Aeonic_Final = 1
        ok = gates.checkGate(player, 'prime', 0)
        assert(ok)
    end)

    it('requires the Abyssea roster only for the first completed Empyrean', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        local ok, gate = gates.checkGate(player, 'empyrean', 2)
        assert(not ok)
        assert(gate ~= nil)

        for index = 1, 136 do
            vars[string.format('AbyNM_%03d', index)] = 1
        end
        ok = gates.checkGate(player, 'empyrean', 2)
        assert(ok)

        vars = { WF_Empyrean_Final = 1 }
        ok = gates.checkGate(player, 'empyrean', 2)
        assert(ok)
    end)
end)
