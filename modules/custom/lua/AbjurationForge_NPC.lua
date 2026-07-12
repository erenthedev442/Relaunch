-----------------------------------
-- AbjurationForge_NPC.lua
-- "Reisenjima Forge" NPC in Purgonorgo Isle (!hub), zone 44.
--
-- Owner request 2026-07-13: the relaunch analogue of retail's Nolan (Norg),
-- unlocking the 25 augmented-armor pieces (Odyssean / Valorous / Chironic /
-- Merlinic / Herculean) that had no source on the server after the
-- Nolan-cleanup pass removed them from the Domain QM. Also handles NQ->+1
-- upgrades for the 6 crafted-family sets (Adhemar / Argosy / Carmine /
-- Rao / Ryuo / Souveran).
--
-- Two menus:
--   TRADE   -- consume 1 abjuration, hand back the matching augmented piece
--              (slot- and family-locked; abjToArmor in the catalog).
--   UPGRADE -- consume 1 NQ crafted piece + 3 Riftborn Boulders (tunable),
--              hand back the +1 version of the same piece (nqToHq in the
--              catalog).
--
-- Abjuration drops are wired in Geas_Fete.lua (T3+ NMs roll for one).
-- Riftborn Boulders drop from the same NMs.
-- Restart-gated (addOverride onInitialize).
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/abjuration_forge_catalog')

require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('abjuration_forge')
local S = xi.msg.channel.SYSTEM_3

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------

local function trunc(s, max)
    if not s or #s <= max then return s or '' end
    return s:sub(1, max - 2) .. '..'
end

local menuState = { title = '', options = {} }

local function openMenu(player)
    local snap = { title = menuState.title, options = menuState.options }
    player:timer(30, function(p) p:customMenu(snap) end)
end

-- customMenu is capped at 8 entries per screen (client limit). Paginated
-- browse: SIZE-1 rows + 'More >>' / 'Back'.
local PAGE_SIZE = 6

