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

local m = Module:new('world_boss')

-----------------------------------
-- Shared state (command module reads xi._wb)
-----------------------------------
xi._wb = xi._wb or nil   -- nil = no boss; set in spawnBoss(), cleared in onMobDeath

-----------------------------------
-- Constants
-----------------------------------
local BOSS_ZONE_ID  = xi.zone.WEST_RONFAURE   -- 100
local GROUP_ZONE_ID = 210   -- GM Home (where all HL mob_groups are registered)
local BOSS_LEVEL    = 250
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
