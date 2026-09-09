local catalog = require('modules/custom/lua/voidspire_catalog')
local gmCatalog = require('modules/custom/lua/game_master_catalog')

describe('Voidspire incoming-skill caps', function()
    it('caps every Voidspire hit at 7500, including Dreadstorm', function()
        assert(catalog.outgoingDamageCap == 7500)
        local caps = catalog.skillDamageCaps
        assert(caps.Hakutaku.DeathRay == 5000)
        assert(caps.Khimaira.Fulmination >= 4000 and caps.Khimaira.Fulmination <= 7500)
        assert(caps.Khimaira.Thunderstrike >= 4000 and caps.Khimaira.Thunderstrike <= 7500)
        assert(caps.Khimaira.Dreadstorm == 7500)
        assert(caps.Cerberus.GatesOfHades >= 4000 and caps.Cerberus.GatesOfHades <= 7500)
        assert(caps.Tiamat.InfernoBlast <= catalog.outgoingDamageCap)
        assert(caps.Tiamat.TebbadWingAir <= catalog.outgoingDamageCap)

        for mobName, skills in pairs(caps) do
            for skillName, cap in pairs(skills) do
                assert(cap <= catalog.outgoingDamageCap,
                    string.format('%s %s cap %d exceeds outgoingDamageCap', mobName, skillName, cap))
            end
        end
    end)
end)

describe('Voidspire floor-advance safety', function()
    it('gives each floor spawn a unique script name', function()
        local first = catalog.nextFloorScriptName()
        local second = catalog.nextFloorScriptName()
        assert(first:match('^VS_%d+$'))
        assert(second:match('^VS_%d+$'))
        assert(first ~= second)
    end)

    it('counts a floor kill only on the killing blow or a no-player kill', function()
        assert(catalog.shouldCountFloorKill({ }, { isKiller = true, noKiller = false }))
        assert(not catalog.shouldCountFloorKill({ }, { isKiller = false, noKiller = false }))
        assert(catalog.shouldCountFloorKill(nil, { noKiller = true }))
        assert(not catalog.shouldCountFloorKill(nil, { noKiller = false }))
        assert(catalog.shouldCountFloorKill({ }, nil))
        assert(catalog.floorWatchdogSec > catalog.floorDelay)
        assert(catalog.spawnRetries >= 2)
    end)
end)

describe('Voidspire plaza ground spawns', function()
    it('pins every roster mob to the Escha entry plaza so they cannot fall through', function()
        assert(catalog.arenaFloorY == catalog.npcPos.y)
        assert(catalog.groundAllSpawns)
        assert(catalog.groundSpawn.Khimaira)
        assert(catalog.groundSpawn.Cerberus)
        assert(catalog.groundSpawn.Vrtra)
        assert(catalog.groundSpawn.Tiamat)
        assert(catalog.groundSpawn.Nidhogg)
        assert(catalog.groundSpawn.Seiryu)
        assert(catalog.groundSpawnRing.maxRadius < catalog.spawnRing.minRadius)

        for _, band in ipairs(catalog.bands) do
            local def = gmCatalog.difficulties[band.diff]
            for _, mob in ipairs(def.mobs) do
                assert(catalog.groundAllSpawns or catalog.groundSpawn[mob.name],
                    string.format('%s is not grounded for Voidspire', mob.name))
            end
        end
    end)
end)
