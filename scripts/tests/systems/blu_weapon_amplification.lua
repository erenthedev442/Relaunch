local catalog = require('modules/custom/lua/blu_weapon_amplification_catalog')
local spellPower = require('modules/custom/lua/blu_spell_power_catalog')
local standardMagic = require('modules/custom/lua/standard_magic_tuning_catalog')

describe('BLU main-hand weapon amplification', function()
    local function makeCaster(itemId, itemLevel, mainJob)
        local weapon = itemId ~= 0 and
        {
            getILvl = function()
                return itemLevel or 0
            end,
        } or nil

        return
        {
            isPC = function()
                return true
            end,
            isAutomaton = function()
                return false
            end,
            getMainJob = function()
                return mainJob or xi.job.BLU
            end,
            getMainLvl = function()
                return 99
            end,
            getEquipID = function(_, slot)
                return slot == xi.slot.MAIN and itemId or 0
            end,
            getEquippedItem = function(_, slot)
                return slot == xi.slot.MAIN and weapon or nil
            end,
        }
    end

    local target =
    {
        isMob = function()
            return true
        end,
        getMainLvl = function()
            return 99
        end,
    }

    local spell =
    {
        getID = function()
            return 527
        end,
        getSkillType = function()
            return xi.skill.BLUE_MAGIC
        end,
        getLevel = function(_, jobId)
            return jobId == xi.job.BLU and 68 or 255
        end,
    }

    it('classifies every named BLU weapon tier exactly', function()
        local cases =
        {
            { 21646, 119, 'PRIME',     105, 999999 },
            { 20695, 119, 'AEONIC',     60, 750000 },
            { 20688, 119, 'MYTHIC',     45, 600000 },
            { 20689, 119, 'EMPYREAN',   45, 600000 },
            { 20685, 119, 'RELIC',      30, 400000 },
            { 21621, 119, 'AMBUSCADE',   9,   99999 },
            { 20651, 119, 'ITEM_119',    9,  239997 }, -- Tizona 119 I: floor 99,999, keep 119 cap
            { 20705, 119, 'ITEM_119',    9,  239997 },
            { 20731, 115, 'PRE_119',     9,  120000 },
        }

        for _, case in ipairs(cases) do
            local caster = makeCaster(case[1], case[2])
            local tier = catalog.classify(caster)
            assert(tier == case[3])
            assert(catalog.getDamageMultiplier(caster) == case[4])
            assert(catalog.getDamageCap(caster) == case[5])
        end
    end)

    it('replaces generic BLU progression with exact weapon ratios and caps', function()
        for _, case in ipairs(
        {
            { 21646, 105, 999999 },
            { 20695,  60, 750000 },
            { 20688,  45, 600000 },
            { 20689,  45, 600000 },
            { 20685,  30, 400000 },
            { 21621,   9,   99999 },
            { 20705,   9,  239997 },
            { 20731,   9,  120000 },
        })
        do
            local caster = makeCaster(case[1], case[1] == 20731 and 115 or 119)
            assert(standardMagic.getDamageMultiplier(caster, target, spell) == case[2])
            assert(standardMagic.getDamageCap(caster) == case[3])
        end
    end)

    it('keeps the aimed-at BLU AoE target on the single-target ceiling', function()
        local floe =
        {
            getID = function()
                return 720
            end,
            getSkillType = function()
                return xi.skill.BLUE_MAGIC
            end,
            getLevel = function(_, jobId)
                return jobId == xi.job.BLU and 99 or 255
            end,
            isAoE = function()
                return 1
            end,
            getPrimaryTargetID = function()
                return 100
            end,
        }

        local primary =
        {
            isMob = function()
                return true
            end,
            getMainLvl = function()
                return 99
            end,
            getMaxHP = function()
                return 5000000
            end,
            getID = function()
                return 100
            end,
        }

        local splash =
        {
            isMob = function()
                return true
            end,
            getMainLvl = function()
                return 99
            end,
            getMaxHP = function()
                return 5000000
            end,
            getID = function()
                return 200
            end,
        }

        -- Caliburnus is also a Prime item id (199,999 generic Prime AoE).
        -- Splash stays on the 149,999 BLU contract; primary keeps the ST cap.
        local prime = makeCaster(21646, 119)
        assert(catalog.AOE_DAMAGE_CAP == 149999)
        assert(standardMagic.getAoEDamageCap(prime, floe) == 149999)
        assert(standardMagic.getOutgoingDamageCap(prime, floe, primary) == 999999)
        assert(standardMagic.getOutgoingDamageCap(prime, floe, splash) == 149999)
        assert(standardMagic.applyPlayerOutgoingLimits(prime, primary, floe, 400000) == 400000)
        assert(standardMagic.applyPlayerOutgoingLimits(prime, splash, floe, 400000) == 149999)

        local tizona = makeCaster(20688, 119)
        assert(standardMagic.getOutgoingDamageCap(tizona, floe, primary) == 600000)
        assert(standardMagic.getOutgoingDamageCap(tizona, floe, splash) == 149999)

        local excalibur = makeCaster(20685, 119)
        assert(standardMagic.getOutgoingDamageCap(excalibur, floe, primary) == 400000)
        assert(standardMagic.applyPlayerOutgoingLimits(excalibur, primary, floe, 500000) == 400000)

        local sequence = makeCaster(20695, 119)
        assert(standardMagic.getOutgoingDamageCap(sequence, floe, primary) == 750000)

        local ambu = makeCaster(21621, 119)
        assert(standardMagic.getOutgoingDamageCap(ambu, floe, primary) == 99999)
        assert(standardMagic.getOutgoingDamageCap(ambu, floe, splash) == 99999)
    end)

    it('requires native main-job BLU and honors explicit exemptions', function()
        local params = { attackType = xi.attackType.MAGICAL }
        assert(standardMagic.isBlueDamageEligible(makeCaster(20685, 119), target, spell, params))
        assert(not standardMagic.isBlueDamageEligible(
            makeCaster(20685, 119, xi.job.SAM), target, spell, params))
        assert(not standardMagic.isBlueDamageEligible(
            makeCaster(20685, 119), target, spell,
            { attackType = xi.attackType.MAGICAL, blueDamageExempt = true }))
    end)

    it('scales spell budgets from 9x baseline to 15x premium damage', function()
        local function makeSpell(id, mpCost)
            return
            {
                getID = function()
                    return id
                end,
                getMPCost = function()
                    return mpCost
                end,
            }
        end

        assert(spellPower.getDamageMultiplier(makeSpell(577, 5)) == 1)
        assert(spellPower.getDamageMultiplier(makeSpell(689, 60)) == 1.2)
        assert(spellPower.getDamageMultiplier(makeSpell(709, 119)) == 1.5)
        assert(spellPower.getDamageMultiplier(makeSpell(724, 175)) == 5 / 3)
        assert(spellPower.getDamageMultiplier(makeSpell(720, 116)) == 5 / 3)
        assert(spellPower.getDamageMultiplier(makeSpell(728, 116)) == 5 / 3)

        local baselineWeapon = catalog.getDamageMultiplier(makeCaster(20705, 119))
        assert(baselineWeapon == 9)
        assert(baselineWeapon * spellPower.getDamageMultiplier(makeSpell(720, 116)) == 15)
    end)

    it('gives cheap spells a slice of weapon amp and 8-point spells the full boost', function()
        local function makeSpell(id, mpCost)
            return
            {
                getID = function()
                    return id
                end,
                getMPCost = function()
                    return mpCost
                end,
            }
        end

        local footKick = makeSpell(577, 5)
        local darkOrb  = makeSpell(689, 60)
        local assault  = makeSpell(709, 119)
        local tempest  = makeSpell(720, 116)
        local salvo    = makeSpell(724, 175)

        assert(spellPower.getSpellFactor(footKick) == spellPower.FACTOR_CHEAP)
        assert(spellPower.getSpellFactor(darkOrb) == spellPower.FACTOR_MID)
        assert(spellPower.getSpellFactor(assault) == spellPower.FACTOR_HIGH)
        assert(spellPower.getSpellFactor(tempest) == spellPower.FACTOR_FULL)
        assert(spellPower.getSpellFactor(salvo) == spellPower.FACTOR_FULL)

        local tizona = 45
        assert(spellPower.getEffectiveWeaponMultiplier(tizona, footKick) == 1 + 44 * 0.06)
        assert(spellPower.getEffectiveWeaponMultiplier(tizona, tempest) == 45)
        assert(spellPower.getEffectiveWeaponMultiplier(9, footKick) == 1 + 8 * 0.06)
        assert(spellPower.getEffectiveWeaponMultiplier(9, tempest) * spellPower.getDamageMultiplier(tempest) == 15)
    end)
end)
