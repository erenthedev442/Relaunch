local overhaul = require('modules/custom/lua/BstJugPetOverhaul')
local jugCatalog = require('modules/custom/lua/jug_power_catalog')
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')
require('scripts/globals/mobskills')

describe('BST jug investment progression', function()
    local function makeMaster(mods, itemId, jobPoints, mainJob)
        return
        {
            getMod = function(_, modId)
                return (mods or {})[modId] or 0
            end,
            getEquipID = function()
                return itemId or 1
            end,
            getMainLvl = function()
                return 99
            end,
            getMainJob = function()
                return mainJob or xi.job.BST
            end,
            getSpentJobPoints = function()
                return jobPoints or 0
            end,
            isPC = function()
                return true
            end,
        }
    end

    local function makeJug(master, ecosystem)
        local localVars =
        {
            JugEcosystemFavorableBps = 5000,
            JugEcosystemUnfavorableBps = 2500,
        }

        return
        {
            getMaster = function()
                return master
            end,
            getEcosystem = function()
                return ecosystem
            end,
            getLocalVar = function(_, name)
                return localVars[name] or 0
            end,
            isJugPet = function()
                return true
            end,
            setLocalVar = function(_, name, value)
                localVars[name] = value
            end,
        }
    end

    local function makeTarget(ecosystem)
        return
        {
            getEcosystem = function()
                return ecosystem
            end,
            getMainLvl = function()
                return 155
            end,
        }
    end

    it('does not raise Ready floors without meaningful pet investment', function()
        local master = makeMaster({})

        assert(overhaul.getReadyInvestmentMultiplier(master, false) == 1)
        assert(overhaul.getReadyInvestmentMultiplier(master, true) == 1)
    end)

    it('scales physical and magical floors from their matching offensive mods', function()
        local shared =
        {
            [xi.mod.PET_BEAST_AFF] = 50,
            [xi.mod.PET_ATTR_BONUS] = 750,
            [xi.mod.PET_TP_BONUS] = 750,
        }
        local physical = {}
        local magical = {}
        for modId, value in pairs(shared) do
            physical[modId] = value
            magical[modId] = value
        end
        physical[xi.mod.PET_ATK_DEF] = 750
        magical[xi.mod.PET_MAB_MDB] = 750

        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(physical), false) == 4.4375)
        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(physical), true) == 3.75)
        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(magical), true) == 4.4375)
        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(magical), false) == 3.75)
    end)

    it('caps full and malformed investment at safe bounds', function()
        local maxed =
        {
            [xi.mod.PET_BEAST_AFF] = 900,
            [xi.mod.PET_ATK_DEF] = 9000,
            [xi.mod.PET_MAB_MDB] = 9000,
            [xi.mod.PET_ATTR_BONUS] = 9000,
            [xi.mod.PET_TP_BONUS] = 9000,
        }
        local negative =
        {
            [xi.mod.PET_BEAST_AFF] = -100,
            [xi.mod.PET_ATK_DEF] = -100,
            [xi.mod.PET_MAB_MDB] = -100,
            [xi.mod.PET_ATTR_BONUS] = -100,
            [xi.mod.PET_TP_BONUS] = -100,
        }

        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(maxed), false) == 12)
        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(maxed), true) == 12)
        assert(overhaul.getReadyInvestmentMultiplier(
            makeMaster(negative), false) == 1)
    end)

    it('gives Dipper Yuly an explicit fast-role identity', function()
        local dipper = jugCatalog.get(xi.petId.DIPPER_YULY)

        assert(dipper.style == 'fast')
        assert(dipper.power == 1)
        assert(dipper.weights.weapon == 0.95)
    end)

    it('puts max-investment Prime burst above REMA without automatic cap hits', function()
        local maxed =
        {
            [xi.mod.PET_BEAST_AFF] = 100,
            [xi.mod.PET_ATK_DEF] = 3000,
            [xi.mod.PET_ATTR_BONUS] = 3000,
            [xi.mod.PET_TP_BONUS] = 3000,
        }
        local primeMaster = makeMaster(maxed, 21730, 2100)
        local remaMaster = makeMaster(maxed, 21751, 2100) -- Aymur
        local target = makeTarget(xi.ecosystem.PLANTOID)
        local primeJug = makeJug(primeMaster, xi.ecosystem.VERMIN)
        local remaJug = makeJug(remaMaster, xi.ecosystem.VERMIN)
        local investedStock = math.floor(
            1200 * overhaul.getReadyInvestmentMultiplier(primeMaster, false))
        local primeMatched = xi.mobskills.applyJugEcosystemMatchupDamage(
            primeJug, target, investedStock)
        local remaMatched = xi.mobskills.applyJugEcosystemMatchupDamage(
            remaJug, target, investedStock)
        local primeDamage = progression.applyMultiplier(
            primeMatched,
            progression.getPetDamageMultiplier(primeMaster, target),
            progression.setPetDamageCap(primeJug, primeMaster))
        local remaDamage = progression.applyMultiplier(
            remaMatched,
            progression.getPetDamageMultiplier(remaMaster, target),
            progression.setPetDamageCap(remaJug, remaMaster))

        assert(remaDamage == 677160)
        assert(primeDamage == 1009800)
        assert(primeDamage < progression.PET_PRIME_DAMAGE_CAP)
    end)

    it('caps exceptional favorable Prime Ready damage at 1499999', function()
        local maxed =
        {
            [xi.mod.PET_BEAST_AFF] = 100,
            [xi.mod.PET_ATK_DEF] = 3000,
            [xi.mod.PET_ATTR_BONUS] = 3000,
            [xi.mod.PET_TP_BONUS] = 3000,
        }
        local master = makeMaster(maxed, 21730, 2100)
        local target = makeTarget(xi.ecosystem.PLANTOID)
        local jug = makeJug(master, xi.ecosystem.VERMIN)
        local matched = xi.mobskills.applyJugEcosystemMatchupDamage(
            jug, target, 24000)

        assert(progression.applyMultiplier(
            matched,
            progression.getPetDamageMultiplier(master, target),
            progression.setPetDamageCap(jug, master)) == 1499999)
    end)

    it('retains the companion AoE reduction at maximum investment', function()
        local master = makeMaster({}, 21730, 2100)
        local target = makeTarget(xi.ecosystem.PLANTOID)
        local jug = makeJug(master, xi.ecosystem.VERMIN)
        local fullMultiplier = progression.getPetDamageMultiplier(master, target)
        local aoeMultiplier = 1 + (fullMultiplier - 1) * 0.50
        local aoeCap = math.floor(
            progression.setPetDamageCap(jug, master) * 0.50)
        local matched = xi.mobskills.applyJugEcosystemMatchupDamage(
            jug, target, 24000)

        assert(aoeMultiplier == 23.875)
        assert(aoeCap == 749999)
        assert(progression.applyMultiplier(
            matched, aoeMultiplier, aoeCap) == 749999)
    end)

    it('does not grant BST progression from another jobs Prime weapon', function()
        local master = makeMaster({}, 22106, 2100) -- SMN Opashoro on BST
        local target = makeTarget(xi.ecosystem.PLANTOID)

        assert(progression.getPetDamageMultiplier(master, target) == 11)
        assert(progression.getPetDamageCap(master) == 79999)
    end)
end)
