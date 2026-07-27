local catalog = require('modules/custom/lua/standard_magic_tuning_catalog')

describe('Level-scaled direct magic tuning', function()
    local function makeCaster(level, isPlayer, mainJob, equipment, spentJobPoints)
        equipment = equipment or {}
        return
        {
            isPC = function()
                return isPlayer ~= false
            end,
            isAutomaton = function()
                return false
            end,
            getMainLvl = function()
                return level
            end,
            getMainJob = function()
                return mainJob or xi.job.BLM
            end,
            getEquipID = function(_, slot)
                return equipment[slot] or 0
            end,
            getSpentJobPoints = function()
                return spentJobPoints or 0
            end,
        }
    end

    local function makeTarget(level, maxHp, isMob)
        return
        {
            isMob = function()
                return isMob ~= false
            end,
            getMainLvl = function()
                return level
            end,
            getMaxHP = function()
                return maxHp
            end,
        }
    end

    local function makeSpell(id, skill, level, nativeJob)
        return
        {
            getID = function()
                return id
            end,
            getSkillType = function()
                return skill
            end,
            getLevel = function(_, jobId)
                if nativeJob and jobId ~= nativeJob then
                    return 255
                end

                return level or 99
            end,
        }
    end

    it('uses spell-tier and mastery multipliers', function()
        local caster = makeCaster(99)
        local target = makeTarget(155, 120000)
        local highTierSpell = makeSpell(
            xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 86)

        assert(catalog.DAMAGE_CAP == 99999)
        assert(catalog.getDamageMultiplier(caster, target, highTierSpell) == 8)
        assert(catalog.getBaseStockBonus(caster, target, highTierSpell) == 600)
        assert(catalog.getMagicAccuracyPenalty(caster, target) == 0)
        assert(catalog.getDamageMultiplier(
            caster, target,
            makeSpell(xi.magic.spell.STONE, xi.skill.ELEMENTAL_MAGIC, 1)) == 1.45)
        assert(catalog.getDamageMultiplier(
            makeCaster(99, true, xi.job.SCH), target,
            makeSpell(xi.magic.spell.FIRE_IV, xi.skill.ELEMENTAL_MAGIC, 73, xi.job.SCH)) == 6)
        assert(catalog.getDamageMultiplier(
            caster, target,
            makeSpell(xi.magic.spell.FREEZE, xi.skill.ELEMENTAL_MAGIC, 50)) == 8)

        caster = makeCaster(99, true, xi.job.BLM, {}, 2100)
        assert(catalog.getDamageMultiplier(caster, target, highTierSpell) == 13)
        assert(catalog.getBaseStockBonus(caster, target, highTierSpell) == 1050)
        assert((100 + catalog.getBaseStockBonus(caster, target, highTierSpell)) *
            catalog.getDamageMultiplier(caster, target, highTierSpell) == 14950)
        assert((3200 + catalog.getBaseStockBonus(caster, target, highTierSpell)) *
            catalog.getDamageMultiplier(caster, target, highTierSpell) == 55250)
        assert((6500 + catalog.getBaseStockBonus(caster, target, highTierSpell)) *
            catalog.getDamageMultiplier(caster, target, highTierSpell) == 98150)
        assert(catalog.getDamageMultiplier(
            caster, makeTarget(76, 8000), highTierSpell) == 13)

        caster = makeCaster(50)
        target = makeTarget(58, 10000)
        assert(math.abs(catalog.getDamageMultiplier(
            caster, target,
            makeSpell(xi.magic.spell.STONE_III, xi.skill.ELEMENTAL_MAGIC, 40)) -
            2.060606) < 0.000001)
        assert(catalog.getMagicAccuracyPenalty(caster, target) == 40)
    end)

    it('keeps ninjutsu in a lower progression band', function()
        local target = makeTarget(155, 120000)
        local katon = makeSpell(
            xi.magic.spell.KATON_SAN, xi.skill.NINJUTSU, 75, xi.job.NIN)

        assert(catalog.getDamageMultiplier(
            makeCaster(99, true, xi.job.NIN), target, katon) == 5)
        assert(catalog.getDamageMultiplier(
            makeCaster(99, true, xi.job.NIN, {}, 2100), target, katon) == 8)
    end)

    it('allows direct elemental, divine, and ninjutsu casts', function()
        local caster = makeCaster(99)
        local target = makeTarget(155, 120000)

        assert(catalog.isDirectSpellEligible(
            caster, target, makeSpell(xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC)))
        assert(catalog.isDirectSpellEligible(
            caster, target, makeSpell(xi.magic.spell.BANISH_III, xi.skill.DIVINE_MAGIC)))
        assert(catalog.isDirectSpellEligible(
            caster, target, makeSpell(xi.magic.spell.KATON_SAN, xi.skill.NINJUTSU)))
        assert(catalog.isDirectSpellEligible(
            makeCaster(99, true, xi.job.SCH), target,
            makeSpell(xi.magic.spell.FIRE_IV, xi.skill.ELEMENTAL_MAGIC, 73, xi.job.SCH)))
    end)

    it('requires the spell to be native to the current main job', function()
        local target = makeTarget(155, 120000)
        local fireV = makeSpell(
            xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 86, xi.job.BLM)

        assert(catalog.isDirectSpellEligible(
            makeCaster(99, true, xi.job.BLM), target, fireV))
        assert(not catalog.isDirectSpellEligible(
            makeCaster(99, true, xi.job.SAM), target, fireV))
    end)

    it('excludes Helix, dark magic, non-player casts, and non-mob targets', function()
        local caster = makeCaster(99)
        local target = makeTarget(155, 120000)

        assert(not catalog.isDirectSpellEligible(
            caster, target, makeSpell(xi.magic.spell.GEOHELIX, xi.skill.ELEMENTAL_MAGIC)))
        assert(not catalog.isDirectSpellEligible(
            caster, target, makeSpell(xi.magic.spell.BIO_II, xi.skill.DARK_MAGIC)))
        assert(not catalog.isDirectSpellEligible(
            makeCaster(99, false), target,
            makeSpell(xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC)))
        assert(not catalog.isDirectSpellEligible(
            caster, makeTarget(99, 2000, false),
            makeSpell(xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC)))
    end)

    it('allows physical, magical, and breath Blue Magic damage paths', function()
        local caster = makeCaster(99, true, xi.job.BLU)
        local target = makeTarget(155, 120000)
        local blueSpell = makeSpell(527, xi.skill.BLUE_MAGIC, 68, xi.job.BLU)

        assert(catalog.isBlueDamageEligible(
            caster, target, blueSpell, { attackType = xi.attackType.MAGICAL }))
        assert(catalog.isBlueDamageEligible(
            caster, target, blueSpell, { attackType = xi.attackType.PHYSICAL }))
        assert(catalog.isBlueDamageEligible(
            caster, target, blueSpell, { attackType = xi.attackType.BREATH }))
        assert(not catalog.isBlueDamageEligible(
            makeCaster(99, true, xi.job.SAM), target, blueSpell,
            { attackType = xi.attackType.MAGICAL }))
    end)

    it('lets player automatons use their spell-tier multiplier', function()
        local master = makeCaster(99, true, xi.job.PUP)
        local automaton =
        {
            isPC = function()
                return false
            end,
            isAutomaton = function()
                return true
            end,
            getMaster = function()
                return master
            end,
        }
        local target = makeTarget(155, 120000)
        local spell = makeSpell(
            xi.magic.spell.FIRE_IV, xi.skill.ELEMENTAL_MAGIC, 75)

        assert(catalog.isDirectSpellEligible(automaton, target, spell))
        assert(catalog.getDamageMultiplier(automaton, target, spell) == 8)
        assert(catalog.getBaseStockBonus(automaton, target, spell) == 600)
    end)

    it('raises cast caps for equipped final REMA and Prime weapons', function()
        assert(catalog.getDamageCap(makeCaster(99)) == 99999)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM,
            { [xi.slot.MAIN] = 22062 })) == 999999)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM,
            { [xi.slot.MAIN] = 22106 })) == 1999999)
    end)
end)
