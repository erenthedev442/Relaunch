local echo = require('modules/custom/lua/maat_infamy_fight')
local htbf = require('modules/custom/lua/htbf_catalog')

describe("Maat's Echo integrity", function()
    it('uses a free battlefield id after the HTBF block', function()
        assert(echo.BATTLEFIELD_ID == 4230)
        assert(xi.battlefield.id.MAATS_ECHO == echo.BATTLEFIELD_ID)
        assert(echo.MENU_INDEX == 22)
        assert(echo.COMPANION_CAP == 2)
        assert(echo.INFAMY_COST == 150)
        assert(echo.KI_NAME == "Echo's Testimony")
        assert(xi.ki.ECHOS_TESTIMONY == 3362)

        local ids = {}
        for _, fight in pairs(htbf.fights) do
            for tier = 1, 3 do
                ids[fight.baseBattlefieldId + tier - 1] = true
            end
        end
        ids[htbf.finalTest.battlefieldId] = true
        assert(ids[echo.BATTLEFIELD_ID] ~= true)
    end)

    it('keeps the Waughroon burning-circle menu slot free of retail and HTBF', function()
        local used =
        {
            [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
            [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
            [10] = true, [11] = true, [12] = true, [13] = true, [14] = true,
            [15] = true, [16] = true, [17] = true, [18] = true, [21] = true,
        }
        assert(used[echo.MENU_INDEX] ~= true)
    end)

    it('exports companion helpers that count the Fellow as a slot', function()
        assert(type(echo.companionSlots) == 'function')
        assert(type(echo.enforceCompanionCap) == 'function')
        assert(type(echo.isEchoBattlefield) == 'function')
        assert(type(echo.isInEchoFight) == 'function')
        assert(type(echo.registerBattlefield) == 'function')
        assert(echo.isEchoBattlefield(nil) == false)
    end)
end)
