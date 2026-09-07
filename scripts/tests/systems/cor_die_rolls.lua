-- Allies' Die item_basic.subid 138 is Deploy's ability ID. The die scripts
-- must keep teaching the real roll IDs (302+), not the animation/subid.

describe('Corsair die roll IDs', function()
    it('keeps Abyssea rolls distinct from Deploy', function()
        assert(xi.jobAbility.DEPLOY == 138)
        assert(xi.jobAbility.ALLIES_ROLL == 302)
        assert(xi.jobAbility.MISERS_ROLL == 303)
        assert(xi.jobAbility.COMPANIONS_ROLL == 304)
        assert(xi.jobAbility.AVENGERS_ROLL == 305)
        assert(xi.jobAbility.NATURALISTS_ROLL == 390)
        assert(xi.jobAbility.RUNEISTS_ROLL == 391)
    end)

    it('teaches Allies and Miser rolls from their dice', function()
        local allies = loadfile('scripts/items/allies_die.lua')()
        local miser  = loadfile('scripts/items/misers_die.lua')()
        assert(type(allies.onItemCheck) == 'function')
        assert(type(allies.onItemUse) == 'function')
        assert(type(miser.onItemCheck) == 'function')
        assert(type(miser.onItemUse) == 'function')
    end)
end)
