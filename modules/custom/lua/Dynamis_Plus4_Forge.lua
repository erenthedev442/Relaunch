-----------------------------------
-- Dynamis - Divergence -- "+4 Reforge Forge" NPC (relaunch custom)
--
-- The endgame tail of the reforge ladder: upgrade a reforged +3 AF/Relic piece
-- to +4. Self-contained in the Dynamis [D] system -- the materials farmed inside
-- the [D] zones ARE the gate (no slot-unlock charVar; drop that DivergenceSlots
-- logic entirely).
--
-- Trade a reforged +3 piece + the required materials:
--   *  3x your job's Paragon Card  (entry.pcard, from reforge_plus4_map.lua)  [ 6x for body]
--   * 12x Rusted ID Card   (9538)  [24x for body]
--   *  6x Black  ID Card   (9540)  [12x for body]
-- ...and it comes back +4. Empyrean armor has no +4 tier, so it is not in the map.
--
-- Materials come from the [D] mobs (see modules/custom/sql/dynamis_plus4_materials.sql
-- for the Rusted/Black droplist rows, and the mega-boss P.Card drop hooked below).
--
-- The trade flow mirrors Divergence_Reforger.lua (consume+refund helper,
-- tradeHasExactly, confirmTrade, npcUtil.giveItem) but is driven off the
-- auto-generated +3->+4 map instead of a hand-seeded table.
--
-- NPC takes the (now retired) Divergence Smith's exact spot in Southern San d'Oria.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')

local plus4map = require('modules/custom/lua/reforge_plus4_map')
local reforgeCatalog = require('modules/custom/lua/reforge_catalog')

local m = Module:new('dynamis_plus4_forge')

