-----------------------------------
-- world_boss.lua
--
-- WEEKLY WORLD BOSS: a single epic encounter spawns in West Ronfaure (100)
-- every Sunday (UTC). Eight bosses rotate in order by week number.
--
-- The boss has a large HP pool saved to server_variables every player tick so
-- that a server restart mid-fight restores HP on zone init rather than
-- resetting the fight. Any player present in Hall of the Gods when the boss
-- dies earns one Prime Weapon Trial 3 kill credit (need 3 total).
--
-- Server variables (prefix [WB]):
--   Active   0=idle  1=boss alive  2=defeated this week
--   BossIdx  1-8 index into BOSSES catalog
--   HP       current HP (synced every 30s; used to restore on restart)
--   MaxHP    max HP for this spawn (printed in status messages)
--   WeekNum  week-number of the last spawn (prevents double-spawn)
--
-- CharVars:
--   PW_Trial3_Kills   number of World Boss kills contributed to (need 3)
--   PW_Trial3_Done    1 when kills >= 3
--
-- Shared runtime state exposed via xi._wb (nil when no boss is active):
--   xi._wb.boss      spawned mob entity
--   xi._wb.bossIdx   1-8 BOSSES index
--   xi._wb.maxHP     boss max HP
--
-- Clock architecture (mirrors the invasion module):
--   * Every player zoning into Hall of the Gods gets a re-arming 30s timer.
--   * The timer syncs HP to server_var and checks for Sunday auto-spawn.
--   * Server vars prevent double-spawn across ticking players and restarts.
--   * onInitialize re-spawns the boss (with saved HP) after a restart.
--
-- Deploy: Lua hot-reload loads this file on edit; no restart needed.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/West_Ronfaure/Zone')

local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m = Module:new('world_boss')

-----------------------------------
-- Shared state (command module reads xi._wb)
-----------------------------------
xi._wb = xi._wb or nil   -- nil = no boss; set in spawnBoss(), cleared in onMobDeath

-- RETIRED 2026-06-20: World Bosses no longer drive any progression -- Prime
-- Weapon Trial 3 is now a Riftborn Boulder turn-in (rare Abyssea NM drop). The
-- whole system is disabled at the spawn choke point below (every path -- restart
-- resume, Sunday auto-spawn, and the !worldboss GM command -- routes through
-- spawnBoss). Code kept intact; flip RETIRED to false to bring it back.
local RETIRED = true

-----------------------------------
-- Constants
-----------------------------------
local BOSS_ZONE_ID  = xi.zone.WEST_RONFAURE   -- 100
local GROUP_ZONE_ID = 210   -- GM Home (where all HL mob_groups are registered)
local BOSS_LEVEL    = 150
local TICK_SECONDS  = 30

