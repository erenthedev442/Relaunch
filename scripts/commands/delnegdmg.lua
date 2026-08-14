-----------------------------------
-- func: delnegdmg
-- desc: Removes whole inventory items whose APPLIED weapon-DMG augment has
--       netted NEGATIVE — i.e. a DMG augment that, once the engine computes it,
--       subtracts damage and underflows the weapon. Targets the symptom, not a
--       fixed augment-ID list, so it catches a "+DMG" augment that lands
--       negative just as well as a literally-negative one.
--
-- DETECTION (reads the engine-computed value, not the nominal augment):
--   On load the server applies each item's augments and stores the result as
--   the item's DMG_RATING (mod 287, melee) / RANGED_DMG_RATING (mod 376,
--   ranged) modifier — see charutils.cpp ApplyAugment + item_equipment.cpp:479
--   `modValue = (base>0 ? base+boost : base-boost) * mult` (an int16). The
--   weapon's damage is then `weapon:getDamage() + getModifier(DMG_RATING)`
--   as a uint16, so a negative DMG_RATING underflows it.
--
--   We read that applied value straight off the item with getMod(287/376).
--   NO base item_mods row uses mod 287 or 376 (verified), so a negative value
--   can ONLY come from an applied DMG augment — zero false positives, and it
--   needs no augment table or catalog (works even for augs pulled from the
--   pool). If getMod(287) < 0 or getMod(376) < 0, the item is flagged.
--
-- USAGE:
--   !delnegdmg                  -> DRY RUN: scan cursor target (or yourself)
--   !delnegdmg <player>         -> DRY RUN: scan that online player
--   !delnegdmg all              -> DRY RUN: scan ALL online players
--   !delnegdmg <player> confirm -> delete the flagged items on that player
--   !delnegdmg me confirm       -> delete on yourself
--   !delnegdmg all confirm      -> delete across ALL online players
--
--   Default is always a DRY RUN that only LISTS what it would remove (with the
--   negative value and any DMG augment IDs found, so you can see the cause).
--   Add "confirm" (either position) to actually delete. Online players only —
--   offline characters' inventories aren't loaded into the map server.
-----------------------------------

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5, -- Senior GM only; matches !delitem and !delcontaineritems
    parameters = 'ss',
}

-- The two weapon-damage augment mods we test the applied value of.
local MOD_DMG        = xi.mod.DMG_RATING        -- 287, melee
local MOD_RANGED_DMG = xi.mod.RANGED_DMG_RATING -- 376, ranged

-- All DMG augment IDs (modId 287 / 376) -> nominal label. REPORT ONLY: shown so
-- you can see which augment(s) sit on a flagged item. Source: sql/augments.sql.
local DMG_AUG_LABELS =
{
    [45]  = 'Dmg:+1',  [46]  = 'Dmg:-1',  [740] = 'Dmg:+1',  [741] = 'Dmg:+33',
    [742] = 'Dmg:+65', [743] = 'Dmg:+97', [744] = 'Dmg:-1',  [745] = 'Dmg:-33',
    [746] = 'Dmg:+1',  [747] = 'Dmg:+33', [748] = 'Dmg:+65', [749] = 'Dmg:+97',
    [750] = 'Dmg:-1',  [751] = 'Dmg:-33',
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

-- Returns a description string if the item's APPLIED DMG augment is negative,
-- else nil. Reads the engine-computed modifier directly.
local function findNegativeDmg(item)
    -- getMod()/getAugment() cast to CItemEquipment in C++ — equipment only.
    if not (item:isType(xi.itemType.WEAPON) or item:isType(xi.itemType.ARMOR)) then
        return nil
    end

    local dmg  = item:getMod(MOD_DMG)        -- augment-only (no base item_mods use 287)
    local rdmg = item:getMod(MOD_RANGED_DMG) -- augment-only (no base item_mods use 376)
    if dmg >= 0 and rdmg >= 0 then
        return nil
    end

    -- Note the negative value(s)...
    local parts = {}
    if dmg  < 0 then parts[#parts + 1] = string.format('DMG %d', dmg)   end
    if rdmg < 0 then parts[#parts + 1] = string.format('R.DMG %d', rdmg) end

    -- ...and which DMG augment(s) physically sit on the item (cause).
    local augs = {}
    for s = 0, 4 do
        local a     = item:getAugment(s)
        local label = DMG_AUG_LABELS[a[1]]
        if label ~= nil then
            augs[#augs + 1] = string.format('%s #%d', label, a[1])
        end
    end

    return string.format('%s%s',
        table.concat(parts, ', '),
        #augs > 0 and ('  [' .. table.concat(augs, ', ') .. ']') or '  [no DMG-aug id?]')
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
                local desc = findNegativeDmg(item)
                if desc ~= nil then
                    hits[#hits + 1] =
                    {
                        loc     = c.id,
                        locName = c.name,
                        slot    = slot,
                        itemId  = item:getID(),
                        qty     = item:getQuantity(),
                        name    = item:getName(),
                        desc    = desc,
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
        say(gm, string.format('    %s %s (id %d) [%s #%d]%s  ->  %s',
            commit and '[removed]' or '[found]',
            h.name, h.itemId, h.locName, h.slot,
            h.eSlot ~= nil and ' (equipped)' or '',
            h.desc))

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

    say(player, string.format('=== Negative applied-DMG augment cleanup [%s] ===',
        commit and 'DELETE' or 'DRY RUN'))

    local grandFound      = 0
    local playersWithHits = 0
    for _, targ in ipairs(targets) do
        local found = processPlayer(player, targ, commit)
        if found > 0 then
            grandFound      = grandFound + found
            playersWithHits = playersWithHits + 1
        end
    end

    if grandFound == 0 then
        say(player, '  No items with a negative applied DMG augment found.')
    elseif commit then
        say(player, string.format('  Removed %d item(s) from %d character(s).',
            grandFound, playersWithHits))
    else
        say(player, string.format('  Found %d item(s) on %d character(s). Re-run with "confirm" to delete.',
            grandFound, playersWithHits))
    end
end

return commandObj
