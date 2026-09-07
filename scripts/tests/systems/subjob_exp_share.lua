local rebirth = require('modules/custom/lua/job_rebirth_catalog')
require('modules/custom/lua/subjob_exp_share')

describe('Subjob EXP share vs Job Rebirth', function()
    local function makePlayer(options)
        options = options or {}
        local vars      = options.vars or {}
        local localVars = {}

        return
        {
            getSubJob = function()
                return options.sjob or xi.job.WAR
            end,
            getCharVar = function(_, key)
                return vars[key] or 0
            end,
            getLocalVar = function(_, key)
                return localVars[key] or 0
            end,
            setLocalVar = function(_, key, value)
                localVars[key] = value
            end,
            printToPlayer = function()
            end,
        }
    end

    it('lets a never-reborn job level as a sub', function()
        local player = makePlayer({ sjob = xi.job.THF })
        assert(xi.subjobExp.canShare(player, xi.job.THF))
    end)

    it('blocks a reborn job from taking subjob EXP', function()
        local player = makePlayer({
            sjob = xi.job.THF,
            vars = { [rebirth.countKey(xi.job.THF)] = 3 },
        })
        assert(not xi.subjobExp.canShare(player, xi.job.THF))
        assert(rebirth.hasRebirth(player, xi.job.THF))
    end)
end)
