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
            { 21646, 119, 'PRIME',     35, 1749999 },
            { 20695, 119, 'AEONIC',    20,  999999 },
            { 20688, 119, 'MYTHIC',    15,  999999 },
            { 20689, 119, 'EMPYREAN',  15,  999999 },
            { 20685, 119, 'RELIC',     10,  999999 },
            { 21621, 119, 'AMBUSCADE',  3,   99999 },
            { 20705, 119, 'ITEM_119',   3,   79999 },
            { 20731, 115, 'PRE_119',    3,   40000 },
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
            { 21646, 35, 1749999 },
            { 20695, 20,  999999 },
            { 20688, 15,  999999 },
            { 20689, 15,  999999 },
            { 20685, 10,  999999 },
            { 21621,  3,   99999 },
            { 20705,  3,   79999 },
            { 20731,  3,   40000 },
        })
        do
            local caster = makeCaster(case[1], case[1] == 20731 and 115 or 119)
            assert(standardMagic.getDamageMultiplier(caster, target, spell) == case[2])
            assert(standardMagic.getDamageCap(caster) == case[3])
        end
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

    it('scales spell budgets from 3x baseline to 5x premium damage', function()
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

        local baselineWeapon = catalog.getDamageMultiplier(makeCaster(20705, 119))
        assert(baselineWeapon == 3)
        assert(baselineWeapon * spellPower.getDamageMultiplier(makeSpell(720, 116)) == 5)
    end)
end)
