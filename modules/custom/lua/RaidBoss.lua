-----------------------------------
-- RaidBoss.lua
-- THE STAR-DEVOURER: the server's weekly raid. Popped on demand from
-- the Voidgate Sentinel at Escha-RuAun; one fight live at a time,
-- anyone present can pile in. Multi-phase scripted mechanics (stance
-- dance, feeding tendrils, dispel sweep, fury, soft enrage) - see
-- raid_catalog.lua for every knob.
--
-- Weekly lockout is on the REWARD, not the door: every character's
-- big payout (marks + Infamy) is once per ISO week; repeat kills pay
-- a token. So Tuesday's group can carry Friday's latecomer.
--
-- Engineering notes:
--   * All phase logic (HP thresholds, stance timer, soft enrage) runs
--     inside the boss's onMobFight tick - no detached timers to leak.
--     A mob-side watchdog handles the "everyone left/died" reset.
--   * The hard-won spawn rails: minLevel+maxLevel+detection set,
--     releaseIdOnDisappear, state cleared BEFORE despawns, fresh add
--     sets per phase (never a stale entity ref), NO_CAPACITY_POINTS.
-----------------------------------
require('modules/module_utils')
local catalog   = require('modules/custom/lua/raid_catalog')
local gmCatalog = require('modules/custom/lua/game_master_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('raid_boss')

-----------------------------------
-- Single shared fight state (nil = no raid up).
--   boss        boss entity ref (valid while alive)
--   bossId      entity id
--   addsAlive   { mobId -> mobEntity } CURRENT tendril set only
--   firedPhases { idx -> true }
--   stanceOn    stance dance engaged
--   stanceIdx   which stance is live
--   nextStanceAt / enrageAt / startedAt   os.time() marks
--   regenActive boss regen applied for the live tendril set
--   leashMisses consecutive watchdog checks with nobody near
-----------------------------------
local state = nil

local SECONDS_PER_WEEK = 604800
local MONDAY_ANCHOR    = 259200
local function currentIsoWeek()
    return math.floor((os.time() + MONDAY_ANCHOR) / SECONDS_PER_WEEK)
end

local function templateFromPool(diffName)
    local diff = gmCatalog.difficulties[diffName]
    local pool = diff and diff.mobs or gmCatalog.difficulties.Easy.mobs
    return pool[math.random(#pool)]
end

local function dist2d(ax, az, bx, bz)
    local dx, dz = ax - bx, az - bz
    return math.sqrt(dx * dx + dz * dz)
end

-- Living players within `radius` of an entity.
local function playersNear(entity, radius)
    local out = {}
    local zone = entity:getZone()
    if not zone then return out end
    local ok, players = pcall(function() return zone:getPlayers() end)
    if not ok or not players then return out end
    local ex, ez = entity:getXPos(), entity:getZPos()
    for _, p in pairs(players) do
        if p and p:getHP() > 0
           and dist2d(ex, ez, p:getXPos(), p:getZPos()) <= radius then
            out[#out + 1] = p
        end
    end
    return out
end

local function shout(entity, msg)
    for _, p in ipairs(playersNear(entity, 80.0)) do
        p:printToPlayer('[Raid] ' .. msg, xi.msg.channel.SYSTEM_3)
    end
end

-----------------------------------
-- Stance handling - setMod is ABSOLUTE, so each swap just sets both
-- damage-taken mods to the new stance's values (no delta bookkeeping).
-----------------------------------
local function applyStance(boss, idx)
    local stance = catalog.stance.stances[idx]
    if not stance then return end
    for modId, val in pairs(stance.mods) do
        pcall(function() boss:setMod(modId, val) end)
    end
    shout(boss, stance.msg)
end

-----------------------------------
-- Tendril phase. Adds spawn around the boss; while ANY of this set
-- lives, the boss regenerates hard. Set is fresh per phase.
-----------------------------------
local function spawnTendrils(boss, phase)
    if not state then return end
    state.addsAlive = {}   -- fresh set (a stale ref = map crash)

    local template = templateFromPool(catalog.addsPoolDifficulty)
    local zone = boss:getZone()
    local bx, by, bz = boss:getXPos(), boss:getYPos(), boss:getZPos()

    for i = 1, (phase.count or 2) do
        local angle = math.random() * math.pi * 2
        local dist  = 6.0 + math.random() * 4.0
        local mx, mz = bx + math.cos(angle) * dist, bz + math.sin(angle) * dist

        local add = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = template.groupId,
            groupZoneId          = catalog.npcPos.zoneId,
            name                 = phase.name or 'Starspawn Tendril',
            x = mx, y = by, z = mz,
            rotation             = math.random(0, 255),
            minLevel             = phase.level or 170,   -- REQUIRED
            maxLevel             = phase.level or 170,
            detection            = xi.detects.SIGHT_AND_HEARING,  -- REQUIRED
            isAggroable          = true,
            releaseIdOnDisappear = true,

            onMobDeath = function(deadMob, killer)
                if not state then return end
                state.addsAlive[deadMob:getID()] = nil
                if killer then
                    killer:setCharVar('Custom_NM_Kills',
                        (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
                end
                for _ in pairs(state.addsAlive) do return end  -- some live

                -- Last tendril down: the feed is severed.
                if state.regenActive and state.boss then
                    state.regenActive = false
                    pcall(function() state.boss:setMod(xi.mod.REGEN, 0) end)
                    shout(deadMob, 'The last tendril is severed - the Devourer\'s wounds stay OPEN!')
                end
            end,
        })

        if add then
            add:setSpawn(mx, by, mz, 0)
            add:spawn()
            add:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
            if phase.hpMult and phase.hpMult > 1.0 then
                local newMax = math.floor(add:getMaxHP() * phase.hpMult)
                add:setMaxHP(newMax)
                add:setHP(newMax)
            end
            state.addsAlive[add:getID()] = add
        end
    end

    if phase.regenWhileAlive then
        state.regenActive = true
        pcall(function() boss:setMod(xi.mod.REGEN, phase.regenWhileAlive) end)
    end
end

-----------------------------------
-- HP phase dispatcher (runs from the boss's onMobFight tick).
-----------------------------------
local function firePhase(boss, phase)
    if phase.message then
        shout(boss, phase.message)
    end
    if phase.action == 'tendrils' then
        spawnTendrils(boss, phase)
    elseif phase.action == 'dispel' then
        for _, p in ipairs(playersNear(boss, 30.0)) do
            for _ = 1, (phase.count or 3) do
                pcall(function() p:dispelStatusEffect() end)
            end
        end
    elseif phase.action == 'fury' then
        pcall(function()
            boss:addMod(xi.mod.ATT, phase.att or 2000)
            boss:addMod(xi.mod.HASTE_GEAR, phase.haste or 100)
        end)
    end
end

-----------------------------------
-- Reward + teardown on kill.
-----------------------------------
local function onBossDown(boss, killer)
    if not state then return end
    local adds = state.addsAlive
    state = nil   -- clear BEFORE despawning leftovers

    for _, add in pairs(adds or {}) do
        if type(add) == 'userdata' then
            pcall(function()
                if add:getHP() > 0 then add:setHP(0) end
            end)
        end
    end

    if killer then
        killer:setCharVar('Custom_NM_Kills',
            (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
    end

    local week = currentIsoWeek()
    for _, p in ipairs(playersNear(boss, catalog.reward.radius)) do
        p:setCharVar('Raid_Kills', (p:getCharVar('Raid_Kills') or 0) + 1)

        if (p:getCharVar('Raid_WeekStamp') or 0) ~= week then
            p:setCharVar('Raid_WeekStamp', week)
            p:setCharVar('HL_Points',
                (p:getCharVar('HL_Points') or 0) + catalog.reward.weeklyMarks)
            p:setCharVar('Infamy',
                (p:getCharVar('Infamy') or 0) + catalog.reward.weeklyInfamy)
            p:setCharVar('Infamy_Lifetime',
                (p:getCharVar('Infamy_Lifetime') or 0) + catalog.reward.weeklyInfamy)
            p:printToPlayer(string.format(
                '[Raid] THE STAR-DEVOURER FALLS! Weekly trophy: +%d marks, +%d Infamy.',
                catalog.reward.weeklyMarks, catalog.reward.weeklyInfamy),
                xi.msg.channel.SYSTEM_3)
        else
            p:setCharVar('HL_Points',
                (p:getCharVar('HL_Points') or 0) + catalog.reward.repeatMarks)
            p:printToPlayer(string.format(
                '[Raid] The Star-Devourer falls again. Trophy already claimed this week - +%d marks.',
                catalog.reward.repeatMarks),
                xi.msg.channel.SYSTEM_3)
        end

        local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
        if okAch and ach and ach.onRaidKill then
            pcall(function() ach.onRaidKill(p) end)
        end
        local okWh, wh = pcall(require, 'modules/custom/lua/weekly_hunts')
        if okWh and wh and wh.fire then
            pcall(function() wh.fire(p, 'raid_kill', {}) end)
        end
    end

    -- Server-wide bragging rights via any nearby player.
    local near = playersNear(boss, catalog.reward.radius)
    if near[1] then
        pcall(function()
            near[1]:printToArea(
                string.format('[Raid] %s and company have slain THE STAR-DEVOURER!',
                    killer and killer:getName() or 'The defenders'),
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
        end)
    end
end

-----------------------------------
-- Full reset (leash / error): despawn everything, clear state.
-----------------------------------
local function resetRaid(reason)
    if not state then return end
    local boss = state.boss
    local adds = state.addsAlive
    state = nil

    for _, add in pairs(adds or {}) do
        if type(add) == 'userdata' then
            pcall(function()
                if add:getHP() > 0 then add:setHP(0) end
            end)
        end
    end
    if boss and type(boss) == 'userdata' then
        pcall(function()
            if boss:getHP() > 0 then boss:setHP(0) end
        end)
    end
    print('[raid] reset: ' .. tostring(reason))
end

-----------------------------------
-- Spawn the boss.
-----------------------------------
local function popRaid(player)
    if state then
        player:printToPlayer('[Raid] The Star-Devourer is already loose! Join the fight.',
            xi.msg.channel.SYSTEM_3)
        return
    end
    if player:getHP() <= 0 then return end

    local template = templateFromPool(catalog.bossPoolDifficulty)
    local zone = player:getZone()
    local b = catalog.boss
    local px, py, pz = player:getXPos(), player:getYPos(), player:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = b.spawnRingMin + math.random() * (b.spawnRingMax - b.spawnRingMin)
    local mx, mz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist
    local popperName = player:getName()

    local boss = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = template.groupId,
        groupZoneId          = catalog.npcPos.zoneId,
        name                 = b.name,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = b.level,   -- REQUIRED
        maxLevel             = b.level,
        detection            = xi.detects.SIGHT_AND_HEARING,  -- REQUIRED
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            onBossDown(deadMob, killer)
        end,

        -- The whole mechanical brain rides the combat tick.
        onMobFight = function(boss_, target)
            if not state then return end
            local now = os.time()
            local hpp = boss_:getHPP()

            -- Stance dance.
            if catalog.stance then
                if not state.stanceOn and hpp <= catalog.stance.startHpp then
                    state.stanceOn     = true
                    state.stanceIdx    = 1
                    state.nextStanceAt = now + catalog.stance.periodSec
                    applyStance(boss_, 1)
                elseif state.stanceOn and now >= state.nextStanceAt then
                    state.stanceIdx    = (state.stanceIdx % #catalog.stance.stances) + 1
                    state.nextStanceAt = now + catalog.stance.periodSec
                    applyStance(boss_, state.stanceIdx)
                end
            end

            -- HP phases, in catalog order (a huge hit fires several
            -- sequentially on one tick - intended, same as dungeons).
            for idx, phase in ipairs(catalog.phases) do
                if not state.firedPhases[idx] and hpp <= phase.hp then
                    state.firedPhases[idx] = true
                    pcall(function() firePhase(boss_, phase) end)
                end
            end

            -- Soft enrage.
            if not state.enraged and catalog.softEnrage
               and now >= state.startedAt + catalog.softEnrage.sec then
                state.enraged = true
                pcall(function()
                    boss_:addMod(xi.mod.ATT, catalog.softEnrage.att)
                    boss_:addMod(xi.mod.HASTE_GEAR, catalog.softEnrage.haste)
                end)
                shout(boss_, catalog.softEnrage.message)
            end
        end,
    })

    if not boss then
        player:printToPlayer('[Raid] The voidgate sputters... nothing emerges. (Spawn failed.)',
            xi.msg.channel.SYSTEM_3)
        return
    end

    boss:setSpawn(mx, py, mz, 0)
    boss:spawn()
    boss:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    for modId, val in pairs(b.mods) do boss:setMod(modId, val) end
    local newMax = math.floor(boss:getMaxHP() * b.hpMult)
    boss:setMaxHP(newMax)
    boss:setHP(newMax)
    pcall(function() boss:setModelSize(b.modelSize or 3) end)
    boss:updateClaim(player)
    boss:addEnmity(player, 1, 1)

    state = {
        boss        = boss,
        bossId      = boss:getID(),
        addsAlive   = {},
        firedPhases = {},
        stanceOn    = false,
        stanceIdx   = 0,
        nextStanceAt = 0,
        enraged     = false,
        regenActive = false,
        startedAt   = os.time(),
        leashMisses = 0,
    }

    -- Leash watchdog on the boss's own PAI: two consecutive empty
    -- checks (no living player in leash range) = full reset, so a wipe
    -- or mass-warp never leaves a 45x-HP god parked on the zone.
    local function armWatchdog(watched)
        watched:timer(catalog.watchdogSec * 1000, function(bossNow)
            if not state or state.boss ~= watched then return end
            if not bossNow or bossNow:getHP() <= 0 then return end
            if #playersNear(bossNow, catalog.leashRadius) == 0 then
                state.leashMisses = state.leashMisses + 1
                if state.leashMisses >= 2 then
                    resetRaid('leash')
                    return
                end
            else
                state.leashMisses = 0
            end
            armWatchdog(bossNow)
        end)
    end
    armWatchdog(boss)

    pcall(function()
        player:printToArea(
            string.format('[Raid] %s has opened the voidgate - THE STAR-DEVOURER emerges at Escha-RuAun!',
                popperName),
            xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
    end)
end

-----------------------------------
-- The Voidgate Sentinel NPC.
-----------------------------------
local menu = { title = 'Voidgate Sentinel', options = {} }

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    local sentinel = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Voidgate_Sentinel',
        packetName = string.format('%sVoidgate Sentinel', xi.icon.STAR_LARGE),
        look       = 3017,
        x = catalog.npcPos.x, y = catalog.npcPos.y, z = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            local week    = currentIsoWeek()
            local claimed = (player:getCharVar('Raid_WeekStamp') or 0) == week
            player:printToPlayer(string.format(
                '[Voidgate Sentinel] Beyond this gate sleeps the Star-Devourer. Weekly trophy: %s. Lifetime kills: %d.',
                claimed and 'CLAIMED (resets Monday 00:00 UTC)' or 'AVAILABLE',
                player:getCharVar('Raid_Kills') or 0),
                xi.msg.channel.SYSTEM_3)

            local options = {}
            if state then
                options[#options + 1] = { 'The Devourer is LOOSE - status', function(p)
                    if state and state.boss then
                        local ok, hpp = pcall(function() return state.boss:getHPP() end)
                        p:printToPlayer(string.format(
                            '[Raid] The Star-Devourer stands at %s%% - join the fight!',
                            ok and tostring(hpp) or '??'), xi.msg.channel.SYSTEM_3)
                    end
                end }
            else
                options[#options + 1] = { 'Open the voidgate (pop the raid)', function(p)
                    popRaid(p)
                end }
            end
            options[#options + 1] = { 'How does the raid work?', function(p)
                p:printToPlayer('[Raid] One shared boss, anyone can join. Stance dance: swap physical/magical damage with its stances. Kill tendrils FAST or it heals through everything. Big weekly reward per character; repeats pay a token.',
                    xi.msg.channel.SYSTEM_3)
            end }
            options[#options + 1] = { 'Close', function(p) end }

            menu.options = options
            player:timer(50, function(p) p:customMenu(menu) end)
        end,
    })
    utils.unused(sentinel)
end)

return m
