local catalog = require('modules/custom/lua/abyssea_marks_catalog')
local progress = require('modules/custom/lua/abyssea_marks_progress')

describe('Abyssea marks bespoke encounter catalog', function()
    it('covers the complete logical QM roster by tier', function()
        assert(catalog.count(1) == 52)
        assert(catalog.count(2) == 57)
        assert(catalog.count(3) == 43)
        assert(catalog.count() == 152)
    end)

    it('groups all 136 first-clear stamps into the nine Abyssea zones', function()
        assert(#progress.groups == 3)
        assert(#progress.zones == 9)

        local total = 0
        for _, zone in ipairs(progress.zones) do
            total = total + zone.total
            assert(zone.lastIndex - zone.firstIndex + 1 == zone.total)
        end
        assert(total == 136)
    end)

    it('reports cleared and missing NMs from lifetime first-clear stamps', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        local firstZone = progress.zones[1]
        local cleared, total = progress.zoneProgress(player, firstZone)
        assert(cleared == 0)
        assert(total == 15)
        assert(#progress.missingInZone(player, firstZone) == 15)

        for index = firstZone.firstIndex, firstZone.lastIndex do
            vars[progress.stampVar(index)] = 1
        end
        cleared = progress.zoneProgress(player, firstZone)
        assert(cleared == 15)
        assert(#progress.missingInZone(player, firstZone) == 0)
        assert(not progress.isComplete(player))
    end)

    it('normalizes alternate naming punctuation consistently', function()
        assert(catalog.get('Eccentric_Eve') == catalog.get('Eccentric Eve'))
        assert(catalog.get('Cirein-croin') == catalog.get('Cirein croin'))
        assert(catalog.get('Cep_Kamuy') == catalog.get('Cep-Kamuy'))
        assert(catalog.get('Ashtaerh_the_Gallvexed') ~= nil)
        assert(catalog.get('Pascerpot') ~= nil)
        assert(catalog.get('Vadleany') ~= nil)
    end)

    it('gives every NM a complete signature and two phase floors', function()
        local pressureByTier = { 240, 360, 480 }
        local validKinds =
        {
            turn = true, face = true, rear = true, near = true, far = true,
            move = true, hold = true, burst = true, weaponskill = true,
            highhp = true, lowhp = true, proc = true, physical = true, magic = true,
        }

        local seen = {}
        for _, entry in ipairs(catalog.ordered) do
            assert(not seen[entry.key])
            seen[entry.key] = true
            assert(entry.label and entry.label ~= '')
            assert(entry.signatureId == 'aby_' .. entry.key)
            assert(entry.signature and validKinds[entry.signature.kind])
            assert(entry.signature.tell and entry.signature.success and entry.signature.fail)
            assert(entry.signature.delaySec == 10)
            assert(entry.signature.reward.sec == 15)
            if entry.index <= progress.total then
                assert(entry.signature.failure.skill and entry.signature.failure.skill > 0)
            end
            assert(#entry.phases == 2)
            assert(entry.phases[1].hp == 70)
            assert(entry.phases[2].hp == 30)
            assert(entry.phases[2].delaySec == 10)
            assert(entry.phases[1].reward.sec == 15)
            assert(entry.phases[2].reward.sec == 15)
            if entry.index <= progress.total then
                assert(entry.phases[1].failure.skill == entry.signature.failure.skill)
                assert(entry.phases[2].failure.skill == entry.signature.failure.skill)
            end
            if entry.tier >= 2 then
                assert(entry.phases[2].kind ~= entry.signature.kind)
            end
            assert(entry.repeatSec > 0)
            assert(entry.pressureSec == pressureByTier[entry.tier])
            assert(entry.signature.failure.damagePct == nil)
            assert(entry.phases[2].failure.damagePct == nil)
            assert(entry.drain == nil and entry.aoe == nil and entry.regen == nil)
        end
    end)

    it('uses Death Scissors as Shaula failure punishment', function()
        local shaula = catalog.get('Shaula')
        assert(shaula.signature.failure.skill == 353)
        assert(shaula.signature.failure.tick == 3)
        assert(shaula.phases[1].failure.skill == 353)
        assert(shaula.phases[2].failure.skill == 353)
    end)

    it('contains the retail-inspired flagship encounters', function()
        for _, name in ipairs(
            {
                'Kukulkan', 'Eccentric Eve', 'Glavoid', 'Chloris', 'Briareus',
                'Carabosse', 'Hadhayosh', 'Smok', 'Ulhuadshi', 'Itzpapalotl',
                'Sobek', 'Bukhis', 'Durinn', 'Sedna', 'Orthrus', 'Dragua',
                'Bennu', 'Rani', 'Alfard', 'Azdaja', 'Raja', 'Amphitrite',
                'Pantokrator', 'Isgebind', 'Apademak', 'Resheph',
            })
        do
            assert(catalog.get(name) ~= nil, string.format('Missing flagship %s', name))
        end
    end)
end)
