local catalog = require('modules/custom/lua/htbf_catalog')

local function entrancesFor(fight)
    if fight.entryNpcs then
        return fight.entryNpcs
    end

    return { fight.entryNpc }
end

describe('HTBF catalog integrity and balance', function()
    it('allows two, three, and four trusts plus the free Fellow', function()
        assert(catalog.trustCap[1] == 2)
        assert(catalog.trustCap[2] == 3)
        assert(catalog.trustCap[3] == 4)
        assert(catalog.firstClearMultiplier == 2)
    end)

    it('gives every fight three valid tiers and safe staging positions', function()
        local fightCount = 0

        for key, fight in pairs(catalog.fights) do
            fightCount = fightCount + 1

            assert(catalog.tierScale[fight.difficulty] ~= nil, key .. ' has no difficulty profile')
            assert(catalog.tierReward[fight.rewardClass] ~= nil, key .. ' has no reward class')
            assert(fight.entryPosByArea ~= nil, key .. ' has no staging positions')

            for tier = 1, 3 do
                assert(catalog.tierScale[fight.difficulty][tier] ~= nil)
                assert(catalog.tierReward[fight.rewardClass][tier] ~= nil)
            end

            if fight.allowedAreas then
                for area in pairs(fight.allowedAreas) do
                    assert(fight.entryPosByArea[area] ~= nil,
                        string.format('%s has no staging position for area %d', key, area))
                end
            else
                for area = 1, 3 do
                    assert(fight.entryPosByArea[area] ~= nil,
                        string.format('%s has no staging position for area %d', key, area))
                end
            end
        end

        assert(fightCount == 22)
    end)

    it('uses unique battlefield IDs and menu indices per entrance', function()
        local ids = {}
        local menuSlots = {}

        for key, fight in pairs(catalog.fights) do
            for tier = 1, 3 do
                local battlefieldId = fight.baseBattlefieldId + tier - 1
                assert(not ids[battlefieldId], string.format(
                    'battlefield ID %d is shared by %s and %s', battlefieldId, ids[battlefieldId] or '?', key))
                ids[battlefieldId] = key

                for _, entrance in ipairs(entrancesFor(fight)) do
                    local slotKey = string.format('%d:%s:%d', fight.zone, entrance, fight.baseIndex + tier - 1)
                    assert(not menuSlots[slotKey], string.format(
                        'menu slot %s is shared by %s and %s', slotKey, menuSlots[slotKey] or '?', key))
                    menuSlots[slotKey] = key
                end
            end
        end

        local final = catalog.finalTest
        local finalFight = catalog.fights[final.fightKey]
        assert(not ids[final.battlefieldId], 'Final Proving battlefield ID collides with a real HTBF')
        for _, entrance in ipairs(entrancesFor(finalFight)) do
            local slotKey = string.format('%d:%s:%d', finalFight.zone, entrance, final.index)
            assert(not menuSlots[slotKey], 'Final Proving menu slot collides with a real HTBF')
        end
    end)

    it('keeps repeat rewards below Hunting League weekly-objective payouts', function()
        assert(catalog.tierReward.simple[3].marks == 60)
        assert(catalog.tierReward.standard[3].marks == 100)
        assert(catalog.tierReward.epic[3].marks == 150)

        for _, rewards in pairs(catalog.tierReward) do
            for tier = 1, 3 do
                assert(rewards[tier].marks <= 150)
                assert(rewards[tier].gil <= 150000)
            end
        end
    end)

    it('keeps avatar durability distributed across stats rather than HP alone', function()
        local avatar = catalog.tierScale.avatar

        assert(avatar[3].hp == 16.0)
        assert(avatar[3].hp < 22.0)
        assert(avatar[3].def == 7500)
        assert(avatar[3].meva == 2600)
        assert(avatar[3].eva == 1900)
    end)

    it('uses a one-time half-strength Garuda test to unlock Tier III', function()
        local final = catalog.finalTest
        local t3    = catalog.tierScale.avatar[3]

        assert(final.fightKey == 'trial_by_wind')
        assert(final.battlefieldId == 4220)
        assert(final.index == catalog.fights.trial_by_wind.baseIndex + 3)
        assert(final.completionVar == 'HTBF_FinalTest_Done')
        assert(final.tierClearVar == 'HTBF_Cleared_T3')
        assert(final.scale.hp == t3.hp / 2)
        assert(final.scale.att == t3.att / 2)
        assert(final.scale.def == t3.def / 2)
        assert(final.scale.macc == t3.macc / 2)
        assert(final.scale.meva == t3.meva / 2)
        assert(final.scale.eva == t3.eva / 2)
    end)

    it('keeps incomplete ToAU arena placeholders disabled', function()
        assert(catalog.fights.puppet_in_peril.allowedAreas[1])
        assert(not catalog.fights.puppet_in_peril.allowedAreas[2])
        assert(catalog.fights.legacy_of_the_lost.allowedAreas[1])
        assert(not catalog.fights.legacy_of_the_lost.allowedAreas[2])
    end)

    it('uses safe staging layers for the reported mission battlefields', function()
        local warriors = catalog.fights.warriors_path.entryPosByArea
        local feared   = catalog.fights.one_to_be_feared.entryPosByArea
        local nexus    = catalog.fights.celestial_nexus.entryPosByArea

        for area = 1, 3 do
            assert(warriors[area][1] == feared[area][1])
            assert(warriors[area][2] == feared[area][2])
            assert(warriors[area][3] == feared[area][3])
            assert(warriors[area][4] == 193)
        end

        assert(warriors[1][1] == -780.010 and warriors[1][2] == -103.348)
        assert(warriors[2][1] == -140.029 and warriors[2][2] == -23.348)
        assert(warriors[3][1] == 499.969 and warriors[3][2] == 56.652)

        assert(nexus[1][3] == -35.0)
        assert(nexus[2][3] == 659.5)
        assert(nexus[3][3] == -680.2)
    end)
end)
