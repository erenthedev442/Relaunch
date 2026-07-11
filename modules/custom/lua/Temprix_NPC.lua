-----------------------------------
-- Temprix_NPC.lua
--
-- Temprix is the gate-keeper for the Aeonic weapon path in Reisenjima.
-- She sells "Malformed" base weapons in exchange for Escha Beads (charVar).
-- Players then forge their Malformed weapon into a full Aeonic 119III at
-- the Weapon Forger (see WeaponForge_NPC.lua) once they have enough Attestations and
-- Riftborn Boulders.
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

-- ===================================================================
-- CONSTANTS
-- ===================================================================
-- Escha Beads are a REAL currency (char_points.escha_beads, shows in the
-- Currencies II tab) -- getCurrency/delCurrency, NOT a charVar. Geas Fete and the
-- bead pouch award the same currency.
local BEADS_KEY = 'escha_beads'
local COST      = 50000   -- Escha Beads per Malformed weapon
local NPC_POS   = { x = 165.000, y = -18.000, z = 335.000, rot = 64 }
-- TODO: position above is approximate; adjust in-game if off.

-- ===================================================================
-- WEAPON CATALOG
-- One entry per Aeonic weapon type. 'id' = Malformed item (item_basic).
-- 'attestation' = the attestation item ID accepted for the Aeonic forge.
-- ===================================================================
local WEAPONS = {
    { name='Malformed Knuckles',   id=29701, wtype='Hand-to-Hand', att=1556, attName='Attest. of Might'         },
    { name='Malformed Knife',      id=29702, wtype='Dagger',       att=1557, attName='Attest. of Celerity'      },
    { name='Malformed Sword',      id=29703, wtype='Sword',        att=1558, attName='Attest. of Glory'         },
    { name='Malformed Claymore',   id=29704, wtype='Gt. Sword',    att=1559, attName='Attest. of Righteousness' },
    { name='Malformed Axe',        id=29705, wtype='Axe',          att=1560, attName='Attest. of Bravery'       },
    { name='Malformed Greataxe',   id=29706, wtype='Gt. Axe',      att=1561, attName='Attest. of Force'         },
    { name='Malformed Scythe',     id=29707, wtype='Scythe',       att=1562, attName='Attest. of Vigor'         },
    { name='Malformed Lance',      id=29708, wtype='Polearm',      att=1563, attName='Attest. of Fortitude'     },
    { name='Malformed Katana',     id=29709, wtype='Katana',       att=1564, attName='Attest. of Legerity'      },
    { name='Malformed Tachi',      id=29710, wtype='Gt. Katana',   att=1565, attName='Attest. of Decisiveness'  },
    { name='Malformed Rod',        id=29711, wtype='Club',         att=1566, attName='Attest. of Sacrifice'     },
    { name='Malformed Staff',      id=29712, wtype='Staff',        att=1567, attName='Attest. of Virtue'        },
    { name='Malformed Bow',        id=29713, wtype='Archery',      att=1568, attName='Attest. of Transcendence' },
    { name='Malformed Culverin',   id=29714, wtype='Marksmanship', att=1569, attName='Attest. of Harmony'       },
}

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
    local beads   = player:getCharVar(BEADS_KEY)
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
                pp:delCurrency(BEADS_KEY, COST)
                pp:addItem({ id = wCapture.id, quantity = 1 })
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
        x        = NPC_POS.x,
        y        = NPC_POS.y,
        z        = NPC_POS.z,
        rotation = NPC_POS.rot,

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
            local beads = player:getCurrency(BEADS_KEY)
            if beads < COST then
                player:printToPlayer(string.format(
                    '[Temprix] These weapons were forged in the crucible of eternity. '..
                    'You must offer %d Escha Beads. You carry %d.',
                    COST, beads), S)
                return
            end
            showPage(player, 1)
        end,
    })
end)

return m
