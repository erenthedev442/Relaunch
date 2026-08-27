local nmCatalog       = require('modules/custom/lua/affinity_nm_catalog')
local affinityCatalog = require('modules/custom/lua/augment_affinity_catalog')

describe('Affinity NM roster and progression integrity', function()
    it('defines 24 unique, fully routable collection targets', function()
        assert(#nmCatalog.entries == 24)

        local ids   = {}
        local names = {}
        for index, entry in ipairs(nmCatalog.entries) do
            assert(entry.index == index)
            assert(not ids[entry.mobId], 'duplicate mob ID ' .. entry.mobId)
            assert(not names[entry.name], 'duplicate NM name ' .. entry.name)
            assert(nmCatalog.profiles[entry.band] ~= nil)
            assert(entry.zoneId > 0)
            assert(type(entry.zoneOverride) == 'string' and entry.zoneOverride ~= '')
            assert(type(entry.x) == 'number')
            assert(type(entry.y) == 'number')
            assert(type(entry.z) == 'number')
            ids[entry.mobId] = true
            names[entry.name] = true
        end
    end)

    it('places relocated Affinity NMs at their retail homes', function()
        local homes =
        {
            Behemoth         = { zone = xi.zone.BEHEMOTHS_DOMINION,    mobId = 17298309 },
            King_Arthro      = { zone = xi.zone.JUGNER_FOREST,         mobId = 17204087 },
            Aspidochelone    = { zone = xi.zone.VALLEY_OF_SORROWS,     mobId = 17302414 },
            Vrtra            = { zone = xi.zone.KING_RANPERRES_TOMB,   mobId = 17556374 },
            Tiamat           = { zone = xi.zone.ATTOHWA_CHASM,         mobId = 16806807 },
            Khimaira         = { zone = xi.zone.CAEDARVA_MIRE,         mobId = 17101721 },
            Cerberus         = { zone = xi.zone.MOUNT_ZHAYOLM,         mobId = 17027994 },
            Absolute_Virtue  = { zone = xi.zone.ALTAIEU,               mobId = 16913307 },
            ['Proto-Omega']  = { zone = xi.zone.SEALIONS_DEN,          mobId = 16909196 },
        }

        for name, home in pairs(homes) do
            local entry = nmCatalog.byName(name)
            assert(entry ~= nil, 'missing ' .. name)
            assert(entry.zoneId == home.zone, name .. ' zone')
            assert(entry.mobId == home.mobId, name .. ' mobId')
        end
    end)

    it('maps exactly the 11 live Sage affinities to collection targets', function()
        local mapped = {}
        local count  = 0
        for _, entry in ipairs(nmCatalog.entries) do
            if entry.registerCat then
                local affinity = affinityCatalog.byCat(entry.registerCat)
                assert(affinity ~= nil)
                assert(affinity.nm == entry.name)
                assert(not mapped[entry.registerCat])
                mapped[entry.registerCat] = true
                count = count + 1
            end
        end

        assert(count == #affinityCatalog.affinities)
        assert(count == 11)
    end)

    it('uses increasing solo-with-trust difficulty and reward bands', function()
        local order = { 'intro', 'standard', 'veteran', 'apex' }
        local expectedFirst = { 90, 150, 225, 300 }
        local expectedRepeat = { 5, 8, 10, 12 }
        local expectedHp = { 800000, 1200000, 1800000, 2500000 }

        assert(nmCatalog.level == 99)
        assert(nmCatalog.ccCaps[xi.effect.PETRIFICATION] == 8)
        assert(nmCatalog.ccCaps[xi.effect.TERROR] == 6)
        assert(nmCatalog.ccCaps[xi.effect.DOOM] == 15)

        for index, key in ipairs(order) do
            local profile = nmCatalog.profiles[key]
            assert(profile.firstMarks == expectedFirst[index])
            assert(profile.repeatMarks == expectedRepeat[index])
            assert(profile.hp == expectedHp[index])
            assert(profile.hp > 79999)
            if index > 1 then
                local previous = nmCatalog.profiles[order[index - 1]]
                assert(profile.hp > previous.hp)
                assert(profile.mods[xi.mod.ATT] > previous.mods[xi.mod.ATT])
                assert(profile.mods[xi.mod.ACC] > previous.mods[xi.mod.ACC])
            end
        end
    end)

    it('keeps one-time and repeat mark budgets bounded', function()
        local firstTotal = 0
        for _, entry in ipairs(nmCatalog.entries) do
            firstTotal = firstTotal + nmCatalog.profiles[entry.band].firstMarks
        end
        assert(firstTotal == 4290)

        local milestoneTotal = 0
        for threshold, milestone in pairs(nmCatalog.milestones) do
            assert(threshold == 6 or threshold == 12 or threshold == 18 or threshold == 24)
            milestoneTotal = milestoneTotal + milestone.marks
        end
        assert(milestoneTotal == 975)
        assert(nmCatalog.repeatDailyCap == 120)
        assert(nmCatalog.milestones[24].title == xi.title.MASTER_HUNTER)
    end)
end)