-----------------------------------
-- Boss catalog
-- groupId reuses the 15 existing Hunting League mob_groups (registered under
-- zone 210/GM_Home in hunting_league_gm_home_mobs.sql). Boss pos is inside
-- Hall of the Gods main chamber. Run !pos after a live test and paste coords
-- here if they land off-ground.
-----------------------------------
local BOSSES =
{
    {
        name    = 'Ancient Behemoth',
        groupId = 11365,    -- King_Behemoth base
        hp      = 3000000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Absolute Virtue Reborn',
        groupId = 11367,    -- Absolute_Virtue base
        hp      = 3500000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Grand Pandemonium',
        groupId = 11368,    -- Pandemonium_Warden base
        hp      = 3500000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Eternal Shinryu',
        groupId = 11369,    -- Shinryu base
        hp      = 4000000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Lord Kirin Ascendant',
        groupId = 11366,    -- Kirin base
        hp      = 3000000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Vrtra the Unbound',
        groupId = 11362,    -- Vrtra base
        hp      = 3000000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Nidhogg Unchained',
        groupId = 11364,    -- Nidhogg base
        hp      = 3500000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
    {
        name    = 'Simurgh Eternal',
        groupId = 11363,    -- Simurgh base
        hp      = 3000000,
        pos     = { x = -300.000, y = -50.000, z = 270.000, rot = 0 },
    },
}

-- Expose catalog for the command module.
xi._wb_bosses = BOSSES

-----------------------------------
-- Hardcore mechanics configs (mob_mechanics_library.lua)
-- One distinct full-kit identity per boss so each week plays differently.
-- addGroupId/addZoneId: adds are inserted using GROUP_ZONE_ID (210) mob_groups,
-- the same zone the bosses themselves come from. This mirrors the pattern used
-- by Endless Tower and Hunting League. Each addGroupId reuses one of the 8
-- world-boss groupIds (11362-11369) that already exist in zone 210.
-- BOSS_ZONE_ID (100) is where the add mobs PHYSICALLY SPAWN (next to the boss);
-- GROUP_ZONE_ID (210) is the DB zone the groupId rows are registered under.
-- DMGPHYS/DMGMAGIC capped at -5000 (-50% resist) per library convention.
-- ATT/REGEN only in enrage/fury/adds.regen -- never via mob:addMod directly.
-----------------------------------
local BOSS_MECH =
{
    -- [1] Ancient Behemoth  groupId=11365
    -- Identity: UNSTOPPABLE BRUISER. Stance dance from the start; tremor AoE;
    -- fury spike at 40%; doom + hard enrage at low HP. Melee-heavy
    -- but punishes magic turtling too.
    [1] = {
        name   = 'Ancient Behemoth',
        stance = { startHpp = 100, periodSec = 18, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hardens its hide -- weapons glance off! Use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'shrugs off sorcery -- hack it down with steel!' },
        } },
        aoe    = { periodSec = 14, dmgPct = 24, msg = 'EARTH TREMOR -- the ground heaves, shockwave outward!' },
        enrage = { sec = 300, att = 6000, haste = 150, msg = 'the Behemoth loses all restraint -- its fury becomes absolute!' },
        phases = {
            { hp = 40, action = 'fury',  att = 4000, haste = 120, msg = 'the Behemoth enrages -- its strikes land like boulders!' },
            { hp = 20, action = 'doom',  dur = 28, msg = 'the Behemoth fixes its gaze on you -- marked for death!' },
            { hp = 10, action = 'enrage', att = 9000, haste = 250, msg = 'PRIMAL FURY -- the Behemoth becomes unkillable in its rage!' },
        },
        doom   = { startHpp = 15, dur = 30, msg = 'the Behemoth marks you for annihilation!' },
    },

    -- [2] Absolute Virtue Reborn  groupId=11367
    -- Identity: DIVINE INQUISITOR. Silences casters; AoE judgment waves;
    -- dispels your buffs in two waves; doom sentence at 10%; tight enrage.
    -- Forces melee during silence windows, forces magic when DMGPHYS hits.
    [2] = {
        name   = 'Absolute Virtue Reborn',
        stance = { startHpp = 85, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Virtue deems blades unworthy -- the divine shields it. Use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Virtue wards sorcery -- your spells dissolve. Strike with steel!' },
        } },
        aoe    = { periodSec = 12, dmgPct = 28, msg = 'DIVINE RETRIBUTION -- a wave of judgment scours the arena!' },
        cc     = { periodSec = 20, effect = xi.effect.SILENCE, dur = 8, msg = 'Virtue silences the heretical -- no words, no spells!' },
        enrage = { sec = 240, att = 7000, haste = 180, msg = 'Absolute Virtue sheds all limitation -- the end draws near!' },
        phases = {
            { hp = 55, action = 'dispel', count = 4, msg = 'DIVINE STRIP -- Virtue tears your blessings away!' },
            { hp = 40, action = 'nuke',   dmgPct = 40, msg = 'RIGHTEOUS NOVA -- divine energy erupts from Virtue!' },
            { hp = 10, action = 'doom',   dur = 22, msg = 'Absolute Virtue passes final judgment -- doom upon you!' },
        },
        doom   = { startHpp = 10, dur = 22, msg = 'Absolute Virtue sentences you to death!' },
    },

    -- [3] Grand Pandemonium  groupId=11368
    -- Identity: CHAOS FEEDER. Self-drains to survive; AoE shockwaves; dispel
    -- at 35%; doom + enrage at 10%. No stance -- pure sustained chaos.
    [3] = {
        name   = 'Grand Pandemonium',
        aoe    = { periodSec = 13, dmgPct = 22, msg = 'PANDEMONIUM WAVE -- chaos energy tears outward!' },
        drain  = { periodSec = 9, healPct = 3 },
        cc     = { periodSec = 25, effect = xi.effect.TERROR, dur = 6, msg = 'Grand Pandemonium exhales chaos -- you freeze in absolute dread!' },
        enrage = { sec = 270, att = 6500, haste = 160, msg = 'Grand Pandemonium ascends to its true form!' },
        phases = {
            { hp = 50, action = 'fury',   att = 3500, haste = 130, msg = 'Grand Pandemonium surges -- strikes intensify!' },
            { hp = 35, action = 'dispel', count = 5, msg = 'CHAOS ERASURE -- your enhancements are unmade!' },
            { hp = 20, action = 'nuke',   dmgPct = 38, msg = 'PANDEMONIUM COLLAPSE -- reality itself buckles!' },
            { hp = 10, action = 'doom',   dur = 25, msg = 'Grand Pandemonium marks the end of all things -- doom falls!' },
        },
        doom   = { startHpp = 12, dur = 28, msg = 'Grand Pandemonium seals your fate!' },
    },

    -- [4] Eternal Shinryu  groupId=11369
    -- Identity: APEX DRAGON. Full hardcore kit with the tightest enrage timer.
    -- Stance dance, AoE breath, dispel, nuke, fury, doom -- every
    -- mechanic deployed. The hardest fight in the rotation.
    [4] = {
        name   = 'Eternal Shinryu',
        stance = { startHpp = 90, periodSec = 14, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Shinryu\'s scales turn to diamond -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Shinryu warps the aether -- steel only!' },
        } },
        aoe    = { periodSec = 11, dmgPct = 26, msg = 'SHINRYU BREATH -- a torrent of destruction!' },
        drain  = { periodSec = 10, healPct = 2 },
        enrage = { sec = 210, att = 8000, haste = 200, msg = 'Shinryu crosses into legend -- absolute fury!' },
        phases = {
            { hp = 55, action = 'dispel', count = 5, msg = 'TIDAL WAVE BREATH -- your protections are annihilated!' },
            { hp = 40, action = 'nuke',   dmgPct = 42, msg = 'SHINRYU\'S JUDGMENT -- reality cracks under divine wrath!' },
            { hp = 15, action = 'fury',   att = 5000, haste = 160, msg = 'Shinryu ascends -- you stand before a true god!' },
            { hp = 10, action = 'doom',   dur = 22, msg = 'Shinryu marks the unworthy for annihilation!' },
        },
        doom   = { startHpp = 10, dur = 22, msg = 'Shinryu sentences you to death eternal!' },
    },

    -- [5] Lord Kirin Ascendant  groupId=11366
    -- Identity: ELEMENTAL TYRANT. No melee identity -- pure elemental assault.
    -- AoE shockwaves; CC terror; dispel in two waves; final nuke + doom.
    -- The most caster-centric fight; melee must dodge waves.
    [5] = {
        name   = 'Lord Kirin Ascendant',
        aoe    = { periodSec = 10, dmgPct = 25, msg = 'KIRIN\'S TEMPEST -- elemental energy detonates around it!' },
        cc     = { periodSec = 22, effect = xi.effect.TERROR, dur = 7, msg = 'Lord Kirin lets out a deific roar -- all freeze in terror!' },
        enrage = { sec = 260, att = 5500, haste = 140, msg = 'Lord Kirin summons the full power of the heavens!' },
        phases = {
            { hp = 75, action = 'dispel', count = 4, msg = 'LORD KIRIN DISPELS -- the divine strips your enhancements!' },
            { hp = 40, action = 'dispel', count = 6, msg = 'LORD KIRIN\'S PURGE -- everything is stripped bare!' },
            { hp = 25, action = 'nuke',   dmgPct = 38, msg = 'HEAVEN\'S WRATH -- the sky collapses on you!' },
            { hp = 10, action = 'doom',   dur = 26, msg = 'Lord Kirin decrees your end -- doom enacted!' },
        },
        doom   = { startHpp = 12, dur = 28, msg = 'Lord Kirin marks you for divine judgment!' },
    },

    -- [6] Vrtra the Unbound  groupId=11362
    -- Identity: SHADOW TYRANT. Stance dance + drain combo; fury spike at 30%;
    -- doom. Uniquely punishing on tanks: constant self-healing makes this a
    -- race to out-damage Vrtra before it out-sustains the raid.
    [6] = {
        name   = 'Vrtra the Unbound',
        stance = { startHpp = 95, periodSec = 20, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Vrtra shrouds itself in shadow -- blades pass through. Use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Vrtra disperses the aether -- spells dissolve. Strike with steel!' },
        } },
        drain  = { periodSec = 8, healPct = 3 },
        cc     = { periodSec = 26, effect = xi.effect.TERROR, dur = 5, msg = 'Vrtra\'s presence crushes the soul -- all freeze!' },
        enrage = { sec = 280, att = 5500, haste = 130, msg = 'Vrtra the Unbound tears free of all restraint!' },
        phases = {
            { hp = 45, action = 'nuke',  dmgPct = 35, msg = 'SHADOW NOVA -- void energy rips through the arena!' },
            { hp = 30, action = 'fury',  att = 4000, haste = 120, msg = 'Vrtra enters a killing frenzy -- strikes accelerate!' },
            { hp = 15, action = 'doom',  dur = 30, msg = 'Vrtra the Unbound marks you to be consumed!' },
        },
        doom   = { startHpp = 15, dur = 32, msg = 'Vrtra will consume you -- doom sealed!' },
    },

    -- [7] Nidhogg Unchained  groupId=11364
    -- Identity: BERSERKER DRAGON. No stance -- just relentless aggression.
    -- AoE every 9s (shortest in the rotation); fury at 25%;
    -- the tightest enrage + doom combo. The attrition fight.
    [7] = {
        name   = 'Nidhogg Unchained',
        aoe    = { periodSec = 9, dmgPct = 22, msg = 'NIDHOGG\'S RAMPAGE -- a savage shockwave tears outward!' },
        drain  = { periodSec = 11, healPct = 2 },
        enrage = { sec = 230, att = 7500, haste = 180, msg = 'Nidhogg Unchained sheds all restraint -- pure berserker fury!' },
        phases = {
            { hp = 50, action = 'dispel', count = 4, msg = 'SAVAGE GUST -- Nidhogg\'s wings shear your enhancements away!' },
            { hp = 25, action = 'fury',   att = 4500, haste = 140, msg = 'Nidhogg enters its kill-frenzy -- the pace becomes merciless!' },
            { hp = 10, action = 'doom',   dur = 24, msg = 'Nidhogg locks onto you -- doom inescapable!' },
        },
        doom   = { startHpp = 12, dur = 25, msg = 'Nidhogg marks you as prey -- doom!' },
    },

    -- [8] Simurgh Eternal  groupId=11363
    -- Identity: STORM HERALD. Silence + AoE combo punishes clustered casters.
    -- Adds at 65%; nuke at 45%; dispel at 25%; doom at 10%. Unique: the AoE
    -- has the largest dmgPct of any non-Shinryu boss (30%) to punish zerg tactics.
    [8] = {
        name   = 'Simurgh Eternal',
        aoe    = { periodSec = 12, dmgPct = 30, msg = 'SIMURGH\'S TEMPEST -- a storm of lightning and wind erupts!' },
        cc     = { periodSec = 18, effect = xi.effect.SILENCE, dur = 9, msg = 'Simurgh\'s cry silences the storm -- no spells, only steel!' },
        enrage = { sec = 250, att = 5000, haste = 140, msg = 'Simurgh Eternal rides the eternal storm -- its power crests!' },
        phases = {
            { hp = 45, action = 'nuke',   dmgPct = 36, msg = 'LIGHTNING JUDGMENT -- Simurgh calls down the full storm!' },
            { hp = 25, action = 'dispel', count = 5, msg = 'GALE STRIP -- the wind tears every buff from your body!' },
            { hp = 15, action = 'fury',   att = 3500, haste = 120, msg = 'Simurgh enters its final flight -- speed beyond reckoning!' },
            { hp = 10, action = 'doom',   dur = 26, msg = 'Simurgh\'s eye fixes on you -- the storm follows!' },
        },
        doom   = { startHpp = 12, dur = 28, msg = 'Simurgh Eternal marks you to fall with the storm!' },
    },
}

