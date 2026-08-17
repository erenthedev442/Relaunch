require('modules/custom/lua/bp_delay_uncap')

describe('Blood Pact delay progression', function()
    local function makeSummoner(delayI, delayII, favorPower)
        return
        {
            getMod = function(_, modId)
                if modId == xi.mod.BP_DELAY then
                    return delayI
                elseif modId == xi.mod.BP_DELAY_II then
                    return delayII
                end

                return 0
            end,
            getStatusEffect = function(_, effectId)
                if effectId ~= xi.effect.AVATARS_FAVOR or not favorPower then
                    return nil
                end

                return
                {
                    getPower = function()
                        return favorPower
                    end,
                }
            end,
        }
    end

    it('allows ordinary Blood Pact delay augments past the stock 15-second bucket', function()
        local summoner = makeSummoner(20, 0, nil)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 40)
    end)

    it('combines delay I, delay II and Avatars Favor', function()
        local summoner = makeSummoner(18, 7, 10)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 25)
    end)

    it('enforces the 20-second maximum-frequency floor', function()
        local augmented = makeSummoner(32, 7, 10)
        local overcapped = makeSummoner(99, 99, 99)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(augmented) == 20)
        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(overcapped) == 20)
    end)

    it('does not let malformed negative delay values increase recast', function()
        local summoner = makeSummoner(-3, -3, nil)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 60)
    end)
end)
