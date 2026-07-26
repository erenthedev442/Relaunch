local catalog = require('modules/custom/lua/standard_magic_tuning_catalog')

describe('Level-scaled direct magic tuning', function()
    local function makeCaster(level, isPlayer, mainJob, equipment)
        equipment = equipment or {}
        return
        {
            isPC = function()
                return isPlayer ~= false
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

    it('targets the same HP share as ordinary weaponskills', function()
        local caster = makeCaster(99)
        local target = makeTarget(155, 120000)
        local highTierSpell = makeSpell(
            xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 86)

        assert(catalog.DAMAGE_CAP == 99999)
        assert(catalog.getDamageBonus(caster, target, highTierSpell) == 36000)
        assert(catalog.getMagicAccuracyPenalty(caster, target) == 0)
        assert(catalog.getDamageBonus(
            caster, target,
            makeSpell(xi.magic.spell.STONE, xi.skill.ELEMENTAL_MAGIC, 1)) == 5400)

        caster = makeCaster(50)
        target = makeTarget(58, 10000)
        assert(catalog.getDamageBonus(
            caster, target,
            makeSpell(xi.magic.spell.STONE_III, xi.skill.ELEMENTAL_MAGIC, 40)) == 2100)
        assert(catalog.getMagicAccuracyPenalty(caster, target) == 40)
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

    it('allows only magical Blue Magic damage paths', function()
        local caster = makeCaster(99, true, xi.job.BLU)
        local target = makeTarget(155, 120000)
        local blueSpell = makeSpell(527, xi.skill.BLUE_MAGIC, 68, xi.job.BLU)

        assert(catalog.isMagicalBlueEligible(
            caster, target, blueSpell, { attackType = xi.attackType.MAGICAL }))
        assert(not catalog.isMagicalBlueEligible(
            caster, target, blueSpell, { attackType = xi.attackType.PHYSICAL }))
        assert(not catalog.isMagicalBlueEligible(
            makeCaster(99, true, xi.job.SAM), target, blueSpell,
            { attackType = xi.attackType.MAGICAL }))
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
