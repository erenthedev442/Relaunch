-----------------------------------
-- func: delnegdmg
-- desc: Removes whole inventory items that carry a NEGATIVE weapon-damage
--       augment (the "Dmg:-X" melee/ranged augments). These were pulled from
--       the augment roll pool (commit 09ab29bffd); this command cleans up the
--       items players already rolled them onto.
--
-- DETECTION:
--   Scans every storage-container slot of the target. For each equipment item
--   it reads the 5 augment slots; if any slot holds a known negative-DMG
--   augment ID the item is flagged (and deleted on confirm). Negativity is a
--   FIXED property of the augment ID — its augments.sql value is < 0 for the
--   melee-DMG (mod 287) / ranged-DMG (mod 376) families, and the per-item Sage
--   boost only scales magnitude, never flips the sign — so an ID allowlist is
--   exact. (The removed augs are no longer in augment_catalog.lua, so we can't
--   look them up there; the list below is the source of truth.)
--
-- USAGE:
--   !delnegdmg                  -> DRY RUN: scan cursor target (or yourself)
--   !delnegdmg <player>         -> DRY RUN: scan that online player
--   !delnegdmg all              -> DRY RUN: scan ALL online players
--   !delnegdmg <player> confirm -> delete the flagged items on that player
--   !delnegdmg me confirm       -> delete on yourself
--   !delnegdmg all confirm      -> delete across ALL online players
--
--   Default is always a DRY RUN that only LISTS what it would remove. Add the
--   word "confirm" (in either position) to actually delete. Online players
--   only — offline characters' inventories aren't loaded into the map server.
-----------------------------------

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1, -- GM (matches !delitem / !delcontaineritems); raise to lock down the 'all' sweep
    parameters = 'ss',
}

-- Negative weapon-DMG augment IDs. Source of truth: sql/augments.sql.
-- modId 287 = Dmg (melee), 376 = Dmg (ranged); only the rows whose stored
-- value is < 0 are listed. augId -> human label for the audit line.
local NEG_DMG_AUGS =
{
    [46]  = 'DMG:-(boost+1) melee',
    [744] = 'Dmg:-1 melee',
    [745] = 'Dmg:-33 melee',
    [750] = 'Dmg:-1 ranged',
    [751] = 'Dmg:-33 ranged',
}

-- Containers that can hold equipment (and therefore augmented gear).
local CONTAINERS =
{
    { id = xi.inv.INVENTORY,  name = 'Inventory'   },
    { id = xi.inv.MOGSAFE,    name = 'Mog Safe'    },
    { id = xi.inv.MOGSAFE2,   name = 'Mog Safe 2'  },
    { id = xi.inv.STORAGE,    name = 'Storage'     },
    { id = xi.inv.MOGLOCKER,  name = 'Mog Locker'  },
    { id = xi.inv.MOGSATCHEL, name = 'Mog Satchel' },
    { id = xi.inv.MOGSACK,    name = 'Mog Sack'    },
    { id = xi.inv.MOGCASE,    name = 'Mog Case'    },
    { id = xi.inv.WARDROBE,   name = 'Wardrobe'    },
    { id = xi.inv.WARDROBE2,  name = 'Wardrobe 2'  },
    { id = xi.inv.WARDROBE3,  name = 'Wardrobe 3'  },
    { id = xi.inv.WARDROBE4,  name = 'Wardrobe 4'  },
    { id = xi.inv.WARDROBE5,  name = 'Wardrobe 5'  },
    { id = xi.inv.WARDROBE6,  name = 'Wardrobe 6'  },
    { id = xi.inv.WARDROBE7,  name = 'Wardrobe 7'  },
    { id = xi.inv.WARDROBE8,  name = 'Wardrobe 8'  },
}

local CHANNEL = xi.msg.channel.SYSTEM_3

local function say(gm, msg)
    gm:printToPlayer(msg, CHANNEL)
end

local function isConfirm(s)
    return s ~= nil and string.lower(s) == 'confirm'
end

-- Returns the offending augment label for an item, or nil if it is clean.
local function findNegDmgAug(item)
    -- getAugment() does an unconditional cast to CItemEquipment in C++,
    -- so only call it on actual equipment (weapons / armor).
    if not (item:isType(xi.itemType.WEAPON) or item:isType(xi.itemType.ARMOR)) then
        return nil
    end

    for augSlot = 0, 4 do
        local aug   = item:getAugment(augSlot)
        local label = NEG_DMG_AUGS[aug[1]]
        if label ~= nil then
            return label
        end
    end

    return nil
end

