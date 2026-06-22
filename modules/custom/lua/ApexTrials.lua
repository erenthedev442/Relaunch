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
-- Arena: Walk of Echoes (shared with the Tower -- our onZoneIn only fires for
-- players holding an Apex session, so the two never collide). Trusts are off in
-- that zone (solo), but pets work (commit 0495400f71).
--
-- NPC: Apex Arbiter in GM Home, the endgame-challenge row (x 4.5, z -35).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Walk_of_Echoes/Zone')
require('scripts/zones/GM_Home/Zone')
require('scripts/globals/job_utils/dragoon')
local C = require('modules/custom/lua/apex_catalog')

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
local startTier, endRun, onTierCleared

-----------------------------------
-- Spawn one scaled Apex boss for a tier
-----------------------------------
local function spawnApexBoss(owner, tier)
    local px, pz       = owner:getXPos(), owner:getZPos()
    local py           = owner:getYPos()
    local angle        = math.random() * math.pi * 2
    local dist         = 9 + math.random() * 6
    local mx           = px + math.cos(angle) * dist
    local mz           = pz + math.sin(angle) * dist
    local ownerName    = owner:getName()
    local groupId      = C.BOSS_GROUPS[math.random(#C.BOSS_GROUPS)]
    local bossName     = C.BOSS_NAMES[math.random(#C.BOSS_NAMES)]
    local level        = C.bossLevel(tier)

    local mob = owner:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = groupId,
        groupZoneId          = C.GROUP_ZONE,
        name                 = bossName,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = level,
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            local sess = sessions[ownerName]
            if not sess then return end
            sess.mobsAlive[deadMob:getID()] = nil
            -- Boss down -> tier cleared. Resolve the owner fresh (never touch
            -- the dead mob or a stale player ref).
            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            onTierCleared(resolved, sess)
        end,
    })

    if not mob then return nil end

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
                if val ~= 0 then mob:addMod(modId, val) end
            end
        end
    end

    mob:setMaxHP(hp)
    mob:setHP(hp)
    mob:addEnmity(owner, 30000, 30000)

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

    if sess then
        for _, mob in pairs(sess.mobsAlive or {}) do
            pcall(function() mob:setHP(0) end)
        end
    end

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

-- Expose for the !apex command.
xi._apex_endRun = endRun

-----------------------------------
-- Enter the trial (called by the NPC and !apex enter)
-----------------------------------
local function enterApex(player)
    if getSession(player) then
        player:printToPlayer('[Apex] You are already climbing! Use !apex abort to reset.', SYS)
        return
    end
    local record   = player:getCharVar('Apex_HighestTier') or 0
    local startTr  = record + 1
    -- session.tier starts one BELOW the first tier; onZoneIn advances into it.
    sessions[player:getName()] = { tier = startTr - 1, mobsAlive = {} }
    player:printToPlayer(string.format(
        '[Apex] Entering the climb at Tier %d (your record is %d). Solo only -- no Trusts. Pets allowed.',
        startTr, record), SYS)
    player:setPos(C.WARP_IN.x, C.WARP_IN.y, C.WARP_IN.z, C.WARP_IN.rot, C.ARENA_ZONE)
end
xi._apex_enter = enterApex

-----------------------------------
-- Overrides: arena zone-in starts the climb
-----------------------------------
m:addOverride('xi.zones.Walk_of_Echoes.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)

    local sess = getSession(player)
    if sess and sess.tier == (player:getCharVar('Apex_HighestTier') or 0) then
        -- Arrived from the entry warp (tier still one below the first). Begin.
        player:printToPlayer('[Apex] The Apex Trials begin. Climb as far as you can!', SYS)
        player:timer(2500, function(p)
            local s = sessions[p:getName()]
            if s then startTier(p) end
        end)
    end

    return cs
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
-- Override: GM Home - place the Apex Arbiter NPC
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Apex_Arbiter',
        packetName = string.format('%sApex Arbiter', xi.icon.STAR_LARGE),
        look       = 2401,
        x          =  4.500,
        y          =  0.000,
        z          = -35.000,
        rotation   =  128,
        widescan   =  1,

        onTrigger = function(player, npc)
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

-- Walk of Echoes (zone 182) lacks xi.zoneMisc.PET, which makes
-- abilityCheckCallWyvern return CANT_BE_USED_IN_AREA.  The arena
-- explicitly allows pets, so bypass that flag check inside the arena.
m:addOverride('xi.job_utils.dragoon.abilityCheckCallWyvern', function(player, target, ability)
    if player:getZoneID() ~= C.ARENA_ZONE then
        return super(player, target, ability)
    end
    if player:getPet() ~= nil then
        return xi.msg.basic.ALREADY_HAS_A_PET, 0
    elseif player:hasStatusEffect(xi.effect.SPIRIT_SURGE) then
        return xi.msg.basic.UNABLE_TO_USE_JA, 0
    end
    return 0, 0
end)

return m
