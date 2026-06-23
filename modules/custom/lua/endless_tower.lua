-----------------------------------
-- endless_tower.lua
--
-- THE ENDLESS TOWER: a 50-floor solo gauntlet in Walk of Echoes.
-- Floor by floor mob escalation; boss every 10 floors. Reach floor 50,
-- defeat the Pinnacle Sovereign, and earn the Prime Weapon Trial 2
-- completion (charVar PW_Trial2_Done = 1).
--
-- Rules:
--   * Solo only -- Trusts are disabled in this zone (Walk of Echoes MISC_TRUST off).
--   * Death ends the run with no reward and no floor save.
--   * You can abort via !tower abort.
--
-- CharVars:
--   PW_Trial2_Done       1 when floor 50 boss was killed
--   Tower_Best_Floor     personal best floor ever cleared (leaderboard)
--   Tower_Climbs         count of full floor-50 clears (leaderboard)
--
-- Architecture (mirrors Voidspire.lua):
--   * Per-player sessions table; ownerName captured in mob onMobDeath
--     closures so the mob entity reference is never used after its death.
--   * releaseIdOnDisappear = true on every mob so IDs self-reclaim.
--   * mobsAlive reset to {} each floor - NO stale cross-floor refs.
--   * Death hook via xi.player.onPlayerDeath override.
--   * Timer-based floor advance (never re-entrant from mob callback).
--
-- NPC: Endless Tower Arbiter in GM Home (zone 210), z = -35.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Walk_of_Echoes/Zone')
require('scripts/zones/GM_Home/Zone')

local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m = Module:new('endless_tower')

-----------------------------------
-- Constants
-----------------------------------
local TOWER_ZONE_ID  = xi.zone.WALK_OF_ECHOES   -- 182
local GROUP_ZONE_ID  = 210   -- GM Home (where HL mob_groups are registered)
local MAX_FLOOR      = 50
local FLOOR_DELAY_MS = 5000  -- ms between floors (breather)
local WARP_IN        = { x = -420, y = 14, z = -49, rot = 192 }

-- Exit warp: back to GM Home activities area.
local EXIT_WARP = { zoneId = 210, x = -15, y = 0, z = -18, rot = 128 }

-----------------------------------
-- Floor band definitions
-- Trash mobs and their levels/groups per 10-floor band.
-----------------------------------
local BANDS = {
    { maxFloor = 10, level = 120, bossLevel = 135,
      groups = { 11355, 11356, 11357, 11358 },
      bossGroup = 11358, bossHp = 600000,
      names  = { 'Tower Guardian', 'Spire Sentinel', 'Ascendant Watcher' },
      bossName = 'Guardian of the Spire' },
    { maxFloor = 20, level = 155, bossLevel = 170,
      groups = { 11359, 11360, 11361, 11362 },
      bossGroup = 11362, bossHp = 1200000,
      names  = { 'Shadow Hulk', 'Void Sentinel', 'Abyssal Watcher' },
      bossName = 'Shadow of the Abyss' },
    { maxFloor = 30, level = 185, bossLevel = 205,
      groups = { 11362, 11363, 11364, 11365 },
      bossGroup = 11365, bossHp = 2500000,
      names  = { 'Eternal Hulk', 'Timeless Watcher', 'Void Drake' },
      bossName = 'The Eternal Warden' },
    { maxFloor = 40, level = 215, bossLevel = 240,
      groups = { 11364, 11365, 11366, 11367 },
      bossGroup = 11367, bossHp = 4000000,
      names  = { 'Divine Revenant', 'Apex Inquisitor', 'Celestial Hulk' },
      bossName = 'Lord of the Void' },
    { maxFloor = 50, level = 240, bossLevel = 275,
      groups = { 11366, 11367, 11368, 11369 },
      bossGroup = 11369, bossHp = 7000000,
      names  = { 'Pinnacle Revenant', 'Apex Guardian', 'Sovereign Watcher' },
      bossName = 'The Pinnacle Sovereign' },
}

-- Affix pool for boss floors (one random affix applied to the boss).
local BOSS_AFFIXES = {
    { label = 'Fortified',    mods = { [xi.mod.DEF] = 600 },                        hpMult = 1.3  },
    { label = 'Frenzied',     mods = { [xi.mod.HASTE_GEAR] = 150, [xi.mod.DOUBLE_ATTACK] = 10 }, hpMult = 1.0  },
    { label = 'Regenerating', mods = { [xi.mod.REGEN] = 80 },                       hpMult = 1.0  },
    { label = 'Empowered',    mods = { [xi.mod.ATT] = 2500, [xi.mod.STR] = 100 },   hpMult = 1.0  },
    { label = 'Colossal',     mods = {},                                              hpMult = 2.0  },
    { label = 'Furious',      mods = { [xi.mod.ATT] = 3000, [xi.mod.HASTE_GEAR] = 100 }, hpMult = 1.2 },
}

