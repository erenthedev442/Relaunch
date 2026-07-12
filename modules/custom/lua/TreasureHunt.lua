-----------------------------------
-- TreasureHunt.lua
-- TREASURE HUNTING: Hunting League kills can drop a treasure map that
-- points at a classic overworld zone. Travel there and !dig - the
-- first dig anchors the strongbox within a ring of where you stand
-- (always reachable ground), then temperature + compass feedback
-- guides every following dig until you unearth it. Payout: marks,
-- gil, and real augment catalysts (drawn from the same pool mobs
-- drop), so the world tour feeds the augment economy.
--
-- State is pure CharVars (no entities, no sessions):
--   TH_Active   1 while a map is held
--   TH_MapTier  1..3 (payout quality)
--   TH_ZoneId   target zone
--   TH_TX/TH_TZ strongbox coords x10 (0 until the first dig seeds it)
--   TH_LastDig  os.time() of last dig (cooldown)
--   TH_Found    lifetime strongboxes (leaderboard / achievements)
--
-- Integration: HuntingLeague.lua lazy-requires this module after each
-- HL kill -> m.onHuntKill(player, tier). The !dig command calls
-- m.onDig(player).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/npc_util')
local catalog = require('modules/custom/lua/treasure_catalog')

local m = Module:new('treasure_hunt')

