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

    it('does not strip Doom so Ruthven Eternal Damnation stays a holy-water check', function()
        for _, effectId in ipairs(catalog.SOLO_FAIL_EFFECTS) do
            assert(effectId ~= xi.effect.DOOM)
        end
        local foundTerror = false
        for _, effectId in ipairs(catalog.SOLO_FAIL_EFFECTS) do
            if effectId == xi.effect.TERROR then
                foundTerror = true
            end
        end
        assert(foundTerror)
    end)

    it('uses exact stratum-based Sortie earring tiers and rates', function()
        local ruthven = catalog.nmLoot('Lord_Ruthven')
        assert(#ruthven.rare == 2)
        assert(ruthven.rare[1] == 11628)
        assert(ruthven.rare[2] == 15953)
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

    it('prefers unseen Amber NMs and will not immediately repeat Yilbegan', function()
        local amber = catalog.STRATUM_BY_KEY.AMBER.roster
        local seen = { Yilbegan = true }
        local counts = { Yilbegan = 0, Lord_Ruthven = 0, Erebus = 0 }

        for _ = 1, 40 do
            local entry = catalog.pickRosterEntry(amber, seen, 'Yilbegan')
            counts[entry.name] = counts[entry.name] + 1
        end

        assert(counts.Yilbegan == 0)
        assert(counts.Lord_Ruthven > 0)
        assert(counts.Erebus > 0)

        local first = catalog.pickRosterEntry(amber, { Yilbegan = true, Lord_Ruthven = true, Erebus = true }, 'Yilbegan')
        assert(first.name ~= 'Yilbegan')
    end)

    it('does not put Mog Bonanza prize weapons on Voidwatch NM tables', function()
        local banned =
        {
            [20672] = true, -- Ice Brand
            [20673] = true, -- Flametongue
            [21071] = true, -- Cath Palug Hammer
            [21528] = true, -- Dragon Fangs
            [21529] = true, -- Premium Heart
            [21568] = true, -- Acrontica
            [21569] = true, -- Chocobo Knife
            [21570] = true, -- Air Knife
            [21640] = true, -- Onion Sword III
            [21641] = true, -- Save the Queen III
            [21676] = true, -- Brave Blade III
            [21725] = true, -- Malefic Axe
            [21764] = true, -- Drastic Axe
            [21814] = true, -- Final Sickle
            [21885] = true, -- Hebo's Spear
            [21927] = true, -- Yagyu Darkblade
            [21980] = true, -- Zanmato +2
            [21981] = true, -- Mutsu-no-Kami Yoshiyuki
            [22042] = true, -- Wizard's Rod
            [22101] = true, -- Pandit's Staff
            [22145] = true, -- Artemis's Bow +2
            [22152] = true, -- Exeter
            [22249] = true, -- Miracle Cheer
            [26488] = true, -- Diamond Aspis
        }

        local function assertClean(label, ids)
            for _, id in ipairs(ids or {}) do
                assert(not banned[id], string.format('%s includes Bonanza prize %d', label, id))
            end
        end

        assertClean('shared rare pool', catalog.LOOT.rare)
        for name, loot in pairs(catalog.NM_LOOT) do
            assertClean(name .. ' rare', loot.rare)
            assertClean(name .. ' uncommon', loot.uncommon)
        end
    end)

    it('does not put Sortie / Limbus SU armor on Voidwatch NM tables', function()
        local function assertClean(label, ids)
            for _, id in ipairs(ids or {}) do
                assert(not catalog.isLimbusArmor(id), string.format('%s includes Limbus armor %d', label, id))
            end
        end

        assert(catalog.isLimbusArmor(24166)) -- Magnificent Crown
        assert(catalog.isLimbusArmor(24178)) -- Magnificent Sollerets
        assert(catalog.isLimbusArmor(24128)) -- Revelation Gauntlets
        assert(not catalog.isLimbusArmor(11587))

        assertClean('shared rare pool', catalog.LOOT.rare)
        for name, loot in pairs(catalog.NM_LOOT) do
            assertClean(name .. ' rare', loot.rare)
            assertClean(name .. ' uncommon', loot.uncommon)
        end

        local erebus = catalog.nmLoot('Erebus')
        assert(#erebus.rare == 1)
        assert(erebus.rare[1] == 11587)
    end)

    it('keeps rare tables on authentic Voidwatch pieces only', function()
        local function assertAuthentic(label, ids)
            for _, id in ipairs(ids or {}) do
                assert(catalog.isVoidwatchRare(id), string.format('%s includes non-Voidwatch rare %d', label, id))
            end
        end

        assert(catalog.isVoidwatchRare(11632)) -- Karka Ring
        assert(catalog.isVoidwatchRare(19248)) -- Lucky Coin
        assert(not catalog.isVoidwatchRare(26400)) -- Culminus
        assert(not catalog.isVoidwatchRare(25600)) -- Ma'iitsoh Haube
        assert(not catalog.isVoidwatchRare(26403)) -- Srivatsa
        assert(not catalog.isVoidwatchRare(28152)) -- Gorney Brayettes +1
        assert(not catalog.isVoidwatchRare(21712)) -- Voluspa Axe
        assert(not catalog.isVoidwatchRare(20827)) -- Kerehcatl

        assertAuthentic('shared rare pool', catalog.LOOT.rare)
        for name, loot in pairs(catalog.NM_LOOT) do
            assertAuthentic(name .. ' rare', loot.rare)
        end

        local yilbegan = catalog.nmLoot('Yilbegan')
        assert(#yilbegan.rare == 4)
        local krab = catalog.nmLoot('Krabkatoa')
        assert(#krab.rare == 2)
        assert(krab.rare[1] == 11502)
        assert(krab.rare[2] == 11632)
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
