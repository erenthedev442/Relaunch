-----------------------------------
-- Metalid Body
--
-- Gives the effect of "Stoneskin."
-- Type: Magical
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local power = 25 -- ffxiclopedia claims its always 25 on the crabs page. Tested on wootzshell in mt zhayolm..
    --[[
    if mob:isNM() then
        power = ???  Betting NMs aren't 25 but I don't have data..
    end
    ]]
    skill:setMsg(xi.mobskills.mobBuffMove(target, xi.effect.STONESKIN, power, 0, 300))
    -- Share buff with the master when cast by a player's jug pet.
    local master = mob:getMaster()
    if master and master:isPC() then
        master:addStatusEffect(xi.effect.STONESKIN, power, 0, 300)
    end
    return xi.effect.STONESKIN
end

return mobskillObject
