local jail = require('modules/custom/lua/mordion_jail')

describe('Mordion jail helpers', function()
    it('clamps cell ids to the 32-cell table', function()
        assert(jail.cellId(1) == 1)
        assert(jail.cellId(32) == 32)
        assert(jail.cellId(0) == 1)
        assert(jail.cellId(99) == 1)
        assert(jail.cellId(nil) == 1)
        assert(jail.ZONE == 131)
        assert(#jail.cells == 32)
        assert(jail.cellDest(7)[1] == 260)
        assert(jail.cellDest(17)[2] == -400)
    end)

    it('treats inJail >= 1 as jailed', function()
        assert(jail.isJailedVar(1) == true)
        assert(jail.isJailedVar(32) == true)
        assert(jail.isJailedVar(0) == false)
        assert(jail.isJailedVar(nil) == false)
    end)

    it('refuses travel only while the player is flagged jailed', function()
        local messages = {}
        local player =
        {
            vars = { inJail = 4 },
            getCharVar = function(self, name)
                return self.vars[name] or 0
            end,
            printToPlayer = function(_, msg)
                messages[#messages + 1] = msg
            end,
        }

        assert(jail.isJailedPlayer(player) == true)
        assert(jail.refuseTravel(player) == true)
        assert(#messages == 1)

        player.vars.inJail = 0
        assert(jail.isJailedPlayer(player) == false)
        assert(jail.refuseTravel(player) == false)
        assert(#messages == 1)
    end)

    it('does not enforce when the jailed player is already in Mordion', function()
        local player =
        {
            vars = { inJail = 2 },
            getCharVar = function(self, name)
                return self.vars[name] or 0
            end,
            getZoneID = function()
                return jail.ZONE
            end,
        }

        assert(jail.enforceSentence(player) == false)
    end)
end)
