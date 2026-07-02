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
--      across the floor, claim-locked but PASSIVE -- he holds his far spawn with
--      no enmity, so you load in safely. He then engages AND CHASES the moment you
--      provoke him: either land a hit (damage enmity) or walk within ~15 yalms
--      (maatTick). MANY players can fight at once; each gets a private, claim-locked
--      Maat, the way Voidspire / Colosseum isolate per-player mobs.
--   4. On Maat's death: 25% chance to receive Maat's Cap (item 15194 -- a
--      retail Rare/EX item, so it renders correctly on the client).
--   5. Maat's Cap guarantees a critical augment at the Augment Moogle
--      and is consumed on that successful augment.
--   6. The FIRST win (Maat_Kills >= 1) permanently unlocks Tier 5 (Archon)
--      augment catalysts at the Augment Moogle -- Sage rank 5 alone is no
--      longer enough (gate lives in Augment_Moogle.lua).
--
-- SQL pre-req: sql/zz_maat_crit_token.sql must be applied to the DB.
-- Deploys: pure Lua. Edits to the NPC / onZoneIn / spawn logic hot-reload on a
-- Lua sync; only the very first registration of this module file needed a
-- restart (long since done).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
require('scripts/zones/Waughroon_Shrine/Zone')

local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m = Module:new('maat_infamy_fight')

-- Hardcore mechanics config for the Maat duel.
-- 1v1 duel identity: no adds (thematically wrong for a solo skill-check).
-- Pillars: stance dance (his melee vs Chainspell phases), AoE shockwave,
-- CC terror, lifedrain regen pressure, tight 2.5-min enrage, low-HP doom.
local MAAT_MECH_CFG = {
    name    = 'Maat',

    -- 2.5-min DPS check. If you can't kill a 12M-HP boss in 150s you die.
    enrage  = {
        sec   = 150,
        att   = 5000,
        haste = 200,
        msg   = "You haven't proven yourself yet. Witness TRUE power!",
    },

    -- Stance dance: alternates between physical-resist (magic window) and
    -- magic-resist (melee window). DMGPHYS/DMGMAGIC capped at -5000 (=-50%).
    -- Starts immediately (startHpp=100) and swaps every 18s.
    stance  = {
        startHpp  = 100,
        periodSec = 18,
        stances   = {
            {
                mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },
                msg  = 'Maat fortifies his body against weapons -- unleash your magic!',
            },
            {
                mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -5000 },
                msg  = 'Maat channels Chainspell -- steel cuts deeper than spells now!',
            },
        },
    },

    -- AoE shockwave every 14s: 20% of each nearby player's max HP.
    aoe     = {
        periodSec = 14,
        dmgPct    = 20,
        msg       = 'Maat releases a burst of concentrated aura!',
    },

    -- Terror CC every 25s: briefly locks out all actions (5s window).
    cc      = {
        periodSec = 25,
        effect    = xi.effect.TERROR,
        power     = 1,
        dur       = 5,
        msg       = "Maat's presence overwhelms you!",
    },

    -- Lifedrain every 9s: heals 2% max HP -- out-damage this or stall forever.
    drain   = {
        periodSec = 9,
        healPct   = 2,
    },

    -- HP phases: escalating pressure as the duel progresses.
    phases  = {
        { hp = 50, action = 'fury',   att = 3000, haste = 120,
          msg = 'Maat cries out -- his speed and power surge!' },
        { hp = 25, action = 'nuke',   dmgPct = 38,
          msg = 'Maat unleashes Chainspell -- brace yourself!' },
        { hp = 15, action = 'dispel', count = 3,
          msg = 'Maat tears your enhancements away!' },
    },

    -- Doom at 12% HP: the final execution window (25s to finish him).
    doom    = {
        startHpp = 12,
        dur      = 25,
        msg      = 'Maat marks you for oblivion -- end this NOW!',
    },
}

