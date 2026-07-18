local catalog = require('modules/custom/lua/reforge_catalog')
local native  = require('modules/custom/lua/reforge_native_mechanics')

describe('Reforge combat catalog', function()
    local expectedSkillLists =
    {
        Genbu = 277, Suzaku = 280, Seiryu = 278, Byakko = 279, Kirin = 281,
        Bukhis = 3000, Khun = 450, Padfoot = 226, Glavoid = 839, Tinnin = 313,
        Aello = 471, Iratham = 841, Briareus = 811, Itzpapalotl = 864, Hadhayosh = 3001,
    }

    local expectedAccuracy = { 900, 1200, 1500, 2100, 2400 }

    local function findMob(name)
        for _, sourceKey in ipairs(catalog.sourceOrder) do
            for _, mob in ipairs(catalog.sources[sourceKey].mobs) do
                if mob.name == name then
                    return mob
                end
            end
        end
    end

    it('defines a complete mechanics and working TP profile for every NM', function()
        local seen = {}
        local names = {}
        local count = 0

        assert(catalog.combatLevel == 99)
        assert(#catalog.sourceOrder == 3)

        for _, sourceKey in ipairs(catalog.sourceOrder) do
            local source = catalog.sources[sourceKey]
            assert(#source.mobs == 5)
            for tier, mob in ipairs(source.mobs) do
                count = count + 1
                assert(not seen[mob.groupId])
                seen[mob.groupId] = true
                names[mob.name] = true

                assert(mob.skillList == expectedSkillLists[mob.name])
                assert(mob.mods[xi.mod.ACC] == expectedAccuracy[tier])
                assert(catalog.mechCfgs[mob.groupId] ~= nil)
                assert(catalog.mechCfgs[mob.groupId].name == mob.name)
                assert(mob.minLv == 99 and mob.maxLv == 99)
            end
        end

        assert(count == 15)
        for groupId = 11400, 11414 do
            assert(seen[groupId])
        end
        for name in pairs(expectedSkillLists) do
            assert(names[name])
        end
    end)

    it('keeps accuracy monotonic across the five-step ladder', function()
        for _, sourceKey in ipairs(catalog.sourceOrder) do
            local mobs = catalog.sources[sourceKey].mobs
            for tier = 2, #mobs do
                assert(mobs[tier].mods[xi.mod.ACC] > mobs[tier - 1].mods[xi.mod.ACC])
            end
        end
    end)

    it('uses family-correct lists for Padfoot, Khun, and Aello', function()
        assert(findMob('Padfoot').skillList == 226) -- Sheep
        assert(findMob('Khun').skillList == 450)    -- Caturae
        assert(findMob('Aello').skillList == 471)   -- Harpeia
    end)

    it('registers handlers for previously missing TP moves', function()
        local handlers =
        {
            'rending_talons',
            'shrieking_gale',
            'wings_of_woe',
            'wings_of_agony',
            'typhoean_rage',
            'ravenous_wail',
            'extreme_purgation',
            'desiccation',
        }

        for _, handler in ipairs(handlers) do
            local skill = require('scripts/actions/mobskills/' .. handler)
            assert(type(skill.onMobSkillCheck) == 'function')
            assert(type(skill.onMobWeaponSkill) == 'function')
        end
    end)

    it('ports Genbu attack scaling and Iratham spell phases', function()
        assert(native.genbuAttackAtHpp(2700, 100) == 2700)
        assert(native.genbuAttackAtHpp(2700, 50) == 3200)
        assert(native.genbuAttackAtHpp(2700, 1) == 3690)

        assert(native.irathamSpellListAtHpp(100) == 153)
        assert(native.irathamSpellListAtHpp(50) == 153)
        assert(native.irathamSpellListAtHpp(49) == 154)
        assert(native.irathamSpellListAtHpp(20) == 154)
        assert(native.irathamSpellListAtHpp(19) == 155)
    end)

    it('executes portable native callback decisions', function()
        local cue = 2576
        local briareus =
        {
            getLocalVar = function(_, key)
                return key == 'CUE_MOVE' and cue or 0
            end,
            setLocalVar = function(_, key, value)
                if key == 'CUE_MOVE' then
                    cue = value
                end
            end,
            hasStatusEffect = function()
                return false
            end,
        }

        assert(native.chooseMobSkill(briareus, 11410) == 2576)
        assert(cue == 0)
        assert(native.chooseMobSkill(briareus, 11404) == 0)

        local mods = {}
        local genbu =
        {
            getLocalVar = function(_, key)
                return key == 'RF_GenbuBaseATT' and 2700 or 0
            end,
            getHPP = function()
                return 40
            end,
            setMod = function(_, modId, value)
                mods[modId] = value
            end,
        }

        native.tick(genbu, nil, 11404)
        assert(mods[xi.mod.ATT] == 3300)
        assert(mods[xi.mod.REGAIN] == 80)
    end)

    it('keeps all armor loot pools complete', function()
        assert(#catalog.jobs == 22)
        for _, sourceKey in ipairs(catalog.sourceOrder) do
            assert(#catalog.buildLootPool(sourceKey) == 110)
            for _, job in ipairs(catalog.jobs) do
                assert(#catalog.buildJobLootPool(job.id, sourceKey) == 5)
            end
        end
    end)

    it('keeps dynamic Kirin away from unsafe fixed-offset Astral Flow pets', function()
        assert(native.mixinsFor(11400) == nil)
        assert(native.mixinsFor(11401) ~= nil)
        assert(native.mixinsFor(11409) ~= nil)
    end)

    it('keeps tier mechanics present at the expected pressure levels', function()
        for _, sourceKey in ipairs(catalog.sourceOrder) do
            local mobs = catalog.sources[sourceKey].mobs
            assert(catalog.mechCfgs[mobs[1].groupId].drain)
            assert(catalog.mechCfgs[mobs[2].groupId].stance)
            assert(catalog.mechCfgs[mobs[2].groupId].cc)
            assert(catalog.mechCfgs[mobs[3].groupId].aoe)
            assert(catalog.mechCfgs[mobs[3].groupId].phases)
            assert(catalog.mechCfgs[mobs[4].groupId].doom)
            assert(catalog.mechCfgs[mobs[5].groupId].enrage)
        end

        assert(catalog.mechCfgs[11409].stance == nil)
    end)
end)
