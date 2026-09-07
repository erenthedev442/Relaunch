require('modules/custom/lua/abyssea_access')

describe('Abyssea access floor', function()
    local function makePlayer(level, gmLevel)
        return
        {
            getMainLvl = function()
                return level
            end,
            getGMLevel = function()
                return gmLevel or 0
            end,
            printToPlayer = function()
            end,
        }
    end

    it('blocks below 75 and allows 75+', function()
        assert(not xi.abyssea.canEnterAbyssea(makePlayer(1)))
        assert(not xi.abyssea.canEnterAbyssea(makePlayer(74)))
        assert(xi.abyssea.canEnterAbyssea(makePlayer(75)))
        assert(xi.abyssea.canEnterAbyssea(makePlayer(99)))
    end)

    it('lets GMs in below the floor', function()
        assert(xi.abyssea.canEnterAbyssea(makePlayer(1, 1)))
    end)

    it('does not call the enter function when refused', function()
        local entered = false
        local ok = xi.abyssea.tryEnter(makePlayer(10), function()
            entered = true
        end)
        assert(not ok)
        assert(not entered)
    end)

    it('treats custom waypoint destinations as Abyssea when they should', function()
        assert(xi.abyssea.isAbysseaZone(xi.zone.ABYSSEA_KONSCHTAT))
        assert(xi.abyssea.isAbysseaZone(xi.zone.ABYSSEA_EMPYREAL_PARADOX))
        assert(not xi.abyssea.isAbysseaZone(xi.zone.LOWER_JEUNO))
    end)

    it('refuses a waypoint into Abyssea and ejects if already there', function()
        local outside = makePlayer(1)
        outside.getZoneID = function()
            return xi.zone.LOWER_JEUNO
        end
        assert(xi.abyssea.refuseDestination(outside, xi.zone.ABYSSEA_KONSCHTAT))
        assert(not xi.abyssea.refuseDestination(makePlayer(75), xi.zone.ABYSSEA_KONSCHTAT))
        assert(not xi.abyssea.refuseDestination(makePlayer(1), xi.zone.LOWER_JEUNO))

        local warped = false
        local inside = makePlayer(1)
        inside.getZoneID = function()
            return xi.zone.ABYSSEA_TAHRONGI
        end
        inside.timer = function(_, _, fn)
            fn(inside)
        end
        inside.setPos = function()
            warped = true
        end
        assert(xi.abyssea.refuseDestination(inside, xi.zone.ABYSSEA_KONSCHTAT))
        assert(warped)
    end)

    it('ejects underleveled players from an Abyssea zone', function()
        local warped = false
        local player = makePlayer(1)
        player.getZoneID = function()
            return xi.zone.ABYSSEA_KONSCHTAT
        end
        player.timer = function(_, _, fn)
            fn(player)
        end
        player.setPos = function()
            warped = true
        end

        assert(xi.abyssea.ejectIfIneligible(player))
        assert(warped)
        assert(not xi.abyssea.ejectIfIneligible(makePlayer(75)))
    end)
end)