local INFAMY_COST   = 150
local CRIT_TOKEN_ID = 15194  -- Maat's Cap (retail Rare/EX; renders on the client, unlike the old custom 29000)
local DROP_CHANCE   = 0.25

-- Maat_rdm (groupId=12, zone=144) - the classic Chainspell-nuke version.
-- All three Maat groups in zone 144 share the same model; this one is used
-- as the spawn template. Level is overridden to MAAT_LEVEL by min/maxLevel.
local MAAT_GROUP_ID  = 12
local MAAT_GROUP_ZID = 144
local MAAT_LEVEL     = 200

-- "Lv200-equivalent" stat block. Level alone does NOT make a fight: LSB's stat
-- tables top out near 99, so the raw level is cosmetic -- this profile is the
-- real difficulty. Like every other endgame encounter here (Prestige, Abyssea,
-- the Test Dummy) we apply it AFTER spawn(). Scaled down ~20% from the old Lv250
-- profile to a Lv200 target -- still a hard fight, a clear step easier than
-- before. HP is the main difficulty dial; tune after a playtest.
local MAAT_HP   = 12000000   -- 12M (Lv200 target; ~20% under the old 15M)
local MAAT_MODS =
{
    [xi.mod.DEF]           = 7200,    -- mitigates your physical damage
    [xi.mod.ATT]           = 40000,   -- hits hard even through tank DEF
    [xi.mod.ACC]           = 8800,    -- rarely whiffs, even vs high-EVA tanks
    [xi.mod.EVASION]       = 2250,    -- your melee misses a fair bit
    [xi.mod.MATT]          = 4000,    -- Chainspell nukes HURT
    [xi.mod.MACC]          = 4150,    -- nukes / debuffs land
    [xi.mod.MEVA]          = 3050,    -- your spells resist
    [xi.mod.MDEF]          = 3050,    -- mitigates your magic damage
    [xi.mod.STR]           = 960,
    [xi.mod.INT]           = 960,     -- feeds his nuke damage
    [xi.mod.DOUBLE_ATTACK] = 36,
    [xi.mod.TRIPLE_ATTACK] = 19,
    [xi.mod.HASTE_GEAR]    = 400,     -- clamps to the 25% gear-haste cap
    [xi.mod.REGEN]         = 2400,    -- soft DPS check: out-damage it or stall
}

-- Per-fight tick: holds Maat passive until the challenger approaches within
-- ENGAGE_DIST, then engages him; and despawns him QUICKLY once his owner is dead
-- or gone, so a leftover Maat can't loiter near other challengers. 1s ticks.
local TICK_MS    = 1000
local IDLE_LIMIT = 6   -- 6 x 1s = ~6s after the owner is dead/gone -> despawn

-- Waughroon Shrine default zone-in point (matches Zone.lua onZoneIn default).
local SHRINE_ENTRY_X =  -361.434
local SHRINE_ENTRY_Y =   101.798
local SHRINE_ENTRY_Z =  -259.996
local SHRINE_ENTRY_R =     0