-- NPC placement (the retired Divergence Smith's exact spot).
local NPC_POS = { x = 155.0, y = -2.0, z = 162.0, rot = 96 }

-- Material costs (tunable; raised 3x/owner rebalance 2026-07-12). All three
-- materials are body-taxed (body pieces are the strongest slot).
local PCARD_QTY        = 3      -- x entry.pcard (job-matched Paragon Card), non-body
local PCARD_QTY_BODY   = 6      -- body
local RUSTED_ID        = 9538   -- Rusted Identification Card
-- 2026-07-13 (owner): a full-stack (99) requirement triggered a client/server
-- inventory-sync race in the trade path -- putting the ENTIRE stack of an item
-- into the trade window and having any part of the trade fail leaves the
-- client with an underflowed (-99 -> 4294967197) count, and the server flags
-- the cards as reserved. Jbae hit exactly this. Rolled back to sub-99 so
-- players always have leftover cards -- keeps the "this is a real farm gate"
-- intent (60/90 is still 5x the original 12/24 cost) without the edge case.
local RUSTED_QTY       = 60     -- non-body
local RUSTED_QTY_BODY  = 90     -- body
local BLACK_ID         = 9540   -- Blackened Identification Card
local BLACK_QTY        = 6      -- non-body
local BLACK_QTY_BODY   = 12     -- body

-- The 4 [D] mega-bosses. Killing one hands the killer their main-job Paragon
-- Card (pcard = 9280 + jobId). Names match modules/custom/sql/dynamis_divergence.sql
-- mob_groups group 9 for zones 294/295/296/297.
local MEGABOSSES =
{
    ['Halphas']            = true,  -- San d'Oria [D] (294)
    ['KaRhoFearsinger']    = true,  -- Bastok    [D] (295)
    ['FiiPexuTheEternal']  = true,  -- Windurst  [D] (296)
    ['Obstatrix_JeunoD']   = true,  -- Jeuno     [D] (297)
}

local SYS = xi.msg.channel.SYSTEM_3

-- Empyrean +3 pieces are valid reforge pieces, but retail has no matching +4
-- item rows. Detect them explicitly so players are not told that a valid Boii
-- (etc.) +3 is merely the wrong tier.
local unsupportedEmpyreanPlus3 = {}
for _, jobPieces in pairs(reforgeCatalog.pieces or {}) do
    for _, tiers in pairs(jobPieces.empy or {}) do
        local plus3 = tiers[4]
        if plus3 and plus3 > 0 and not plus4map[plus3] then
            unsupportedEmpyreanPlus3[plus3] = true
        end
    end
end

-- Consume qty of item id; refund the partial removal and fail if the player
-- did not actually hold a full single stack (mirrors Divergence_Reforger).
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

-- Build the material list for one upgrade (Paragon Card + ID cards, body-taxed).
local function materialsFor(entry)
    local pcard  = (entry.slot == 'body') and PCARD_QTY_BODY  or PCARD_QTY
    local rusted = (entry.slot == 'body') and RUSTED_QTY_BODY or RUSTED_QTY
    local black  = (entry.slot == 'body') and BLACK_QTY_BODY  or BLACK_QTY
    return {
        { id = entry.pcard, qty = pcard,     name = 'your job\'s Paragon Card' },
        { id = RUSTED_ID,   qty = rusted,    name = 'Rusted ID Card'  },
        { id = BLACK_ID,    qty = black,     name = 'Black ID Card'   },
    }
end

local function costString(entry)
    local parts = {}
    for _, c in ipairs(materialsFor(entry)) do
        parts[#parts + 1] = string.format('%dx %s', c.qty, c.name)
    end
    return table.concat(parts, ', ')
end

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

    -- matsInTrade: the materials were traded alongside the +3 piece and are
    -- already confirmed on the trade -- confirmTrade consumes them. Otherwise
    -- pull them from MAIN inventory (lone-piece trade).
    local function doForge(player, entry, matsInTrade)
        local mats = materialsFor(entry)

        -- Guard: entries with no job card (pcard 0) can't be forged here.
        if not entry.pcard or entry.pcard == 0 then
            player:printToPlayer('[+4 Forge] That piece has no Paragon Card, kupo. Cannot upgrade it here.', SYS)
            return
        end

        -- RARE pre-check: giveItem would refuse a second +4 AFTER the trade
        -- and materials were consumed. Refuse before anything is spent.
        if player:hasItem(entry.result) then
            player:printToPlayer(string.format(
                '[+4 Forge] You already own %s +4 -- it is RARE, so a second cannot be forged, kupo!',
                entry.name), SYS)
            return
        end

        if not matsInTrade then
            -- Enough of every material?
            for _, c in ipairs(mats) do
                if player:getItemCount(c.id) < c.qty then
                    player:printToPlayer(string.format('[+4 Forge] %s -> +4 costs %s. Kupo!', entry.name, costString(entry)), SYS)
                    return
                end
            end

            -- Consume materials (abort + refund on any shortfall, BEFORE the trade).
            local paid = {}
            for _, c in ipairs(mats) do
                if not consume(player, c.id, c.qty) then
                    for id, qty in pairs(paid) do
                        player:addItem({ id = id, quantity = qty })
                    end
                    player:printToPlayer('[+4 Forge] Keep your cards as single MAIN-inventory stacks and try again, kupo!', SYS)
                    return
                end
                paid[c.id] = (paid[c.id] or 0) + c.qty
            end
        end

        -- Consume the traded +3 piece (and traded materials) and hand back the +4.
        player:confirmTrade()
        npcUtil.giveItem(player, entry.result)
        player:printToPlayer(string.format('[+4 Forge] %s reforged to +4! Kupo!', entry.name), SYS)
    end

    local forge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Divergence_Forge',
        packetName = string.format('%sDivergence Forge', xi.icon.STAR_LARGE),
        look       = 63,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            -- Accept both trade shapes the NPC/website describe:
            --   1) +3 piece + the exact materials all in the trade window
            --   2) +3 piece alone, materials pulled from MAIN inventory
            for tradedId, entry in pairs(plus4map) do
                local fullTrade = { tradedId }
                for _, c in ipairs(materialsFor(entry)) do
                    if c.id and c.id > 0 then
                        fullTrade[#fullTrade + 1] = { c.id, c.qty }
                    end
                end

                if npcUtil.tradeHasExactly(trade, fullTrade) then
                    doForge(player, entry, true)
                    return
                elseif npcUtil.tradeHasExactly(trade, { tradedId }) then
                    doForge(player, entry, false)
                    return
                elseif npcUtil.tradeHas(trade, { tradedId }) then
                    -- The +3 piece is in the trade, but with the wrong extras
                    -- (short on cards / unrelated items alongside it).
                    player:printToPlayer(string.format('[+4 Forge] %s -> +4 costs %s. Kupo!', entry.name, costString(entry)), SYS)
                    player:printToPlayer('[+4 Forge] Trade the +3 piece with exactly those materials, or trade it alone with the materials in your inventory, kupo!', SYS)
                    return
                end
            end

            for tradedId in pairs(unsupportedEmpyreanPlus3) do
                if npcUtil.tradeHas(trade, { tradedId }) then
                    player:printToPlayer(
                        '[+4 Forge] That is an Empyrean +3 piece. Empyrean armor has no +4 item; only Artifact and Relic +3 can be forged here, kupo!',
                        SYS)
                    return
                end
            end

            player:printToPlayer('[+4 Forge] Trade me a reforged +3 AF/Relic piece to upgrade it to +4, kupo!', SYS)
        end,

        onTrigger = function(player, npc)
            player:printToPlayer('[+4 Forge] Trade a reforged +3 AF/Relic piece + your job\'s Paragon Card + Rusted/Black ID Cards, and I forge it to +4. Kupo!', SYS)
            player:printToPlayer(string.format('[+4 Forge] Cost: %dx Paragon Card (%dx body), %dx Rusted (%dx body) + %dx Black (%dx body) ID Cards. Empyrean has no +4.',
                PCARD_QTY, PCARD_QTY_BODY, RUSTED_QTY, RUSTED_QTY_BODY, BLACK_QTY, BLACK_QTY_BODY), SYS)
        end,
    })
    utils.unused(forge)
end)

-- ----------------------------------------------------------------------------
-- Mega-boss Paragon Card drop. When one of the 4 [D] mega-bosses dies, the
-- killer gets their MAIN-job Paragon Card (9280 + jobId) -- the job-matched
-- material the forge above requires. Not a droplist row (it depends on the
-- killer's job), so it lives here.
-- ----------------------------------------------------------------------------
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    -- Once per kill (isKiller marks the killing blow), PC only.
    if not isKiller or player == nil then
        return
    end
    if player:getObjType() ~= xi.objType.PC then
        return
    end
    if mob == nil or not MEGABOSSES[mob:getName()] then
        return
    end

    local jobId = player:getMainJob()
    if jobId == nil or jobId < 1 or jobId > 22 then
        return
    end
    local cardId = 9280 + jobId

    if player:getFreeSlotsCount() <= 0 then
        player:printToPlayer('[+4 Forge] A Paragon Card dropped, but your inventory is full, kupo!', SYS)
        return
    end
    pcall(function() player:addItem({ id = cardId, quantity = 1 }) end)
    player:printToPlayer('[+4 Forge] The mega-boss yields your Paragon Card! Bring it and a +3 piece to the Divergence Forge, kupo!', SYS)
end)

return m
