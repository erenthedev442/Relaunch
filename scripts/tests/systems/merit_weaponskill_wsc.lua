describe('Merit weaponskill WSC', function()
    local function makePlayer(ranks, level)
        return
        {
            getMainLvl = function()
                return level or 99
            end,
            getMeritRank = function(_, _meritId)
                return ranks
            end,
            getMerit = function()
                -- Old path: SQL value=3, so 5 ranks returned 15.
                return ranks * 3
            end,
        }
    end

    it('uses 70% + 3% per rank under Adoulin (73% at 1, 85% at 5)', function()
        assert(xi.settings.main.USE_ADOULIN_WEAPON_SKILL_CHANGES)

        assert(math.abs(xi.weaponskills.getMeritWeaponSkillWSC(makePlayer(0), xi.merit.RESOLUTION) - 0.7) < 1e-9)
        assert(math.abs(xi.weaponskills.getMeritWeaponSkillWSC(makePlayer(1), xi.merit.RESOLUTION) - 0.73) < 1e-9)
        assert(math.abs(xi.weaponskills.getMeritWeaponSkillWSC(makePlayer(5), xi.merit.RESOLUTION) - 0.85) < 1e-9)
    end)

    it('does not treat getMerit() count*3 as extra ranks', function()
        -- 5 ranks used to become 0.7 + 15*0.03 = 1.15
        local wsc = xi.weaponskills.getMeritWeaponSkillWSC(makePlayer(5), xi.merit.SHIJIN_SPIRAL)
        assert(math.abs(wsc - 0.85) < 1e-9)
        assert(math.abs(wsc - 1.15) > 0.01)
    end)

    it('reads raw ranks so jobs that can use the WS still get the bonus', function()
        local player = makePlayer(5)
        player.getMerit = function()
            return 0 -- GetMeritValue used to zero off-job WS merits
        end

        assert(xi.weaponskills.getMeritWeaponSkillRanks(player, xi.merit.RESOLUTION) == 5)
        assert(math.abs(xi.weaponskills.getMeritWeaponSkillWSC(player, xi.merit.RESOLUTION) - 0.85) < 1e-9)
    end)

    it('does not apply WS merit WSC below level 96', function()
        assert(xi.weaponskills.getMeritWeaponSkillRanks(makePlayer(5, 95), xi.merit.RESOLUTION) == 0)
        assert(math.abs(xi.weaponskills.getMeritWeaponSkillWSC(makePlayer(5, 95), xi.merit.RESOLUTION) - 0.7) < 1e-9)
    end)
end)
