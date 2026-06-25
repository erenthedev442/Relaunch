-----------------------------------
-- !offhand  [ <number> | off ]
--
-- Force-equips a 1-handed weapon into the SUB (off-hand) slot, bypassing the
-- retail client's LOCAL dual-wield gate. On a non-dual-wield job the client
-- greys out the sub slot and never even sends the equip packet, so the server
-- never sees it -- which is why dragging a weapon there does nothing. This
-- command does the equip server-side, where the engine equip patches honor the
-- CJTrait_dwield charVar (charutils.cpp 2535/3338/3483), so it works on ANY job.
--
-- GATED on having BOUGHT the Dual Wield trait from the Cross-Job Trait Trainer
-- at GM Home (charVar CJTrait_dwield ~= 0). Non-buyers are told to buy it first.
--
--   !offhand          -> list your 1-handed weapons (Inventory + Wardrobes), numbered
--   !offhand <n>      -> equip list-entry n into your off-hand
--   !offhand off      -> clear your off-hand
--
-- The chosen weapon id is saved (charVar CJTrait_offhand). DualWieldPersist.lua
-- re-equips it on every login/zone if the slot is empty, and the C++ keep patch
-- (0x100_myroom_job.cpp:129) holds it across job changes -- so you set it once
-- and forget it. See [[reference_cross_job_trainer]].
-----------------------------------
---@type TCommand
local commandObj = {}

local CHANNEL = xi.msg.channel.SYSTEM_3

-- 1-handed melee skills that can occupy the sub (off-hand) slot. Hand-to-hand
-- (both hands), the great weapons, ranged and instruments are NOT sub-equippable.
local ONE_HAND_SKILLS =
{
    [xi.skill.DAGGER] = true,
    [xi.skill.SWORD]  = true,
    [xi.skill.AXE]    = true,
    [xi.skill.KATANA] = true,
    [xi.skill.CLUB]   = true,
}

commandObj.cmdprops =
{
    permission = 0, -- all players
    parameters = 's',
}

-- Containers a weapon can be equipped FROM: the main Inventory + all 8 Wardrobes.
-- (Mog Safe/Satchel/Sack/Case can hold gear but the client can't equip directly
-- from them.) Endgame players keep their weapons in Wardrobes, so scanning ONLY
-- INVENTORY found nothing and the command looked broken ("No 1-handed weapons").
local EQUIP_CONTAINERS =
{
    xi.inv.INVENTORY,
    xi.inv.WARDROBE,  xi.inv.WARDROBE2, xi.inv.WARDROBE3, xi.inv.WARDROBE4,
    xi.inv.WARDROBE5, xi.inv.WARDROBE6, xi.inv.WARDROBE7, xi.inv.WARDROBE8,
}

-- Ordered list of sub-equippable 1H weapons across Inventory + every Wardrobe.
-- Deterministic (container order, then slot) so "!offhand <n>" re-derives the
-- same numbering. Records each weapon's container so we equip it from where it
-- actually lives.
local function listOneHanders(player)
    local list = {}
    for _, cid in ipairs(EQUIP_CONTAINERS) do
        local size = player:getContainerSize(cid)
        for slot = 1, size do
            local item = player:getStorageItem(cid, slot, 255)
            if item ~= nil and ONE_HAND_SKILLS[item:getSkillType()] then
                list[#list + 1] = { id = item:getID(), name = item:getName(), container = cid }
            end
        end
    end
    return list
end

commandObj.onTrigger = function(player, arg)
    -- Gate: must own the purchased Dual Wield trait.
    if (player:getCharVar('CJTrait_dwield') or 0) == 0 then
        player:printToPlayer('[Off-hand] Buy the Dual Wield trait from the Trait Trainer at GM Home first, then use !offhand.', CHANNEL)
        return
    end

    -- !offhand off  -> clear the sub slot + forget the saved choice.
    if arg ~= nil and string.lower(arg) == 'off' then
        player:unequipItem(xi.slot.SUB)
        player:setCharVar('CJTrait_offhand', 0)
        player:printToPlayer('[Off-hand] Cleared -- your sub slot is empty.', CHANNEL)
        return
    end

    local list = listOneHanders(player)
    if #list == 0 then
        player:printToPlayer('[Off-hand] No 1-handed weapons found in your Inventory or Wardrobes. Get a dagger/sword/axe/katana/club, then run !offhand.', CHANNEL)
        return
    end

    -- !offhand  (no number) -> show the numbered picker.
    local n = tonumber(arg)
    if n == nil then
        player:printToPlayer('[Off-hand] Your 1-handed weapons -- run "!offhand <number>" to equip one in your off-hand:', CHANNEL)
        for i, w in ipairs(list) do
            player:printToPlayer(string.format('   %d) %s', i, w.name), CHANNEL)
        end
        player:printToPlayer('   ("!offhand off" clears it.) You also need a 1-handed weapon in your MAIN hand.', CHANNEL)
        return
    end

    -- !offhand <number> -> force-equip into the sub slot.
    local w = list[n]
    if w == nil then
        player:printToPlayer(string.format('[Off-hand] No weapon #%d in your list. Run !offhand to see it.', n), CHANNEL)
        return
    end

    player:equipItem(w.id, w.container, xi.slot.SUB)
    if player:getEquipID(xi.slot.SUB) == w.id then
        player:setCharVar('CJTrait_offhand', w.id)
        player:printToPlayer(string.format('[Off-hand] Equipped %s -- it will stay across jobs and logins, kupo!', w.name), CHANNEL)
    else
        player:printToPlayer(string.format('[Off-hand] Could not equip %s. You need a 1-handed weapon in your MAIN hand first (no dual wield with an empty or two-handed main).', w.name), CHANNEL)
    end
end

return commandObj