-----------------------------------
-- Per-boss-floor hardcore mechanics configs (mob_mechanics_library.lua).
-- Keyed by floor number (10/20/30/40/50). Scale up with floor depth:
-- early = light; late = punishing. addGroupId reuses this system's own
-- mob_groups rows for the matching band so adds are always valid.
-- DMGPHYS/DMGMAGIC are capped at -5000 by convention (= heavy resist, not
-- immunity). ATT/REGEN are routed through safeAddMod inside the library.
-----------------------------------
local BOSS_MECHANICS = {
    -- Floor 10: "Guardian of the Spire"
    -- Light introduction -- a terror roar and a soft enrage are enough to
    -- teach the player that bosses bite back.
    [10] = {
        name   = 'Guardian of the Spire',
        cc     = { periodSec = 24, effect = xi.effect.TERROR, dur = 4, msg = 'lets out a thunderous roar -- you are frozen in terror!' },
        enrage = { sec = 240, att = 3000, haste = 100, msg = 'grows impatient -- its assault quickens!' },
    },

    -- Floor 20: "Shadow of the Abyss"
    -- Adds a self-heal drain (anti-turtle) and an AoE shockwave.
    [20] = {
        name   = 'Shadow of the Abyss',
        drain  = { periodSec = 9, healPct = 2 },
        aoe    = { periodSec = 14, dmgPct = 20, msg = 'erupts with void energy -- the shockwave tears at you!' },
        cc     = { periodSec = 26, effect = xi.effect.TERROR, dur = 5, msg = 'releases a wave of dread -- you are gripped by terror!' },
        enrage = { sec = 210, att = 4000, haste = 130, msg = 'seethes with shadow -- strikes grow punishing!' },
    },

    -- Floor 30: "The Eternal Warden"
    -- Stance dance forces damage-type switching; fury phase at 50 HP.
    [30] = {
        name   = 'The Eternal Warden',
        stance = {
            startHpp  = 100,
            periodSec = 18,
            stances   = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },    msg = 'hardens its shell against weapons -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards itself from sorcery -- use steel!' },
            },
        },
        drain  = { periodSec = 8, healPct = 2 },
        aoe    = { periodSec = 12, dmgPct = 24, msg = 'unleashes an eternal shockwave -- brace yourself!' },
        enrage = { sec = 190, att = 4500, haste = 150, msg = 'the Warden\'s patience ends -- ruin quickens!' },
        phases = {
            -- 40%: fury burst.
            { hp = 40, action = 'fury', att = 3000, haste = 100,
              msg = 'the Warden surges with eternal power -- its blows grow lethal!' },
        },
    },

    -- Floor 40: "Lord of the Void"
    -- Near-full kit: stance, AoE, CC, drain, dispel, doom at low HP.
    [40] = {
        name   = 'Lord of the Void',
        stance = {
            startHpp  = 100,
            periodSec = 16,
            stances   = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },    msg = 'the Void hardens -- weapons skitter off! Use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'the Void warps magic -- spells unravel! Use weapons!' },
            },
        },
        aoe    = { periodSec = 11, dmgPct = 28, msg = 'the Void expands -- a crushing wave of dark energy!' },
        cc     = { periodSec = 22, effect = xi.effect.TERROR, dur = 6, msg = 'the Lord peers into your soul -- terror takes hold!' },
        drain  = { periodSec = 7, healPct = 3 },
        enrage = { sec = 170, att = 5000, haste = 170, msg = 'the Lord of the Void loses all restraint -- RUN!' },
        phases = {
            -- 50%: dispels your buffs.
            { hp = 50, action = 'dispel', count = 3,
              msg = 'the Void tears your protections away -- buffs stripped!' },
            -- 25%: fury surge.
            { hp = 25, action = 'fury', att = 4000, haste = 120,
              msg = 'the Lord of the Void erupts -- its attacks are devastating!' },
            -- 10%: doom.
            { hp = 10, action = 'doom', dur = 28,
              msg = 'the Void brands you for annihilation!' },
        },
        doom = { startHpp = 12, dur = 30, msg = 'the Lord of the Void marks you for death!' },
    },

    -- Floor 50: "The Pinnacle Sovereign" -- FULL HARDCORE KIT.
    -- Tightest enrage, all mechanics active, doom + execute pressure throughout
    -- the final phase. This is the Trial 2 gate.
    [50] = {
        name   = 'The Pinnacle Sovereign',
        stance = {
            startHpp  = 100,
            periodSec = 14,
            stances   = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },    msg = 'the Sovereign forges an adamantine shell -- weapons are useless! Switch to magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'the Sovereign shrouds itself in runic wards -- magic falters! Switch to weapons!' },
            },
        },
        aoe    = { periodSec = 10, dmgPct = 32, msg = 'the Pinnacle Sovereign unleashes Sovereign\'s Wrath -- everyone near takes grievous damage!' },
        cc     = { periodSec = 20, effect = xi.effect.TERROR, dur = 7, msg = 'the Sovereign\'s gaze pierces your will -- you are paralysed with terror!' },
        drain  = { periodSec = 6, healPct = 3 },
        enrage = { sec = 150, att = 5500, haste = 200, msg = 'the Sovereign has grown tired of you -- its assault becomes overwhelming!' },
        phases = {
            -- 60%: dispel burst.
            { hp = 60, action = 'dispel', count = 4,
              msg = 'the Sovereign shatters your protections -- buffs annihilated!' },
            -- 50%: nuke -- a 45% max-HP AoE execute burst.
            { hp = 50, action = 'nuke', dmgPct = 45,
              msg = 'SOVEREIGN\'S JUDGEMENT -- a cataclysmic burst of power!' },
            -- 25%: fury -- the Sovereign enters its final reckoning.
            { hp = 25, action = 'fury', att = 5000, haste = 150,
              msg = 'the Pinnacle Sovereign enters its final reckoning -- attacks are lethal!' },
            -- 10%: phase enrage + doom for execute pressure.
            { hp = 10, action = 'enrage', att = 8000, haste = 250,
              msg = 'the Sovereign reaches its apex -- all restraint is gone!' },
        },
        doom = { startHpp = 12, dur = 25, msg = 'the Pinnacle Sovereign marks you for oblivion. Finish it!' },
    },
}