-- Scans one player, prints a per-item audit block, and (when commit) deletes.
-- Returns the number of flagged items.
local function processPlayer(gm, targ, commit)
    -- Map each equipped item's container slot -> its equip-slot index, so a
    -- flagged item that's currently worn can be unequipped before deletion
    -- (UpdateItem does NOT auto-unequip; deleting a worn item otherwise leaves
    --  a dangling equip pointer).
    local equippedAt = {}
    for eSlot = 0, 15 do
        local eItem = targ:getEquippedItem(eSlot)
        if eItem ~= nil then
            equippedAt[eItem:getLocationID() * 256 + eItem:getSlotID()] = eSlot
        end
    end

    -- Collect first, then act — keeps the scan read-only while iterating.
    local hits = {}
    for _, c in ipairs(CONTAINERS) do
        local size = targ:getContainerSize(c.id) -- capacity; items live in slots 1..size
        for slot = 1, size do
            local item = targ:getStorageItem(c.id, slot, 255)
            if item ~= nil then
                local label = findNegDmgAug(item)
                if label ~= nil then
                    hits[#hits + 1] =
                    {
                        loc     = c.id,
                        locName = c.name,
                        slot    = slot,
                        itemId  = item:getID(),
                        qty     = item:getQuantity(),
                        name    = item:getName(),
                        label   = label,
                        eSlot   = equippedAt[c.id * 256 + slot],
                    }
                end
            end
        end
    end

    if #hits == 0 then
        return 0
    end

    say(gm, string.format('  %s (%d):', targ:getName(), #hits))
    for _, h in ipairs(hits) do
        say(gm, string.format('    %s %s (id %d) [%s #%d]%s  <- %s',
            commit and '[removed]' or '[found]',
            h.name, h.itemId, h.locName, h.slot,
            h.eSlot ~= nil and ' (equipped)' or '',
            h.label))

        if commit then
            if h.eSlot ~= nil then
                pcall(function() targ:unequipItem(h.eSlot) end)
            end
            -- slot-precise + id-validated delete (won't hit the wrong same-id stack)
            targ:delItemAt(h.itemId, h.qty, h.loc, h.slot)
        end
    end

    return #hits
end

-- Enumerate every online player by sweeping all zones.
local function getAllOnlinePlayers()
    local seen = {}
    local list = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' then
            local ok, zone = pcall(GetZone, zoneId)
            if ok and zone ~= nil then
                local players = zone:getPlayers()
                if players ~= nil then
                    for _, p in pairs(players) do
                        local id = p:getID()
                        if not seen[id] then
                            seen[id] = true
                            list[#list + 1] = p
                        end
                    end
                end
            end
        end
    end
    return list
end

commandObj.onTrigger = function(player, arg1, arg2)
    local commit = isConfirm(arg1) or isConfirm(arg2)

    -- The selector is the first argument that isn't the "confirm" keyword.
    local selector = nil
    if arg1 ~= nil and not isConfirm(arg1) then
        selector = arg1
    elseif arg2 ~= nil and not isConfirm(arg2) then
        selector = arg2
    end

    -- Resolve the target list.
    local targets = {}
    local lowSel  = selector and string.lower(selector) or nil

    if selector == nil then
        -- cursor target if it's a player, else yourself
        local t = player:getCursorTarget()
        if t == nil or not t:isPC() then
            t = player
        end
        targets = { t }
    elseif lowSel == 'all' then
        targets = getAllOnlinePlayers()
    elseif lowSel == 'me' or lowSel == 'self' or selector == '.' then
        targets = { player }
    else
        local t = GetPlayerByName(selector)
        if t == nil then
            say(player, string.format('Player "%s" not found (online players only).', selector))
            say(player, '!delnegdmg [player|all|me] (confirm)')
            return
        end
        targets = { t }
    end

    say(player, string.format('=== Negative-DMG augment cleanup [%s] ===',
        commit and 'DELETE' or 'DRY RUN'))

    local grandFound       = 0
    local playersWithHits  = 0
    for _, targ in ipairs(targets) do
        local found = processPlayer(player, targ, commit)
        if found > 0 then
            grandFound      = grandFound + found
            playersWithHits = playersWithHits + 1
        end
    end

    if grandFound == 0 then
        say(player, '  No items with negative DMG augments found.')
    elseif commit then
        say(player, string.format('  Removed %d item(s) from %d character(s).',
            grandFound, playersWithHits))
    else
        say(player, string.format('  Found %d item(s) on %d character(s). Re-run with "confirm" to delete.',
            grandFound, playersWithHits))
    end
end

return commandObj
