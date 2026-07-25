-----------------------------------
-- Relic_Forge.lua
-- DYNAMIS-GATED Relic Weapon forge (owner request 2026-06-25).
--
-- The 16 Stage-5 Relic weapons (Lv.119 III) were pulled from the Prime Armory
-- forge, the GearProgression vendor, and the Invasion drop pool -- this NPC is
-- now available here as a repeat-relic shortcut after the player has completed
-- one Relic through the full Weapon Forge progression. Each repeat forge costs
-- the retail final-stage currency type again.
--
-- NPC lives in Leafallia (the relaunch end-game hub, alongside Prime Armory /
-- Apex / Paragon / etc.). The Dynamis *gate* is the currency cost, not the NPC
-- location.
--
-- Currency and Plutons are consumed through hl_seal_currency so costs can span
-- stacks and containers safely.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('relic_forge')
local currency = require('modules/custom/lua/hl_seal_currency')

local NPC_POS = { x = 572.000, y = -3.360, z = 534.200, rot = 64 }

-- The 14 final damage Relics use their real 119 III item IDs.  The previous list
-- reused the Stage-5 Prime IDs (21535 etc.) and merely relabeled them as Relics.
-- That made a forged "Relic" indistinguishable from a Prime to every combat
-- system, so it received Prime WS handling and could never receive the RELIC
-- defense-ignore tuning in rema_ws_tier_catalog.lua.  Shield/instrument retain
-- their highest real Relic IDs; neither participates in damage-WS tuning.
local relicCatalog = require('modules/custom/lua/relic_forge_catalog')
local RELICS = relicCatalog.weapons
local FORGE_COST = relicCatalog.repeatCurrencyCost
local PLUTON_COST = relicCatalog.repeatPlutonCost
local PLUTON_ID   = relicCatalog.plutonId

local function costStr(relic)
    return string.format('%d %s + %d Plutons', FORGE_COST, relic.currencyName, PLUTON_COST)
end

local function refundItem(player, itemId, amount)
    local remaining = amount
    while remaining > 0 do
        local quantity = math.min(remaining, 99)
        if not player:addItem({ id = itemId, quantity = quantity }) then
            return false
        end
        remaining = remaining - quantity
    end
    return true
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, title, options)
        local snapshot = { title = title, options = options }  -- snapshot before deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -- customMenu encodes title + all labels into ~150 bytes; 4 relics/page keeps
    -- every page under the cap.
    local PAGE_SIZE = 4

    local showRelics  -- forward decl

    -- Consume the currency and grant the relic. Refunds on any shortfall.
    local function doForge(player, relic)
        if (player:getCharVar('WF_Relic_Final') or 0) ~= 1 then
            player:printToPlayer(
                '[Relic Forge] Complete one Relic to 119 III through the full Weapon Forge path first, kupo!',
                xi.msg.channel.SYSTEM_3)
            return
        end
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Relic Forge] Free an inventory slot first, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- RARE pre-check: the engine refuses a second copy, and consuming
        -- first would eat the currency with nothing granted.
        if player:hasItem(relic.id) then
            player:printToPlayer(string.format(
                '[Relic Forge] You already hold %s -- it is RARE, so a second cannot be forged, kupo!',
                relic.name), xi.msg.channel.SYSTEM_3)
            return
        end
        if player:getItemCount(relic.currency) < FORGE_COST then
            player:printToPlayer(string.format(
                '[Relic Forge] Not enough Dynamis currency -- need %s (you have %d). Kupo!',
                costStr(relic), player:getItemCount(relic.currency)), xi.msg.channel.SYSTEM_3)
            return
        end
        if player:getItemCount(PLUTON_ID) < PLUTON_COST then
            player:printToPlayer(string.format(
                '[Relic Forge] Not enough Plutons -- need %d (you have %d). Kupo!',
                PLUTON_COST, player:getItemCount(PLUTON_ID)), xi.msg.channel.SYSTEM_3)
            return
        end
        if not currency.take(player, relic.currency, FORGE_COST) then
            player:printToPlayer(
                '[Relic Forge] I could not gather the full currency payment, so nothing was forged, kupo!',
                xi.msg.channel.SYSTEM_3)
            return
        end
        if not currency.take(player, PLUTON_ID, PLUTON_COST) then
            refundItem(player, relic.currency, FORGE_COST)
            player:printToPlayer(
                '[Relic Forge] I could not gather the Pluton payment, so your Dynamis currency was returned, kupo!',
                xi.msg.channel.SYSTEM_3)
            return
        end
        if not player:addItem({ id = relic.id, quantity = 1 }) then
            refundItem(player, relic.currency, FORGE_COST)
            refundItem(player, PLUTON_ID, PLUTON_COST)
            player:printToPlayer('[Relic Forge] The forging failed -- your currency and Plutons have been returned, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        player:printToPlayer(string.format(
            '[Relic Forge] %s, forged from the spoils of Dynamis! Kupo!', relic.name),
            xi.msg.channel.SYSTEM_3)
    end

    local function showConfirm(player, relic)
        local options =
        {
            { string.format('Forge for %s', costStr(relic)),
                function(p)
                    doForge(p, relic)
                    showRelics(p, 1)
                end },
            { 'No - go back.',
                function(p) showRelics(p, 1) end },
        }
        sendMenu(player, string.format('Forge %s?', relic.name), options)
    end

    showRelics = function(player, page)
        page = page or 1
        local totalPages = math.ceil(#RELICS / PAGE_SIZE)
        local options = {}
        local startIdx = (page - 1) * PAGE_SIZE + 1
        local endIdx   = math.min(startIdx + PAGE_SIZE - 1, #RELICS)
        for i = startIdx, endIdx do
            local relic = RELICS[i]
            options[#options + 1] =
            {
                relic.name,
                function(p)
                    p:printToPlayer(relic.info, xi.msg.channel.SYSTEM_3)
                    showConfirm(p, relic)
                end,
            }
        end
        if page > 1 then
            options[#options + 1] = { string.format('<< Prev (%d/%d)', page - 1, totalPages),
                function(p) showRelics(p, page - 1) end }
        end
        if page < totalPages then
            options[#options + 1] = { string.format('Next >> (%d/%d)', page + 1, totalPages),
                function(p) showRelics(p, page + 1) end }
        end
        options[#options + 1] = { 'Never mind.', function() end }
        sendMenu(player, string.format('Relic Forge (%d/%d)', page, totalPages), options)
    end

    local RelicForge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Relic_Forge',
        packetName = string.format('%sRelic Forge', xi.icon.STAR_LARGE),
        look       = 219,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Relic Forge] No trades -- pick a relic from the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            if (player:getCharVar('WF_Relic_Final') or 0) ~= 1 then
                player:printToPlayer(
                    '[Relic Forge] Complete one Relic to 119 III through the full Weapon Forge path to unlock repeat forging, kupo!',
                    xi.msg.channel.SYSTEM_3)
                return
            end
            player:printToPlayer(string.format(
                '[Relic Forge] Repeat Relics cost %d of their Dynamis currency plus %d Plutons, kupo!',
                FORGE_COST, PLUTON_COST), xi.msg.channel.SYSTEM_3)
            showRelics(player, 1)
        end,
    })
    utils.unused(RelicForge)
end)

return m
