require('modules/custom/lua/bp_delay_uncap')

describe('Blood Pact delay progression', function()
    local function makeSummoner(delayI, delayII, favorPower, conduit)
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
            hasStatusEffect = function(_, effectId)
                return conduit and effectId == xi.effect.ASTRAL_CONDUIT
            end,
        }
    end

    it('uses a 20-second native recast before delay gear', function()
        local summoner = makeSummoner(0, 0, nil)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 20)
    end)

    it('allows ordinary Blood Pact delay augments past the stock 15-second bucket', function()
        local summoner = makeSummoner(8, 0, nil)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 12)
    end)

    it('combines delay I, delay II and Avatars Favor down to the 6-second floor', function()
        local summoner = makeSummoner(8, 3, 10)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 6)
    end)

    it('enforces the 6-second maximum-frequency floor', function()
        local augmented = makeSummoner(32, 7, 10)
        local overcapped = makeSummoner(99, 99, 99)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(augmented) == 6)
        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(overcapped) == 6)
    end)

    it('lets Astral Conduit ignore the normal Blood Pact floor', function()
        local summoner = makeSummoner(0, 0, nil, true)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 0)
    end)

    it('does not let malformed negative delay values increase recast', function()
        local summoner = makeSummoner(-3, -3, nil)

        assert(xi.job_utils.summoner.getRelaunchBloodPactRecast(summoner) == 20)
    end)
end)
