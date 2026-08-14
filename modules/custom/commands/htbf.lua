-----------------------------------
-- !htbf   (High-Tier Battlefield warp)
--
-- Warps you to the burning-circle entrance of the fight you chose -- i.e. the
-- battlefield that matches the Phantom Gem you're currently holding. Buy a gem
-- from the Phantom Gems vendor in Leafallia first (see htbf_catalog / HTBF_Vendor).
--
-- How it resolves the destination:
--   * Reads every Phantom Gem key item you hold (the gems the HTBF vendor sells).
--   * Maps each gem to its fight(s) via htbf_catalog.fights (gem field).
--   * Exactly one candidate  -> warp straight there.
--   * Several candidates     -> the Avatar gem enters any of the 6 elemental
--                               trials (different Cloisters), or you're holding
--                               more than one gem -> a picker menu is shown.
--
-- Warp = drop into the fight's zone at its normal entry point, then snap you
-- exactly onto the entrance NPC (queryEntitiesByName) once the zone has loaded.
-- If the snap can't find the NPC, you still land at the zone entry as a fallback.
--
-- Available to all players (permission 0). Does NOT consume the gem -- entering
-- the battlefield (trading the gem at the entrance) still does that.
-----------------------------------
local catalog = require('modules/custom/lua/htbf_catalog')

local SYS = xi.msg.channel.SYSTEM_3

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

-- Initial landing coordinate per battlefield zone (the zone's normal onZoneIn
-- entry point). After the warp the player is snapped onto the exact entrance NPC,
-- so these only need to put them in the correct zone (and act as the fallback).
-- Sourced from each zone's scripts/zones/<Zone>/Zone.lua onZoneIn.
local ZONE_ENTRY =
{
    [xi.zone.CLOISTER_OF_FLAMES]   = { -698.729,  -1.045, -646.659, 184 },
    [xi.zone.CLOISTER_OF_FROST]    = {  499.993,  -1.696,  523.343, 194 },
    [xi.zone.CLOISTER_OF_GALES]    = { -399.541,  -1.697, -420.000, 252 },
    [xi.zone.CLOISTER_OF_TREMORS]  = { -636.001, -16.563, -500.023, 205 },
    [xi.zone.CLOISTER_OF_STORMS]   = {  517.957, -18.013,  540.045,   0 },
    [xi.zone.CLOISTER_OF_TIDES]    = {  564.776,  34.297,  500.819, 250 },
    [xi.zone.MONARCH_LINN]         = {   12.527,   0.345, -539.602, 127 },
    [xi.zone.SEALIONS_DEN]         = {  600.101, 130.355,  797.612,  50 },
    [xi.zone.BONEYARD_GULLY]       = { -709.508,  18.066,  456.241,  24 },
    [xi.zone.JADE_SEPULCHER]       = {  340.383, -13.625, -157.447, 189 },
    [xi.zone.TALACCA_COVE]         = {   64.007,  -9.281,  -99.988,  88 },
    [xi.zone.THRONE_ROOM]          = {  114.308,  -7.639,    0.022, 126 },
    [xi.zone.STELLAR_FULCRUM]      = { -519.000,   1.000,  -33.000, 193 },
    [xi.zone.THE_CELESTIAL_NEXUS]  = { -697.114,  -6.656,  -32.351,   0 },
    [xi.zone.LALOFF_AMPHITHEATER]  = {  189.849,-176.455,  346.531, 244 },
}

-- Fights whose gem this player is currently carrying.
local function heldFightKeys(player)
    local out = {}
    for gem in pairs(catalog.gemPrice) do
        if player:hasKeyItem(gem) then
            for key, f in pairs(catalog.fights) do
                if f.gem == gem then
                    out[#out + 1] = key
                end
            end
        end
    end
    return out
end

-- Snap the player onto the exact entrance NPC once they've finished zoning in.
-- Retries a few times because a cross-zone warp takes a moment to complete.
local function snapToEntrance(player, zoneId, entryNpc, rot, tries)
    if player:getZoneID() ~= zoneId then
        if tries > 0 then
            player:timer(2000, function(p) snapToEntrance(p, zoneId, entryNpc, rot, tries - 1) end)
        end
        return
    end
    local ok, npcs = pcall(function() return player:getZone():queryEntitiesByName(entryNpc) end)
    if ok and npcs and npcs[1] then
        local npc = npcs[1]
        pcall(function()
            player:setPos(npc:getXPos(), npc:getYPos(), npc:getZPos(), rot, zoneId)
        end)
    end
end

local function warpToFight(player, fightKey)
    local f = catalog.fights[fightKey]
    if not f then
        player:printToPlayer('[HTBF] Unknown fight.', SYS)
        return
    end

    local entry = ZONE_ENTRY[f.zone]
    if not entry then
        player:printToPlayer('[HTBF] No warp point is configured for that battlefield yet.', SYS)
        return
    end

    local entryNpc = f.entryNpc or (f.entryNpcs and f.entryNpcs[1])

    player:printToPlayer(string.format('[HTBF] Warping to the %s entrance...', f.label or fightKey), SYS)
    player:setPos(entry[1], entry[2], entry[3], entry[4], f.zone)

    -- Refine to the exact burning-circle NPC after the zone finishes loading.
    if entryNpc then
        player:timer(2500, function(p) snapToEntrance(p, f.zone, entryNpc, entry[4], 3) end)
    end
end

commandObj.onTrigger = function(player)
    local keys = heldFightKeys(player)

    if #keys == 0 then
        player:printToPlayer('[HTBF] You are not holding a Phantom Gem. Buy one from the HTBF Vendor at !hub first.', SYS)
        return
    end

    if #keys == 1 then
        warpToFight(player, keys[1])
        return
    end

    -- Several candidate fights (the Avatar gem opens all 6 elemental trials, or
    -- you're carrying more than one gem). Let the player pick which entrance.
    -- customMenu caps: 8 options and ~150 bytes of title+labels -- keep 7 fights
    -- + Cancel; the Avatar gem yields exactly 6, so it always fits.
    local options = {}
    for _, key in ipairs(keys) do
        local f           = catalog.fights[key]
        local capturedKey = key
        table.insert(options, { f.label or key, function(p) warpToFight(p, capturedKey) end })
        if #options >= 7 then
            break
        end
    end
    table.insert(options, { 'Cancel', function(p) end })

    player:customMenu({ title = 'HTBF Warp', options = options })
end

return commandObj
