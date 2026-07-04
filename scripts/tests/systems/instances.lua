local customCrawlersNestDungeon = require('scripts/zones/Crawlers_Nest/instances/dungeon_crawlers_nest')
local dungeonCatalog = require('modules/custom/lua/dungeon_catalog')
local unityWantedInstance = require('scripts/zones/Ghelsba_Outpost/instances/unity_wanted_trial')
local unityWantedRuntime = require('modules/custom/lua/unity_wanted_instance_runtime')

describe('Instances', function()
    it("loads the custom Crawlers' Nest dungeon definition", function()
        assert(type(customCrawlersNestDungeon.onInstanceCreated) == 'function')
        assert(type(customCrawlersNestDungeon.onInstanceTimeUpdate) == 'function')
        assert(type(customCrawlersNestDungeon.onInstanceComplete) == 'function')
    end)

    it('loads every categorized dungeon with a complete isolated roster', function()
        local dungeonCount = 0
        local instanceIds = {}

        for _, dungeon in pairs(dungeonCatalog.dungeons) do
            dungeonCount = dungeonCount + 1
            assert(not instanceIds[dungeon.instanceId], 'duplicate dungeon instance ID')
            instanceIds[dungeon.instanceId] = true
            assert(#dungeon.mobs == 13, dungeon.label .. ' must have 13 mobs')

            local groups = {}
            for _, mob in ipairs(dungeon.mobs) do
                assert(not groups[mob.groupId], dungeon.label .. ' has a duplicate group ID')
                groups[mob.groupId] = true
            end

            local instanceScript = require(string.format(
                'scripts/zones/%s/instances/%s', dungeon.zoneName, dungeon.scriptName))
            assert(type(instanceScript.onInstanceCreated) == 'function')
            assert(type(instanceScript.onInstanceTimeUpdate) == 'function')
            assert(type(instanceScript.onInstanceComplete) == 'function')
        end

        assert(dungeonCount == 10)
        assert(#dungeonCatalog.categories == 3)
        assert(dungeonCatalog.getDungeonByInstanceId(19700).label == "Crawlers' Nest")
        assert(dungeonCatalog.getDungeonByInstanceId(9999) == nil)
    end)

    it('builds separate runtime handlers for repeated copies of one template', function()
        local dungeonRuntime = require('modules/custom/lua/dungeon_instance')
        local firstCopy = dungeonRuntime.create('crawlersNest')
        local secondCopy = dungeonRuntime.create('crawlersNest')

        assert(firstCopy ~= secondCopy)
        assert(firstCopy.onInstanceCreated ~= secondCopy.onInstanceCreated)
    end)

    it('loads the private Unity Wanted trial without replacing the Escha board', function()
        assert(unityWantedRuntime.config.instanceId == 14000)
        assert(unityWantedRuntime.config.zoneId == xi.zone.GHELSBA_OUTPOST)
        assert(unityWantedRuntime.vars.nm == 'UWI_NM')
        assert(unityWantedRuntime.vars.nm ~= 'UW_NM')
        assert(type(unityWantedInstance.onInstanceCreatedCallback) == 'function')
        assert(type(unityWantedInstance.onInstanceCreated) == 'function')
        assert(type(unityWantedInstance.onInstanceTimeUpdate) == 'function')
        assert(type(unityWantedInstance.onInstanceComplete) == 'function')
        assert(type(unityWantedInstance.onInstanceFailure) == 'function')
        assert(unityWantedRuntime.getNm(1).name == 'Hugemaw_Harold')
        assert(unityWantedRuntime.getNm(56).name == 'Borealis_Shadow')
    end)

    it('Waking the Colossus spawns Alexander', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.ALZADAAL_UNDERSEA_RUINS })

        player:createInstance(7702)
        xi.test.world:tick(xi.tick.TIME)

        local instance = player:getInstance()
        assert(instance and instance:getID() == 7702)

        for _, mob in pairs(instance:getMobs()) do
            if mob:getName() == 'Alexander_WTC' then
                return
            end
        end

        assert(false, 'Alexander_WTC not spawned')
    end)
end)
