-----------------------------------
-- Salaheem Spirit
-- Description: Provides a bonus to base attributes for party members in area of effect.
-- Duration varies by TP. Only available to Abquhbah Trust.
--
-- Power: level / 4 (+24 @ 99). Decays -1 per tick (10s).
-- Duration (retail approx): ~50s @1000, ~70s @1500, ~90s @2000, 120s @3000.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local power = math.floor(mob:getMainLvl() / 4)
    local tick = 10
    -- 20 + TP/30 → 53/70/87/120 at 1000/1500/2000/3000 (wiki table + closer notes).
    local duration = math.floor(20 + mob:getTP() / 30)

    target:delStatusEffect(xi.effect.STR_BOOST)
    target:delStatusEffect(xi.effect.DEX_BOOST)
    target:delStatusEffect(xi.effect.VIT_BOOST)
    target:delStatusEffect(xi.effect.AGI_BOOST)
    target:delStatusEffect(xi.effect.INT_BOOST)
    target:delStatusEffect(xi.effect.MND_BOOST)
    target:delStatusEffect(xi.effect.CHR_BOOST)

    target:addStatusEffect(xi.effect.STR_BOOST, { power = power, duration = duration, origin = mob, tick = tick })
    target:addStatusEffect(xi.effect.DEX_BOOST, { power = power, duration = duration, origin = mob, tick = tick })
    target:addStatusEffect(xi.effect.VIT_BOOST, { power = power, duration = duration, origin = mob, tick = tick })
    target:addStatusEffect(xi.effect.AGI_BOOST, { power = power, duration = duration, origin = mob, tick = tick })
    target:addStatusEffect(xi.effect.INT_BOOST, { power = power, duration = duration, origin = mob, tick = tick })
    target:addStatusEffect(xi.effect.MND_BOOST, { power = power, duration = duration, origin = mob, tick = tick })
    target:addStatusEffect(xi.effect.CHR_BOOST, { power = power, duration = duration, origin = mob, tick = tick })

    skill:setMsg(xi.msg.basic.STATUS_BOOST_2)

    return 0
end

return mobskillObject
