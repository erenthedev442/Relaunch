-----------------------------------
-- maat_infamy_fight.lua
-- Custom level-250 Maat challenge at GM_Home.
--
-- Entry cost: 50 Infamy (charVar 'Infamy').
-- Maat spawns at level 250 (full stats scaled by engine).
-- On death: 25% chance to drop Maat's Blessing (item 29000).
-- Maat's Blessing guarantees a critical augment at the Augment Moogle
-- and is consumed on successful augment.
--
-- One fight active at a time per zone (module-level entity ref).
-- SQL pre-req: sql/zz_maat_crit_token.sql must be applied to the DB.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')

local m = Module:new('maat_infamy_fight')

local INFAMY_COST      = 50
local CRIT_TOKEN_ID    = 29000
local DROP_CHANCE      = 0.25
local MAAT_GROUP_ID    = 63    -- Maat_war entry (mob_groups.sql row, mobId=6823)
local MAAT_ZONE_ID     = 80    -- groupZoneId that row lives in
local MAAT_LEVEL       = 250
-- Spawn point for the fight: north end of the vendor plaza, open floor.
local MAAT_X, MAAT_Y, MAAT_Z = 0.0, 0.0, 15.0
-- NPC position: a free spot in the vendor area (z=-25 row, centre column).
local NPC_X, NPC_Y, NPC_Z, NPC_ROT = 0.0, 0.0, -25.0, 0

-- Module-level ref to the active Maat entity.
-- Cleared in onMobDeath. Guards against double-spawning while Maat is alive.
local activeMaat = nil

local function isAlive(entity)
    if entity == nil then return false end
    -- pcall guards against a dangling pointer if the entity was freed
    local ok, hp = pcall(function() return entity:getHP() end)
    return ok and hp > 0
end

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local MaatEcho = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Maat_Echo',
        packetName = string.format('%sChampion', xi.icon.STAR_LARGE),
        look       = 2428,  -- humanoid elder look
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
                        '[Champion\'s Echo] A battle already rages. Wait for it to end.',
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                if infamy < INFAMY_COST then
                    p:printToPlayer(
                        string.format('[Champion\'s Echo] Challenging me costs %d Infamy. You have %d.',
                            INFAMY_COST, infamy),
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                -- Deduct Infamy and spawn Maat.
                p:setCharVar('Infamy', infamy - INFAMY_COST)

                local mz = p:getZone()
                local mob = mz:insertDynamicEntity({
                    objtype              = xi.objType.MOB,
                    groupId              = MAAT_GROUP_ID,
                    groupZoneId          = MAAT_ZONE_ID,
                    name                 = 'Maat',
                    x                    = MAAT_X,
                    y                    = MAAT_Y,
                    z                    = MAAT_Z,
                    rotation             = 128,
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
                                        'Maat yields a Maat\'s Blessing! Take it to the Augment Moogle for a guaranteed critical augment.',
                                        xi.msg.channel.SYSTEM_3)
                                else
                                    killer:printToPlayer(
                                        'Maat would have dropped a Maat\'s Blessing, but your inventory is full!',
                                        xi.msg.channel.SYSTEM_3)
                                end
                            end
                        end
                    end,
                })

                if not mob then
                    -- Refund on spawn failure.
                    p:setCharVar('Infamy', infamy)
                    p:printToPlayer('[Champion\'s Echo] The echo could not manifest. Try again.',
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                activeMaat = mob
                mob:setSpawn(MAAT_X, MAAT_Y, MAAT_Z, 128)
                mob:spawn()
                mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)

                p:printToPlayer(
                    string.format('[Champion\'s Echo] %d Infamy spent. Maat awaits — prove yourself!',
                        INFAMY_COST),
                    xi.msg.channel.SYSTEM_3)
            end)
        end,
    })
    utils.unused(MaatEcho)
end)

return m
