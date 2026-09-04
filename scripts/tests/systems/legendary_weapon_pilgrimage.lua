local pilgrimage = require('modules/custom/lua/legendary_pilgrimage_catalog')
local forge      = require('modules/custom/lua/weapon_forge_catalog')
local rema       = require('modules/custom/lua/rema_ws_tier_catalog')
local prime      = require('modules/custom/lua/prime_ws_tuning_catalog')
local gates      = require('modules/custom/lua/weapon_forge_gates')
local unity      = require('modules/custom/lua/unity_wanted_catalog')
local abyssea    = require('modules/custom/lua/abyssea_marks_catalog')
local voidwatch  = require('modules/custom/lua/voidwatch_catalog')

describe('Legendary Weapon Pilgrimage integrity', function()
    it('covers all 78 exact chains with three chapters and 14 archetypes', function()
        assert(#pilgrimage.chains == 78)
        local familyCounts, archetypes, finals = {}, {}, {}
        for index, entry in ipairs(pilgrimage.chains) do
            assert(entry.index == index)
            assert(entry.wsId > 0 and entry.finalId > 0)
            assert(#entry.stages == 3 and #entry.chapters == 3)
            assert(entry.archetype and pilgrimage.ARCHETYPES[entry.weaponType] == entry.archetype)
            assert(entry.archetypeRule and entry.archetypeRule.key == entry.archetype)
            assert(not finals[entry.finalId])
            finals[entry.finalId] = true
            archetypes[entry.archetype] = true
            familyCounts[entry.family] = (familyCounts[entry.family] or 0) + 1
            for chapter = 1, 3 do
                assert(entry.family == 'aeonic' or entry.stages[chapter] > 0)
                assert(entry.chapters[chapter].count > 0)
                local kind = entry.chapters[chapter].kind
                if entry.chapters[chapter].distinct then
                    assert(entry.chapters[chapter].targets)
                    assert(#entry.chapters[chapter].targets >= entry.chapters[chapter].count)
                end
                if kind == 'ws_kills' or kind == 'named_ws_kills' then
                    assert(entry.chapters[chapter].archetypeRule == entry.archetypeRule)
                end
            end
        end
        for family, expected in pairs(pilgrimage.FAMILY_COUNTS) do
            assert(familyCounts[family] == expected)
        end
        local archetypeCount = 0
        for _ in pairs(archetypes) do archetypeCount = archetypeCount + 1 end
        assert(archetypeCount == 14)
    end)

    it('maps every item and native WS through authoritative forge/tuning catalogs', function()
        for _, entry in ipairs(pilgrimage.chains) do
            if entry.family == 'prime' then
                local tuning = prime.PRIME_WS_TUNING[entry.wsId]
                assert(tuning and tuning.itemId == entry.finalId and tuning.slot == entry.slot)
            else
                local tuning = rema.BY_ITEM_ID[entry.finalId]
                assert(tuning and tuning.wsId == entry.wsId and tuning.slot == entry.slot)
            end
        end
    end)

    it('binds Epeolatry and Idris chapters to 99 / 119 I / 119 II', function()
        local epeo = pilgrimage.byFinalId[21685]
        local idris = pilgrimage.byFinalId[21080]
        assert(epeo and epeo.family == 'mythic' and not epeo.singleStep)
        assert(epeo.stages[1] == 19968 and epeo.stages[2] == 19969 and epeo.stages[3] == 20753)
        assert(epeo.wsId == rema.BY_ITEM_ID[21685].wsId)
        assert(idris and idris.family == 'mythic' and not idris.singleStep)
        assert(idris.stages[1] == 19970 and idris.stages[2] == 19971 and idris.stages[3] == 21070)
        assert(idris.wsId == rema.BY_ITEM_ID[21080].wsId)
    end)

    it('binds chapters to lower, 119 I, and 119 II stages', function()
        for _, entry in ipairs(pilgrimage.chains) do
            if entry.family == 'aeonic' then
                assert(entry.stages[1] == 0 and entry.stages[2] == 0 and entry.stages[3] == 0)
            else
                assert(entry.stages[1] ~= entry.finalId)
                assert(entry.stages[2] ~= entry.finalId)
                assert(entry.stages[3] ~= entry.finalId)
            end
            if entry.singleStep then
                assert(entry.stages[1] == entry.stages[2] and entry.stages[2] == entry.stages[3])
            elseif entry.family ~= 'prime' and entry.family ~= 'aeonic' then
                assert(entry.stages[1] ~= entry.stages[2])
                assert(entry.stages[2] ~= entry.stages[3])
            else
                assert(entry.stages[1] == entry.stages[2])
                assert(entry.stages[2] ~= entry.stages[3])
            end
        end
    end)

    it('uses support objectives for Dagan, Myrkr, and Atonement only', function()
        local found = {}
        for _, entry in ipairs(pilgrimage.chains) do
            local utility = pilgrimage.UTILITY_WS[entry.wsId]
            if utility then
                found[utility] = entry.chapters[1]
                assert(entry.chapters[1].kind == 'support_ws')
                if utility == 'dagan' or utility == 'myrkr' then
                    assert(entry.chapters[2].kind == 'support_ws')
                    assert(entry.chapters[3].kind == 'support_ws')
                end
            else
                assert(entry.chapters[1].kind ~= 'support_ws')
            end
        end
        assert(found.dagan.count == 8 and found.dagan.hpBelow == 35 and found.dagan.restore == 1500)
        assert(found.myrkr.count == 8 and found.myrkr.mpBelow == 10 and found.myrkr.restore == 900)
        assert(found.atonement.count == 8 and found.atonement.positiveDamage)
    end)

    it('keeps every family inside the approved progression bands', function()
        for _, entry in ipairs(pilgrimage.chains) do
            local c1, c2, c3 = entry.chapters[1], entry.chapters[2], entry.chapters[3]
            if entry.family == 'relic' then
                assert(c1.count >= 60 and c1.count <= 80)
                assert(c1.minLevel == 99 and c1.minMaxHP == nil)
                assert(c2.count >= 6 and c2.count <= 10 and c2.distinct)
                assert(c3.count == 4 and c3.distinct and c3.tag == 'divergence_disjoined')
            elseif entry.family == 'empyrean' then
                if c1.kind ~= 'support_ws' then assert(c1.count >= 70 and c1.count <= 90) end
                assert(c2.count >= 8 and c2.count <= 12 and c2.distinct)
                assert(c3.count == 3 and c3.tag == 'signature_material_nm')
            elseif entry.family == 'mythic' then
                if c1.kind ~= 'support_ws' then assert(c1.count >= 25 and c1.count <= 40) end
                assert(c2.count == 5 and not c2.distinct)
                assert(c2.kind == 'nyzul_objectives')
                assert(c2.tag == 'nyzul_specified_enemy')
                assert(c2.objectiveKind == pilgrimage.NYZUL_SPECIFIED_ENEMY)
                assert(c3.count == 3 and c3.distinct)
            elseif entry.family == 'aeonic' then
                assert(c1.count == 8 and c1.distinct and c1.tag == 'geas_t3')
                assert(c2.count + c3.count == 4)
                assert(c2.tag == 'geas_t4' and c3.tag == 'geas_t4')
            elseif entry.family == 'prime' then
                assert(c1.count >= 20 and c1.count <= 30 and c1.tag == 'elite' and c1.distinct)
                assert(#c1.targets >= c1.count)
                assert(c2.count + c3.count == 5)
                assert(c2.distinct and c3.distinct)
                assert(#c2.targets >= c2.count and #c3.targets >= c3.count)
                assert(c2.tag == 'geas_t4' and c3.tag == 'geas_t4')
                local seen = {}
                for _, target in ipairs(c2.targets) do seen[pilgrimage.normalizeName(target)] = true end
                for _, target in ipairs(c3.targets) do
                    assert(not seen[pilgrimage.normalizeName(target)])
                end
            end
        end
    end)

    it('replaces only the approved final Reforge Mark amounts', function()
        assert(forge.relicCosts[3].marks == 1000)
        assert(forge.empyreanCosts[3].marks == 1500)
        assert(forge.mythicCosts[3].marks == 2000)
        assert(forge.mythicCostsSum.marks == 2000)
        assert(forge.aeonicCosts.toStage3.reforgeMarks == 2000)
        assert(forge.costs.toStage3.reforgeMarks == 5000)
    end)

    it('preserves all previous non-mark costs and currencies', function()
        assert(forge.relicCosts[3].relicCurrency == 500)
        assert(forge.relicCosts[3].highTierAlt == 50 and forge.relicCosts[3].pluton == 500)
        assert(forge.empyreanCosts[3].boulder == 3000 and forge.empyreanCosts[3].beastcoin == 50)
        assert(forge.mythicCosts[3].gold == 5 and forge.mythicCosts[3].beitetsu == 10000)
        assert(forge.mythicCostsSum.standing == 4000 and forge.mythicCostsSum.beitetsu == 10300)
        assert(forge.aeonicCosts.toStage3.attestations == 3)
        assert(forge.aeonicCosts.toStage3.eschaSilt == 35000)
        assert(forge.costs.toStage3.medals.id == 9543 and forge.costs.toStage3.medals.qty == 100)
        assert(forge.costs.toStage3.gil == 750000000 and forge.costs.toStage3.requireTrials)
    end)

    it('keeps existing Aeonic Maat/Wave and Prime Armory/Ragnarok gates', function()
        assert(gates.STAGE_GATES.aeonic[2].label:find('Maat', 1, true))
        assert(gates.STAGE_GATES.aeonic[2].label:find('Oblivion', 1, true))
        assert(gates.STAGE_GATES.prime[1].label:find('All 5 Prime Armory Trials', 1, true))
        assert(gates.STAGE_GATES.prime[2].label:find('Ragnarok', 1, true))
    end)

    it('references only supported deterministic content tags', function()
        local supported =
        {
            magian_family = true, unity_nm = true, divergence_disjoined = true,
            abyssea_ecology = true, abyssea_nm = true, signature_material_nm = true,
            job_mastery = true, nyzul_specified_enemy = true, imperial_final_targets = true,
            geas_t3 = true, geas_t4 = true, elite = true,
        }
        for _, entry in ipairs(pilgrimage.chains) do
            for _, chapter in ipairs(entry.chapters) do
                assert(chapter.kind == 'support_ws' or supported[chapter.tag],
                    string.format('%s has unsupported tag %s', entry.name, tostring(chapter.tag)))
            end
        end
    end)

    it('publishes the engine local-variable WS contract', function()
        assert(pilgrimage.GRANTED_MAIN_WS_VAR == 'LWP_GrantedMainWS')
        assert(pilgrimage.GRANTED_RANGED_WS_VAR == 'LWP_GrantedRangedWS')
        assert(pilgrimage.PRIME_ENTRY_VAR == 'WF_Aeonic_Final')
        assert(pilgrimage.LOWER_WS_CAP == 149999)
    end)

    it('locks Prime registration and trial WS access behind a final Aeonic', function()
        local vars = {}
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        assert(pilgrimage.entryUnlocked(player, pilgrimage.chains[1]))
        local primeEntry = pilgrimage.chains[65]
        assert(primeEntry.family == 'prime')
        assert(not pilgrimage.entryUnlocked(player, primeEntry))
        vars.WF_Aeonic_Final = 1
        assert(pilgrimage.entryUnlocked(player, primeEntry))
    end)

    it('defines an enforceable condition for every archetype profile', function()
        local seen = {}
        local state = { tp = 3000, behind = true, hpp = 0, mpp = 0, distance = 99, pet = true, status = true }
        local pet = { getHP = function() return state.pet and 1 or 0 end }
        local attacker =
        {
            getPet = function() return state.pet and pet or nil end,
            hasStatusEffect = function() return state.status end,
            isBehind = function() return state.behind end,
            getHPP = function() return state.hpp end,
            getMPP = function() return state.mpp end,
            checkDistance = function() return state.distance end,
        }
        for _, entry in ipairs(pilgrimage.chains) do
            local rule = entry.archetypeRule
            seen[rule.key] = true
            assert(rule.key == 'great_sword_burst_survival' or rule.key == 'great_axe_armor'
                or rule.key == 'katana_shadows'
                or rule.minTp or rule.behind or rule.maxHpp
                or rule.maxMpp or rule.minDistance or rule.petAlive
                or rule.petOrBerserk)
            assert(rule.minDamage == nil)
            assert(pilgrimage.archetypePass(attacker, {}, rule, state.tp))
            if rule.minTp then
                assert(not pilgrimage.archetypePass(attacker, {}, rule, rule.minTp - 1))
            elseif rule.behind then
                state.behind = false
                assert(not pilgrimage.archetypePass(attacker, {}, rule, state.tp))
                state.behind = true
            elseif rule.maxHpp then
                state.hpp = rule.maxHpp + 1
                assert(not pilgrimage.archetypePass(attacker, {}, rule, state.tp))
                state.hpp = 0
            elseif rule.maxMpp then
                state.mpp = rule.maxMpp + 1
                assert(not pilgrimage.archetypePass(attacker, {}, rule, state.tp))
                state.mpp = 0
            elseif rule.minDistance then
                state.distance = rule.minDistance - 1
                assert(not pilgrimage.archetypePass(attacker, {}, rule, state.tp))
                state.distance = 99
            elseif rule.petAlive or rule.petOrBerserk then
                state.pet, state.status = false, false
                assert(not pilgrimage.archetypePass(attacker, {}, rule, state.tp))
                state.pet, state.status = true, true
            end
        end
        local count = 0
        for _ in pairs(seen) do count = count + 1 end
        assert(count == 14)
    end)

    it('normalizes catalog targets to live source entity names', function()
        for label, targets in pairs(pilgrimage.TARGETS) do
            local normalized = {}
            for _, name in ipairs(targets) do
                local key = pilgrimage.normalizeName(name)
                assert(key ~= '', 'Empty normalized target in ' .. label)
                assert(not normalized[key], 'Duplicate normalized target in ' .. label .. ': ' .. name)
                normalized[key] = true
            end
        end

        local unityNames = {}
        for _, nm in ipairs(unity.nms) do unityNames[pilgrimage.normalizeName(nm.name)] = true end
        for _, name in ipairs(pilgrimage.TARGETS.unity) do
            assert(unityNames[pilgrimage.normalizeName(name)], 'Unknown Unity target: ' .. name)
        end

        for _, name in ipairs(pilgrimage.TARGETS.abyssea) do
            assert(abyssea.get(name), 'Unknown Abyssea target: ' .. name)
        end

        local voidwatchNames = {}
        for name in pairs(voidwatch.UNIQUE_NMS) do
            voidwatchNames[pilgrimage.normalizeName(name)] = true
        end
        for _, name in ipairs(pilgrimage.TARGETS.voidwatch) do
            assert(voidwatchNames[pilgrimage.normalizeName(name)], 'Unknown Voidwatch target: ' .. name)
        end

        assert(pilgrimage.TARGETS.divergence[1] == 'Disjoined Elvaan')
        assert(pilgrimage.TARGETS.divergence[2] == 'Disjoined Galka')
        assert(pilgrimage.TARGETS.divergence[3] == 'Disjoined Tarutaru')
        assert(pilgrimage.TARGETS.divergence[4] == 'Disjoined Mithra')
    end)

    it('matches all four instanced Divergence Disjoined names', function()
        local requirement =
        {
            tag = 'divergence_disjoined',
            targets = pilgrimage.TARGETS.divergence,
        }
        local internalNames =
        {
            'Disjoined_Elvaan_D',
            'Disjoined_Galka_D',
            'Disjoined_Tarutaru_D',
            'Disjoined_Mithra_D',
        }

        for index, name in ipairs(internalNames) do
            assert(pilgrimage.targetIndex(requirement, name) == index)
        end
    end)
end)
