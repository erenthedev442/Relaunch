require('scripts/globals/mobskills')

describe('BST jug ecosystem matchup damage', function()
    local function makeJug(ecosystem, isJug, ownerState, mainJob)
        local master =
        {
            isPC = function()
                return ownerState ~= false
            end,
            getMainJob = function()
                return mainJob or xi.job.BST
            end,
        }

        return
        {
            getLocalVar = function(_, name)
                if name == 'JugEcosystemFavorableBps' then
                    return 5000
                elseif name == 'JugEcosystemUnfavorableBps' then
                    return 2500
                end

                return 0
            end,
            isJugPet = function()
                return isJug ~= false
            end,
            getEcosystem = function()
                return ecosystem
            end,
            getMaster = function()
                if ownerState == 'none' then
                    return nil
                end

                return master
            end,
        }
    end

    local function makeTarget(ecosystem)
        return
        {
            getEcosystem = function()
                return ecosystem
            end,
        }
    end

    it('rewards the jug family that naturally preys on the target', function()
        local beast = makeJug(xi.ecosystem.BEAST)
        local lizard = makeTarget(xi.ecosystem.LIZARD)

        assert(xi.mobskills.applyJugEcosystemMatchupDamage(beast, lizard, 10000) == 15000)
    end)

    it('penalizes a jug fighting its natural predator', function()
        local beast = makeJug(xi.ecosystem.BEAST)
        local plantoid = makeTarget(xi.ecosystem.PLANTOID)

        assert(xi.mobskills.applyJugEcosystemMatchupDamage(beast, plantoid, 10000) == 7500)
    end)

    it('supports the Aquan, Amorph and Bird triangle', function()
        local aquan = makeJug(xi.ecosystem.AQUAN)

        assert(xi.mobskills.applyJugEcosystemMatchupDamage(
            aquan, makeTarget(xi.ecosystem.AMORPH), 10000) == 15000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(
            aquan, makeTarget(xi.ecosystem.BIRD), 10000) == 7500)
    end)

    it('matches every canonical ecosystem relationship at plus 50 or minus 25 percent', function()
        local relationships =
        {
            { xi.ecosystem.BEAST,     xi.ecosystem.LIZARD,   xi.ecosystem.PLANTOID },
            { xi.ecosystem.LIZARD,    xi.ecosystem.VERMIN,   xi.ecosystem.BEAST },
            { xi.ecosystem.VERMIN,    xi.ecosystem.PLANTOID, xi.ecosystem.LIZARD },
            { xi.ecosystem.PLANTOID,  xi.ecosystem.BEAST,    xi.ecosystem.VERMIN },
            { xi.ecosystem.AQUAN,     xi.ecosystem.AMORPH,   xi.ecosystem.BIRD },
            { xi.ecosystem.AMORPH,    xi.ecosystem.BIRD,     xi.ecosystem.AQUAN },
            { xi.ecosystem.BIRD,      xi.ecosystem.AQUAN,    xi.ecosystem.AMORPH },
        }

        for _, relationship in ipairs(relationships) do
            local jug = makeJug(relationship[1])
            assert(xi.mobskills.applyJugEcosystemMatchupDamage(
                jug, makeTarget(relationship[2]), 10000) == 15000)
            assert(xi.mobskills.applyJugEcosystemMatchupDamage(
                jug, makeTarget(relationship[3]), 10000) == 7500)
        end

        local reciprocalRelationships =
        {
            { xi.ecosystem.UNDEAD,   xi.ecosystem.ARCANA },
            { xi.ecosystem.DRAGON,   xi.ecosystem.DEMON },
            { xi.ecosystem.LUMINIAN, xi.ecosystem.LUMINION },
        }

        for _, relationship in ipairs(reciprocalRelationships) do
            assert(xi.mobskills.applyJugEcosystemMatchupDamage(
                makeJug(relationship[1]),
                makeTarget(relationship[2]),
                10000) == 15000)
            assert(xi.mobskills.applyJugEcosystemMatchupDamage(
                makeJug(relationship[2]),
                makeTarget(relationship[1]),
                10000) == 15000)
        end
    end)

    it('leaves neutral, unrelated, and non-player-owned damage unchanged', function()
        local beast = makeJug(xi.ecosystem.BEAST)
        local nonJug = makeJug(xi.ecosystem.BEAST, false)
        local npcOwnedJug = makeJug(xi.ecosystem.BEAST, true, false)
        local unownedJug = makeJug(xi.ecosystem.BEAST, true, 'none')
        local nonBstJug = makeJug(xi.ecosystem.BEAST, true, true, xi.job.WAR)
        local neutral = makeTarget(xi.ecosystem.BEASTMEN)
        local favorable = makeTarget(xi.ecosystem.LIZARD)

        assert(xi.mobskills.applyJugEcosystemMatchupDamage(beast, neutral, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(nonJug, favorable, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(npcOwnedJug, favorable, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(unownedJug, favorable, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(nonBstJug, favorable, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(nil, favorable, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(beast, nil, 10000) == 10000)
        assert(xi.mobskills.applyJugEcosystemMatchupDamage(beast, favorable, nil) == nil)
    end)
end)
