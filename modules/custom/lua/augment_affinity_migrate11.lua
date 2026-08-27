-----------------------------------
-- augment_affinity_migrate11.lua
-- One-time per-character remap of the Augment_Affinities bitfield from the old
-- 24 stat-family categories (cat 1..24) to the new 11 functional categories
-- (cat 1..11) introduced 2026-07-06. See [[augment_affinity_catalog]].
--
-- The old and new schemes share the SAME charvar and overlapping low bits, so
-- the new field is computed wholesale from the old field and then overwritten
-- -- never OR'd in place (that would misread old bits 0..10 as new ones).
-- Gated by Augment_Affinities_Mig11 so it runs exactly once per character;
-- fresh characters (field 0) simply get the flag set with no other change.
-- Player-registered affinities are preserved where a new category exists.
--
-- OLD cat -> NEW cat (old bit = oldCat-1, new bit = newCat-1):
--   STR DEX VIT AGI INT MND CHR HP MP (1,3,5,7,10,12,14,16,18) -> 1  Base stats
--   Attack Accuracy (2,4)  + WSD+ (24)                         -> 2  Melee
--   Magic ATK (11)                                             -> 3  Magic
--   Defense Evasion Enmity EleResist Status (6,8,15,21,22)     -> 4  Defense
--   Haste (9)                                                  -> 5  Delays
--   Healing Regen Refresh (13,17,19)                           -> 8  Potency
--   Pet (20)                                                   -> 7  Pets
--   Skills (23)                                                -> 9  Skills
-- New cats 6 (Duration), 10 (Exp/Cap Points) and 11 (Job niche utilities) have
-- no old-scheme source and are registered fresh at the Augment Sage.
-----------------------------------
require('modules/module_utils')

local m = Module:new('augment_affinity_migrate11')
local nmCatalog = require('modules/custom/lua/affinity_nm_catalog')

-- oldCat -> newCat
local REMAP =
{
    [1]  = 1, [2]  = 2, [3]  = 1, [4]  = 2, [5]  = 1, [6]  = 4,
    [7]  = 1, [8]  = 4, [9]  = 5, [10] = 1, [11] = 3, [12] = 1,
    [13] = 8, [14] = 1, [15] = 4, [16] = 1, [17] = 8, [18] = 1,
    [19] = 8, [20] = 7, [21] = 4, [22] = 4, [23] = 9, [24] = 2,
}

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if (player:getCharVar('Augment_Affinities_Mig11') or 0) ~= 0 then
        return -- already migrated
    end

    local old = player:getCharVar('Augment_Affinities') or 0
    if old ~= 0 then
        local new = 0
        for oldCat = 1, 24 do
            if bit.band(old, bit.lshift(1, oldCat - 1)) ~= 0 then
                local newCat = REMAP[oldCat]
                if newCat then
                    new = bit.bor(new, bit.lshift(1, newCat - 1))
                end
            end
        end
        player:setCharVar('Augment_Affinities', new)
    end

    player:setCharVar('Augment_Affinities_Mig11', 1)
    nmCatalog.migrateRegisteredClears(player)
end)

return m
