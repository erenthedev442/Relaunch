-----------------------------------
-- ApexTrials.lua
--
-- APEX TRIALS: the infinite, top-tier chase for already-maxed characters.
-- A Greater-Rift-style climb -- one scaled Apex boss per TIER, tiers scale
-- FOREVER. Each NEW tier you clear banks Paragon Points and raises your record
-- (Apex_HighestTier), which is the new uncapped leaderboard. Death or leaving
-- ends the run, but everything you banked on the way up is kept.
--
-- Loop: enter -> warp to the arena -> fight tier (record+1) -> on kill, bank
-- Paragon Points + raise record + auto-advance to the next tier -> repeat until
-- you die or !apex abort. Next run resumes at your new record+1.
--
-- Paragon Points feed the Paragon board (Paragon.lua) -- prestige levels, star
-- auras, titles, QoL, and small capped perks.
--
-- CharVars:
--   Apex_HighestTier   highest tier ever cleared (leaderboard + resume point)
--   Paragon_Points     unspent Paragon currency (spent at the Paragon NPC)
--
-- Architecture mirrors endless_tower.lua: per-player sessions keyed by name;
-- ownerName captured in the onMobDeath closure so the dead mob ref is never
-- reused; releaseIdOnDisappear so IDs self-reclaim; timer-based tier advance
-- (never re-entrant from the mob callback).
--
-- Arena: Walk of Echoes [P2] (zone 279) -- same geometry as Walk of Echoes
-- but a dedicated, otherwise-unused zone so Apex never shares with the Tower.
-- Trusts off (solo), pets on (zone misc 0x80=MISC_PET).
--
-- NPC: Apex Arbiter in Leafallia (Abdhaljs_Isle-Purgonorgo), the endgame hub.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Walk_of_Echoes_[P2]/Zone')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
local C         = require('modules/custom/lua/apex_catalog')
local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m = Module:new('apex_trials')

local SYS = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Sessions (per player, keyed by name)
-----------------------------------
local sessions = {}
xi._apex_sessions = sessions
local function getSession(player)   return sessions[player:getName()] end
local function clearSession(player) sessions[player:getName()] = nil end

-- forward declarations
local startTier, endRun, endRunByName, onTierCleared

local apexBossNames = {}
for _, name in ipairs(C.BOSS_NAMES) do
    apexBossNames[name] = true
end

local function dismissTrusts(player)
    pcall(function() player:clearTrusts() end)

    local ok, party = pcall(function() return player:getPartyWithTrusts() end)
    if not ok or not party then return end
    for _, member in ipairs(party) do
        pcall(function()
            if member:isTrust() then member:setHP(0) end
        end)
    end
end

local function killApexMob(mob)
    if type(mob) ~= 'userdata' then return false end

    pcall(function() mechanics.cleanup(mob) end)

    local killed = false
    pcall(function()
        if mob:getHP() > 0 then
            mob:setHP(0)
            killed = true
        end
    end)

    return killed
end

local function cleanupSessionMobs(sess)
    if not sess then return 0 end

    local killed = 0
    for _, mob in pairs(sess.mobsAlive or {}) do
        if killApexMob(mob) then
            killed = killed + 1
        end
    end

    return killed
end

local function cleanupStaleSessions()
    local now = os.time()
    for name, sess in pairs(sessions) do
        local climber = GetPlayerByName(name)
        local age = now - (sess.startedAt or now)
        if not climber or (climber:getZoneID() ~= C.ARENA_ZONE and age > 30) then
            sessions[name] = nil
            cleanupSessionMobs(sess)
        end
    end
end

