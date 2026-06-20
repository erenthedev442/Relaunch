-----------------------------------
-- allied_notes_drop.lua
-- Awards Allied Notes to every alliance member who participates in a kill
-- inside any Wings of the Goddess (S) zone.
--
-- The engine calls onMobDeathEx once per alliance member, so each player
-- earns their own notes -- no isKiller filter needed.
--
-- Amount scales with mob level: floor(level / 5), clamped [5, 50].
--   Level  25 →  5 AN    Level  75 → 15 AN
--   Level  50 → 10 AN    Level 150 → 30 AN
-----------------------------------
require('modules/module_utils')

local m = Module:new('allied_notes_drop')

local PAST_ZONES = set {
    xi.zone.SOUTHERN_SAN_DORIA_S,
    xi.zone.EAST_RONFAURE_S,
    xi.zone.JUGNER_FOREST_S,
    xi.zone.VUNKERL_INLET_S,
    xi.zone.BATALLIA_DOWNS_S,
    xi.zone.LA_VAULE_S,
    xi.zone.BASTOK_MARKETS_S,
    xi.zone.NORTH_GUSTABERG_S,
    xi.zone.GRAUBERG_S,
    xi.zone.PASHHOW_MARSHLANDS_S,
    xi.zone.ROLANBERRY_FIELDS_S,
    xi.zone.BEADEAUX_S,
    xi.zone.WINDURST_WATERS_S,
    xi.zone.WEST_SARUTABARUTA_S,
    xi.zone.FORT_KARUGO_NARUGO_S,
    xi.zone.MERIPHATAUD_MOUNTAINS_S,
    xi.zone.SAUROMUGUE_CHAMPAIGN_S,
    xi.zone.CASTLE_OZTROJA_S,
    xi.zone.BEAUCEDINE_GLACIER_S,
    xi.zone.XARCABARD_S,
    xi.zone.CASTLE_ZVAHL_BAILEYS_S,
    xi.zone.CASTLE_ZVAHL_KEEP_S,
    xi.zone.THRONE_ROOM_S,
    xi.zone.GARLAIGE_CITADEL_S,
    xi.zone.CRAWLERS_NEST_S,
    xi.zone.THE_ELDIEME_NECROPOLIS_S,
}

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if mob == nil or player == nil then
        return
    end
    if player:getObjType() ~= xi.objType.PC then
        return
    end
    if not PAST_ZONES[mob:getZoneID()] then
        return
    end

    local amount = math.max(5, math.min(50, math.floor(mob:getMainLvl() / 5)))
    player:addCurrency('allied_notes', amount)
end)

return m
