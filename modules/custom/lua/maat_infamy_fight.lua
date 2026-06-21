-----------------------------------
-- maat_infamy_fight.lua
-- Custom level-250 Maat challenge.
--
-- Entry NPC: Ru'Lude Gardens (zone 243), near the original Maat NPC.
-- Fight arena: Waughroon Shrine (zone 144), the BCNM zone retail Maat
-- fights actually take place in.
--
-- Flow:
--   1. Player talks to "Maat's Echo" NPC in Ru'Lude Gardens.
--   2. Cost: 50 Infamy. One fight active zone-wide at a time.
--   3. Player is teleported to Waughroon Shrine; Maat spawns on zone-in.
--   4. On Maat's death: 25% chance to receive Maat's Blessing (item 29000).
--   5. Maat's Blessing guarantees a critical augment at the Augment Moogle
--      and is consumed on that successful augment.
--
-- SQL pre-req: sql/zz_maat_crit_token.sql must be applied to the DB.
-- Deploys: Lua hot-reload for NPC and onZoneIn; map restart required for
-- the new module file to register (one-time).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
require('scripts/zones/Waughroon_Shrine/Zone')

local m = Module:new('maat_infamy_fight')

local INFAMY_COST   = 50
local CRIT_TOKEN_ID = 29000
local DROP_CHANCE   = 0.25

-- Maat_rdm (groupId=12, zone=144) — the classic Chainspell-nuke version.
-- All three Maat groups in zone 144 share the same model; this one is used
-- as the spawn template. Level is overridden to MAAT_LEVEL by min/maxLevel.
local MAAT_GROUP_ID  = 12
local MAAT_GROUP_ZID = 144
local MAAT_LEVEL     = 250

-- Waughroon Shrine default zone-in point (matches Zone.lua onZoneIn default).
local SHRINE_ENTRY_X =  -361.434
local SHRINE_ENTRY_Y =   101.798
local SHRINE_ENTRY_Z =  -259.996
local SHRINE_ENTRY_R =     0

-- Maat spawn: a few units forward from the player's landing spot.
local MAAT_X = -361.0
local MAAT_Y =  101.798
local MAAT_Z = -252.0
local MAAT_R =   128   -- facing toward entry

-- NPC position: alongside Maat's original retail NPC in Ru'Lude Gardens.
-- Retail Maat is at x=8, y=3, z=118. Place the Echo a step to the side.
local NPC_X, NPC_Y, NPC_Z, NPC_ROT = 12.0, 3.0, 118.0, 200

-- Module-level ref to the active fight mob.
-- Cleared in onMobDeath; prevents double-spawning while a fight is running.
local activeMaat = nil

local function isAlive(entity)
    if entity == nil then return false end
    local ok, hp = pcall(function() return entity:getHP() end)
    return ok and hp > 0
end

local function spawnMaat(player)
    local zone = player:getZone()

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = MAAT_GROUP_ID,
        groupZoneId          = MAAT_GROUP_ZID,
        name                 = 'Maat',
        x                    = MAAT_X,
        y                    = MAAT_Y,
        z                    = MAAT_Z,
        rotation             = MAAT_R,
        minLevel             = MAAT_LEVEL,
        maxLevel             = MAAT_LEVEL,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            activeMaat = nil

            if killer and killer:isPC() then
                if math.random() < DROP_CHANCE then
                    local added = killer:addItem(CRIT_TOKEN_ID, 1)
                    if added then
                        killer:printToPlayer(
                            "Maat relinquishes a Maat's Blessing! Bring it to the Augment Moogle for a guaranteed critical augment.",
                            xi.msg.channel.SYSTEM_3)
                    else
                        killer:printToPlayer(
                            "Maat dropped a Maat's Blessing, but your inventory is full!",
                            xi.msg.channel.SYSTEM_3)
                    end
                end
            end
        end,
    })

    if not mob then
        player:printToPlayer('[Maat] The echo could not manifest in the shrine. Try again.',
            xi.msg.channel.SYSTEM_3)
        return false
    end

    activeMaat = mob
    mob:setSpawn(MAAT_X, MAAT_Y, MAAT_Z, MAAT_R)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    return true
end

-----------------------------------
-- Ru'Lude Gardens: spawn the challenge NPC near retail Maat.
-----------------------------------
m:addOverride('xi.zones.RuLude_Gardens.Zone.onInitialize', function(zone)
    super(zone)

    local MaatEcho = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Maat_Echo',
        packetName = string.format("%sMaat's Echo", xi.icon.STAR_LARGE),
        look       = 2401,  -- 2428 was not a valid model id -> NPC inserted but invisible. 2401 is a proven-visible model (same one JobRebirth uses in this very zone).
        x          = NPC_X,
        y          = NPC_Y,
        z          = NPC_Z,
        rotation   = NPC_ROT,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:timer(50, function(p)
                local infamy = p:getCharVar('Infamy') or 0

                if isAlive(activeMaat) then
                    p:printToPlayer(
                        '[Maat] A challenger already faces Maat in the shrine. Wait for the battle to conclude.',
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                if infamy < INFAMY_COST then
                    p:printToPlayer(
                        string.format("[Maat] Entering Maat's arena costs %d Infamy. You have %d.",
                            INFAMY_COST, infamy),
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                -- Deduct Infamy first; mark the pending fight so onZoneIn knows
                -- to spawn Maat when the player lands in Waughroon Shrine.
                p:setCharVar('Infamy', infamy - INFAMY_COST)
                p:setCharVar('MaatFight_Pending', 1)

                p:printToPlayer(
                    string.format('[Maat] %d Infamy paid. Prove your worth in the shrine!',
                        INFAMY_COST),
                    xi.msg.channel.SYSTEM_3)

                -- Teleport to Waughroon Shrine (zone 144).
                p:setPos(SHRINE_ENTRY_X, SHRINE_ENTRY_Y, SHRINE_ENTRY_Z, SHRINE_ENTRY_R, 144)
            end)
        end,
    })
    utils.unused(MaatEcho)
end)

-----------------------------------
-- Waughroon Shrine: spawn Maat when a challenger zones in.
-----------------------------------
m:addOverride('xi.zones.Waughroon_Shrine.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)

    if player:getCharVar('MaatFight_Pending') == 1 then
        player:setCharVar('MaatFight_Pending', 0)
        -- Small delay so the player finishes loading before aggro can trigger.
        player:timer(1000, function(p)
            spawnMaat(p)
            p:printToPlayer('[Maat] The echo of Maat stirs. Your legend will be forged here!',
                xi.msg.channel.SYSTEM_3)
        end)
    end

    return cs
end)

return m
