-- Quest-unlocked Eren raises DPS weaponskills to 149,999, Magus AoE to
-- 99,999 per target, tank DT, and Oracle Cure Potency II. The name alone no
-- longer grants the form.

describe('Eren fellow role bonuses', function()
    local fellow

    before_each(function()
        require('modules/custom/lua/fellow_companion')
        fellow = xi.fellow
    end)

    it('keeps stock outgoing and endgame caps when the Fellow is not named Eren', function()
        assert(fellow.outgoingCap(false, 'vanguard', 1.0) == 99999)
        assert(fellow.outgoingCap(false, 'magus', 1.0) == 99999)
        assert(fellow.aoeCap(false, 'magus') == 0)

        local floor, cap = fellow.endgameDamageBand(false, 'vanguard', 400000, 1.0)
        assert(floor == 50000)
        assert(cap == 70000)
    end)

    it('lets Eren Vanguard, Hunter, and Berserker weaponskills hit the 149,999 cap', function()
        assert(fellow.outgoingCap(true, 'vanguard', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'berserker', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'hunter', 1.0) == 149999)
        assert(fellow.outgoingCap(true, 'mastered', 1.0) == 99999)

        local floor, cap = fellow.endgameDamageBand(true, 'vanguard', 400000, 1.0)
        assert(floor == 149999)
        assert(cap == 149999)
        -- Leveling / trash HP: 50% of max HP binds before the 149,999 cap.
        local smallFloor, smallCap = fellow.endgameDamageBand(true, 'berserker', 100000, 1.0)
        assert(smallFloor == 50000)
        assert(smallCap == 50000)
        local trashFloor, trashCap = fellow.endgameDamageBand(true, 'hunter', 8000, 1.0)
        assert(trashFloor == 4000)
        assert(trashCap == 4000)
    end)

    it('caps Eren Magus AoE at 99,999 per target and leaves Magus as the only AoE role', function()
        assert(fellow.aoeCap(true, 'magus') == 99999)
        assert(fellow.aoeCap(true, 'vanguard') == 0)
        assert(fellow.aoeCap(true, 'hunter') == 0)
        assert(fellow.aoeCap(true, 'berserker') == 0)
        assert(fellow.outgoingCap(true, 'magus', 1.0) == 99999)
        assert(fellow.outgoingCap(true, 'bulwark', 1.0) == 99999)
        assert(fellow.outgoingCap(true, 'oracle', 1.0) == 99999)

        local magusFloor, magusCap = fellow.endgameDamageBand(true, 'magus', 400000, 1.0)
        local _, tankCap = fellow.endgameDamageBand(true, 'bulwark', 400000, 1.0)
        assert(magusFloor == 99999)
        assert(magusCap == 99999)
        assert(tankCap == 70000)
        local magusTrashFloor, magusTrashCap = fellow.endgameDamageBand(true, 'magus', 8000, 1.0)
        assert(magusTrashFloor == 4000)
        assert(magusTrashCap == 4000)
    end)

    it('gives Eren tank 50% DT and extra HP, and Oracle Cure VI ~2200', function()
        assert(fellow.eren.tankDt == -5000)
        assert(fellow.eren.tankHpMult == 1.50)
        assert(fellow.eren.oracleCurePotencyII == 30)
        assert(fellow.eren.oracleCureBonus == 900)
        assert(fellow.eren.oracleHealMult == 1.70)
        assert(fellow.eren.dpsWsFloor == 149999)
        assert(fellow.eren.dpsAbsoluteCap == 149999)
        assert(fellow.eren.hpPctCap == 50)
        assert(fellow.eren.wsCooldownSec == 3)
        assert(fellow.eren.nukeCooldownSec == 8)
        assert(fellow.eren.dpsHp.berserker == 5790)
        assert(fellow.eren.dpsHp.vanguard == 6180)
        assert(fellow.eren.dpsHp.hunter == 6410)
        assert(fellow.eren.dpsHp.berserker ~= fellow.eren.dpsHp.vanguard)
        assert(fellow.eren.dpsHp.vanguard ~= fellow.eren.dpsHp.hunter)
        assert(fellow.eren.dpsDoubleAttack == 100)
        assert(fellow.eren.dpsHasteGear == 2500)
        assert(fellow.eren.dpsHasteMagic == 4375)
        assert(fellow.eren.dpsHasteAbility == 2500)
    end)

    it('maps Eren TP-menu picks onto Hades v1 skills instead of Naji Vorpal Blade', function()
        assert(fellow.resolveErenWs('vanguard', 0) == xi.mobSkill.FULMINOUS_SMASH)
        assert(fellow.resolveErenWs('vanguard', 1) == xi.mobSkill.FULMINOUS_SMASH)
        assert(fellow.resolveErenWs('vanguard', 2) == xi.mobSkill.FLAMING_KICK)
        assert(fellow.resolveErenWs('berserker', 0) == xi.mobSkill.VIVISECTION)
        assert(fellow.resolveErenWs('magus', 6) == xi.mobSkill.VIVISECTION)
        assert(fellow.resolveErenWs('vanguard', 2) ~= xi.mobSkill.VORPAL_BLADE_1)
        for _, move in ipairs(fellow.erenMoves) do
            assert(move.ws ~= xi.mobSkill.VORPAL_BLADE_1)
            assert(move.ws >= xi.mobSkill.FULMINOUS_SMASH)
            assert(move.ws <= xi.mobSkill.VIVISECTION)
        end
    end)

    it('requires the permanent unlock flag rather than the chosen name', function()
        local vars =
        {
            Fellow_NameCustom = 1,
            Fellow_NameW0 = string.byte('E') +
                bit.lshift(string.byte('r'), 8) +
                bit.lshift(string.byte('e'), 16) +
                bit.lshift(string.byte('n'), 24),
            Fellow_ErenUnlocked = 0,
        }
        local player =
        {
            getCharVar = function(_, key) return vars[key] or 0 end,
            setCharVar = function(_, key, value) vars[key] = value end,
        }

        assert(fellow.isEren(player) == false)
        vars.Fellow_ErenUnlocked = 1
        assert(fellow.isEren(player) == true)
    end)
end)
