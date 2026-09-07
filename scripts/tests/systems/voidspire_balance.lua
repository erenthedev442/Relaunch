local catalog = require('modules/custom/lua/voidspire_catalog')

describe('Voidspire incoming-skill caps', function()
    it('caps the high-fTP magic nukes that Voidspire MATT would one-shot with', function()
        local caps = catalog.skillDamageCaps
        assert(caps.Hakutaku.DeathRay == 5000)
        assert(caps.Khimaira.Fulmination >= 4000 and caps.Khimaira.Fulmination <= 6000)
        assert(caps.Khimaira.Thunderstrike >= 4000 and caps.Khimaira.Thunderstrike <= 6000)
        assert(caps.Cerberus.GatesOfHades >= 4000 and caps.Cerberus.GatesOfHades <= 6000)
        -- Flying Tiamat: just under 9k-10k player HP, not the 4-6k nuke band.
        assert(caps.Tiamat.InfernoBlast >= 8000 and caps.Tiamat.InfernoBlast < 9000)
        assert(caps.Tiamat.TebbadWingAir >= 7500 and caps.Tiamat.TebbadWingAir < 9000)
    end)
end)

describe('Voidspire plaza ground spawns', function()
    it('pins Hard-band wyrms to the Escha entry plaza so they cannot fall through', function()
        assert(catalog.arenaFloorY == catalog.npcPos.y)
        assert(catalog.groundSpawn.Vrtra)
        assert(catalog.groundSpawn.Tiamat)
        assert(catalog.groundSpawn.Nidhogg)
        assert(catalog.groundSpawnRing.maxRadius < catalog.spawnRing.minRadius)
    end)
end)
