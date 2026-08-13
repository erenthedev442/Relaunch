local catalog = require('modules/custom/lua/weapon_forge_catalog')
local gates = require('modules/custom/lua/weapon_forge_gates')
local aeonicMaat = require('modules/custom/lua/aeonic_maat_catalog')

describe('Weapon Forge catalog and gate integrity', function()
    it('keeps every Prime and Aeonic chain complete with unique item IDs', function()
        local ids = {}

        assert(#catalog.chains == 14)
        for _, chain in ipairs(catalog.chains) do
            assert(chain.s1 and chain.s2 and chain.s3 and chain.aeonic)
            for _, item in ipairs({
                chain.s1, chain.s2, chain.s3, chain.aeonic.base,
                chain.aeonic.s1, chain.aeonic.s2, chain.aeonic.s3,
            }) do
                assert(item.id > 0 and item.name ~= '')
                assert(not ids[item.id], string.format('duplicate weapon ID %d', item.id))
                ids[item.id] = true
            end
        end
    end)

    it('keeps every Aeonic stage on the Aeonic route', function()
        for _, chain in ipairs(catalog.chains) do
            for stage, item in ipairs({ chain.aeonic.base, chain.aeonic.s1, chain.aeonic.s2 }) do
                local entry = catalog.byId[item.id]
                assert(entry ~= nil)
                assert(entry.path == 'aeonic')
                assert(entry.fromStage == stage - 1)
                assert(entry.chain == chain)
            end
        end
    end)

    it('maps every final Aeonic to one unique job-restricted Maat trial', function()
        assert(#aeonicMaat.trials == #catalog.chains)
        local seen = {}
        for _, chain in ipairs(catalog.chains) do
            local trial = aeonicMaat.byFinalId[chain.aeonic.s3.id]
            assert(trial ~= nil, string.format('Missing Maat trial for %s', chain.aeonic.s3.name))
            assert(trial.empoweredId == chain.aeonic.s2.id)
            assert(trial.name == chain.aeonic.s3.name)
            assert(#trial.jobs > 0)
            assert(aeonicMaat.jobList(trial) == chain.jobs,
                string.format('%s trial jobs drifted from forge jobs', trial.name))
            assert(not seen[trial.mechanic], string.format('Duplicate mechanic %s', trial.mechanic))
            seen[trial.mechanic] = true
        end
    end)

    it('requires the matching solo Maat victory for the final Aeonic forge', function()
        local chain = catalog.chains[2] -- Aeneas
        local vars =
        {
            Dungeon_Unique_Clears = 7,
            GM_Wave_Clears = 127,
            Maat_Kills = 999,
        }
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        local oldInstances = xi.dungeonInstances
        xi.dungeonInstances = { uniqueDungeonCount = 7 }

        assert(not gates.checkGate(player, 'aeonic', 2, chain))
        vars[aeonicMaat.completionVar(chain.aeonic.s3.id)] = xi.job.BRD
        assert(gates.checkGate(player, 'aeonic', 2, chain))

        -- Aeneas credit must not satisfy another weapon's final gate.
        assert(not gates.checkGate(player, 'aeonic', 2, catalog.chains[1]))
        xi.dungeonInstances = oldInstances
    end)

    it('admits only a solo allowed job carrying the matching Empowered weapon', function()
        local trial = aeonicMaat.byFinalId[20594] -- Aeneas
        local jobId = xi.job.BRD
        local hasWeapon = true
        local otherPlayer = false
        local selfMember = { isPC = function() return true end, getID = function() return 1 end }
        local trustMember = { isPC = function() return false end, getID = function() return 2 end }
        local otherMember = { isPC = function() return true end, getID = function() return 3 end }
        local player = {}
        function player:getID() return 1 end
        function player:getMainJob() return jobId end
        function player:getItemCount(id) return hasWeapon and id == trial.empoweredId and 1 or 0 end
        function player:getParty()
            return otherPlayer and { selfMember, trustMember, otherMember } or { selfMember, trustMember }
        end
        function player:getAlliance() return {} end

        assert(aeonicMaat.canEnter(player, trial))

        jobId = xi.job.WAR
        local ok, reason = aeonicMaat.canEnter(player, trial)
        assert(not ok and reason == 'wrong_job')

        jobId = xi.job.BRD
        hasWeapon = false
        ok, reason = aeonicMaat.canEnter(player, trial)
        assert(not ok and reason == 'missing_weapon')

        hasWeapon = true
        otherPlayer = true
        ok, reason = aeonicMaat.canEnter(player, trial)
        assert(not ok and reason == 'grouped')
    end)

    it('places Aeonic after completed Relic, Empyrean, and Mythic paths', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        assert(not gates.checkGate(player, 'aeonic', 0))
        vars.WF_Relic_Final = 1
        vars.WF_Empyrean_Final = 1
        vars.WF_Mythic_Final = 1
        assert(not gates.checkGate(player, 'aeonic', 0))
        vars.Rebirth_Count_1 = 50
        assert(gates.checkGate(player, 'aeonic', 0))
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

    it('keeps Aeonic currency time above the prior REMA paths', function()
        local costs = catalog.aeonicCosts
        assert(catalog.aeonicBase.eschaBeads == 50000)
        assert(costs.toStage1.eschaSilt + costs.toStage2.eschaSilt + costs.toStage3.eschaSilt == 50000)
        assert(costs.toStage1.attestations + costs.toStage2.attestations + costs.toStage3.attestations == 6)
        assert(costs.toStage3.reforgeMarks == 24000)
        assert(costs.toStage1.hlRank == 5 and costs.toStage2.hlRank == 5 and costs.toStage3.hlRank == 5)
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
