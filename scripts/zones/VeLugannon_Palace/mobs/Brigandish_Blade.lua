-----------------------------------
-- Area: VeLugannon Palace
--   NM: Brigandish Blade
-----------------------------------
local ID = zones[xi.zone.VELUGANNON_PALACE]
-----------------------------------
---@type TMobEntity
local entity = {}

-- Hunt Guild Empy T4: stationary 30-minute camp at !huntwarp brigandish_blade.
entity.spawnPoints =
{
    { x = -1.000, y = -1.000, z = -283.000 }
}

entity.onMobInitialize = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
    mob:setMobMod(xi.mobMod.ADD_EFFECT, 1)
    mob:setMobMod(xi.mobMod.GIL_MIN, 18000)
    mob:setMobMod(xi.mobMod.GIL_MAX, 18000)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.TERROR)
    mob:addImmunity(xi.immunity.PLAGUE)
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 150)
end

entity.onMobSpawn = function(mob)
    mob:setMod(xi.mod.STORETP, 60)
    mob:setMod(xi.mod.UDMGMAGIC, -1250)
    mob:setLocalVar('defaultAttack', mob:getMod(xi.mod.ATT))
end

entity.onMobFight = function(mob, target)
    -- Gains significantly increased damage as HP decreases.
    local power = (100 - mob:getHPP()) * 5

    mob:setMod(xi.mod.ATT, mob:getLocalVar('defaultAttack') + power)
end

entity.onAdditionalEffect = function(mob, target, damage)
    return xi.mob.onAddEffect(mob, target, damage, xi.mob.ae.TERROR, { chance = 30 })
end

entity.onMobDeath = function(mob, player, optParams)
    GetNPCByID(ID.npc.QM3):setLocalVar('PillarCharged', 1)
end

entity.onMobDespawn = function(mob)
    xi.mob.updateNMSpawnPoint(mob)
end

return entity
