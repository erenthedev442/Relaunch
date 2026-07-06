-----------------------------------
-- Dynamis - Divergence -- "+4 Reforge Forge" NPC (relaunch custom)
--
-- The endgame tail of the reforge ladder: upgrade a reforged +3 AF/Relic piece
-- to +4. Self-contained in the Dynamis [D] system -- the materials farmed inside
-- the [D] zones ARE the gate (no slot-unlock charVar; drop that DivergenceSlots
-- logic entirely).
--
-- Trade a reforged +3 piece + the required materials:
--   * 1x your job's Paragon Card   (entry.pcard, from reforge_plus4_map.lua)
--   * 8x Rusted ID Card    (9538)  [12x for body]
--   * 2x Black  ID Card    (9540)  [ 4x for body]
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

local m = Module:new('dynamis_plus4_forge')

-- NPC placement (the retired Divergence Smith's exact spot).
local NPC_POS = { x = 155.0, y = -2.0, z = 162.0, rot = 96 }

-- Material costs (tunable). Paragon Card is per-entry (entry.pcard); the ID cards
-- are flat, with a heavier body tax (body pieces are the strongest slot).
local PCARD_QTY        = 1      -- x entry.pcard (job-matched Paragon Card)
local RUSTED_ID        = 9538   -- Rusted Identification Card
local RUSTED_QTY       = 8      -- non-body
local RUSTED_QTY_BODY  = 12     -- body
local BLACK_ID         = 9540   -- Blackened Identification Card
local BLACK_QTY        = 2      -- non-body
local BLACK_QTY_BODY   = 4      -- body

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
    local rusted = (entry.slot == 'body') and RUSTED_QTY_BODY or RUSTED_QTY
    local black  = (entry.slot == 'body') and BLACK_QTY_BODY  or BLACK_QTY
    return {
        { id = entry.pcard, qty = PCARD_QTY, name = 'your job\'s Paragon Card' },
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

    local function doForge(player, entry)
        local mats = materialsFor(entry)

        -- Guard: entries with no job card (pcard 0) can't be forged here.
        if not entry.pcard or entry.pcard == 0 then
            player:printToPlayer('[+4 Forge] That piece has no Paragon Card, kupo. Cannot upgrade it here.', SYS)
            return
        end

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

        -- Consume the traded +3 piece and hand back the +4.
        player:confirmTrade()
        npcUtil.giveItem(player, entry.result)
        player:printToPlayer(string.format('[+4 Forge] %s reforged to +4! Kupo!', entry.name), SYS)
    end

    local forge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Divergence_Forge',
        packetName = string.format('%sDivergence Forge', xi.icon.STAR_LARGE),
        look       = 3000,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            for tradedId, entry in pairs(plus4map) do
                if npcUtil.tradeHasExactly(trade, { tradedId }) then
                    doForge(player, entry)
                    return
                end
            end
            player:printToPlayer('[+4 Forge] Trade me a reforged +3 AF/Relic piece to upgrade it to +4, kupo!', SYS)
        end,

        onTrigger = function(player, npc)
            player:printToPlayer('[+4 Forge] Trade a reforged +3 AF/Relic piece + your job\'s Paragon Card + Rusted/Black ID Cards, and I forge it to +4. Kupo!', SYS)
            player:printToPlayer(string.format('[+4 Forge] Cost: %dx Paragon Card, %dx Rusted (%dx body) + %dx Black (%dx body) ID Cards. Empyrean has no +4.',
                PCARD_QTY, RUSTED_QTY, RUSTED_QTY_BODY, BLACK_QTY, BLACK_QTY_BODY), SYS)
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
