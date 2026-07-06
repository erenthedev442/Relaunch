-----------------------------------
-- Dynamis - Divergence -- reforge NPC "Divergence Smith" (relaunch custom)
--
-- The payoff for clearing the [D] zones: upgrade Reforged Artifact/Relic/Empyrean
-- armor +1 -> +2 -> +3, spending the medals farmed inside. Each zone unlocks one
-- slot (San d'Oria=Feet, Bastok=Hands, Windurst=Head, Jeuno=Legs; all four=Body),
-- tracked in the 'DivergenceSlots' charVar set by the instance on completion
-- (see scripts/globals/dynamis_divergence.lua).
--
-- Trade a reforged +1 (or +2) piece; if you've cleared that slot's zone and hold
-- enough medals, it comes back upgraded.
--
-- Phase 1 slice: seeded with FEET pieces (the slot San d'Oria unlocks). The
-- REFORGE/COST tables are the template -- expand to every job/slot in the
-- fidelity pass (ideally via a generator over the reforged-armor item set).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')
require('scripts/globals/dynamis_divergence')

local m = Module:new('divergence_reforger')

local NPC_POS = { x = 155.0, y = -2.0, z = 162.0, rot = 96 }

-- [traded item] = { result = upgraded item, slot, tier (2 or 3), name }
local REFORGE =
{
    -- WAR Relic set "Boii" -- one verified full set across every slot as the template.
    -- Head (Mask)
    [26741] = { result = 23085, slot = 'head',  tier = 2, name = 'Boii Mask +1' },
    [23085] = { result = 23420, slot = 'head',  tier = 3, name = 'Boii Mask +2' },
    -- Hands (Mufflers)
    [27053] = { result = 23219, slot = 'hands', tier = 2, name = 'Boii Mufflers +1' },
    [23219] = { result = 23554, slot = 'hands', tier = 3, name = 'Boii Mufflers +2' },
    -- Legs (Cuisses)
    [27238] = { result = 23286, slot = 'legs',  tier = 2, name = 'Boii Cuisses +1' },
    [23286] = { result = 23621, slot = 'legs',  tier = 3, name = 'Boii Cuisses +2' },
    -- Feet (Calligae)
    [27412] = { result = 23353, slot = 'feet',  tier = 2, name = 'Boii Calligae +1' },
    [23353] = { result = 23688, slot = 'feet',  tier = 3, name = 'Boii Calligae +2' },
    -- Body (Lorica) -- gated on 'body' (all four slots cleared)
    [26899] = { result = 23152, slot = 'body',  tier = 2, name = 'Boii Lorica +1' },
    [23152] = { result = 23487, slot = 'body',  tier = 3, name = 'Boii Lorica +2' },
    -- SCH Empyrean feet: Argute Loafers
    [11399] = { result = 10749, slot = 'feet',  tier = 2, name = 'Argute Loafers +1' },
}

-- Medal cost by target tier. Medals drop from the [D] mobs (mob_droplist).
local COST =
{
    [2] = { { id = 9539, qty = 3, name = "Beastmen's Medal" } },
    [3] = { { id = 9541, qty = 3, name = "Kindred's Medal" }, { id = 9543, qty = 1, name = "Demon's Medal" } },
}

local function consume(player, id, qty)
    local before = player:getItemCount(id)
    if before < qty then
        return false
    end
    player:delItem(id, qty)
    local removed = before - player:getItemCount(id)
    if removed < qty then
        if removed > 0 then
            player:addItem({ id = id, quantity = removed })
        end
        return false
    end
    return true
end

local function costString(tier)
    local parts = {}
    for _, c in ipairs(COST[tier]) do
        parts[#parts + 1] = string.format('%d %s', c.qty, c.name)
    end
    return table.concat(parts, ', ')
end

local function unlockedSlots(player)
    local slots = player:getCharVar('DivergenceSlots')
    local names = {}
    if bit.band(slots, 1) ~= 0 then names[#names + 1] = 'Feet'  end
    if bit.band(slots, 2) ~= 0 then names[#names + 1] = 'Hands' end
    if bit.band(slots, 4) ~= 0 then names[#names + 1] = 'Head'  end
    if bit.band(slots, 8) ~= 0 then names[#names + 1] = 'Legs'  end
    if bit.band(slots, 15) == 15 then names[#names + 1] = 'Body' end
    return #names > 0 and table.concat(names, ', ') or 'none yet'
end

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

    local function doReforge(player, entry)
        -- Slot must be unlocked by clearing that zone. Body is special: it is NOT a
        -- single bit -- it unlocks only when all four slot bits (15) are set, mirroring
        -- the engine's onInstanceComplete all-four check and unlockedSlots() above.
        -- (slotBit['body'] is nil, so the old single-bit gate left Body unreachable.)
        local slots = player:getCharVar('DivergenceSlots') or 0
        local unlocked
        if entry.slot == 'body' then
            unlocked = bit.band(slots, 15) == 15
        else
            local slotBit = xi.divergence.slotBit[entry.slot] or 0
            unlocked = slotBit ~= 0 and bit.band(slots, slotBit) ~= 0
        end
        if not unlocked then
            player:printToPlayer(string.format('[Reforge] Clear the Divergence zone that unlocks %s armor first, kupo!', entry.slot:upper()), xi.msg.channel.SYSTEM_3)
            return
        end
        -- Enough medals?
        for _, c in ipairs(COST[entry.tier]) do
            if player:getItemCount(c.id) < c.qty then
                player:printToPlayer(string.format('[Reforge] %s -> +%d costs %s. Kupo!', entry.name, entry.tier, costString(entry.tier)), xi.msg.channel.SYSTEM_3)
                return
            end
        end
        -- Consume medals (abort + refund on any shortfall, before touching the trade).
        local paid = {}
        for _, c in ipairs(COST[entry.tier]) do
            if not consume(player, c.id, c.qty) then
                for id, qty in pairs(paid) do
                    player:addItem({ id = id, quantity = qty })
                end
                player:printToPlayer('[Reforge] Keep your medals as single MAIN-inventory stacks and try again, kupo!', xi.msg.channel.SYSTEM_3)
                return
            end
            paid[c.id] = (paid[c.id] or 0) + c.qty
        end
        -- Consume the traded piece and hand back the upgrade.
        player:confirmTrade()
        npcUtil.giveItem(player, entry.result)
        player:printToPlayer(string.format('[Reforge] %s reforged to +%d! Kupo!', entry.name, entry.tier), xi.msg.channel.SYSTEM_3)
    end

    -- Retired 2026-07-06; replaced by Dynamis_Plus4_Forge.lua, which takes this
    -- exact spot (the "+4 Reforge Forge"). The Divergence Smith no longer spawns.
    -- The doReforge closure, REFORGE/COST tables, and helpers above are left in
    -- place so re-enabling is just restoring the insertDynamicEntity call below.
    --
    -- local smith = zone:insertDynamicEntity({
    --     objtype    = xi.objType.NPC,
    --     name       = 'Divergence_Smith',
    --     packetName = string.format('%sDivergence Smith', xi.icon.STAR_LARGE),
    --     look       = 3000,
    --     x          = NPC_POS.x,
    --     y          = NPC_POS.y,
    --     z          = NPC_POS.z,
    --     rotation   = NPC_POS.rot,
    --     widescan   = 1,
    --
    --     onTrade = function(player, npc, trade)
    --         for tradedId, entry in pairs(REFORGE) do
    --             if npcUtil.tradeHasExactly(trade, { tradedId }) then
    --                 doReforge(player, entry)
    --                 return
    --             end
    --         end
    --         player:printToPlayer('[Reforge] Trade me a reforged +1 or +2 piece for a slot you have unlocked, kupo!', xi.msg.channel.SYSTEM_3)
    --     end,
    --
    --     onTrigger = function(player, npc)
    --         player:printToPlayer(string.format('[Reforge] I upgrade Reforged armor with Divergence medals. Slots you have unlocked: %s. Kupo!', unlockedSlots(player)), xi.msg.channel.SYSTEM_3)
    --         player:printToPlayer('[Reforge] Trade a reforged +1 (or +2) piece to upgrade it. +2 costs Beastmen\'s Medals; +3 costs Kindred\'s + Demon\'s Medals.', xi.msg.channel.SYSTEM_3)
    --     end,
    -- })
    -- utils.unused(smith)
    utils.unused(doReforge)
end)

return m