-- Catalyst pool: every key of the augment catalog is a catalyst item
-- id (the same items mobs drop for the Augment Moogle).
local catalystPool = {}
do
    local ok, augCat = pcall(require, 'modules/custom/lua/augment_catalog')
    if ok and type(augCat) == 'table' then
        for itemId in pairs(augCat) do
            catalystPool[#catalystPool + 1] = itemId
        end
        table.sort(catalystPool)
    end
end

local function zoneEntry(zoneId)
    for _, z in ipairs(catalog.zones) do
        if z.id == zoneId then return z end
    end
    return nil
end

-----------------------------------
-- Map drop hook - called (guarded) from HuntingLeague.lua after every
-- HL kill, with the NM's tier.
-----------------------------------
m.onHuntKill = function(player, killTier)
    if (player:getCharVar('TH_Active') or 0) == 1 then return end

    local chance = catalog.drop.basePct + catalog.drop.perTierPct * (killTier or 1)
    if math.random(100) > chance then return end

    local mapTier = catalog.mapTierForKillTier[math.max(1, math.min(killTier or 1, 5))] or 1
    local target  = catalog.zones[math.random(#catalog.zones)]

    player:setCharVar('TH_Active', 1)
    player:setCharVar('TH_MapTier', mapTier)
    player:setCharVar('TH_ZoneId', target.id)
    player:setCharVar('TH_TX', 0)
    player:setCharVar('TH_TZ', 0)
    player:setCharVar('TH_LastDig', 0)

    player:printToPlayer(string.format(
        '[Treasure] A %s tumbles from the carcass! It marks a spot in %s. Travel there and use !dig to begin the search.',
        catalog.mapNames[mapTier] or 'Treasure Map', target.label),
        xi.msg.channel.SYSTEM_3)
end

-----------------------------------
-- Compass flavor for the feedback line. Convention: +Z = north,
-- +X = east. If a live run shows the compass reading mirrored, flip
-- the signs here - the hot/cold bands are direction-agnostic.
-----------------------------------
local function compass(dx, dz)
    local parts = {}
    if dz > 5 then parts[#parts + 1] = 'north'
    elseif dz < -5 then parts[#parts + 1] = 'south' end
    if dx > 5 then parts[#parts + 1] = 'east'
    elseif dx < -5 then parts[#parts + 1] = 'west' end
    if #parts == 0 then return 'right around here' end
    return 'to the ' .. table.concat(parts, '-')
end

-----------------------------------
-- Navmesh probes. GetFurthestValidPosition(entity, dist, theta) walks
-- the zone navmesh from the entity toward a point `dist` away and
-- returns the furthest reachable ground {x,y,z} (nil on failure), but
-- its theta is relative to the entity's facing: nearPosition() places
-- the point at world bearing 2*pi - (rotationToRadian(rot) + theta).
-- worldTheta() inverts that so a probe can aim at an absolute bearing
-- (atan2(dz, dx) convention) regardless of where the player is looking.
-----------------------------------
local atan2 = math.atan2 or math.atan

local function worldTheta(player, bearing)
    local rotRad = (player:getRotPos() / 256) * 2 * math.pi
    return 2 * math.pi - bearing - rotRad
end

local function reachablePoint(player, bearing, dist)
    local ok, pos = pcall(GetFurthestValidPosition, player, dist, worldTheta(player, bearing))
    if ok and type(pos) == 'table' and pos.x ~= nil then
        return pos
    end
    return nil
end

-----------------------------------
-- The strongbox payout.
-----------------------------------
local function openStrongbox(player, mapTier)
    local loot = catalog.loot[mapTier] or catalog.loot[1]

    player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + loot.marks)
    if loot.gil > 0 then
        pcall(function() player:addGil(loot.gil) end)
    end

    local given, missed = {}, 0
    for _ = 1, loot.catalysts do
        if #catalystPool > 0 then
            local itemId = catalystPool[math.random(#catalystPool)]
            local ok, fit = pcall(function() return npcUtil.giveItem(player, itemId) end)
            if ok and fit then
                given[#given + 1] = itemId
            else
                missed = missed + 1
            end
        end
    end
    if missed > 0 then
        local consolation = missed * catalog.fullInventoryMarks
        player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + consolation)
        player:printToPlayer(string.format(
            '[Treasure] %d catalyst(s) would not fit - converted to +%d marks.',
            missed, consolation), xi.msg.channel.SYSTEM_3)
    end

    local found = (player:getCharVar('TH_Found') or 0) + 1
    player:setCharVar('TH_Found', found)

    player:printToPlayer(string.format(
        '[Treasure] YOU UNEARTH A BURIED STRONGBOX! +%d marks, +%d gil, %d catalyst(s). (Lifetime finds: %d)',
        loot.marks, loot.gil, #given, found),
        xi.msg.channel.SYSTEM_3)

    if loot.announce then
        pcall(function()
            player:printToArea(string.format(
                '[Treasure] %s has unearthed a pristine strongbox in %s!',
                player:getName(),
                (zoneEntry(player:getZoneID()) or { label = 'the wilds' }).label),
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
        end)
    end

    local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
    if okAch and ach and ach.onTreasureFound then
        pcall(function() ach.onTreasureFound(player) end)
    end
    local okWh, wh = pcall(require, 'modules/custom/lua/weekly_hunts')
    if okWh and wh and wh.fire then
        pcall(function() wh.fire(player, 'treasure_found', { tier = mapTier }) end)
    end
end

-----------------------------------
-- !dig handler.
-----------------------------------
m.onDig = function(player)
    if (player:getCharVar('TH_Active') or 0) ~= 1 then
        player:printToPlayer('[Treasure] You have no treasure map. Hunting League NMs sometimes drop them!',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local targetZone = player:getCharVar('TH_ZoneId') or 0
    if player:getZoneID() ~= targetZone then
        local z = zoneEntry(targetZone)
        player:printToPlayer(string.format(
            '[Treasure] The map points to %s. Dig there.',
            z and z.label or ('zone #' .. targetZone)),
            xi.msg.channel.SYSTEM_3)
        return
    end

    local now  = os.time()
    local last = player:getCharVar('TH_LastDig') or 0
    if now - last < catalog.dig.cooldownSec then
        player:printToPlayer('[Treasure] Still catching your breath from the last dig...',
            xi.msg.channel.SYSTEM_3)
        return
    end
    player:setCharVar('TH_LastDig', now)

    local px, pz = player:getXPos(), player:getZPos()
    local tx = (player:getCharVar('TH_TX') or 0) / 10.0
    local tz = (player:getCharVar('TH_TZ') or 0) / 10.0

    -- First dig in the right zone seeds the strongbox in a ring around
    -- the player. Each candidate is walked along the navmesh from the
    -- player outward, so the box can never end up inside a wall, over
    -- a ledge, or out in the sea - only on ground the digger can reach.
    if tx == 0 and tz == 0 then
        local best, bestDist = nil, -1
        for _ = 1, catalog.dig.seedTries do
            local bearing = math.random() * math.pi * 2
            local want    = catalog.dig.seedRingMin
                + math.random() * (catalog.dig.seedRingMax - catalog.dig.seedRingMin)
            local pos = reachablePoint(player, bearing, want)
            if pos then
                local ddx, ddz = pos.x - px, pos.z - pz
                local d = math.sqrt(ddx * ddx + ddz * ddz)
                if d > bestDist then
                    best, bestDist = pos, d
                end
                if d >= catalog.dig.seedRingMin then break end
            end
        end
        -- Every probe failed (no navmesh?): bury it underfoot rather
        -- than risk an unreachable spot.
        tx = best and best.x or px
        tz = best and best.z or pz
        player:setCharVar('TH_TX', math.floor(tx * 10))
        player:setCharVar('TH_TZ', math.floor(tz * 10))
        player:printToPlayer(
            '[Treasure] Your shovel strikes dirt... nothing. But the map begins to glow - the mark is NEAR. Keep digging; it will tell you hot or cold.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local dx, dz = tx - px, tz - pz
    local dist = math.sqrt(dx * dx + dz * dz)

    -- Reachability self-heal: in the hottest band, verify the ground
    -- straight toward the box can actually be walked to within
    -- successRadius. If not (box seeded before the navmesh fix, or a
    -- terrain quirk), slide the box back to the furthest ground the
    -- digger CAN reach so no map is ever impossible to finish.
    if dist > catalog.dig.successRadius and dist <= catalog.dig.healBand then
        local pos = reachablePoint(player, atan2(dz, dx), dist)
        if pos then
            local gx, gz = tx - pos.x, tz - pos.z
            if math.sqrt(gx * gx + gz * gz) > catalog.dig.successRadius then
                tx, tz = pos.x, pos.z
                player:setCharVar('TH_TX', math.floor(tx * 10))
                player:setCharVar('TH_TZ', math.floor(tz * 10))
                dx, dz = tx - px, tz - pz
                dist = math.sqrt(dx * dx + dz * dz)
                player:printToPlayer(
                    '[Treasure] The earth here is impenetrable... the pull shudders and settles into softer ground nearby.',
                    xi.msg.channel.SYSTEM_3)
            end
        end
    end

    if dist <= catalog.dig.successRadius then
        local mapTier = player:getCharVar('TH_MapTier') or 1
        -- Clear the map BEFORE paying out (a payout error must not
        -- leave a re-diggable infinite chest).
        player:setCharVar('TH_Active', 0)
        player:setCharVar('TH_MapTier', 0)
        player:setCharVar('TH_ZoneId', 0)
        player:setCharVar('TH_TX', 0)
        player:setCharVar('TH_TZ', 0)
        openStrongbox(player, mapTier)
        return
    end

    for _, band in ipairs(catalog.dig.bands) do
        if dist <= band.dist then
            player:printToPlayer(string.format(
                '[Treasure] You dig... nothing here. %s (The pull feels strongest %s.)',
                band.text, compass(dx, dz)),
                xi.msg.channel.SYSTEM_3)
            return
        end
    end
end

return m
