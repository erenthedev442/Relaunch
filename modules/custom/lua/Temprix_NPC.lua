-----------------------------------
-- Temprix_NPC.lua
--
-- Temprix is the Reisenjima entry point for the Aeonic weapon path.
-- She mirrors the hub Weapon Forge's Malformed-base service for Escha Beads.
-- Players then forge their Malformed weapon into a full Aeonic 119III at
-- the Weapon Forger (see WeaponForge_NPC.lua) with Attestations and Escha Silt.
--
-- POSITION: adjust x/y/z to match Reisenjima zone geometry on first test.
--
-- The 14 Malformed weapon item rows (IDs 29701-29714) are added to item_basic by
-- modules/custom/sql/aeonic_malformed_items.sql (auto-applied every deploy).
--
-- restart-gated (addOverride)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Reisenjima/Zone')

local m = Module:new('temprix_npc')
local S = xi.msg.channel.SYSTEM_3
local forgeCatalog = require('modules/custom/lua/weapon_forge_catalog')
local forgeGates = require('modules/custom/lua/weapon_forge_gates')

-- ===================================================================
-- CONSTANTS
-- ===================================================================
-- Escha Beads are a REAL currency (char_points.escha_beads, shows in the
-- Currencies II tab) -- getCurrency/delCurrency, NOT a charVar. Geas Fete and the
-- bead pouch award the same currency.
local BEADS_KEY = 'escha_beads'
local COST      = forgeCatalog.aeonicBase.eschaBeads
local REQUIRED_HL_RANK = forgeCatalog.aeonicBase.hlRank
local NPC_POS   = { x = -365.000, y = -113.300, z = 211.500, rot = 64 }
local TEMPRIX_LOOK = '0x0000E20300000000000000000000000000000000'

local function checkEntryGate(player)
    local ok, gate = forgeGates.checkGate(player, 'aeonic', 0)
    if not ok then
        player:printToPlayer(string.format(
            '[Temprix] Aeonic path locked: %s.', gate.label), S)
    end
    return ok
end

