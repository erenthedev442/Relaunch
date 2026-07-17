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

    it('requires the Rank 3 roster, Voidspire, and every GM wave for T3', function()
        local vars = { HL_Tier = 3 }
        stampTier(vars, 2)
        stampTier(vars, 3)
        local player = makePlayer(vars, 99)

        vars.Voidspire_Best_Floor = 10
        vars.GM_Wave_Clears = 30
        assert(xi.augmentTiers.tierOf(player) == 2)

        vars.GM_Wave_Clears = 31
        vars.NMKilled_11363 = 0
        assert(xi.augmentTiers.tierOf(player) == 2)

        vars.NMKilled_11363 = 1
        assert(xi.augmentTiers.tierOf(player) == 3)
    end)

    it('requires the Rank 4 roster and a Disjoined full clear for T4', function()
        local vars =
        {
            HL_Tier = 4,
            Voidspire_Best_Floor = 10,
            GM_Wave_Clears = 31,
            DivergenceMegaSlots = 1,
        }
        stampTier(vars, 2)
        stampTier(vars, 3)
        stampTier(vars, 4)
        local player = makePlayer(vars, 99)

        assert(xi.augmentTiers.tierOf(player) == 3)

        vars.DivergenceSlots = 1
        assert(xi.augmentTiers.tierOf(player) == 4)
    end)

    it('keeps Maat as the final consecutive gate without Rank 5 NMs', function()
        local vars =
        {
            HL_Tier = 4,
            Voidspire_Best_Floor = 10,
            GM_Wave_Clears = 31,
            DivergenceSlots = 1,
            Maat_Kills = 1,
        }
        stampTier(vars, 2)
        stampTier(vars, 3)
        stampTier(vars, 4)

        assert(xi.augmentTiers.tierOf(makePlayer(vars, 99)) == 5)
    end)
end)
