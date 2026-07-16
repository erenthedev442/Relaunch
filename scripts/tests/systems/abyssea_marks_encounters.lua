local catalog = require('modules/custom/lua/abyssea_marks_catalog')

describe('Abyssea marks bespoke encounter catalog', function()
    it('covers the complete logical QM roster by tier', function()
        assert(catalog.count(1) == 45)
        assert(catalog.count(2) == 49)
        assert(catalog.count(3) == 42)
        assert(catalog.count() == 136)
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
            assert(#entry.phases == 2)
            assert(entry.phases[1].hp == 70)
            assert(entry.phases[2].hp == 30)
            if entry.tier >= 2 then
                assert(entry.phases[2].kind ~= entry.signature.kind)
            end
            assert(entry.repeatSec > 0)
            assert(entry.pressureSec >= 720)
            assert(entry.drain == nil and entry.aoe == nil and entry.regen == nil)
        end
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
