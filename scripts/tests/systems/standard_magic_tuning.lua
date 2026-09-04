local catalog = require('modules/custom/lua/standard_magic_tuning_catalog')

describe('Level-scaled direct magic tuning', function()
    local function makeCaster(level, isPlayer, mainJob, equipment, spentJobPoints, itemLevel, subJob)
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
            getSubJob = function()
                return subJob or xi.job.NONE
            end,
            getEquipID = function(_, slot)
                local entry = equipment[slot]
                if type(entry) == 'table' then
                    return entry.id or 0
                end

                return entry or 0
            end,
            getEquippedItem = function(_, slot)
                local entry = equipment[slot]
                if entry == nil or entry == 0 then
                    return nil
                end

                local id = type(entry) == 'table' and entry.id or entry
                local ilvl = type(entry) == 'table' and entry.ilvl or itemLevel or 0
                return
                {
                    getILvl = function()
                        return ilvl
                    end,
                    getID = function()
                        return id
                    end,
                }
            end,
            getSpentJobPoints = function()
                return spentJobPoints or 0
            end,
        }
    end

    local function makeTarget(level, maxHp, isMob, id)
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
            getID = function()
                return id or 1
            end,
        }
    end

    local function makeSpell(id, skill, level, nativeJob, isAoE, primaryTargetId)
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
            isAoE = function()
                return isAoE and 1 or 0
            end,
            getPrimaryTargetID = function()
                return primaryTargetId or 0
            end,
        }
    end

    it('uses spell-tier and mastery multipliers', function()
        local caster = makeCaster(99)
        local target = makeTarget(155, 120000)
        local highTierSpell = makeSpell(
            xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 86)

        assert(catalog.DAMAGE_CAP == 79999)
        assert(catalog.NON_ITEM_LEVEL_119_CAP == 40000)
        assert(catalog.getDamageMultiplier(caster, target, highTierSpell) == 8)
        assert(catalog.getBaseStockBonus(caster, target, highTierSpell) == 0)
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
        assert(catalog.getBaseStockBonus(caster, target, highTierSpell) == 0)
        assert((100 + catalog.getBaseStockBonus(caster, target, highTierSpell)) *
            catalog.getDamageMultiplier(caster, target, highTierSpell) == 800)
        assert((3200 + catalog.getBaseStockBonus(caster, target, highTierSpell)) *
            catalog.getDamageMultiplier(caster, target, highTierSpell) == 41600)
        assert((6500 + catalog.getBaseStockBonus(caster, target, highTierSpell)) *
            catalog.getDamageMultiplier(caster, target, highTierSpell) == 84500)
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

    it('keeps automaton nukes on companion weapon tiers', function()
        local function makeAutomaton(master)
            local localVars = {}

            return
            {
                isAutomaton = function()
                    return true
                end,
                isPC = function()
                    return false
                end,
                getMaster = function()
                    return master
                end,
                setLocalVar = function(_, name, value)
                    localVars[name] = value
                end,
            }
        end

        assert(catalog.getDamageCap(
            makeAutomaton(makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 1 }))) == 79999)
        assert(catalog.getDamageCap(
            makeAutomaton(makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 20511 }))) == 999999)
        assert(catalog.getDamageCap(
            makeAutomaton(makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 21535 }))) == 1499999)

        local firega = makeSpell(
            xi.magic.spell.FIRAGA, xi.skill.ELEMENTAL_MAGIC, 28, xi.job.BLM, true)
        assert(catalog.getAoEDamageCap(
            makeAutomaton(makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 1 })), firega) == 40000)
        assert(catalog.getAoEDamageCap(
            makeAutomaton(makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 20511 })), firega) == 149999)
        assert(catalog.getAoEDamageCap(
            makeAutomaton(makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 21535 })), firega) == 199999)
    end)

    it('uses lower player caps for companion main jobs only', function()
        assert(catalog.getDamageCap(
            makeCaster(99, true, xi.job.SMN, { [xi.slot.MAIN] = 22063 })) == 249999)
        assert(catalog.getDamageCap(
            makeCaster(99, true, xi.job.PUP, { [xi.slot.MAIN] = 21535 })) == 499999)
        assert(catalog.getDamageCap(
            makeCaster(99, true, xi.job.BLM, { [xi.slot.MAIN] = 22062 })) == 999999)
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
        assert(catalog.isDirectSpellEligible(
            makeCaster(99, true, xi.job.RDM), target,
            makeSpell(xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 91, xi.job.RDM)))
        assert(catalog.isDirectSpellEligible(
            makeCaster(99, true, xi.job.BLM), target,
            makeSpell(xi.magic.spell.BLIZZARD_VI, xi.skill.ELEMENTAL_MAGIC, 99, xi.job.BLM)))
    end)

    it('allows Helix but excludes ordinary dark magic, non-player casts, and non-mob targets', function()
        local caster = makeCaster(99)
        local target = makeTarget(155, 120000)

        assert(catalog.isDirectSpellEligible(
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
        assert(catalog.getBaseStockBonus(automaton, target, spell) == 0)
    end)

    it('raises cast caps along the ordinary 40k / 79,999 / 99,999 / 999,999 ladder', function()
        assert(catalog.getDamageCap(makeCaster(99)) == 40000)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = { id = 1, ilvl = 119 } })) == 79999)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 22086 })) == 99999)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 21139 })) == 99999)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM,
            { [xi.slot.MAIN] = 22062 })) == 999999)
        assert(catalog.getDamageCap(makeCaster(
            99, true, xi.job.BLM,
            { [xi.slot.MAIN] = 22106 })) == 999999)
    end)

    it('keeps RDM and subjob elemental far below main BLM', function()
        local fireV = makeSpell(
            xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 86, xi.job.BLM)
        local rdmFire = makeSpell(
            xi.magic.spell.FIRE_IV, xi.skill.ELEMENTAL_MAGIC, 73, xi.job.RDM)

        assert(catalog.getCasterPowerFactor(makeCaster(99, true, xi.job.BLM), fireV) == 1.00)
        assert(catalog.getCasterPowerFactor(makeCaster(99, true, xi.job.RDM), rdmFire) == 0.35)
        assert(catalog.getCasterPowerFactor(makeCaster(99, true, xi.job.WAR), fireV) == 0.20)
        assert(catalog.getCasterPowerFactor(makeCaster(99, true, xi.job.SAM), fireV) == 0.20)
    end)

    it('keeps SCH at 0.90 and treats /SCH like /BLM', function()
        local target = makeTarget(50, 9000)
        local schFireIV = makeSpell(
            xi.magic.spell.FIRE_IV, xi.skill.ELEMENTAL_MAGIC, 73, xi.job.SCH)
        local schFireV = makeSpell(
            xi.magic.spell.FIRE_V, xi.skill.ELEMENTAL_MAGIC, 91, xi.job.SCH)
        local firaga = makeSpell(
            xi.magic.spell.FIRAGA, xi.skill.ELEMENTAL_MAGIC, 28, xi.job.BLM)
        local flare = makeSpell(
            xi.magic.spell.FLARE, xi.skill.ELEMENTAL_MAGIC, 60, xi.job.BLM)
        local stone = makeSpell(
            xi.magic.spell.STONE, xi.skill.ELEMENTAL_MAGIC, 4, xi.job.SCH)
        local helix = makeSpell(
            xi.magic.spell.GEOHELIX, xi.skill.ELEMENTAL_MAGIC, 18, xi.job.SCH)

        assert(catalog.getCasterPowerFactor(
            makeCaster(99, true, xi.job.SCH), schFireIV) == 0.90)
        assert(catalog.getCasterPowerFactor(
            makeCaster(99, true, xi.job.SCH), schFireV) == 0.90)
        assert(catalog.getCasterPowerFactor(
            makeCaster(99, true, xi.job.SCH), firaga) == 0.20)
        assert(catalog.getCasterPowerFactor(
            makeCaster(99, true, xi.job.SCH), flare) == 0.20)
        assert(catalog.getCasterPowerFactor(
            makeCaster(50, true, xi.job.WAR, {}, 0, 0, xi.job.SCH), stone) == 0.20)
        assert(catalog.getCasterPowerFactor(
            makeCaster(50, true, xi.job.WHM, {}, 0, 0, xi.job.SCH), stone) == 0.20)
        assert(catalog.getCasterPowerFactor(
            makeCaster(50, true, xi.job.NIN, {}, 0, 0, xi.job.SCH), helix) == 0.20)
        assert(not catalog.isDirectSpellEligible(
            makeCaster(50, true, xi.job.WAR, {}, 0, 0, xi.job.SCH), target, stone))
        assert(not catalog.isDirectSpellEligible(
            makeCaster(99, true, xi.job.SCH), target, firaga))
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(50, true, xi.job.WAR, {}, 0, 0, xi.job.SCH),
            target, stone, 8000) == 1600)
    end)

    it('caps AoE nukes to the weaponskill AoE ceiling', function()
        local firega = makeSpell(
            xi.magic.spell.FIRAGA, xi.skill.ELEMENTAL_MAGIC, 28, xi.job.BLM, true)
        local stone = makeSpell(
            xi.magic.spell.STONE, xi.skill.ELEMENTAL_MAGIC, 1, xi.job.BLM, false)

        assert(catalog.getAoEDamageCap(makeCaster(99), stone) == nil)
        assert(catalog.getAoEDamageCap(makeCaster(99), firega) == 40000)
        assert(catalog.getAoEDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = { id = 1, ilvl = 119 } }), firega) == 79999)
        assert(catalog.getAoEDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 22086 }), firega) == 99999)
        assert(catalog.getAoEDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 21139 }), firega) == 99999)
        assert(catalog.getAoEDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 22062 }), firega) == 149999)
        assert(catalog.getAoEDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 22106 }), firega) == 199999)
        assert(catalog.getOutgoingDamageCap(makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 22062 }), firega) == 149999)
    end)

    it('keeps the aimed-at AoE target on the single-target ceiling', function()
        local caster = makeCaster(
            99, true, xi.job.BLM, { [xi.slot.MAIN] = 22062 })
        local primary = makeTarget(99, 500000, true, 100)
        local splash = makeTarget(99, 500000, true, 200)
        local firega = makeSpell(
            xi.magic.spell.FIRAGA, xi.skill.ELEMENTAL_MAGIC, 28, xi.job.BLM, true, 100)

        assert(catalog.isAoESplashTarget(firega, primary) == false)
        assert(catalog.isAoESplashTarget(firega, splash) == true)
        assert(catalog.getOutgoingDamageCap(caster, firega, primary) == 999999)
        assert(catalog.getOutgoingDamageCap(caster, firega, splash) == 149999)
        assert(catalog.applyPlayerOutgoingLimits(caster, primary, firega, 200000) == 200000)
        assert(catalog.applyPlayerOutgoingLimits(caster, splash, firega, 200000) == 149999)
    end)

    it('caps BLU AoE splash to the shared iLvl ladder while the aimed-at mob keeps the ST ceiling', function()
        local prime = makeCaster(99, true, xi.job.BLU, { [xi.slot.MAIN] = 21646 })
        local item119 = makeCaster(
            99, true, xi.job.BLU, { [xi.slot.MAIN] = { id = 1, ilvl = 119 } })
        local pre119 = makeCaster(
            99, true, xi.job.BLU, { [xi.slot.MAIN] = { id = 1, ilvl = 1 } })
        local primary = makeTarget(99, 5000000, true, 100)
        local splash = makeTarget(99, 5000000, true, 200)
        local floe = makeSpell(
            xi.magic.spell.SPECTRAL_FLOE, xi.skill.BLUE_MAGIC, 99, xi.job.BLU, true, 100)

        assert(catalog.getOutgoingDamageCap(prime, floe, primary) == 999999)
        assert(catalog.getOutgoingDamageCap(prime, floe, splash) == 199999)
        assert(catalog.getOutgoingDamageCap(item119, floe, splash) == 79999)
        assert(catalog.getOutgoingDamageCap(pre119, floe, splash) == 40000)
        assert(catalog.applyPlayerOutgoingLimits(prime, primary, floe, 400000) == 400000)
        assert(catalog.applyPlayerOutgoingLimits(prime, splash, floe, 400000) == 199999)
    end)

    it('clamps leveling nukes to one third of mob HP after the job factor', function()
        local caster = makeCaster(50)
        local target = makeTarget(50, 9000)
        local stone = makeSpell(
            xi.magic.spell.STONE, xi.skill.ELEMENTAL_MAGIC, 1, xi.job.BLM)

        assert(catalog.applyPlayerOutgoingLimits(caster, target, stone, 8000) == 3000)
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(99), makeTarget(10, 3000), stone, 40000) == 40000)
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(99, true, xi.job.WAR), target, stone, 8000) == 1600)
    end)

    it('treats Dia / Diaga / Bio opening hits as tokens, not nukes', function()
        local dia = makeSpell(
            xi.magic.spell.DIA, xi.skill.ENFEEBLING_MAGIC, 1, xi.job.WHM)
        local diaga = makeSpell(
            xi.magic.spell.DIAGA_II, xi.skill.ENFEEBLING_MAGIC, 31, xi.job.WHM)
        local bio = makeSpell(
            xi.magic.spell.BIO_II, xi.skill.DARK_MAGIC, 35, xi.job.BLM)

        assert(catalog.isTokenInitialSpell(dia))
        assert(catalog.isTokenInitialSpell(diaga))
        assert(catalog.isTokenInitialSpellId(xi.magic.spell.BIO_V))
        assert(not catalog.isTokenInitialSpell(
            makeSpell(xi.magic.spell.STONE, xi.skill.ELEMENTAL_MAGIC, 1)))
        assert(not catalog.isTokenInitialSpell(
            makeSpell(xi.magic.spell.BANISH, xi.skill.DIVINE_MAGIC, 5)))
        assert(not catalog.isTokenInitialSpell(
            makeSpell(xi.magic.spell.KAUSTRA, xi.skill.DARK_MAGIC, 5)))

        -- 33% leveling clamp, no RDM/WHM job-nuke factor (RDM nuke path
        -- would have been 8000 * 0.35 = 2800).
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(50, true, xi.job.RDM), makeTarget(50, 9000), dia, 8000) == 3000)
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(50), makeTarget(50, 9000), bio, 8000) == 3000)
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(50, true, xi.job.WHM), makeTarget(50, 9000), diaga, 8000) == 3000)
        assert(catalog.applyPlayerOutgoingLimits(
            makeCaster(99, true, xi.job.WHM), makeTarget(10, 3000), dia, 8000) == 8000)
    end)
end)
