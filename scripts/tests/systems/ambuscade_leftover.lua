require('scripts/globals/ambuscade')

describe('Ambuscade leftover copies', function()
    local legionB = xi.zone.MAQUETTE_ABDHALJS_LEGION_B
    local mhaura  = xi.zone.MHAURA

    local function makePc(opts)
        opts = opts or {}
        return
        {
            getObjType = function()
                return xi.objType.PC
            end,
            getZoneID = function()
                return opts.zoneId or legionB
            end,
            getHP = function()
                return opts.hp or 1000
            end,
            isDead = function()
                return (opts.hp or 1000) == 0
            end,
        }
    end

    local function makeInstance(opts)
        opts = opts or {}
        local inst =
        {
            id        = opts.id or 30000,
            progress  = opts.progress or 1,
            wipeTime  = opts.wipeTime or 0,
            timeLimit = opts.timeLimit or 30,
            chars     = opts.chars or {},
            vars      = {},
            isFailed  = opts.failed or false,
            isComplete = opts.completed or false,
        }

        inst.getID = function()
            return inst.id
        end
        inst.getProgress = function()
            return inst.progress
        end
        inst.getWipeTime = function()
            return inst.wipeTime
        end
        inst.getTimeLimit = function()
            return inst.timeLimit
        end
        inst.getChars = function()
            return inst.chars
        end
        inst.completed = function()
            return inst.isComplete
        end
        inst.failed = function()
            return inst.isFailed
        end
        inst.setLocalVar = function(_, name, value)
            inst.vars[name] = value
        end
        inst.getLocalVar = function(_, name)
            return inst.vars[name] or 0
        end
        inst.fail = function()
            inst.isFailed = true
        end

        return inst
    end

    it('does not treat an empty leftover as a battle in progress', function()
        local leftover = makeInstance({ progress = 1, chars = {} })
        assert(not xi.ambuscade.hasLivingOccupants(leftover))
        assert(xi.ambuscade.closeLeftover(leftover))
        assert(leftover.isFailed)
        assert(leftover.vars.Amb_Abandoned == 1)
    end)

    it('does not treat an all-dead wipe as a battle in progress', function()
        local leftover = makeInstance({
            progress = 2,
            chars = { makePc({ hp = 0 }) },
        })
        assert(not xi.ambuscade.hasLivingOccupants(leftover))
        assert(xi.ambuscade.closeLeftover(leftover))
        assert(leftover.isFailed)
    end)

    it('leaves a living mid-fight copy alone', function()
        local live = makeInstance({
            progress = 1,
            chars = { makePc({ hp = 800 }) },
        })
        assert(xi.ambuscade.hasLivingOccupants(live))
        assert(not xi.ambuscade.closeLeftover(live))
        assert(not live.isFailed)
    end)

    it('ignores leftover chars who already zoned back to Mhaura', function()
        local leftover = makeInstance({
            chars = { makePc({ zoneId = mhaura, hp = 1000 }) },
        })
        assert(not xi.ambuscade.hasLivingOccupants(leftover))
        assert(xi.ambuscade.closeLeftover(leftover))
    end)

    it('fails an empty leftover on the wipe-time tick', function()
        local leftover = makeInstance({ wipeTime = 5000, chars = {} })
        assert(xi.ambuscade.tickInstance(leftover, 6000) == 'abandoned')
        assert(leftover.isFailed)
    end)

    it('does not fail a fresh copy before anyone has left', function()
        local fresh = makeInstance({ wipeTime = 0, chars = {} })
        assert(xi.ambuscade.tickInstance(fresh, 1000) == 'live')
        assert(not fresh.isFailed)
    end)

    it('fails when the 30-minute time limit expires', function()
        local fight = makeInstance({
            timeLimit = 30,
            chars = { makePc({ hp = 1000 }) },
        })
        assert(xi.ambuscade.tickInstance(fight, 30 * 60 * 1000) == 'timeout')
        assert(fight.isFailed)
    end)

    it('keeps a living fight live before the time limit', function()
        local fight = makeInstance({
            wipeTime = 0,
            chars = { makePc({ hp = 1000 }) },
        })
        assert(xi.ambuscade.tickInstance(fight, 60 * 1000) == 'live')
        assert(not fight.isFailed)
    end)
end)
