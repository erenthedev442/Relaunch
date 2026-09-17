require('scripts/globals/dynamis_divergence')
local travelGuard = require('modules/custom/lua/travel_guard')

describe('Dynamis Divergence abandoned copies', function()
    local function makeInstance(opts)
        opts = opts or {}
        local inst =
        {
            id         = opts.id or 29700,
            wipeTime   = opts.wipeTime or 0,
            chars      = opts.chars or {},
            isFailed   = opts.failed or false,
            isComplete = opts.completed or false,
        }

        inst.getID = function()
            return inst.id
        end
        inst.getWipeTime = function()
            return inst.wipeTime
        end
        inst.getChars = function()
            return inst.chars
        end
        inst.failed = function()
            return inst.isFailed
        end
        inst.completed = function()
            return inst.isComplete
        end
        inst.fail = function()
            inst.isFailed = true
        end

        return inst
    end

    it('fails an empty leftover after the last player left', function()
        local leftover = makeInstance({ wipeTime = 5000, chars = {} })
        assert(xi.divergence.shouldFailAbandoned(leftover))
    end)

    it('does not fail a fresh copy waiting for the opener to zone in', function()
        local fresh = makeInstance({ wipeTime = 0, chars = {} })
        assert(not xi.divergence.shouldFailAbandoned(fresh))
    end)

    it('does not fail a living run', function()
        local live = makeInstance({
            wipeTime = 0,
            chars = { { name = 'Kana' } },
        })
        assert(not xi.divergence.shouldFailAbandoned(live))
    end)

    it('does not fail an already completed copy', function()
        local done = makeInstance({ wipeTime = 8000, chars = {}, completed = true })
        assert(not xi.divergence.shouldFailAbandoned(done))
    end)
end)

describe('Instance waypoint guard', function()
    local function makePlayer(opts)
        opts = opts or {}
        local messages = {}
        return
        {
            messages   = messages,
            gm         = opts.gm or 0,
            zoneId     = opts.zoneId or xi.zone.RULUDE_GARDENS,
            instance   = opts.instance,
            getGMLevel = function(self)
                return self.gm
            end,
            getZoneID = function(self)
                return self.zoneId
            end,
            getInstance = function(self)
                return self.instance
            end,
            printToPlayer = function(_, text)
                messages[#messages + 1] = text
            end,
        }
    end

    it('blocks saving or warping into Dynamis [D] from outside', function()
        local outside = makePlayer({ zoneId = xi.zone.RULUDE_GARDENS })
        assert(travelGuard.refuseInstanceTravel(outside, xi.zone.DYNAMIS_JEUNO_D))
        assert(#outside.messages > 0)
    end)

    it('blocks saving a waypoint while standing in Dynamis [D]', function()
        local inside = makePlayer({
            zoneId   = xi.zone.DYNAMIS_JEUNO_D,
            instance = { id = 29700 },
        })
        assert(travelGuard.refuseInstanceSave(inside))
        assert(#inside.messages > 0)
    end)

    it('lets a player already inside reposition in the same copy', function()
        local inside = makePlayer({
            zoneId   = xi.zone.DYNAMIS_JEUNO_D,
            instance = { id = 29700 },
        })
        assert(not travelGuard.refuseInstanceTravel(inside, xi.zone.DYNAMIS_JEUNO_D))
    end)

    it('lets GMs through', function()
        local gm = makePlayer({ zoneId = xi.zone.RULUDE_GARDENS, gm = 1 })
        assert(not travelGuard.refuseInstanceTravel(gm, xi.zone.DYNAMIS_JEUNO_D))
    end)

    it('does not block ordinary city warps', function()
        local player = makePlayer({ zoneId = xi.zone.BASTOK_MINES })
        assert(not travelGuard.refuseInstanceTravel(player, xi.zone.RULUDE_GARDENS))
    end)
end)