-----------------------------------
-- Spawn one scaled Apex boss for a tier
-----------------------------------
local function spawnApexBoss(owner, tier)
    local px, pz       = owner:getXPos(), owner:getZPos()
    local py           = owner:getYPos()
    local angle        = math.random() * math.pi * 2
    -- Spawn well clear of the warp-in point. Was 9-15y -- right on top of where
    -- the player just zoned in, so a fresh climber got jumped before they could
    -- even move. 22-30y puts the boss across the arena instead.
    local dist         = 22 + math.random() * 8
    local mx           = px + math.cos(angle) * dist
    local mz           = pz + math.sin(angle) * dist
    local ownerName    = owner:getName()
    local groupId      = C.BOSS_GROUPS[math.random(#C.BOSS_GROUPS)]
    local bossName     = C.BOSS_NAMES[math.random(#C.BOSS_NAMES)]
    local level        = C.bossLevel(tier)

    local insertOk, mob = pcall(function() return owner:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = groupId,
        groupZoneId          = C.GROUP_ZONE,
        name                 = bossName,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = level,
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        -- Never auto-aggro. The boss engages ONLY its owner via the delayed
        -- enmity below -- so other climbers' bosses can't gang a player who just
        -- zoned in at the shared warp point (the reported "die on zone-in" bug).
        isAggroable          = false,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            pcall(function() mechanics.cleanup(deadMob) end)

            local ok, err = pcall(function()
                local sess = sessions[ownerName]
                if not sess then
                    if killer and killer:isPC() and killer:getName() ~= ownerName then
                        killer:printToPlayer('[Apex] That boss belonged to another climber -- no Paragon Points. Your own boss is still out there.', SYS)
                    end
                    return
                end

                local mobId = deadMob:getID()
                if not sess.mobsAlive[mobId] then return end

                sess.mobsAlive[mobId] = nil
                local resolved = GetPlayerByName(ownerName)
                if not resolved then sessions[ownerName] = nil; return end
                onTierCleared(resolved, sess)
            end)

            if not ok then
                print(string.format('[Apex] onMobDeath error for owner=%s: %s', ownerName, tostring(err)))
            end
        end,

        -- Mechanics ride the combat tick (all pcall-guarded in the library).
        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    }) end)

    if not insertOk or not mob then return nil end

    mob:setSpawn(mx, py, mz, 0)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setModelSize(3)

    -- Base tier stat mods.
    for modId, val in pairs(C.bossMods(tier)) do
        if val ~= 0 then mob:setMod(modId, val) end
    end

    -- HP + affixes (stack more at higher tiers).
    local hp        = C.bossHp(tier)
    local affixN    = C.affixCount(tier)
    local labels    = {}
    if affixN > 0 then
        local pool = {}
        for i = 1, #C.AFFIX_DEFS do pool[i] = C.AFFIX_DEFS[i] end
        for _ = 1, affixN do
            if #pool == 0 then break end
            local idx   = math.random(#pool)
            local affix = table.remove(pool, idx)
            labels[#labels + 1] = affix.key
            hp = math.floor(hp * affix.hpMult)
            for modId, val in pairs(C.affixMods(affix.key, tier)) do
                if val ~= 0 then mechanics.safeAddMod(mob, modId, val) end
            end
        end
    end

    -- FJB: clamp HP below the int32 ceiling (2,147,483,647). If future tuning or
    -- stacked affix HP multipliers push a tier over int32, setMaxHP would wrap
    -- negative and the boss could spawn already dead. 2.0B is still a huge wall;
    -- deeper difficulty continues via stat mods, affixes, and mechanics.
    hp = math.min(hp, 2000000000)
    mob:setMaxHP(hp)
    mob:setHP(hp)

    -- Engage after a short delay. 4s lets the owner move off the warp-in point;
    -- the 60s value was too long -- at high tiers fast-clearing players killed the
    -- boss before it ever engaged (reported as "mobs don't aggro you").
    owner:timer(4000, function(p)
        local s = sessions[p:getName()]
        if not s then return end
        pcall(function()
            if s.mobsAlive[mob:getID()] then
                mob:addEnmity(p, 30000, 30000)
            end
        end)
    end)

    -- Attach tier-appropriate hardcore mechanics AFTER all stats/HP are set.
    mechanics.attach(mob, C.mechCfg(tier), ownerName)

    -- If the owner disconnects/crashes or is moved out of the arena before Lua
    -- zone-out cleanup runs, this mob-side watchdog tears the run down anyway.
    local function armOwnerWatchdog(watchedMob)
        watchedMob:timer(10000, function(mobNow)
            local s = sessions[ownerName]
            if not s or s.tier ~= tier then return end

            local ownerNow = GetPlayerByName(ownerName)
            if not ownerNow or ownerNow:getZoneID() ~= C.ARENA_ZONE then
                endRunByName(ownerName, ownerNow and 'left' or 'logout')
                return
            end

            local alive = false
            pcall(function() alive = mobNow:getHP() > 0 end)
            if alive then
                armOwnerWatchdog(mobNow)
            end
        end)
    end
    armOwnerWatchdog(mob)

    return mob, bossName, level, labels
end

-----------------------------------
-- Tier cleared -> bank Paragon Points, raise record, auto-advance
-----------------------------------
onTierCleared = function(player, sess)
    local tier = sess.tier

    -- New record? (In this climb the run always starts at record+1, so every
    -- cleared tier is fresh ground -- but guard anyway so points never double.)
    local record = player:getCharVar('Apex_HighestTier') or 0
    if tier > record then
        player:setCharVar('Apex_HighestTier', tier)
        local pp = C.ppReward(tier)
        player:setCharVar('Paragon_Points', (player:getCharVar('Paragon_Points') or 0) + pp)
        player:printToPlayer(string.format(
            '[Apex] Tier %d CLEARED! +%d Paragon Points (banked). New record: %d.',
            tier, pp, tier), SYS)
    else
        player:printToPlayer(string.format('[Apex] Tier %d cleared.', tier), SYS)
    end

    player:printToPlayer(string.format('[Apex] Tier %d approaches... brace yourself.', tier + 1), SYS)

    player:timer(C.FLOOR_DELAY_MS, function(p)
        local s = sessions[p:getName()]
        if not s or s.tier ~= tier then return end
        startTier(p)
    end)
end

-----------------------------------
-- Start (or advance to) the next tier
-----------------------------------
startTier = function(player)
    local sess = getSession(player)
    if not sess then return end
    if player:getZoneID() ~= C.ARENA_ZONE then
        endRun(player, 'left')
        return
    end

    sess.tier      = sess.tier + 1
    sess.mobsAlive = {}
    local tier     = sess.tier

    local mob, bossName, level, labels = spawnApexBoss(player, tier)
    if not mob then
        player:printToPlayer('[Apex] ERROR: boss spawn failed. Ending run.', SYS)
        endRun(player, 'error')
        return
    end

    sess.mobsAlive[mob:getID()] = mob

    local affixStr = (#labels > 0) and ('  [' .. table.concat(labels, ', ') .. ']') or ''
    player:printToPlayer(string.format(
        '[Apex] TIER %d  -  %s  (Lv%d)%s', tier, bossName, level, affixStr), SYS)
end

-----------------------------------
-- End the run (death / left / abort / error)
-----------------------------------
endRun = function(player, reason)
    local sess = getSession(player)
    clearSession(player)
    cleanupSessionMobs(sess)

    local reached = sess and sess.tier or 0
    if reason == 'death' then
        player:printToPlayer(string.format(
            '[Apex] You fell at Tier %d. The climb ends -- but your Paragon Points are safe.', reached), SYS)
    elseif reason == 'left' then
        player:printToPlayer('[Apex] You left the trial. Climb ended (points kept).', SYS)
    elseif reason == 'abort' then
        player:printToPlayer('[Apex] Climb aborted (points kept).', SYS)
    end

    player:timer(3000, function(p)
        p:setPos(C.EXIT_WARP.x, C.EXIT_WARP.y, C.EXIT_WARP.z, C.EXIT_WARP.rot, C.EXIT_WARP.zoneId)
    end)
end

endRunByName = function(playerName, reason)
    local sess = sessions[playerName]
    if not sess then return end

    sessions[playerName] = nil
    cleanupSessionMobs(sess)

    local player = GetPlayerByName(playerName)
    if player and reason == 'logout' then
        player:printToPlayer('[Apex] Your climb was cleaned up after a disconnect.', SYS)
    elseif player and reason == 'left' then
        player:printToPlayer('[Apex] Your climb was cleaned up after leaving the arena.', SYS)
    end
end

-- Expose for the !apex command.
xi._apex_endRun = endRun
xi._apex_cleanupOrphans = function()
    cleanupStaleSessions()

    local zone = GetZone(C.ARENA_ZONE)
    if not zone then return 0 end

    local activeMobIds = {}
    for _, sess in pairs(sessions) do
        for mobId in pairs(sess.mobsAlive or {}) do
            activeMobIds[mobId] = true
        end
    end

    local killed = 0
    local mobs = zone:getMobs() or {}
    for _, mob in pairs(mobs) do
        pcall(function()
            local mobId = mob:getID()
            if not activeMobIds[mobId] and apexBossNames[mob:getName()] and mob:getHP() > 0 then
                if killApexMob(mob) then
                    killed = killed + 1
                end
            end
        end)
    end

    return killed
end

-----------------------------------
-- Enter the trial (called by the NPC and !apex enter)
-----------------------------------
local function enterApex(player)
    cleanupStaleSessions()
    if getSession(player) then
        player:printToPlayer('[Apex] You are already climbing! Use !apex abort to reset.', SYS)
        return
    end

    dismissTrusts(player)
    local record   = player:getCharVar('Apex_HighestTier') or 0
    local startTr  = record + 1
    -- session.tier starts one BELOW the first tier; onZoneIn advances into it.
    sessions[player:getName()] = { tier = startTr - 1, mobsAlive = {}, startedAt = os.time() }
    player:printToPlayer(string.format(
        '[Apex] Entering the climb at Tier %d (your record is %d). Solo only -- no Trusts. Pets allowed.',
        startTr, record), SYS)
    player:setPos(C.WARP_IN.x, C.WARP_IN.y, C.WARP_IN.z, C.WARP_IN.rot, C.ARENA_ZONE)
end
xi._apex_enter = enterApex

-----------------------------------
-- Overrides: arena zone-in starts the climb
-----------------------------------
m:addOverride('xi.zones.Walk_of_Echoes_[P2].Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)

    local sess = getSession(player)
    if sess and sess.tier == (player:getCharVar('Apex_HighestTier') or 0) then
        dismissTrusts(player)
        -- Arrived from the entry warp (tier still one below the first). Begin.
        -- capturedTier guards against double-fire: if onZoneIn somehow fires
        -- twice (Walk_of_Echoes_[P2] re-enters this hook under some conditions),
        -- the first 2500ms timer increments sess.tier; the second sees
        -- s.tier != capturedTier and exits cleanly -- no floor skip.
        local capturedTier = sess.tier
        player:printToPlayer('[Apex] The Apex Trials begin. Climb as far as you can!', SYS)
        player:timer(2500, function(p)
            local s = sessions[p:getName()]
            if not s or s.tier ~= capturedTier then return end
            startTier(p)
        end)
    end

    return cs
end)

-- Trusts are blocked only for players who are currently in an Apex climb.
m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if caster:getZoneID() == C.ARENA_ZONE and getSession(caster) then
        caster:printToPlayer('[Apex] Trusts are not permitted in Apex Trials.', SYS)
        return xi.msg.basic.TRUST_NO_CAST_TRUST
    end

    return super(caster, spell, notAllowedTrustIds)
end)

-- Zone-out ends the run and removes the player's active boss.
m:addOverride('xi.zones.Walk_of_Echoes_[P2].Zone.onZoneOut', function(player, ...)
    pcall(super, player, ...)
    if getSession(player) then
        endRun(player, 'left')
    end
end)

-- Death ends the run.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    if getSession(player) then
        player:timer(2000, function(p) endRun(p, 'death') end)
    end
    return cs
end)

-----------------------------------
-- Override: Leafallia - place the Apex Arbiter NPC
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Apex_Arbiter',
        packetName = string.format('%sApex Arbiter', xi.icon.STAR_LARGE),
        look       = 75,
        x          = 601.000,
        y          =   -3.360,
        z          =  526.000,
        rotation   = 135,
        widescan   =  1,

        onTrigger = function(player, npc)
            cleanupStaleSessions()
            if getSession(player) then
                player:printToPlayer('[Apex] You are already climbing! Use !apex abort to reset.', SYS)
                return
            end

            local record = player:getCharVar('Apex_HighestTier') or 0
            local pp     = player:getCharVar('Paragon_Points') or 0
            player:printToPlayer(
                '[Apex Trials] An infinite climb of scaled Apex bosses. Each NEW tier banks Paragon Points.', SYS)
            player:printToPlayer(string.format(
                '[Apex Trials] Your record: Tier %d.  Unspent Paragon Points: %d.  Next push: Tier %d.',
                record, pp, record + 1), SYS)
            player:printToPlayer(
                '[Apex Trials] Solo only (no Trusts; pets OK). Death ends the run -- but banked points are kept.', SYS)

            local options =
            {
                { 'Begin the climb', function(p) enterApex(p) end },
                { 'Not now',         function(p) end },
            }
            local snap = { title = 'Apex Trials', options = options }
            player:timer(30, function(p) p:customMenu(snap) end)
        end,
    })
    utils.unused(npc)
end)

return m
