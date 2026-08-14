-----------------------------------
-- Area: Waughroon Shrine
--  Mob: Maat
-- Genkai 5 Fight
-----------------------------------
mixins = { require('scripts/mixins/families/maat') }
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobInitialize = function(mob)
    xi.pet.setMobPet(mob, 1, 'Maats_Pet')
    mob:setMobMod(xi.mobMod.ROAM_DISTANCE, 0)
    mob:setMobMod(xi.mobMod.ROAM_TURNS, 0)
end

-- Maat's Echo reuses these three mobs. Retail Shattering Stars yields at 20%
-- (MAAT_CTICK) and on THF steal. Echo is a full kill, so strip those here as
-- well as in setupBattlefield -- covers spawn-after-setup.
entity.onMobSpawn = function(mob)
    local battlefield = mob:getBattlefield()
    if battlefield and battlefield:getID() == xi.battlefield.id.MAATS_ECHO then
        mob:removeListener('MAAT_CTICK')
        mob:removeListener('MAAT_ITEM_STOLEN')
    end
end

entity.onMobDeath = function(mob, player, optParams)
end

return entity
