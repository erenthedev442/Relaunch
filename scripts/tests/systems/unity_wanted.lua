local catalog = require('modules/custom/lua/unity_wanted_catalog')
local junctions = require('modules/custom/lua/unity_junction_map')
local mechanics = require('modules/custom/lua/unity_wanted_mechanics')
local progress = require('modules/custom/lua/unity_wanted_progress')
local forgeGates = require('modules/custom/lua/weapon_forge_gates')

local function testPlayer()
    local player = { vars = {} }
    function player:getCharVar(name)
        return self.vars[name] or 0
    end
    return player
end

local function conquerTier(player, tier)
    for _, nm in ipairs(catalog.nms) do
        if nm.tier == tier then
            player.vars['UW_Conq_' .. nm.id] = 1
        end
    end
end

describe('Unity Wanted progression', function()
    it('keeps the intended three-tier roster', function()
        assert(#catalog.nms == 56)
        assert(progress.tierTotals[1] == 21)
        assert(progress.tierTotals[2] == 16)
        assert(progress.tierTotals[3] == 19)
    end)

    it('unlocks each upper tier only after the previous roster', function()
        local player = testPlayer()
        assert(progress.isTierUnlocked(player, 1))
        assert(not progress.isTierUnlocked(player, 2))
        assert(not progress.isTierUnlocked(player, 3))

        conquerTier(player, 1)
        assert(progress.isTierUnlocked(player, 2))
        assert(not progress.isTierUnlocked(player, 3))

        conquerTier(player, 2)
        assert(progress.isTierUnlocked(player, 3))
    end)

    it('keeps Tumult Curator behind its retail king prerequisites', function()
        local player = testPlayer()
        conquerTier(player, 2)
        local tumult
        for _, nm in ipairs(catalog.nms) do
            if nm.name == 'Tumult_Curator' then tumult = nm end
        end

        assert(tumult and tumult.tier == 3)
        assert(not progress.isNmUnlocked(player, tumult))
        player.vars.UW_Conq_43 = 1
        player.vars.UW_Conq_52 = 1
        assert(progress.isNmUnlocked(player, tumult))
    end)

    it('uses T2 and T3 completion for the first two Relic stages', function()
        local player = testPlayer()
        assert(not forgeGates.STAGE_GATES.relic[0].check(player))
        assert(not forgeGates.STAGE_GATES.relic[1].check(player))

        conquerTier(player, 2)
        assert(forgeGates.STAGE_GATES.relic[0].check(player))
        assert(not forgeGates.STAGE_GATES.relic[1].check(player))

        conquerTier(player, 3)
        assert(forgeGates.STAGE_GATES.relic[1].check(player))
    end)
end)

describe('Unity Wanted encounter invariants', function()
    it('gives every T2 and T3 mark a mechanics profile', function()
        local upperTierCount = 0
        for _, nm in ipairs(catalog.nms) do
            if nm.tier >= 2 then
                upperTierCount = upperTierCount + 1
                assert(mechanics.hasProfile(nm.name), nm.name .. ' has no mechanics profile')
            end
        end

        assert(upperTierCount == 35)
        assert(mechanics.profileCount() == upperTierCount)
    end)

    it('keeps Grand Grenade movement outside Self-Destruct range', function()
        local profile = mechanics.profiles.Grand_Grenade
        assert(profile)
        assert(profile.farDistance == 22)
    end)

    it('makes T3 distinctly harder than T2 without changing T1 entry balance', function()
        local t1 = catalog.difficulty[1]
        local t2 = catalog.difficulty[2]
        local t3 = catalog.difficulty[3]
        assert(t1.hp == 250000)
        assert(t2.hp > t1.hp)
        assert(t3.hp > t2.hp)
        assert(t3.att > t2.att)
        assert(t3.macc > t2.macc)
        assert(t3.mdef > t2.mdef)
        assert(t3.regain > t2.regain)
    end)

    it('keeps Shedu execute pressure bounded for solo/trust play', function()
        local shedu
        for _, nm in ipairs(catalog.nms) do
            if nm.name == 'Shedu' then
                shedu = nm
                break
            end
        end
        assert(shedu ~= nil)

        local profile = mechanics.resolveDifficulty(shedu, catalog.difficulty)
        assert(profile.regain == 200)
        assert(profile.regain < catalog.difficulty[3].regain)
        assert(profile.hp == catalog.difficulty[3].hp)
        assert(shedu.skillList == 9702)
        assert(shedu.lowHpSkillList == 9708)
        assert(shedu.lowHpThreshold == 37)
    end)

    it('maps every mark to a visible non-origin junction and safe board warp', function()
        for _, nm in ipairs(catalog.nms) do
            local zoneId = junctions.byNm[nm.name]
            local zone = zoneId and junctions.junctions[zoneId]
            assert(zone and zone.points and #zone.points > 0, nm.name .. ' has no junction')

            local first = zone.points[1]
            assert(first.x ~= 0 or first.z ~= 0, nm.name .. ' warps to the origin')
            for _, point in ipairs(zone.points) do
                assert(point.custom or point.id > 0, nm.name .. ' has an invalid junction entity')
            end
        end
    end)

    it('keeps reported custom junctions at their corrected anchors', function()
        local expected =
        {
            [ 68] = { x =  -98.7150, z = -92.8438 },
            [ 79] = { x = -716.9192, z = 340.5056 },
            [119] = { x = -315.0, z = 405.0 },
            [159] = { x =  215.75, z = -25.0 },
            [176] = { x =  179.3713, z = 241.6031 },
            [212] = { x =  145.6993, z = -36.2936 },
        }

        for zoneId, position in pairs(expected) do
            local point = junctions.junctions[zoneId].points[1]
            assert(point.custom)
            assert(point.x == position.x)
            assert(point.z == position.z)
        end
    end)
end)