-- Maat spawns FAR from the challenger's landing tile (SHRINE_ENTRY) and stays
-- PASSIVE until they walk within ENGAGE_DIST yalms -- so you load in safely
-- instead of dying on the zone-in tile. A small random jitter keeps several
-- challengers' (claim-locked, private) Maats from stacking on one model.
-- MAAT_SPAWN_* is an owner-confirmed spot on the open entry floor (read off the
-- in-game position display) -- ~27y from the SHRINE_ENTRY landing tile.
local MAAT_SPAWN_X = -334.553
local MAAT_SPAWN_Y =  104.824
local MAAT_SPAWN_Z = -259.501
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
            m:addEnmity(owner, 30000, 30000)              -- engages + chases (damage enmity also engages him on its own)
            -- Start fight timer the first time Maat engages (measures pure fight time).
            if m:getLocalVar('maatStartTime') == 0 then
                m:setLocalVar('maatStartTime', os.time())
            end
        end

        -- (2) Despawn watchdog: keep Maat ONLY while his owner is alive + in the
        -- shrine (loading, approaching, or fighting). The instant the owner is dead
        -- or has left, count down and remove him fast -- even if he's still
        -- "engaged" on the corpse -- so he can't linger and threaten other players.
        if ownerActive then
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

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)
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

            -- Track kill count and best fight time.
            local startTime = deadMob:getLocalVar('maatStartTime')
            local elapsed   = (startTime and startTime > 0) and (os.time() - startTime) or 0
            local kills     = (owner:getCharVar('Maat_Kills') or 0) + 1
            owner:setCharVar('Maat_Kills', kills)

            -- First win unlocks Tier 5 (Archon) catalysts at the Augment Moogle
            -- (the gate reads Maat_Kills -- see Augment_Moogle.lua tier gate).
            if kills == 1 then
                owner:printToPlayer(
                    'Maat acknowledges your mastery! Tier 5 augment catalysts are now unlocked at the Augment Moogle.',
                    xi.msg.channel.SYSTEM_3)
            end
            if elapsed > 0 then
                local best = owner:getCharVar('Maat_Best_Time') or 0
                if best == 0 or elapsed < best then
                    owner:setCharVar('Maat_Best_Time', elapsed)
                end
            end

            if math.random() < DROP_CHANCE then
                if owner:addItem(CRIT_TOKEN_ID, 1) then
                    owner:printToPlayer(
                        "Maat relinquishes his Cap! Bring Maat's Cap to the Augment Moogle for a guaranteed critical augment.",
                        xi.msg.channel.SYSTEM_3)
                else
                    owner:printToPlayer(
                        "Maat offered his Cap, but you couldn't carry it (inventory full, or you already hold one).",
                        xi.msg.channel.SYSTEM_3)
                end
            end

            -- Prime Weapon TRIAL 3: a Prime Voucher (the Maze Monger Crown, item 3038) drops 0.5%
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
    -- Maat CHASES once provoked (NO_MOVE intentionally NOT set): the instant the
    -- challenger lands a hit (damage enmity is automatic) OR walks within
    -- ENGAGE_DIST (maatTick), he engages AND beelines them, like a real duel.
    -- The safe zone-in is preserved WITHOUT rooting him -- he spawns FAR with NO
    -- enmity and passive (setAggressive(false) + detection 0 below), so he just
    -- holds at his far spawn until you provoke him; he can't aggro you on the load
    -- tile. Re-adding NO_MOVE would make him fight in place and never run at you.

    -- Apply the tuned Lv250 profile AFTER spawn() -- spawn() recomputes stats
    -- from the mob pool and would wipe anything set earlier (same ordering the
    -- Test Dummy and Prestige bosses use). Offense + defense first, then HP.
    for mod, val in pairs(MAAT_MODS) do
        mob:addMod(mod, val)
    end
    mob:setMaxHP(MAAT_HP)
    mob:setHP(MAAT_HP)
    mob:setAggressive(false)   -- stays passive until the challenger approaches

    -- Wire hardcore mechanics AFTER all stat/HP setup is complete.
    mechanics.attach(mob, MAAT_MECH_CFG)

    -- Claim-lock this Maat to its challenger (so no one else can tag or steal it)
    -- but DO NOT give it enmity yet -- it holds at its far spawn until the owner
    -- walks within ENGAGE_DIST (handled by maatTick). THIS is the fix for "spawns
    -- on top of us and kills us before the screen loads". Per-player isolation as
    -- in Voidspire.
    mob:updateClaim(player)

    -- Start the per-fight tick (proximity-engage + abandon-despawn).
    mob:setLocalVar('maatIdle', 0)
    mob:setLocalVar('maatStartTime', 0)  -- set to os.time() on first engage in maatTick
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
