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
--   2. Cost: 150 Infamy.
--   3. Player is teleported to Waughroon Shrine; their OWN Maat spawns FAR
--      across the floor, claim-locked but PASSIVE, and only engages once they
--      walk within ~15 yalms -- so you load in safely instead of dying on the
--      zone-in tile. MANY players can fight at once; each gets a private,
--      claim-locked Maat, the way Voidspire / Colosseum isolate per-player mobs.
--   4. On Maat's death: 25% chance to receive Maat's Blessing (item 29000).
--   5. Maat's Blessing guarantees a critical augment at the Augment Moogle
--      and is consumed on that successful augment.
--
-- SQL pre-req: sql/zz_maat_crit_token.sql must be applied to the DB.
-- Deploys: pure Lua. Edits to the NPC / onZoneIn / spawn logic hot-reload on a
-- Lua sync; only the very first registration of this module file needed a
-- restart (long since done).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
require('scripts/zones/Waughroon_Shrine/Zone')

local m = Module:new('maat_infamy_fight')

local INFAMY_COST   = 150
local CRIT_TOKEN_ID = 29000
local DROP_CHANCE   = 0.25

-- Maat_rdm (groupId=12, zone=144) - the classic Chainspell-nuke version.
-- All three Maat groups in zone 144 share the same model; this one is used
-- as the spawn template. Level is overridden to MAAT_LEVEL by min/maxLevel.
local MAAT_GROUP_ID  = 12
local MAAT_GROUP_ZID = 144
local MAAT_LEVEL     = 250

