-----------------------------------
-- Relic_Forge.lua
-- DYNAMIS-GATED Relic Weapon forge (owner request 2026-06-25).
--
-- The 16 Stage-5 Relic weapons (Lv.119 III) were pulled from the Prime Armory
-- forge, the GearProgression vendor, and the Invasion drop pool -- this NPC is
-- now the ONLY way to obtain them, and it charges DYNAMIS CURRENCY. So a player
-- must farm Dynamis to earn a relic. Repeatable: each forge costs the currency
-- again, so dedicated Dynamis runners can build multiple relics.
--
-- NPC lives in Leafallia (the relaunch end-game hub, alongside Prime Armory /
-- Apex / Paragon / etc.). The Dynamis *gate* is the currency cost, not the NPC
-- location.
--
-- Currency-consume note: player:delItem only debits the FIRST main-inventory
-- stack, while getItemCount spans all containers -- so the consume loop measures
-- the real delta and refunds on a split/satchel stack (mirrors PrimeArmory's
-- Trial-5 turn-in). Keep each FORGE_COST qty <= 99 (one stack) for this to work.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('relic_forge')

local NPC_POS = { x = 572.000, y = -3.360, z = 534.200, rot = 64 }

-- Dynamis currency cost PER relic. Tunable. Dynamis currencies (item_basic):
--   1449 Tukuku Whiteshell (Windurst)   1450 Lungo-Nango Jadeshell (San d'Oria)
--   1452 Ordelle Bronzepiece            1453 Montiont Silverpiece (Bastok)
--   1455 One Byne Bill (Jeuno)          1456 One-Hundred Byne Bill (Jeuno)
-- Default: 75 One-Hundred Byne Bills (= 7,500 bynes of Jeuno Dynamis). Add rows
-- (e.g. nation shells) to require farming more Dynamis zones. Keep each qty<=99.
local FORGE_COST =
{
    { id = 1456, qty = 75, name = '100 Byne Bill' },
}

-- The 14 final damage Relics use their real 119 III item IDs.  The previous list
-- reused the Stage-5 Prime IDs (21535 etc.) and merely relabeled them as Relics.
-- That made a forged "Relic" indistinguishable from a Prime to every combat
-- system, so it received Prime WS handling and could never receive the RELIC
-- defense-ignore tuning in rema_ws_tier_catalog.lua.  Shield/instrument retain
-- their highest real Relic IDs; neither participates in damage-WS tuning.
local RELICS = require('modules/custom/lua/relic_forge_catalog').weapons

local function costStr()
    local parts = {}
    for _, c in ipairs(FORGE_COST) do
        parts[#parts + 1] = string.format('%d %s', c.qty, c.name)
    end
    return table.concat(parts, ', ')
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
        -- All currencies present?
        for _, c in ipairs(FORGE_COST) do
            if player:getItemCount(c.id) < c.qty then
                player:printToPlayer(string.format(
                    '[Relic Forge] Not enough Dynamis currency -- need %s (you have %d %s). Kupo!',
                    costStr(), player:getItemCount(c.id), c.name), xi.msg.channel.SYSTEM_3)
                return
            end
        end
        -- Consume, measuring the real delta; refund all on any shortfall.
        local removed, shortfall = {}, false
        for _, c in ipairs(FORGE_COST) do
            local before = player:getItemCount(c.id)
            player:delItem(c.id, c.qty)
            local got = before - player:getItemCount(c.id)
            removed[c.id] = got
            if got < c.qty then shortfall = true end
        end
        if shortfall then
            for id, qty in pairs(removed) do
                if qty > 0 then player:addItem({ id = id, quantity = qty }) end
            end
            player:printToPlayer('[Relic Forge] I could not gather it all -- keep each currency as a single stack in your MAIN inventory (not satchel/case) and try again, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        if not player:addItem({ id = relic.id, quantity = 1 }) then
            -- Grant failed anyway: return every consumed currency.
            for id, qty in pairs(removed) do
                if qty > 0 then player:addItem({ id = id, quantity = qty }) end
            end
            player:printToPlayer('[Relic Forge] The forging failed -- your currency has been returned, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        player:printToPlayer(string.format(
            '[Relic Forge] %s, forged from the spoils of Dynamis! Kupo!', relic.name),
            xi.msg.channel.SYSTEM_3)
    end

    local function showConfirm(player, relic)
        local options =
        {
            { string.format('Forge for %s', costStr()),
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
            player:printToPlayer(string.format(
                '[Relic Forge] I forge Stage-5 Relic weapons from Dynamis spoils -- %s per relic. Earn the currency in Dynamis, kupo!',
                costStr()), xi.msg.channel.SYSTEM_3)
            showRelics(player, 1)
        end,
    })
    utils.unused(RelicForge)
end)

return m
