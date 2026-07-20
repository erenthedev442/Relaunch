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
        assert(catalog.nmMods(1)[xi.mod.REGEN] == nil)
        assert(catalog.nmMods(19)[xi.mod.REGEN] == nil)
        assert(catalog.mechCfg(1).drain == nil)
        assert(catalog.mechCfg(19).drain == nil)
        assert(catalog.mechCfg(5).enrage ~= nil)
        assert(catalog.mechCfg(6).doom ~= nil)
    end)

    it('exposes named spawn and combat behavior for dynamic rift NMs', function()
        assert(xi.voidwalker.hasSpawnBehavior('Krabkatoa'))
        assert(xi.voidwalker.hasSpawnBehavior('Erebus'))
        assert(xi.voidwalker.hasCombatBehavior('Capricornus'))
        assert(xi.voidwalker.hasCombatBehavior('Blobdingnag'))
        assert(xi.voidwalker.hasCombatBehavior('Dawon'))
        assert(not xi.voidwalker.hasCombatBehavior('Lord_Ruthven'))
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
