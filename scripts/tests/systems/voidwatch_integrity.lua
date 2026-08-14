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

    it('uses readable upper-stratum pressure without generic solo-fail mechanics', function()
        assert(catalog.nmMods('CRIMSON', 0)[xi.mod.REGEN] == 0)
        assert(catalog.nmMods('AMBER', 5)[xi.mod.REGEN] == 0)
        assert(catalog.mechCfg('WHITE').phases == nil)
        assert(catalog.mechCfg('ASHEN').phases ~= nil)
        assert(catalog.mechCfg('HYACINTH').doom == nil)
        assert(catalog.mechCfg('AMBER').stance == nil)
        assert(catalog.mechCfg('AMBER').aoe == nil)
        assert(catalog.mechCfg('AMBER').forceMessages == true)
    end)

    it('keeps stratum bands ordered through capped repeat scaling', function()
        local ashen = catalog.STRATUM_BY_KEY.ASHEN
        local hyacinth = catalog.STRATUM_BY_KEY.HYACINTH
        local amber = catalog.STRATUM_BY_KEY.AMBER

        assert(catalog.nmLevel(ashen) == 125)
        assert(catalog.nmLevel(hyacinth) == 135)
        assert(catalog.nmLevel(amber) == 145)
        assert(catalog.nmHp(ashen, 0) == 2500000)
        assert(catalog.nmHp(ashen, 999) == 3000000)
        assert(catalog.nmHp(ashen, 999) < catalog.nmHp(hyacinth, 0))
        assert(catalog.nmHp(hyacinth, 999) < catalog.nmHp(amber, 0))
        assert(catalog.nmHp(amber, 999) == 8400000)
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

    it('uses exact stratum-based Sortie earring tiers and rates', function()
        local ruthven = catalog.nmLoot('Lord_Ruthven')
        assert(#ruthven.rare == 4)
        assert(ruthven.earrings == nil)

        local ashenPool, ashenChance = catalog.earringReward('ASHEN')
        local hyacinthPool, hyacinthChance = catalog.earringReward('HYACINTH')
        local amberPool, amberChance = catalog.earringReward('AMBER')
        assert(#ashenPool == 22 and #hyacinthPool == 22 and #amberPool == 22)
        assert(ashenPool[1] == 25422 and hyacinthPool[1] == 25422 and amberPool[1] == 25422)
        assert(ashenChance == 5)
        assert(hyacinthChance == 10)
        assert(amberChance == 20)
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