-- ===================================================================
-- Weapon list derives from the main forge catalog so Temprix cannot drift.
-- ===================================================================
local WEAPONS = {}
for _, chain in ipairs(forgeCatalog.chains) do
    WEAPONS[#WEAPONS + 1] =
    {
        name    = chain.aeonic.base.name,
        id      = chain.aeonic.base.id,
        wtype   = chain.type,
        att     = chain.aeonic.attestationId,
        attName = chain.aeonic.attestationName,
        chain   = chain,
    }
end

local PAGE_SIZE   = 5
local TOTAL_PAGES = math.ceil(#WEAPONS / PAGE_SIZE)

-- ===================================================================
-- MENU HELPERS
-- ===================================================================
local function sendMenu(player, title, options)
    local snap = { title = title, options = options }
    player:timer(30, function(p) p:customMenu(snap) end)
end

local showPage  -- forward-declared so purchase handler can reference it

showPage = function(player, page)
    -- escha_beads is a CURRENCY (char_points), not a charvar -- getCharVar
    -- always read 0 here, so the title showed the wrong balance.
    local beads   = player:getCurrency(BEADS_KEY)
    local title   = string.format('Temprix [Beads: %d]', beads)
    local options = {}
    local p       = math.max(1, math.min(page, TOTAL_PAGES))
    local base    = (p - 1) * PAGE_SIZE

    for i = base + 1, math.min(base + PAGE_SIZE, #WEAPONS) do
        local w = WEAPONS[i]
        -- Capture i so the closure binds the right weapon.
        local wCapture = w
        local pageCapture = p
        options[#options + 1] = {
            wCapture.name,
            function(pp)
                if not checkEntryGate(pp) then return end
                local hl = math.max(1, pp:getCharVar('HL_Tier'))
                if hl < REQUIRED_HL_RANK then
                    pp:printToPlayer(string.format(
                        '[Temprix] Hunting League Rank %d is required. You are Rank %d.',
                        REQUIRED_HL_RANK, hl), S)
                    pp:timer(30, function(p2) showPage(p2, pageCapture) end)
                    return
                end
                local b = pp:getCurrency(BEADS_KEY)
                if b < COST then
                    pp:printToPlayer(string.format(
                        '[Temprix] %d Escha Beads needed. You have %d.',
                        COST, b), S)
                    pp:timer(30, function(p2) showPage(p2, pageCapture) end)
                    return
                end
                if pp:getFreeSlotsCount() < 1 then
                    pp:printToPlayer('[Temprix] Your inventory is full.', S)
                    pp:timer(30, function(p2) showPage(p2, pageCapture) end)
                    return
                end
                -- RARE pre-check: charging first would eat the beads with
                -- nothing granted.
                local ae = wCapture.chain.aeonic
                if
                    pp:hasItem(ae.base.id) or
                    pp:hasItem(ae.s1.id) or
                    pp:hasItem(ae.s2.id) or
                    pp:hasItem(ae.s3.id)
                then
                    pp:printToPlayer(string.format(
                        '[Temprix] You already hold a stage of the %s chain.',
                        ae.s3.name), S)
                    pp:timer(30, function(p2) showPage(p2, pageCapture) end)
                    return
                end
                pp:delCurrency(BEADS_KEY, COST)
                if not pp:addItem({ id = wCapture.id, quantity = 1 }) then
                    pp:addCurrency(BEADS_KEY, COST)
                    pp:printToPlayer('[Temprix] Something went wrong -- your beads have been returned.', S)
                    pp:timer(30, function(p2) showPage(p2, pageCapture) end)
                    return
                end
                pp:printToPlayer(string.format(
                    '[Temprix] %s entrusted to you. Attune it with %s to begin forging.',
                    wCapture.name, wCapture.attName), S)
                pp:timer(30, function(p2) showPage(p2, pageCapture) end)
            end,
        }
    end

    if p < TOTAL_PAGES then
        options[#options + 1] = { 'Next Page', function(pp) showPage(pp, p + 1) end }
    end
    if p > 1 then
        options[#options + 1] = { 'Prev Page', function(pp) showPage(pp, p - 1) end }
    end
    options[#options + 1] = { 'Nothing.', function(_) end }

    sendMenu(player, title, options)
end

-- ===================================================================
-- NPC SPAWN
-- ===================================================================
m:addOverride('xi.zones.Reisenjima.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype  = xi.objType.NPC,
        name     = 'Temprix',
        packetName = string.format('Temprix %sAeonic', xi.icon.STAR_LARGE),
        look     = TEMPRIX_LOOK,
        x        = NPC_POS.x,
        y        = NPC_POS.y,
        z        = NPC_POS.z,
        rotation = NPC_POS.rot,
        widescan = 1,

        onTrigger = function(player, npc)
            -- One-time migration: fold the DEAD legacy charVars (Escha_Beads /
            -- Escha_Silt, pre-real-currency) into the unified escha_beads currency
            -- so pre-refactor balances aren't stranded. Idempotent. (The real
            -- escha_silt currency is left alone -- it's portal/travel fuel.)
            for _, var in ipairs({ 'Escha_Beads', 'Escha_Silt' }) do
                local old = player:getCharVar(var) or 0
                if old > 0 then
                    player:addCurrency(BEADS_KEY, old)
                    player:setCharVar(var, 0)
                end
            end
            local hl = math.max(1, player:getCharVar('HL_Tier'))
            if not checkEntryGate(player) then
                return
            end
            if hl < REQUIRED_HL_RANK then
                player:printToPlayer(string.format(
                    '[Temprix] Hunting League Rank %d is required to obtain a Malformed weapon. You are Rank %d.',
                    REQUIRED_HL_RANK, hl), S)
                return
            end
            showPage(player, 1)
        end,
    })
end)

return m
