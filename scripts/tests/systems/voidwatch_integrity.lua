local catalog = require('modules/custom/lua/voidwatch_catalog')
require('scripts/globals/voidwalker')

describe('Voidwatch combat and catalog integrity', function()
    it('keeps the roster valid and deduplicates repeated stratum NMs', function()
        local entries = 0
        local unique = {}

        for _, stratum in ipairs(catalog.STRATA) do
            assert(#stratum.zones > 0)
            assert(#stratum.roster == 3)

            for _, nm in ipairs(stratum.roster) do
                entries = entries + 1
                assert(nm.name and nm.group > 0 and nm.zone > 0)
                unique[nm.name] = true
            end
        end

        local uniqueCount = 0
        for _ in pairs(unique) do uniqueCount = uniqueCount + 1 end

        assert(entries == 21)
        assert(uniqueCount == 19)
        assert(catalog.UNIQUE_NM_COUNT == uniqueCount)
    end)

    it('uses pressure mechanics instead of passive regen or periodic healing', function()
        assert(catalog.nmMods(1)[xi.mod.REGEN] == 0)
        assert(catalog.nmMods(19)[xi.mod.REGEN] == 0)
        assert(catalog.mechCfg(1).drain == nil)
        assert(catalog.mechCfg(19).drain == nil)
        assert(catalog.mechCfg(12).enrage == nil)
        assert(catalog.mechCfg(13).enrage ~= nil)
        assert(catalog.mechCfg(16).doom ~= nil)
    end)

    it('caps levels and repeat scaling at server-safe values', function()
        assert(catalog.nmLevel(1) == 99)
        assert(catalog.nmLevel(24) == 150)
        assert(catalog.nmLevel(999) == 150)
        assert(catalog.nmHp(19) == 10000000)
        assert(catalog.nmHp(999) == 14000000)
        assert(catalog.effectiveTier(catalog.STRATUM_BY_KEY.AMBER, 999) == 24)
    end)

    it('gives every dynamic rift NM named spawn or combat behavior', function()
        for name in pairs(catalog.UNIQUE_NMS) do
            assert(
                xi.voidwalker.hasSpawnBehavior(name) or
                xi.voidwalker.hasCombatBehavior(name),
                string.format('%s has no named Voidwalker behavior', name))
        end
        assert(xi.voidwalker.hasCombatBehavior('Lord_Ruthven'))
        assert(xi.voidwalker.hasCombatBehavior('Yilbegan'))
        assert(xi.voidwalker.hasCombatBehavior('Aglaophotis'))
        assert(xi.voidwalker.hasCombatBehavior('Gorehound'))
    end)

    it('keeps Sortie earrings separate from signature rare pools', function()
        local ruthven = catalog.nmLoot('Lord_Ruthven')
        assert(#ruthven.rare == 2)
        assert(#ruthven.earrings == 22)
        assert(catalog.EARRING_ROLL_CHANCE == 20)
    end)

    it('fires crossed HP thresholds once even when damage skips the exact percentage', function()
        local vars = {}
        local abilities = {}
        local mob = {}

        function mob:getName() return 'Yacumama' end
        function mob:getHPP() return 75 end
        function mob:getLocalVar(key) return vars[key] or 0 end
        function mob:setLocalVar(key, value) vars[key] = value end
        function mob:hasStatusEffect() return false end
        function mob:useMobAbility(skill) abilities[#abilities + 1] = skill end

        xi.voidwalker.applyCombatBehavior(mob)
        xi.voidwalker.applyCombatBehavior(mob)

        assert(#abilities == 1)
        assert(abilities[1] == xi.mobSkill.HUNDRED_FISTS_1)
    end)
end)