-- "Damn hard" Lv250 stat block. Level alone does NOT make a fight: LSB's stat
-- tables top out near 99, so a raw Lv250 mob is actually a pushover. Like every
-- other endgame encounter here (Prestige, Abyssea, the Test Dummy) we apply an
-- explicit profile AFTER spawn(). Tuned a notch ABOVE the toughest Prestige
-- apex (World's End / Provenance Watcher, Lv150) -- Maat is the single hardest
-- fight on the server. HP is the main difficulty dial; tune after a playtest.
local MAAT_HP   = 15000000   -- 15M
local MAAT_MODS =
{
    [xi.mod.DEF]           = 9000,    -- mitigates your physical damage
    [xi.mod.ATT]           = 50000,   -- hits hard even through tank DEF
    [xi.mod.ACC]           = 11000,   -- rarely whiffs, even vs high-EVA tanks
    [xi.mod.EVASION]       = 2800,    -- your melee misses a lot
    [xi.mod.MATT]          = 5000,    -- Chainspell nukes HURT
    [xi.mod.MACC]          = 5200,    -- nukes / debuffs land
    [xi.mod.MEVA]          = 3800,    -- your spells resist
    [xi.mod.MDEF]          = 3800,    -- mitigates your magic damage
    [xi.mod.STR]           = 1200,
    [xi.mod.INT]           = 1200,    -- feeds his nuke damage
    [xi.mod.DOUBLE_ATTACK] = 45,
    [xi.mod.TRIPLE_ATTACK] = 24,
    [xi.mod.HASTE_GEAR]    = 500,     -- clamps to the 25% gear-haste cap
    [xi.mod.REGEN]         = 3000,    -- soft DPS check: out-damage it or stall
}

-- Per-fight tick: holds Maat passive until the challenger approaches within
-- ENGAGE_DIST, then engages him; also despawns an abandoned Maat (owner left or
-- died and stayed away ~45s) so it doesn't loiter. Runs once a second.
local TICK_MS    = 1000
local IDLE_LIMIT = 45   -- 45 x 1s = 45s of the owner being absent/dead -> despawn

-- Waughroon Shrine default zone-in point (matches Zone.lua onZoneIn default).
local SHRINE_ENTRY_X =  -361.434
local SHRINE_ENTRY_Y =   101.798
local SHRINE_ENTRY_Z =  -259.996
local SHRINE_ENTRY_R =     0

-- Maat spawns FAR from the challenger's landing tile (SHRINE_ENTRY) and stays
-- PASSIVE until they walk within ENGAGE_DIST yalms -- so you load in safely
-- instead of dying on the zone-in tile. A small random jitter keeps several
-- challengers' (claim-locked, private) Maats from stacking on one model.
-- NOTE: MAAT_SPAWN_* is a best-guess point in the open entry floor; verify it
-- in-game and nudge it if Maat lands in a wall or still spawns too close.
local MAAT_SPAWN_X = -339.434   -- ~22y toward +X (zone interior) from the entry
local MAAT_SPAWN_Y =  101.798
local MAAT_SPAWN_Z = -259.996
local SPAWN_JITTER =    3.0
local ENGAGE_DIST  =   15.0     -- Maat engages once the challenger is this close
local MAAT_R       =  128       -- initial facing (cosmetic; he turns on engage)

-- NPC position: alongside Maat's original retail NPC in Ru'Lude Gardens.
-- Retail Maat is at x=8, y=3, z=118. Place the Echo a step to the side.
local NPC_X, NPC_Y, NPC_Z, NPC_ROT = 12.0, 3.0, 118.0, 200

-- Per-challenger live Maat, keyed by character name. Each player may have at
-- most one fight running; cleared in onMobDeath and on idle-despawn.
local activeFights = {}

local function isAlive(entity)
    if entity == nil then return false end
    local ok, hp = pcall(function() return entity:getHP() end)
    return ok and hp > 0
end

-- Re-arming per-fight tick: (1) engages Maat the moment the challenger gets
-- within ENGAGE_DIST (he holds at his far spawn until then), and (2) despawns an
-- abandoned Maat. mob:timer is dropped automatically when the mob dies, so the
-- chain self-terminates on a real kill; we only stop it on the idle-despawn path.
local function maatTick(mob, ownerName)
    mob:timer(TICK_MS, function(m)
        if not isAlive(m) then return end                 -- killed / despawned

        local owner       = GetPlayerByName(ownerName)
        local ownerActive = owner ~= nil
            and owner:getZoneID() == MAAT_GROUP_ZID
            and owner:getHP() > 0

        -- (1) Proximity engage: stay passive until the owner walks up to him.
        if ownerActive and not m:isEngaged() and m:checkDistance(owner) <= ENGAGE_DIST then
            m:updateClaim(owner)                          -- (re)lock to the owner
            m:addEnmity(owner, 30000, 30000)              -- now he beelines them
        end

        -- (2) Abandon watchdog: only counts while the owner is gone/dead AND Maat
        -- isn't engaged; a present, living owner (loading or approaching) keeps him.
        if m:isEngaged() or ownerActive then
            m:setLocalVar('maatIdle', 0)
        else
            local ticks = (m:getLocalVar('maatIdle') or 0) + 1
            m:setLocalVar('maatIdle', ticks)
            if ticks >= IDLE_LIMIT then
                activeFights[ownerName] = nil
                m:setLocalVar('maatDespawn', 1)           -- onMobDeath: NOT a kill
                m:setHP(0)                                 -- remove the orphaned Maat
                return
            end
        end

        maatTick(m, ownerName)
    end)
end

local function spawnMaat(player)
    local ownerName = player:getName()
    local zone      = player:getZone()

    -- Fixed FAR spawn (MAAT_SPAWN_*) + small jitter; NOT relative to the player,
    -- who always lands on the same SHRINE_ENTRY tile -- this keeps Maat well away
    -- on spawn so you load in before anything can touch you.
    local sx = MAAT_SPAWN_X + (math.random() * 2 - 1) * SPAWN_JITTER
    local sy = MAAT_SPAWN_Y
    local sz = MAAT_SPAWN_Z + (math.random() * 2 - 1) * SPAWN_JITTER

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = MAAT_GROUP_ID,
        groupZoneId          = MAAT_GROUP_ZID,
        name                 = 'Maat',
        x                    = sx,
        y                    = sy,
        z                    = sz,
        rotation             = MAAT_R,
        minLevel             = MAAT_LEVEL,
        maxLevel             = MAAT_LEVEL,
        detection            = 0,            -- no auto-aggro; engages on approach (maatTick)
        isAggroable          = false,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            activeFights[ownerName] = nil

            -- The idle watchdog removes an abandoned Maat via setHP(0); that is
            -- NOT a kill, so don't hand out a reward for it.
            if deadMob:getLocalVar('maatDespawn') == 1 then
                return
            end

            -- Reward the OWNER. The Maat is claim-locked to them so they are the
            -- only one who could have killed it, but resolve by name so a trust
            -- or pet landing the final blow still credits the player.
            local owner = GetPlayerByName(ownerName)
            if not owner then return end

            if math.random() < DROP_CHANCE then
                if owner:addItem(CRIT_TOKEN_ID, 1) then
                    owner:printToPlayer(
                        "Maat relinquishes a Maat's Blessing! Bring it to the Augment Moogle for a guaranteed critical augment.",
                        xi.msg.channel.SYSTEM_3)
                else
                    owner:printToPlayer(
                        "Maat dropped a Maat's Blessing, but you couldn't carry it (inventory full, or you already hold one).",
                        xi.msg.channel.SYSTEM_3)
                end
            end

            -- Prime Weapon TRIAL 3: a Prime Voucher (item 29699) drops 0.5%
            -- from the Maat fight, on top of the Hunting League source. Gated
            -- on PW_Trial3_Done so it stops once Trial 3 is cleared; the reward
            -- helper prints its own message + handles a full inventory.
            if (owner:getCharVar('PW_Trial3_Done') or 0) == 0 and math.random() < 0.005 then
                pcall(function()
                    require('modules/custom/lua/prime_voucher_reward').award(owner, 1, 'Maat')
                end)
            end
        end,
    })

    if not mob then
        player:printToPlayer('[Maat] The echo could not manifest in the shrine. Try again.',
            xi.msg.channel.SYSTEM_3)
        return false
    end

    activeFights[ownerName] = mob
    mob:setSpawn(sx, sy, sz, MAAT_R)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)

    -- Apply the tuned Lv250 profile AFTER spawn() -- spawn() recomputes stats
    -- from the mob pool and would wipe anything set earlier (same ordering the
    -- Test Dummy and Prestige bosses use). Offense + defense first, then HP.
    for mod, val in pairs(MAAT_MODS) do
        mob:addMod(mod, val)
    end
    mob:setMaxHP(MAAT_HP)
    mob:setHP(MAAT_HP)
    mob:setAggressive(false)   -- stays passive until the challenger approaches

    -- Claim-lock this Maat to its challenger (so no one else can tag or steal it)
    -- but DO NOT give it enmity yet -- it holds at its far spawn until the owner
    -- walks within ENGAGE_DIST (handled by maatTick). THIS is the fix for "spawns
    -- on top of us and kills us before the screen loads". Per-player isolation as
    -- in Voidspire.
    mob:updateClaim(player)

    -- Start the per-fight tick (proximity-engage + abandon-despawn).
    mob:setLocalVar('maatIdle', 0)
    maatTick(mob, ownerName)

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
        look       = 126,   -- Maat's actual model. Retail Maat (npc_list 17772593, zone 243) is size=0/modelid=126; insertDynamicEntity look=N -> SetModelId(N), so this renders the real Maat. (Original 2428 was an invalid model id -> NPC inserted but invisible.)
        x          = NPC_X,
        y          = NPC_Y,
        z          = NPC_Z,
        rotation   = NPC_ROT,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:timer(50, function(p)
                local infamy = p:getCharVar('Infamy') or 0

                -- Per-challenger gate: one live Maat each (no server-wide lock).
                if isAlive(activeFights[p:getName()]) then
                    p:printToPlayer(
                        '[Maat] Your echo of Maat still stands in the shrine. Finish that fight first.',
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
                -- to spawn this challenger's Maat when they land in the shrine.
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
-- Waughroon Shrine: spawn this challenger's own Maat when they zone in.
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
