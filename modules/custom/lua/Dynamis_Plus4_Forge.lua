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
--   * 60x Rusted ID Card   (9538)  [90x for body]
--   *  6x Black  ID Card   (9540)  [12x for body]
-- Extra cards in the trade are kept; only the recipe amount is consumed.
-- Empyrean armor has no +4 tier, so it is not in the map.
--
-- NPC takes the (now retired) Divergence Smith's exact spot in Southern San d'Oria.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')

local plus4map = require('modules/custom/lua/reforge_plus4_map')
local plus4 = require('modules/custom/lua/dynamis_plus4')
local reforgeCatalog = require('modules/custom/lua/reforge_catalog')
local gendered = require('modules/custom/lua/gendered_armor')

local m = Module:new('dynamis_plus4_forge')

-- NPC placement (the retired Divergence Smith's exact spot).
local NPC_POS = { x = 155.0, y = -2.0, z = 162.0, rot = 96 }

local PCARD_QTY       = plus4.PCARD_QTY
local PCARD_QTY_BODY  = plus4.PCARD_QTY_BODY
local RUSTED_QTY      = plus4.RUSTED_QTY
local RUSTED_QTY_BODY = plus4.RUSTED_QTY_BODY
local BLACK_QTY       = plus4.BLACK_QTY
local BLACK_QTY_BODY  = plus4.BLACK_QTY_BODY

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

local function refund(player, items)
    for _, row in ipairs(items) do
        if row.id and row.id > 0 and row.qty and row.qty > 0 then
            pcall(function()
                player:addItem({ id = row.id, quantity = row.qty })
            end)
        end
    end
end

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

    -- matsInTrade: confirm only the recipe amounts from the trade window
    -- (leftover cards stay unconfirmed and return). Otherwise pull materials
    -- from MAIN inventory (lone-piece trade).
    local function doForge(player, trade, pieceId, entry, matsInTrade)
        local mats = plus4.materialsFor(entry)

        -- Guard: entries with no job card (pcard 0) can't be forged here.
        if not entry.pcard or entry.pcard == 0 then
            player:printToPlayer('[+4 Forge] That piece has no Paragon Card, kupo. Cannot upgrade it here.', SYS)
            return
        end

        -- RARE pre-check: addItem would refuse a second +4 AFTER the trade
        -- and materials were consumed. Refuse before anything is spent.
        local resultId = gendered.resolve(player, entry.result)
        if player:hasItem(resultId) then
            player:printToPlayer(string.format(
                '[+4 Forge] You already own %s +4 -- it is RARE, so a second cannot be forged, kupo!',
                entry.name), SYS)
            return
        end

        local paidFromInv = {}
        if not matsInTrade then
            for _, cost in ipairs(mats) do
                if player:getItemCount(cost.id) < cost.qty then
                    player:printToPlayer(string.format('[+4 Forge] %s -> +4 costs %s. Kupo!', entry.name, plus4.costString(entry)), SYS)
                    return
                end
            end

            for _, cost in ipairs(mats) do
                if not consume(player, cost.id, cost.qty) then
                    refund(player, paidFromInv)
                    player:printToPlayer('[+4 Forge] Keep your cards as single MAIN-inventory stacks and try again, kupo!', SYS)
                    return
                end
                paidFromInv[#paidFromInv + 1] = { id = cost.id, qty = cost.qty }
            end
        else
            plus4.confirmRecipe(trade, pieceId, mats)
        end
        if not matsInTrade then
            pcall(function()
                trade:confirmItem(pieceId, 1)
            end)
        end

        player:confirmTrade()
        local given = false
        pcall(function()
            given = player:addItem({ id = resultId, quantity = 1 })
        end)
        if not given then
            refund(player, { { id = pieceId, qty = 1 } })
            if matsInTrade then
                refund(player, mats)
            else
                refund(player, paidFromInv)
            end
            player:printToPlayer('[+4 Forge] The +4 could not be granted -- your +3 and materials were returned, kupo!', SYS)
            return
        end
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
            -- Accept both trade shapes:
            --   1) +3 piece + at least the required cards (leftover stack OK)
            --   2) +3 piece alone, materials pulled from MAIN inventory
            -- Do not probe with npcUtil.tradeHas: it confirmItem()s on match.
            local kind, pieceId, entry = plus4.classify(trade, plus4map, unsupportedEmpyreanPlus3)
            if kind == 'recipe' then
                doForge(player, trade, pieceId, entry, true)
                return
            end
            if kind == 'piece_only' then
                doForge(player, trade, pieceId, entry, false)
                return
            end
            if kind == 'short' then
                player:printToPlayer(string.format('[+4 Forge] %s -> +4 costs %s. Kupo!', entry.name, plus4.costString(entry)), SYS)
                player:printToPlayer('[+4 Forge] Trade the +3 piece with those materials (extra cards are fine), or trade the piece alone with the materials in your inventory, kupo!', SYS)
                return
            end
            if kind == 'empyrean' then
                player:printToPlayer(
                    '[+4 Forge] That is an Empyrean +3 piece. Empyrean armor has no +4 item; only Artifact and Relic +3 can be forged here, kupo!',
                    SYS)
                return
            end

            player:printToPlayer('[+4 Forge] Trade me a reforged +3 AF/Relic piece to upgrade it to +4, kupo!', SYS)
        end,

        onTrigger = function(player, npc)
            player:printToPlayer('[+4 Forge] Trade a reforged +3 AF/Relic piece + your job\'s Paragon Card + Rusted/Black ID Cards, and I forge it to +4. Extra cards in the trade are fine. Kupo!', SYS)
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
