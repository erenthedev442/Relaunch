-----------------------------------
-- DualWieldPersist.lua
--
-- Behind-the-scenes off-hand restore for Cross-Job Dual Wield buyers.
--
-- The retail client greys out the sub slot on non-dual-wield jobs and never
-- sends the equip, so players set their off-hand with !offhand (which equips it
-- server-side -- the engine equip patches honor the CJTrait_dwield charVar).
-- This module re-applies that saved off-hand weapon on every login/zone if the
-- sub slot is empty, so it survives any equipment wipe with NO player action.
--
-- This is the closest achievable thing to "auto-equip when they hit the can't-
-- equip error": that error is purely client-side (no packet is sent), so the
-- server can never see it. Instead we keep the saved off-hand applied on the
-- server-visible lifecycle events (login/zone), while the C++ keep patch
-- (0x100_myroom_job.cpp:129) holds it across job changes.
--
-- GATED, per request, on owning the purchased Dual Wield trait (CJTrait_dwield).
--
-- Companions: modules/custom/commands/offhand.lua (sets CJTrait_offhand),
-- CrossJob_TraitTrainer.lua (sells the trait). See [[reference_cross_job_trainer]].
-----------------------------------
require('modules/module_utils')

local m = Module:new('dualwield_persist')

-- Equip-from containers: Inventory + all 8 Wardrobes (mirrors offhand.lua). A
-- saved off-hand may live in any Wardrobe, so we must find which one holds it
-- before re-equipping -- equipItem only searches the container it is given.
local EQUIP_CONTAINERS =
{
    xi.inv.INVENTORY,
    xi.inv.WARDROBE,  xi.inv.WARDROBE2, xi.inv.WARDROBE3, xi.inv.WARDROBE4,
    xi.inv.WARDROBE5, xi.inv.WARDROBE6, xi.inv.WARDROBE7, xi.inv.WARDROBE8,
}

local function containerHolding(player, itemID)
    for _, cid in ipairs(EQUIP_CONTAINERS) do
        local size = player:getContainerSize(cid)
        for slot = 1, size do
            local item = player:getStorageItem(cid, slot, 255)
            if item ~= nil and item:getID() == itemID then
                return cid
            end
        end
    end
    return nil
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- Run the rest of the login chain first so equipment is fully loaded before
    -- we decide whether the sub slot needs restoring.
    super(player, firstLogin, zoning)

    -- Only buyers of the Dual Wield trait. setCharVar/getCharVar is DB-backed.
    if (player:getCharVar('CJTrait_dwield') or 0) == 0 then
        return
    end

    local saved = player:getCharVar('CJTrait_offhand') or 0
    -- Only act if they set an off-hand AND the slot is currently empty (so a
    -- weapon that persisted normally, or an intentional clear, is left alone).
    if saved ~= 0 and player:getEquipID(xi.slot.SUB) == 0 then
        -- Find which container actually holds the saved weapon (Inventory or any
        -- Wardrobe) and equip from there; the equip patches honor CJTrait_dwield
        -- so it succeeds on any job. No-ops if the weapon isn't carried anymore.
        local cid = containerHolding(player, saved)
        if cid then
            player:equipItem(saved, cid, xi.slot.SUB)
        end
    end
end)

return m