-----------------------------------
-- Helpers
-----------------------------------
local function bandFor(floor)
    for _, b in ipairs(BANDS) do
        if floor <= b.maxFloor then return b end
    end
    return BANDS[#BANDS]
end

local function isBossFloor(floor)
    return floor % 10 == 0
end

local function mobCountFor(floor)
    -- 3 on floor 1-10, scaling to 6 by floor 41-50
    local band = math.ceil(floor / 10)
    return 2 + band   -- 3, 4, 5, 6, 7 (cap at 6 for floors 41+)
end

-----------------------------------
-- Sessions
-----------------------------------
local sessions = {}
xi._et_sessions = sessions
local function getSession(player)   return sessions[player:getName()] end
local function clearSession(player) sessions[player:getName()] = nil end

-- forward declarations
local startFloor, endTower, onFloorCleared

-----------------------------------
-- Spawn helpers
-----------------------------------
local function spawnTowerMob(owner, groupId, name, level, hpMult, extraMods)
    local px, py, pz = owner:getXPos(), owner:getYPos(), owner:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = 8 + math.random() * 10
    local mx    = px + math.cos(angle) * dist
    local mz    = pz + math.sin(angle) * dist
    local ownerName = owner:getName()

    local mob = owner:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = groupId,
        groupZoneId          = GROUP_ZONE_ID,
        name                 = name,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = level,
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)   -- free mechanics state + despawn any adds
            -- Allied Notes to the climber for each tower mob cleared, scaled by the
            -- floor's mob level (same curve as allied_notes_drop.lua: floor(lvl/5),
            -- clamped 5..50). Goes to the session owner so the climber is always
            -- rewarded regardless of who/what lands the killing blow.
            local climber = GetPlayerByName(ownerName)
            if climber then
                climber:addCurrency('allied_notes', math.max(5, math.min(50, math.floor(level / 5))))
            end

            local sess = sessions[ownerName]
            if not sess then return end
            sess.mobsAlive[deadMob:getID()] = nil
            -- Any floor mob still alive?
            for _ in pairs(sess.mobsAlive) do return end

            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            onFloorCleared(resolved, sess)
        end,

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    })

    if mob then
        mob:setSpawn(mx, py, mz, 0)
        mob:spawn()
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
        if extraMods then
            for modId, val in pairs(extraMods) do mob:setMod(modId, val) end
        end
        if hpMult and hpMult > 1.0 then
            local newMax = math.floor(mob:getMaxHP() * hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
        mob:addEnmity(owner, 30000, 30000)
    end
    return mob
end

-----------------------------------
-- Floor cleared
-----------------------------------
onFloorCleared = function(player, sess)
    local floor = sess.floor

    -- Update best floor.
    local best = player:getCharVar('Tower_Best_Floor') or 0
    if floor > best then player:setCharVar('Tower_Best_Floor', floor) end

    -- Trial 2: floor 50 boss defeat = done.
    if floor == MAX_FLOOR then
        endTower(player, 'cleared')
        return
    end

    player:printToPlayer(string.format(
        '[Tower] Floor %d cleared! Prepare for floor %d...', floor, floor + 1),
        xi.msg.channel.SYSTEM_3)

    player:timer(FLOOR_DELAY_MS, function(p)
        local s = sessions[p:getName()]
        if not s or s.floor ~= floor then return end
        startFloor(p)
    end)
end

-----------------------------------
-- Start the next floor
-----------------------------------
startFloor = function(player)
    local sess = getSession(player)
    if not sess then return end
    if player:getZoneID() ~= TOWER_ZONE_ID then
        endTower(player, 'left')
        return
    end

    sess.floor     = sess.floor + 1
    local floor    = sess.floor
    sess.mobsAlive = {}

    local band = bandFor(floor)

    if isBossFloor(floor) then
        -- Boss floor: one big mob with a random affix.
        local affix = BOSS_AFFIXES[math.random(#BOSS_AFFIXES)]
        local bossHp = band.bossHp

        player:printToPlayer(string.format(
            '[Tower] FLOOR %d - BOSS: %s  [%s]', floor, band.bossName, affix.label),
            xi.msg.channel.SYSTEM_3)

        local mob = spawnTowerMob(
            player,
            band.bossGroup,
            band.bossName,
            band.bossLevel,
            affix.hpMult,
            affix.mods)

        if mob then
            mob:setModelSize(3)
            mob:setMaxHP(bossHp)
            mob:setHP(bossHp)
            -- Attach floor-specific hardcore mechanics (stance/AoE/drain/doom/
            -- enrage). The config is keyed by boss floor number; early floors get a
            -- light kit, floor 50 gets the full hardcore suite. No-ops on any floor
            -- not in BOSS_MECHANICS (library returns immediately if cfg is nil).
            mechanics.attach(mob, BOSS_MECHANICS[floor])
            sess.mobsAlive[mob:getID()] = mob
        end
    else
        -- Regular floor: trash mobs.
        local count = mobCountFor(floor)
        player:printToPlayer(string.format(
            '[Tower] Floor %d  (Lv%d  x%d mobs)', floor, band.level, count),
            xi.msg.channel.SYSTEM_3)

        for _ = 1, count do
            local groupId = band.groups[math.random(#band.groups)]
            local name    = band.names[math.random(#band.names)]
            local mob     = spawnTowerMob(player, groupId, name, band.level, 1.0, nil)
            if mob then sess.mobsAlive[mob:getID()] = mob end
        end
    end

    if not next(sess.mobsAlive) then
        -- No mobs spawned (engine failure). Abort the run.
        player:printToPlayer('[Tower] ERROR: mob spawn failed. Aborting run.', xi.msg.channel.SYSTEM_3)
        endTower(player, 'error')
    end
end

-----------------------------------
-- End the tower run
-----------------------------------
endTower = function(player, reason)
    local sess = getSession(player)
    clearSession(player)

    -- Kill any live mobs from the current floor.
    if sess then
        for _, mob in pairs(sess.mobsAlive or {}) do
            pcall(function() mob:setHP(0) end)
        end
    end

    if reason == 'cleared' then
        -- Count full clears for the leaderboard.
        player:setCharVar('Tower_Climbs', (player:getCharVar('Tower_Climbs') or 0) + 1)
        -- Trial 2 complete.
        if (player:getCharVar('PW_Trial2_Done') or 0) == 0 then
            player:setCharVar('PW_Trial2_Done', 1)
            player:printToPlayer(
                '[Tower] THE PINNACLE SOVEREIGN FALLS! Trial 2 complete! Visit the Prime Armory.',
                xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(
                '[Tower] Floor 50 cleared! Trial 2 already complete - you have bragging rights.',
                xi.msg.channel.SYSTEM_3)
        end
    elseif reason == 'death' then
        local floor = sess and sess.floor or 0
        player:printToPlayer(string.format(
            '[Tower] You fell on floor %d. Run ended.', floor), xi.msg.channel.SYSTEM_3)
    elseif reason == 'left' then
        player:printToPlayer('[Tower] You left the Tower. Run ended.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'abort' then
        player:printToPlayer('[Tower] Run aborted.', xi.msg.channel.SYSTEM_3)
    end

    -- Warp back to GM Home after a short delay.
    player:timer(3000, function(p)
        p:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
    end)
end

-- Expose for the !tower command file.
xi._et_endTower   = endTower
xi._et_startFloor = startFloor

-----------------------------------
-- Module overrides: Walk of Echoes
-----------------------------------
m:addOverride('xi.zones.Walk_of_Echoes.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)

    local sess = getSession(player)
    if not sess then return cs end

    -- Player has arrived from the warp. Start floor 1.
    if sess.floor == 0 then
        player:printToPlayer(
            string.format('[Tower] Welcome to the Endless Tower! Floors: %d. Bosses every 10 floors.',
                MAX_FLOOR),
            xi.msg.channel.SYSTEM_3)
        player:printToPlayer(
            '[Tower] Remember: solo only - Trusts are disabled in this zone. Use !tower abort to exit early.',
            xi.msg.channel.SYSTEM_3)
        -- Small delay so the zone-in animation settles.
        player:timer(2000, function(p)
            local s = sessions[p:getName()]
            if s and s.floor == 0 then startFloor(p) end
        end)
    end

    return cs
end)

-- Death ends the run.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    if getSession(player) then
        player:timer(2000, function(p) endTower(p, 'death') end)
    end
    return cs
end)

-----------------------------------
-- Module override: GM Home - place the NPC
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Tower_Arbiter',
        packetName = 'Endless Tower Arbiter',
        look       = 2401,
        x          = -15.000,
        y          =  0.000,
        z          = -35.000,
        rotation   =  128,
        widescan   =  1,

        onTrigger = function(player, npc)
            if getSession(player) then
                player:printToPlayer('[Tower] You are already in a Tower run! Use !tower abort to reset.', xi.msg.channel.SYSTEM_3)
                return
            end

            -- One climber at a time -- but lazily RELEASE a stale lock first. A session
            -- sticks if a run ended abnormally (logout, warp/escape, or a server hiccup
            -- that bumped the climber out without endTower firing). Without this, one
            -- ghost run blocks the Tower for EVERYONE (e.g. the "ascended by X but X is
            -- standing in the hub" report). A genuine climber never leaves the arena
            -- (solo, death-ends-run), so "offline" or "not in the Tower zone" == stale.
            -- Setting an existing key to nil mid-pairs() is safe in Lua.
            for name in pairs(sessions) do
                local climber = GetPlayerByName(name)
                if not climber or climber:getZoneID() ~= TOWER_ZONE_ID then
                    sessions[name] = nil
                end
            end

            -- Block only if a GENUINE climber is still inside the arena.
            local activeClimber = next(sessions)
            if activeClimber then
                player:printToPlayer(
                    string.format('[Tower] The Tower is currently being ascended by %s. Wait for their run to end.', activeClimber),
                    xi.msg.channel.SYSTEM_3)
                return
            end

            local done = (player:getCharVar('PW_Trial2_Done') or 0) == 1
            local best = player:getCharVar('Tower_Best_Floor') or 0

            player:printToPlayer(
                string.format('[Endless Tower] Scale 50 floors to claim the Pinnacle Core (Trial 2). Best floor: %d. Trial 2: %s.',
                    best, done and 'COMPLETE' or 'pending'),
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer(
                '[Endless Tower] Rule: solo only, no Trusts. Death ends the run immediately.',
                xi.msg.channel.SYSTEM_3)

            local options =
            {
                {
                    'Enter the Tower',
                    function(p)
                        -- Re-check: another player may have entered between menu-open and click.
                        local occupant = next(sessions)
                        if occupant then
                            p:printToPlayer(
                                string.format('[Tower] %s just entered while your menu was open. Try again shortly.', occupant),
                                xi.msg.channel.SYSTEM_3)
                            return
                        end
                        -- Create session and warp.
                        sessions[p:getName()] = {
                            floor     = 0,
                            mobsAlive = {},
                        }
                        p:setPos(WARP_IN.x, WARP_IN.y, WARP_IN.z, WARP_IN.rot, TOWER_ZONE_ID)
                    end,
                },
                {
                    'Not now',
                    function(p) end,
                },
            }

            local menu = { title = 'Endless Tower', options = options }
            local snap = { title = menu.title, options = menu.options }
            player:timer(30, function(p) p:customMenu(snap) end)
        end,
    })
    utils.unused(npc)
end)

return m
