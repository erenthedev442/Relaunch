-----------------------------------
-- Area: RuAun Gardens
--   NM: Despot
-----------------------------------
---@type TMobEntity
local entity = {}

-- Hunt Guild Empy T2: stationary 30-minute camp at !huntwarp despot.
entity.spawnPoints =
{
    { x = -0.100, y = -42.000, z = -291.000 }
}

entity.onMobInitialize = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
    mob:setBaseSpeed(45) -- Note: setBaseSpeed() also updates the animation speed to match.
    mob:setMobMod(xi.mobMod.GIL_MIN, 18000)
    mob:setMobMod(xi.mobMod.GIL_MAX, 18000)
    mob:setMobMod(xi.mobMod.MUG_GIL, 3250)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    mob:addImmunity(xi.immunity.ELEGY)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.SLOW)
    mob:addImmunity(xi.immunity.PETRIFY)
    mob:addImmunity(xi.immunity.TERROR)
    mob:addImmunity(xi.immunity.PLAGUE)

    mob:addListener('WEAPONSKILL_STATE_EXIT', 'PH_VAR', function(mobArg, skillId, wasExecuted)
        -- Despot rapidly uses several Panzerfaust in a row
        local counter  = mob:getLocalVar('panzerfaustCounter')
        local maxCount = mob:getLocalVar('panzerfaustMax')

        if wasExecuted then
            counter = counter + 1
            mob:setLocalVar('panzerfaustCounter', counter)
        end

        -- Continue sequence.
        local target = mob:getTarget()
        if
            target and
            target:isAlive() and
            counter < maxCount
        then
            mob:useMobAbility(xi.mobSkill.PANZERFAUST, target, 0)

        -- Break sequence.
        else
            mob:setAutoAttackEnabled(true)
            mob:setLocalVar('panzerfaustCounter', 0)
            mob:setLocalVar('panzerfaustMax', 0)
        end
    end)
end

entity.onMobSpawn = function(mob)
    local camp = entity.spawnPoints[1]
    mob:setPos(camp.x, camp.y, camp.z)
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 150)

    -- Ensure default state.
    mob:setAutoAttackEnabled(true)
    mob:setLocalVar('panzerfaustCounter', 0)
    mob:setLocalVar('panzerfaustMax', 0)
end

entity.onMobDespawn = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
end

entity.onMobMobskillChoose = function(mob, target)
    local maxCount = mob:getLocalVar('panzerfaustMax')

    -- Initialize sequence.
    if maxCount == 0 then
        mob:setAutoAttackEnabled(false)
        mob:setLocalVar('panzerfaustMax', math.random(2, 5))
    end

    return xi.mobSkill.PANZERFAUST
end

entity.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setAnimationTime(0)
end

return entity
