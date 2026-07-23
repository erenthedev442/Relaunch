-----------------------------------
-- Dynamis Pluton drops
--
-- Every monster in a Dynamis - Divergence zone has one 5% base Pluton roll.
-- addTreasure applies the mob's accumulated Treasure Hunter level.
-----------------------------------
require('modules/module_utils')

local m = Module:new('pluton_drops')

local PLUTON_DROP_RATE = 50 -- 5% on addTreasure's per-1000 scale
local DIVERGENCE_ZONES = set {
    xi.zone.DYNAMIS_SAN_DORIA_D,
    xi.zone.DYNAMIS_BASTOK_D,
    xi.zone.DYNAMIS_WINDURST_D,
    xi.zone.DYNAMIS_JEUNO_D,
}

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if
        not isKiller or
        mob == nil or
        player == nil or
        player:getObjType() ~= xi.objType.PC or
        not DIVERGENCE_ZONES[mob:getZoneID()]
    then
        return
    end

    player:addTreasure(xi.item.PLUTON, mob, PLUTON_DROP_RATE)
end)

return m
