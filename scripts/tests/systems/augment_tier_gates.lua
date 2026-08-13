require('modules/custom/lua/Augment_Moogle')

local function makePlayer(vars, level)
    return
    {
        getJobLevel = function(_, jobId)
            return jobId == 1 and level or 0
        end,
        getCharVar = function(_, name)
            return vars[name] or 0
        end,
    }
end

local function stampTier(vars, tier)
    local rosters =
    {
        [2] = { 11358, 11359, 11360 },
        [3] = { 11361, 11362, 11363 },
        [4] = { 11364, 11365, 11366 },
    }

    for _, groupId in ipairs(rosters[tier]) do
        vars['NMKilled_' .. groupId] = 1
    end
end

describe('Augment Tier content gates', function()
    it('opens T1 at level 99', function()
        assert(xi.augmentTiers.tierOf(makePlayer({}, 98)) == 0)
        assert(xi.augmentTiers.tierOf(makePlayer({}, 99)) == 1)
    end)

    it('requires all Rank 2 NMs and promotion to Hunt Rank 3 for T2', function()
        local vars = { HL_Tier = 2 }
        stampTier(vars, 2)
        local player = makePlayer(vars, 99)

        assert(xi.augmentTiers.tierOf(player) == 1)

        vars.HL_Tier = 3
        vars.NMKilled_11360 = 0
        assert(xi.augmentTiers.tierOf(player) == 1)

        vars.NMKilled_11360 = 1
        assert(xi.augmentTiers.tierOf(player) == 2)
    end)

    it('requires the Rank 3 roster, Voidspire, and Easy through Hard for T3', function()
        local vars = { HL_Tier = 3 }
        stampTier(vars, 2)
        stampTier(vars, 3)
        local player = makePlayer(vars, 99)

        vars.Voidspire_Best_Floor = 10
        vars.GM_Wave_Clears = 6
        assert(xi.augmentTiers.tierOf(player) == 2)

        vars.GM_Wave_Clears = 7
        vars.NMKilled_11363 = 0
        assert(xi.augmentTiers.tierOf(player) == 2)

        vars.NMKilled_11363 = 1
        assert(xi.augmentTiers.tierOf(player) == 3)
    end)

    it('requires the Rank 4 roster, a Disjoined full clear, and Insane for T4', function()
        local vars =
        {
            HL_Tier = 4,
            Voidspire_Best_Floor = 10,
            GM_Wave_Clears = 7,
            DivergenceMegaSlots = 1,
        }
        stampTier(vars, 2)
        stampTier(vars, 3)
        stampTier(vars, 4)
        local player = makePlayer(vars, 99)

        assert(xi.augmentTiers.tierOf(player) == 3)

        vars.DivergenceSlots = 1
        assert(xi.augmentTiers.tierOf(player) == 3)

        vars.GM_Wave_Clears = 15
        assert(xi.augmentTiers.tierOf(player) == 4)
    end)

    it('keeps Maat as the final consecutive gate without Rank 5 NMs', function()
        local vars =
        {
            HL_Tier = 4,
            Voidspire_Best_Floor = 10,
            GM_Wave_Clears = 15,
            DivergenceSlots = 1,
            Maat_Kills = 1,
        }
        stampTier(vars, 2)
        stampTier(vars, 3)
        stampTier(vars, 4)

        assert(xi.augmentTiers.tierOf(makePlayer(vars, 99)) == 5)
    end)

    it('preserves an established T4/T5 roll band without fabricating wave clears', function()
        local vars = { Augment_Tier_Grandfather = 4 }
        local player = makePlayer(vars, 1)

        assert(xi.augmentTiers.tierOf(player) == 4)
        assert((player:getCharVar('GM_Wave_Clears') or 0) == 0)
    end)

    it('lets a grandfathered T4 player earn T5 from Maat', function()
        local vars =
        {
            Augment_Tier_Grandfather = 4,
            Maat_Kills = 1,
        }

        assert(xi.augmentTiers.tierOf(makePlayer(vars, 1)) == 5)
    end)

    it('reserves each capped augment ceiling for T5', function()
        for cap = 1, 31 do
            assert(xi.augmentTiers.scaleRoll(24, cap, 4) < cap)
            assert(xi.augmentTiers.scaleRoll(31, cap, 5) == cap)
        end
        assert(xi.augmentTiers.scaleRoll(31, 0, 5) == 0)
    end)
end)