-----------------------------------
-- Server-variable helpers
-----------------------------------
local function sv(name)         return '[WB]' .. name end
local function svGet(name)      return GetServerVariable(sv(name)) or 0 end
local function svSet(name, val) return SetServerVariable(sv(name), val) end

-- Expose for the command module.
xi._wb_svGet = svGet
xi._wb_svSet = svSet

-----------------------------------
-- Time helpers
-----------------------------------
-- Week number aligned to Sunday. Epoch (Jan 1 1970) was Thursday.
-- Offset by 3 days so week boundaries land on Sunday 00:00 UTC.
local function currentWeekNum()
    return math.floor((os.time() - 3 * 86400) / (7 * 86400))
end

-- Thursday=0, Friday=1, Saturday=2, Sunday=3 in (epoch_day % 7).
local function isSundayUtc()
    return math.floor(os.time() / 86400) % 7 == 3
end

-----------------------------------
-- Broadcast to all players in a zone
-----------------------------------
local function broadcast(zone, msg)
    pcall(function()
        local players = zone:getPlayers()
        if not players then return end
        for _, p in pairs(players) do
            if p then p:printToPlayer(msg, xi.msg.channel.SYSTEM_3) end
        end
    end)
end

-----------------------------------
-- spawnBoss
-- Spawns (or re-spawns after restart) this week's boss. Sets xi._wb and all
-- WB_ server vars. Returns the mob entity on success, nil on failure.
--   zone     : CZone* (CLuaZone wrapper)
--   bossData : entry from BOSSES catalog
--   bossIdx  : 1-8 index into BOSSES
--   savedHP  : HP to restore (nil or 0 = spawn at full HP)
-----------------------------------
local function spawnBoss(zone, bossData, bossIdx, savedHP)
    if RETIRED then return end   -- World Bosses retired -- see flag above.
    local p = bossData.pos

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = bossData.groupId,
        groupZoneId          = GROUP_ZONE_ID,
        name                 = bossData.name,
        x                    = p.x,
        y                    = p.y,
        z                    = p.z,
        rotation             = p.rot or 0,
        minLevel             = BOSS_LEVEL,
        maxLevel             = BOSS_LEVEL,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        -- On death: award Trial 3 credit to every player present.
        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)
            local zone = deadMob:getZone()

            -- Snapshot participants now (zone:getPlayers at kill time).
            local creditCount = 0
            pcall(function()
                local players = zone:getPlayers() or {}
                for _, p in pairs(players) do
                    if p then
                        local kills = (p:getCharVar('PW_Trial3_Kills') or 0) + 1
                        p:setCharVar('PW_Trial3_Kills', kills)
                        creditCount = creditCount + 1
                        if kills >= 3 and (p:getCharVar('PW_Trial3_Done') or 0) == 0 then
                            p:setCharVar('PW_Trial3_Done', 1)
                            p:printToPlayer(
                                '[World Boss] Trial 3 complete! Visit the Prime Armory when you are ready to forge your weapon.',
                                xi.msg.channel.SYSTEM_3)
                        else
                            p:printToPlayer(string.format(
                                '[World Boss] Kill credited! (%d/3 boss kills toward Trial 3.)',
                                kills), xi.msg.channel.SYSTEM_3)
                        end
                    end
                end
            end)

            broadcast(zone, string.format(
                '[World Boss] %s has been slain! %d hero(es) earn Trial 3 progress.',
                bossData.name, creditCount))

            -- Mark defeated for the rest of this week.
            svSet('Active', 2)
            svSet('HP', 0)
            xi._wb = nil
        end,

        -- Hardcore mechanics tick (stance dance, AoE, phases, drain, doom, etc.).
        -- All calls are pcall-guarded inside the library.
        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    })

    if not mob then
        print(string.format('[world_boss] ERROR: insertDynamicEntity failed for %s', bossData.name))
        return nil
    end

    mob:setSpawn(p.x, p.y, p.z, p.rot or 0)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
    mob:setModelSize(3)

    local spawnHP = (savedHP and savedHP > 0 and savedHP < bossData.hp) and savedHP or bossData.hp
    mob:setMaxHP(bossData.hp)
    mob:setHP(spawnHP)

    -- Attach hardcore mechanics AFTER stats/HP are set (library requirement).
    -- Each boss index maps to a distinct full-kit identity in BOSS_MECH.
    mechanics.attach(mob, BOSS_MECH[bossIdx])

    xi._wb = { boss = mob, bossIdx = bossIdx, maxHP = bossData.hp }

    svSet('Active',  1)
    svSet('BossIdx', bossIdx)
    svSet('MaxHP',   bossData.hp)
    svSet('HP',      spawnHP)

    print(string.format('[world_boss] %s spawned at %d HP (max %d)',
        bossData.name, spawnHP, bossData.hp))
    return mob
