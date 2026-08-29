-----------------------------------
-- Spell: Plenilune Embrace
-- Restores target party member's HP and enhances attack and magic attack..
-- Shamelessly stolen from http://members.shaw.ca/pizza_steve/cure/Cure_Calculator.html
-----------------------------------
require('scripts/globals/magic')
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = 180
    local moonCycle = getVanadielMoonCycle()

    local cycleBuffs =
    {
        [xi.moonCycle.NEW_MOON]                = { atk = 2,  mab = 30 },
        [xi.moonCycle.LESSER_WAXING_CRESCENT]  = { atk = 6,  mab = 24 },
        [xi.moonCycle.GREATER_WAXING_CRESCENT] = { atk = 10, mab = 20 },
        [xi.moonCycle.FIRST_QUARTER]           = { atk = 14, mab = 14 },
        [xi.moonCycle.LESSER_WAXING_GIBBOUS]   = { atk = 20, mab = 10 },
        [xi.moonCycle.GREATER_WAXING_GIBBOUS]  = { atk = 24, mab = 6  },
        [xi.moonCycle.FULL_MOON]               = { atk = 30, mab = 2  },
        [xi.moonCycle.GREATER_WANING_GIBBOUS]  = { atk = 24, mab = 6  },
        [xi.moonCycle.LESSER_WANING_GIBBOUS]   = { atk = 20, mab = 10 },
        [xi.moonCycle.THIRD_QUARTER]           = { atk = 14, mab = 14 },
        [xi.moonCycle.GREATER_WANING_CRESCENT] = { atk = 10, mab = 20 },
        [xi.moonCycle.LESSER_WANING_CRESCENT]  = { atk = 6,  mab = 24 },
    }

    local moonBuff = cycleBuffs[moonCycle]
    local atkBoost = moonBuff.atk
    local mabBoost = moonBuff.mab

    target:addStatusEffect(xi.effect.ATTACK_BOOST, { power = atkBoost, duration = duration, origin = caster })
    target:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = mabBoost, duration = duration, origin = caster })

    local skill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local cure = math.min(1800 + 2.4 * skill + 5 * caster:getStat(xi.mod.MND), 4500)
    cure = math.floor(math.min(cure, target:getMaxHP() - target:getHP()))

    target:addHP(cure)
    caster:updateEnmityFromCure(target, cure)
    return cure
end

return spellObject
