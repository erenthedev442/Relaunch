-----------------------------------
-- alzahbi_loot.lua
-- "Loot fountain": every mob killed in Al Zahbi (zone 48) drops one random item
-- rolled from the whole item database.
--
-- Hooks the GLOBAL mob-death handler (xi.mob.onMobDeathEx, called by the core for
-- every mob death) instead of editing per-mob scripts, so it covers EVERY mob in
-- the zone -- the Besieged invaders and anything else. Gated on:
--   * zone == Al Zahbi
--   * isKiller  -> fires once per kill, for the killer (the core calls this per
--                  alliance member; isKiller marks the one that landed the blow)
--
-- The roll validates with GetItemByID (the id space 1..29699 has gaps), so only a
-- real, loaded item is ever dropped. NOTE: this is "any valid item_basic item" --
-- it does NOT exclude GM/test items (there's no clean flag for those), so tighten
-- the filter if any of those turn out to be a problem.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')

local m = Module:new('alzahbi_loot')

local MAX_ITEM_ID = 29699   -- highest itemid in item_basic
local MAX_ROLLS   = 30       -- give up after this many invalid rolls (gaps in the id space)

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    -- only the killing blow, and only for a real player character, in Al Zahbi
    if mob == nil or player == nil or not isKiller then
        return
    end
    if player:getObjType() ~= xi.objType.PC then
        return
    end
    if mob:getZoneID() ~= xi.zone.AL_ZAHBI then
        return
    end

    for _ = 1, MAX_ROLLS do
        local id = math.random(1, MAX_ITEM_ID)
        if GetItemByID(id) ~= nil then
            -- addTreasure = a real, lottable drop in the treasure pool
            pcall(function() player:addTreasure(id, mob) end)
            return
        end
    end
end)

return m
