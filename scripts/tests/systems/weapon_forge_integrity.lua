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

    it('uses retail final-Abyssea materials and quantities for Empyreans', function()
        local expected =
        {
            Verethragna = 3288, Twashtar = 3287, Almace = 3289,
            Caladbolg = 3290, Farsha = 3291, Ukonvasara = 3287,
            Redemption = 3288, Rhongomiant = 3288, Kannagi = 3289,
            Masamune = 3290, Gambanteinn = 3291, Hvergelmir = 3292,
            Gandiva = 3291, Armageddon = 3290,
        }

        assert(catalog.empyreanCosts[1].mat == 75)
        assert(catalog.empyreanCosts[3].boulder == 3000)
        for _, chain in ipairs(catalog.empyreanChains) do
            assert(chain.mat == expected[chain.name],
                string.format('%s does not use its retail final-Abyssea material', chain.name))
            assert(catalog.empyreanMatNames[chain.mat] ~= nil)
            assert(chain.mat ~= 3498 and chain.mat ~= 3499)
        end
    end)

    it('uses each Relic family currency for the 50/100/500 ladder', function()
        local expected =
        {
            Spharai = { 1456, 1457 }, Mandau = { 1456, 1457 },
            Bravura = { 1456, 1457 }, Kikoku = { 1456, 1457 },
            Annihilator = { 1456, 1457 },
            Guttler = { 1450, 1451 }, Apocalypse = { 1450, 1451 },
            Gungnir = { 1450, 1451 }, Claustrum = { 1450, 1451 },
            Excalibur = { 1453, 1454 }, Ragnarok = { 1453, 1454 },
            Amanomurakumo = { 1453, 1454 }, Mjollnir = { 1453, 1454 },
            Yoichinoyumi = { 1453, 1454 },
        }

        assert(catalog.relicBase.relicCurrency == 50)
        assert(catalog.relicCosts[1].relicCurrency == 50)
        assert(catalog.relicCosts[2].relicCurrency == 100)
        assert(catalog.relicCosts[2].pluton == 200)
        assert(catalog.relicCosts[3].relicCurrency == 500)
        assert(catalog.relicCosts[3].highTierAlt == 5)
        assert(catalog.relicCosts[3].pluton == 500)
        assert(catalog.relicCosts[3].marks == 10000)
        assert(catalog.relicBase.byne == nil)
        for _, cost in ipairs(catalog.relicCosts) do
            assert(cost.byne == nil)
            assert(cost.silverpiece == nil)
            assert(cost.jadeshell == nil)
        end

        for _, chain in ipairs(catalog.relicChains) do
            local currencies = expected[chain.name]
            assert(currencies ~= nil, string.format('Missing expected Relic currency for %s', chain.name))
            assert(chain.currency == currencies[1])
            assert(chain.highCurrency == currencies[2])
            assert(chain.currency ~= 1449, string.format('%s still uses Tukuku Whiteshell', chain.name))
        end
    end)

    it('requires a final Aeonic before entering the Prime path', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        local ok, gate = gates.checkGate(player, 'prime', 0)
        assert(not ok)
        assert(gate ~= nil)

        vars.WF_Relic_Final = 1
        ok = gates.checkGate(player, 'prime', 0)
        assert(not ok)

        vars.WF_Aeonic_Final = 1
        ok = gates.checkGate(player, 'prime', 0)
        assert(ok)
    end)

    it('requires the first-Empyrean roster and Apocalypse at the final stage', function()
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
        assert(not ok)

        vars.GM_Wave_Clears = 63
        ok = gates.checkGate(player, 'empyrean', 2)
        assert(ok)

        vars = { WF_Empyrean_Final = 1, GM_Wave_Clears = 63 }
        ok = gates.checkGate(player, 'empyrean', 2)
        assert(ok)
    end)

    it('places the linear Wave Master clears on the weapon ladder', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        assert(not gates.checkGate(player, 'relic', 2))
        vars.GM_Wave_Clears = 31
        assert(gates.checkGate(player, 'relic', 2))

        vars.Gauntlet_Clears = 1
        assert(not gates.checkGate(player, 'mythic', 2))
        vars.GM_Wave_Clears = 63
        assert(gates.checkGate(player, 'mythic', 2))

        assert(not gates.checkGate(player, 'prime', 2))
        vars.GM_Wave_Clears = 255
        assert(gates.checkGate(player, 'prime', 2))
    end)
end)
