-----------------------------------
-- Firesday Night Fever
-- Trust: Mumor II. Self buff: full HP/MP, all-stat boost, pink aura.
-- ~4 min duration; cooldown starts when Final Eternal Heart ends the fever.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local lvl = mob:getMainLvl()

    mob:eraseAllStatusEffect()
    mob:addHP(mob:getMaxHP())
    mob:addMP(mob:getMaxMP())
    mob:setTP(0)

    local statBoost = math.max(10, math.floor(lvl * 0.35))
    if mob:getLocalVar('mumorFeverBuff') == 0 then
        mob:addMod(xi.mod.STR, statBoost)
        mob:addMod(xi.mod.DEX, statBoost)
        mob:addMod(xi.mod.VIT, statBoost)
        mob:addMod(xi.mod.AGI, statBoost)
        mob:addMod(xi.mod.INT, statBoost)
        mob:addMod(xi.mod.MND, statBoost)
        mob:addMod(xi.mod.CHR, statBoost)
        mob:addMod(xi.mod.ATT, math.floor(statBoost * 2))
        mob:addMod(xi.mod.ACC, math.floor(statBoost * 2))
        mob:addMod(xi.mod.MATT, math.floor(statBoost * 1.5))
        mob:addMod(xi.mod.MACC, math.floor(statBoost * 1.5))
        mob:setLocalVar('mumorFeverBuff', 1)
        mob:setLocalVar('mumorFeverStat', statBoost)
    end

    mob:setAnimationSub(1) -- pink sparkling aura
    mob:setLocalVar('mumorFever', 1)
    mob:setLocalVar('mumorFeverStep', 1)
    mob:setLocalVar('mumorFeverEnd', GetSystemTime() + 240) -- ~4 min

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
    return 0
end

return mobskillObject