local function paginate(player, title, rows, backFn, page)
    page = page or 0
    local pages = math.max(1, math.ceil(#rows / PAGE_SIZE))
    page = page % pages
    local opts = {}
    for i = page * PAGE_SIZE + 1, math.min((page + 1) * PAGE_SIZE, #rows) do
        opts[#opts + 1] = rows[i]
    end
    if pages > 1 then
        opts[#opts + 1] = { string.format('More >> (%d/%d)', page + 1, pages),
            function(p) paginate(p, title, rows, backFn, page + 1) end }
    end
    opts[#opts + 1] = { 'Back', function(p) backFn(p) end }
    menuState.title   = title
    menuState.options = opts
    openMenu(player)
end

--------------------------------------------------------------------
-- TRADE: abjuration -> augmented armor piece
--------------------------------------------------------------------
local function tradeAbjuration(player, abjId)
    local target = catalog.abjToArmor[abjId]
    if not target then return end

    -- Guard: still holding it, and bag room for the reward.
    if player:getItemCount(abjId) < 1 then
        player:printToPlayer('[Forge] You no longer hold that abjuration, kupo.', S)
        return
    end
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer('[Forge] Make room in your bags first, kupo!', S)
        return
    end

    -- Consume the abjuration, then hand the armor. If the addItem fails
    -- (RARE/EX collision), refund the abjuration.
    player:delItem(abjId, 1)
    if not player:addItem({ id = target.id, quantity = 1 }) then
        player:addItem({ id = abjId, quantity = 1 })
        player:printToPlayer(string.format(
            '[Forge] Could not grant %s (already own it? RARE/EX). Abjuration refunded, kupo.',
            target.name), S)
        return
    end
    player:printToPlayer(string.format(
        '[Forge] Abjuration reforged -- receive one %s! Kupo!', target.name), S)
end

local function showTradeMenu(player, backFn)
    -- List only abjurations the player is currently holding.
    local rows = {}
    for abjId, target in pairs(catalog.abjToArmor) do
        local have = player:getItemCount(abjId)
        if have > 0 then
            local id, name = abjId, target.name
            rows[#rows + 1] = {
                string.format('%s (x%d)', trunc(name, 22), have),
                function(p) tradeAbjuration(p, id); backFn(p) end,
            }
        end
    end
    if #rows == 0 then
        player:printToPlayer(
            '[Forge] You hold no Reisenjima abjurations. Farm T3+ Geas Fete NMs to earn them, kupo.', S)
        backFn(player)
        return
    end
    -- Sort by name so the menu is stable across visits.
    table.sort(rows, function(a, b) return a[1] < b[1] end)
    paginate(player, 'Trade abjuration', rows, backFn)
end

--------------------------------------------------------------------
-- UPGRADE: NQ crafted-family piece + N Riftborn Boulders -> +1
--------------------------------------------------------------------
local function upgradePiece(player, nqId)
    local target = catalog.nqToHq[nqId]
    if not target then return end
    local matId  = catalog.upgradeMat
    local matQty = catalog.upgradeMatQty
    local matNm  = catalog.upgradeMatName

    if player:getItemCount(nqId) < 1 then
        player:printToPlayer('[Forge] You no longer hold that piece, kupo.', S)
        return
    end
    if player:getItemCount(matId) < matQty then
        player:printToPlayer(string.format(
            '[Forge] Need %d %s (you have %d). Kupo!',
            matQty, matNm, player:getItemCount(matId)), S)
        return
    end
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer('[Forge] Make room in your bags first, kupo!', S)
        return
    end

    -- Consume NQ + materials, then hand the +1. Refund on RARE/EX collision.
    player:delItem(nqId, 1)
    player:delItem(matId, matQty)
    if not player:addItem({ id = target.id, quantity = 1 }) then
        player:addItem({ id = nqId, quantity = 1 })
        player:addItem({ id = matId, quantity = matQty })
        player:printToPlayer(string.format(
            '[Forge] Could not grant %s (already own it? RARE/EX). Trade refunded, kupo.',
            target.name), S)
        return
    end
    player:printToPlayer(string.format(
        '[Forge] Forge complete -- receive one %s! Kupo!', target.name), S)
end

local function showUpgradeMenu(player, backFn)
    local matId, matQty, matNm = catalog.upgradeMat, catalog.upgradeMatQty, catalog.upgradeMatName
    local haveMat = player:getItemCount(matId)
    local rows = {}
    for nqId, target in pairs(catalog.nqToHq) do
        local have = player:getItemCount(nqId)
        if have > 0 then
            local id, name = nqId, target.name
            rows[#rows + 1] = {
                string.format('%s (x%d)', trunc(name, 22), have),
                function(p) upgradePiece(p, id); backFn(p) end,
            }
        end
    end
    if #rows == 0 then
        player:printToPlayer(
            '[Forge] You hold no upgradeable NQ pieces (Adhemar/Argosy/Carmine/Rao/Ryuo/Souveran). Farm Geas Fete NMs first, kupo!', S)
        backFn(player)
        return
    end
    table.sort(rows, function(a, b) return a[1] < b[1] end)
    player:printToPlayer(string.format(
        '[Forge] Upgrade cost: %d %s per piece. You hold %d.',
        matQty, matNm, haveMat), S)
    paginate(player, 'Upgrade NQ -> +1', rows, backFn)
end

--------------------------------------------------------------------
-- MAIN MENU
--------------------------------------------------------------------
local function showMain(player)
    local mainFn = showMain
    menuState.title = 'Reisenjima Forge'
    menuState.options = {
        { 'Trade abjuration',    function(p) showTradeMenu(p, mainFn) end },
        { 'Upgrade NQ -> +1',    function(p) showUpgradeMenu(p, mainFn) end },
        { 'What are these?',     function(p)
            p:printToPlayer('[Forge] Reisenjima abjurations drop from Tier 3 and Boss Geas Fete NMs. Trade one for its matching augmented piece (Odyssean, Valorous, Chironic, Merlinic, Herculean). Kupo!', S)
            p:printToPlayer('[Forge] Reisenjima NQ pieces (Adhemar, Argosy, Carmine, Rao, Ryuo, Souveran) also drop from those NMs. Bring one plus 3 Riftborn Boulders, I forge it +1. Kupo!', S)
        end },
        { 'Leave', function(p) end },
    }
    openMenu(player)
end

--------------------------------------------------------------------
-- NPC PLACEMENT
--------------------------------------------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local p = catalog.npcPos
    local forge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Reisenjima_Forge',
        packetName = string.format('%sReisenjima Forge', xi.icon.STAR_LARGE),
        look       = 2419,   -- moogle (same look family as Domain QM / Gil Exchange)
        x          = p.x,
        y          = p.y,
        z          = p.z,
        rotation   = p.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                '[Reisenjima Forge] Bring me a Reisenjima abjuration or crafted piece, and I will reforge it, kupo!', S)
            showMain(player)
        end,
    })
    utils.unused(forge)
end)

return m