end

-- Expose for the command module.
xi._wb_spawnBoss = spawnBoss

-----------------------------------
-- Module overrides: Hall of the Gods
-----------------------------------

-- onInitialize: re-spawn the boss if it was alive when the server restarted.
m:addOverride('xi.zones.West_Ronfaure.Zone.onInitialize', function(zone)
    super(zone)

    if RETIRED then return end   -- no boss to resume; system retired.
    if svGet('Active') ~= 1 then return end

    local savedHP  = svGet('HP')
    local bossIdx  = svGet('BossIdx')
    if bossIdx < 1 or bossIdx > #BOSSES then bossIdx = 1 end

    if savedHP <= 0 then
        -- HP stored as 0 or corrupt - treat as already killed.
        svSet('Active', 2)
        return
    end

    local bossData = BOSSES[bossIdx]
    print(string.format('[world_boss] Resuming %s at %d HP after restart.',
        bossData.name, savedHP))

    spawnBoss(zone, bossData, bossIdx, savedHP)
    -- Broadcast deferred: no players have zoned in yet at onInitialize time.
end)

-- onZoneIn: arm the per-player 30s tick and greet with current status.
m:addOverride('xi.zones.West_Ronfaure.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    if RETIRED then return cs end   -- don't arm the boss tick; system retired.

    -- Re-arming 30s tick. Stops automatically once the player leaves HotG
    -- (zone check inside prevents re-arming from another zone).
    local function tick()
        local ok = pcall(function() player:getName() end)
        if not ok then return end

        -- Zone guard: only run while the player is still in Hall of the Gods.
        local inHotG = false
        pcall(function()
            inHotG = player:getZone():getID() == BOSS_ZONE_ID
        end)
        if not inHotG then return end

        -- Sync HP to server_var so a restart can restore it.
        if xi._wb and xi._wb.boss then
            pcall(function()
                local hp = xi._wb.boss:getHP()
                if hp > 0 then svSet('HP', hp) end
            end)
        end

        -- Sunday auto-spawn check.
        local week = currentWeekNum()
        local lastWeek = svGet('WeekNum')

        -- New week: reset the defeated flag so Sunday fires again.
        if lastWeek < week and svGet('Active') == 2 then
            svSet('Active', 0)
        end

        if svGet('Active') == 0 and isSundayUtc() and svGet('WeekNum') < week then
            -- Claim the spawn slot immediately to prevent double-spawn from
            -- concurrent ticking players.
            svSet('WeekNum', week)

            local bossIdx  = (week % #BOSSES) + 1
            local bossData = BOSSES[bossIdx]
            local zone     = player:getZone()

            broadcast(zone, string.format(
                '[World Boss] %s descends into Hall of the Gods! Rally your allies and enter the fray!',
                bossData.name))

            local mob = spawnBoss(zone, bossData, bossIdx, nil)
            if not mob then
                -- Spawn failed - release the claim so the next player can retry.
                svSet('WeekNum', 0)
            end
        end

        player:timer(TICK_SECONDS * 1000, tick)
    end

    player:timer(TICK_SECONDS * 1000, tick)

    -- Greet with current boss status.
    local active = svGet('Active')
    if active == 1 then
        local bossIdx = svGet('BossIdx')
        if bossIdx < 1 or bossIdx > #BOSSES then bossIdx = 1 end
        local bossData = BOSSES[bossIdx]
        local hp       = svGet('HP')
        player:printToPlayer(string.format(
            '[World Boss] %s is here with ~%d HP remaining. Join the fight!',
            bossData.name, hp), xi.msg.channel.SYSTEM_3)
    elseif active == 2 then
        player:printToPlayer(
            '[World Boss] The World Boss has been defeated this week. Return Sunday for the next encounter.',
            xi.msg.channel.SYSTEM_3)
    elseif isSundayUtc() then
        player:printToPlayer(
            '[World Boss] Today is Sunday - the World Boss will arrive soon. Stay in the area!',
            xi.msg.channel.SYSTEM_3)
    end

    return cs
end)

return m
