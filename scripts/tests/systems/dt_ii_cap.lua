local catalog = require('modules/custom/lua/augment_catalog')

describe('augment PDT-II / MDT-II', function()
    it('is a 1% Treasure Hunter line on Marid Hide and Gargouille Horn', function()
        local phys = catalog[2151]
        local magic = catalog[2747]
        assert(phys.augId == 1155 and phys.flatValue == 1 and phys.maxBoost == 0)
        assert(magic.augId == 1156 and magic.flatValue == 1 and magic.maxBoost == 0)
        assert(phys.mult == 100 and magic.mult == 100)
        assert(phys.disp == 100 and magic.disp == 100)
    end)

    it('caps augment II at 10% and leaves unique weapons alone', function()
        assert(xi.combat.damage.AUGMENT_DT_II_CAP == 0.10)
        assert(xi.combat.damage.cappedAugmentII(-1500, 0) == -0.10)
        assert(xi.combat.damage.cappedAugmentII(-800, 0) == -0.08)
        assert(xi.combat.damage.cappedAugmentII(-2800, -1800) == -0.28)
        assert(xi.combat.damage.cappedAugmentII(-1800, -1800) == -0.18)
        assert(xi.combat.damage.cappedAugmentII(-6000, -5000) == -0.60)
    end)

    it('reads Burtgang and Aegis as unique II, not augment II', function()
        local target = {
            getEquipID = function(_, slot)
                if slot == 0 then
                    return 20687 -- Burtgang 99
                end
                if slot == 1 then
                    return 16200 -- Aegis 99 II
                end
                return 0
            end,
        }

        assert(xi.combat.damage.equippedUniqueII(target, xi.combat.damage.UNIQUE_PDT_II) == -1800)
        assert(xi.combat.damage.equippedUniqueII(target, xi.combat.damage.UNIQUE_MDT_II) == -5000)
    end)
end)
