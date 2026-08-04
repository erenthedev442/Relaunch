-----------------------------------
-- Berserk-Ruf
-- Trust Volker (3205): Attack Boost (ATTP). TP spent scales power.
-- Story Volker (976) uses berserk_volker.lua (Warcry).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3205

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    -- Script sets volkerRuf=1; keep off the random WS picker.
    if skill:getID() == MS_TRUST and mob:getLocalVar('volkerRuf') == 0 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:setLocalVar('volkerRuf', 0)

    -- ~25–40% ATTP from TP (retail: enhances attacks; TP increases effect).
    local tp    = mob:getLocalVar('volkerRufTP')
    if tp <= 0 then
        tp = mob:getTP()
    end

    mob:setLocalVar('volkerRufTP', 0)
    local power = math.min(40, 25 + math.floor(tp / 200))

    skill:setMsg(xi.mobskills.mobBuffMove(mob, xi.effect.ATTACK_BOOST, power, 0, 180, 0, power))

    return xi.effect.ATTACK_BOOST
end

return mobskillObject
