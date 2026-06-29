-----------------------------------
-- TheGauntlet.lua
--
-- A 10-level solo challenge in Riverne-Site_A01. At each level (1-9) the
-- player chooses between a safe advance (no combat) or a NM challenge.
-- Level 10 has no safe option: defeat Shinryu or be expelled.
--
-- Clearing level 10 grants a reward (5M gil / 500 PP / 500 Infamy)
-- and permanently spawns a named NPC champion in the Hall of Champions (B01).
--
-- Rules: No Trusts (cleared on zone-in). Pets OK. Death = expulsion.
--
-- Architecture: THREE singleton NPCs (Safe/Fight/Final) spawned ONCE per
-- session via spawnSessionNPCs. Callbacks always read live sessions[ownerName]
-- so they reflect the current level and phase — no per-level re-spawn, no NPC
-- accumulation between levels. releaseIdOnDisappear reclaims entity IDs on
-- zone restart.
--
-- Requires ONE map restart to activate (addOverride module).
--
-- CharVars:  Gauntlet_Clears  (total level-10 clears)
-- Commands:  !gauntlet abort [name]  |  !gauntlet status  (scripts/commands/)
-- Entry NPC: "The Gauntlet" in GM Home at (x=15, z=-35)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Riverne-Site_A01/Zone')
require('scripts/zones/Riverne-Site_B01/Zone')
require('scripts/zones/Leafallia/Zone')

local C   = require('modules/custom/lua/gauntlet_catalog')

local m   = Module:new('the_gauntlet')
local SYS = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Session state (keyed by playerName)
-- phase: 'choose' | 'fight' | 'advancing'
-----------------------------------
local sessions = {}
xi._gauntlet_sessions = sessions

local function getSession(player)   return sessions[player:getName()] end
local function clearSession(player) sessions[player:getName()] = nil end

-----------------------------------
-- Forward declarations
-----------------------------------
local spawnSessionNPCs, spawnNM, advanceLevel, endRun

-----------------------------------
-- Champion file persistence
-----------------------------------
local function loadChampions()
    local ok, fn = pcall(loadfile, C.CHAMPION_DATA_FILE)
    if ok and fn then
        local ok2, data = pcall(fn)
        if ok2 and type(data) == 'table' then return data end
    end
    return {}
end

local function saveChampion(charname, charid)
    local data = loadChampions()
    local found = false
    for _, c in ipairs(data) do
        if c.charname == charname then
            c.times  = (c.times or 1) + 1
            c.latest = os.date('%Y-%m-%d')
            found = true
            break
        end
    end
    if not found then
        table.insert(data, {
            charname = charname,
            charid   = charid,
            latest   = os.date('%Y-%m-%d'),
            times    = 1,
        })
    end

    local f = io.open(C.CHAMPION_DATA_FILE, 'w')
    if not f then return end
    f:write('-- gauntlet_champion_data.lua (auto-updated by TheGauntlet.lua)\nreturn {\n')
    for _, c in ipairs(data) do
        f:write(string.format(
            '    { charname = %q, charid = %d, latest = %q, times = %d },\n',
            c.charname, c.charid, c.latest, c.times))
    end
    f:write('}\n')
    f:close()
end

-----------------------------------
-- Final clear reward
-----------------------------------
local function grantFinalReward(player)
    local r = C.FINAL_REWARD
    player:addGil(r.gil)
    player:setCharVar('Paragon_Points',
        (player:getCharVar('Paragon_Points') or 0) + r.pp)
    player:setCharVar('Infamy',
        (player:getCharVar('Infamy') or 0) + r.infamy)
    local clears = (player:getCharVar('Gauntlet_Clears') or 0) + 1
    player:setCharVar('Gauntlet_Clears', clears)

    player:printToPlayer('[The Gauntlet] *** THE GAUNTLET IS CONQUERED! ***', SYS)
    player:printToPlayer(string.format(
        '[The Gauntlet] Reward: %dM gil, +%d Paragon Points, +%d Infamy.',
        math.floor(r.gil / 1000000), r.pp, r.infamy), SYS)
    player:printToPlayer(
        '[The Gauntlet] Your legend is etched in the Hall of Champions forever.', SYS)

    saveChampion(player:getName(), player:getID())
end

-----------------------------------
-- End run (death / left / abort / error)
-----------------------------------
endRun = function(player, reason)
    local sess = getSession(player)
    clearSession(player)

    if sess and sess.nm then
        pcall(function() sess.nm:setHP(0) end)
    end

    local lvl = sess and sess.level or 0
    if reason == 'death' then
        player:printToPlayer(string.format(
            '[The Gauntlet] You fell at Level %d. The Gauntlet claims another soul.', lvl), SYS)
    elseif reason == 'left' then
        player:printToPlayer('[The Gauntlet] You fled the Gauntlet. Return when worthy.', SYS)
    elseif reason == 'abort' then
        player:printToPlayer('[The Gauntlet] Run aborted.', SYS)
    end

    player:timer(2500, function(p)
        p:setPos(C.EXIT_POS.x, C.EXIT_POS.y, C.EXIT_POS.z, C.EXIT_POS.rot, C.EXIT_POS.zoneId)
    end)
end

xi._gauntlet_endRun = endRun

-----------------------------------
-- Spawn the level's NM
-----------------------------------
spawnNM = function(player, session)
    local level     = session.level
    local nm        = C.NM_POOL[level]
    local ownerName = player:getName()

    local px = C.WARP_IN.x
    local py = C.WARP_IN.y
    local pz = C.WARP_IN.z
    local mx = px + C.NM_SPAWN_OFFSET.x
    local mz = pz + C.NM_SPAWN_OFFSET.z

    local mob = player:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = nm.groupId,
        groupZoneId          = C.GROUP_ZONE,
        name                 = nm.name,
        x = mx, y = py, z = mz,
        rotation             = 180,
        minLevel             = C.nmLevel(level),
        maxLevel             = C.nmLevel(level),
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            local sess = sessions[ownerName]
            if not sess then return end
            sess.nm    = nil
            sess.level = sess.level + 1
            sess.phase = 'advancing'
            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            resolved:printToPlayer(string.format(
                '[The Gauntlet] %s is defeated! Level %d cleared!',
                nm.name, level), SYS)
            resolved:timer(2500, function(p)
                local s = sessions[p:getName()]
                if s then advanceLevel(p, s) end
            end)
        end,

        onMobFight = function() end,
    })

    if not mob then
        player:printToPlayer('[The Gauntlet] ERROR: spawn failed. Aborting.', SYS)
        endRun(player, 'error')
        return
    end

    mob:setSpawn(mx, py, mz, 0)
    local hp = C.nmHp(level)
    mob:setMaxHP(hp)    -- must be before spawn() or template resets it
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setModelSize(3)
    mob:setHP(hp)
    -- Mods are int16: a value >32767 wraps NEGATIVE (the Lv10 boss ATT 36000 would
    -- spawn at ~-29.5k = ~0 attack, not max). Clamp <=31000 so the apex is hard.
    for modId, val in pairs(C.nmMods(level)) do
        if val ~= 0 then mob:setMod(modId, math.min(val, 31000)) end
    end
    mob:addEnmity(player, 30000, 30000)

    session.nm    = mob
    session.phase = 'fight'

    player:printToPlayer(string.format(
        '[The Gauntlet] Level %d — %s  (Lv%d / %s HP)',
        level, nm.name, C.nmLevel(level), C.formatHp(hp)), SYS)
    player:printToPlayer('[The Gauntlet] Defeat it to advance. Death ends your run.', SYS)
end

-----------------------------------
-- Advance to next level (called after NM kill or Safe Path click)
-- session.level is already the NEW level when this is called.
-----------------------------------
advanceLevel = function(player, session)
    if not session then return end
    local level = session.level  -- already incremented by caller

    if level > 10 then
        -- Post-Shinryu kill: final clear
        grantFinalReward(player)
        clearSession(player)
        player:timer(6000, function(p)
            p:setPos(C.EXIT_POS.x, C.EXIT_POS.y, C.EXIT_POS.z, C.EXIT_POS.rot, C.EXIT_POS.zoneId)
        end)
        return
    end

    session.phase = 'choose'

    if level == 10 then
        player:printToPlayer('[The Gauntlet] Level 10: the final trial. No retreat.', SYS)
        player:printToPlayer('[The Gauntlet] Face Shinryu and earn your legend — or be expelled.', SYS)
        player:printToPlayer('[The Gauntlet] Approach the Final Trial NPC when ready.', SYS)
    else
        local nm = C.NM_POOL[level]
        player:printToPlayer(string.format('[The Gauntlet] Level %d reached.', level), SYS)
        player:printToPlayer(string.format(
            '[The Gauntlet] Safe Path (no combat) or Challenge: %s  (Lv%d / %s HP)?',
            nm.name, C.nmLevel(level), C.formatHp(C.nmHp(level))), SYS)
    end
end

-----------------------------------
-- Spawn all three session NPCs exactly once.
-- Safe/Fight respond at levels 1-9; Final responds only at level 10.
-- All callbacks read live sessions[ownerName] for current state, so the same
-- three NPCs handle every level transition without re-spawning.
-----------------------------------
spawnSessionNPCs = function(player, session)
    local ownerName = player:getName()
    local px = C.WARP_IN.x
    local py = C.WARP_IN.y
    local pz = C.WARP_IN.z

    -- Safe Path NPC (levels 1-9)
    player:getZone():insertDynamicEntity({
        objtype              = xi.objType.NPC,
        name                 = string.format('G_Safe_%s', ownerName),
        packetName           = string.format('%sSafe Path', xi.icon.STAR_LARGE),
        look                 = 2419,
        x = px + C.SAFE_NPC_OFFSET.x, y = py, z = pz + C.SAFE_NPC_OFFSET.z,
        rotation             = 0,
        widescan             = 0,
        releaseIdOnDisappear = true,

        onTrigger = function(trigPlayer, npc)
            if trigPlayer:getName() ~= ownerName then return end
            local sess = sessions[ownerName]
            if not sess then return end
            if sess.level == 10 then
                trigPlayer:printToPlayer(
                    '[The Gauntlet] No safe path at level 10. Use the Final Trial NPC.', SYS)
                return
            end
            if sess.phase ~= 'choose' then return end

            local level = sess.level
            sess.phase = 'advancing'
            sess.level = sess.level + 1

            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            resolved:printToPlayer(string.format(
                '[The Gauntlet] Safe path taken. Level %d bypassed.', level), SYS)
            resolved:timer(1200, function(p)
                local s = sessions[p:getName()]
                if s then advanceLevel(p, s) end
            end)
        end,
    })

    -- Challenge NPC (levels 1-9)
    player:getZone():insertDynamicEntity({
        objtype              = xi.objType.NPC,
        name                 = string.format('G_Fight_%s', ownerName),
        packetName           = string.format('%sChallenge', xi.icon.SWORD),
        look                 = 2419,
        x = px + C.FIGHT_NPC_OFFSET.x, y = py, z = pz + C.FIGHT_NPC_OFFSET.z,
        rotation             = 0,
        widescan             = 0,
        releaseIdOnDisappear = true,

        onTrigger = function(trigPlayer, npc)
            if trigPlayer:getName() ~= ownerName then return end
            local sess = sessions[ownerName]
            if not sess or sess.phase ~= 'choose' or sess.level > 9 then return end

            sess.phase = 'fight'

            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            spawnNM(resolved, sess)
        end,
    })

    -- Final Trial NPC (level 10 only)
    player:getZone():insertDynamicEntity({
        objtype              = xi.objType.NPC,
        name                 = string.format('G_Final_%s', ownerName),
        packetName           = string.format('%sFinal Trial', xi.icon.STAR_LARGE),
        look                 = 2419,
        x = px, y = py, z = pz + 8,
        rotation             = 0,
        widescan             = 0,
        releaseIdOnDisappear = true,

        onTrigger = function(trigPlayer, npc)
            if trigPlayer:getName() ~= ownerName then return end
            local sess = sessions[ownerName]
            if not sess or sess.phase ~= 'choose' then return end
            if sess.level ~= 10 then
                trigPlayer:printToPlayer(
                    '[The Gauntlet] This path opens only at level 10.', SYS)
                return
            end

            sess.phase = 'fight'

            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            resolved:printToPlayer('[The Gauntlet] Shinryu descends!', SYS)
            spawnNM(resolved, sess)
        end,
    })
end

-----------------------------------
-- Enter The Gauntlet (called by entry NPC)
-----------------------------------
local function enterGauntlet(player)
    if getSession(player) then
        player:printToPlayer('[The Gauntlet] You are already in a run. Use !gauntlet abort to reset.', SYS)
        return
    end
    sessions[player:getName()] = { level = 1, phase = 'choose', nm = nil, npcsSpawned = false }
    player:printToPlayer('[The Gauntlet] Entering the arena. Trusts are not permitted.', SYS)
    player:setPos(C.WARP_IN.x, C.WARP_IN.y, C.WARP_IN.z, C.WARP_IN.rot, C.ARENA_ZONE)
end

-----------------------------------
-- Override: Riverne-Site_A01 zone-in → start the run
-----------------------------------
m:addOverride('xi.zones.Riverne-Site_A01.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    local sess = getSession(player)
    if sess then
        pcall(function() player:clearTrusts() end)
        player:timer(2000, function(p)
            local s = sessions[p:getName()]
            if not s then return end
            -- Spawn once per session; npcsSpawned guards against reconnect re-spawning.
            if not s.npcsSpawned then
                s.npcsSpawned = true
                spawnSessionNPCs(p, s)
            end
            -- Announce current state
            if s.level == 10 then
                p:printToPlayer('[The Gauntlet] Level 10: defeat Shinryu. No retreat.', SYS)
                p:printToPlayer('[The Gauntlet] Approach the Final Trial NPC when ready.', SYS)
            else
                local nm = C.NM_POOL[s.level]
                p:printToPlayer(string.format(
                    '[The Gauntlet] Level %d — Safe Path or Challenge: %s  (Lv%d / %s HP).',
                    s.level, nm and nm.name or '?',
                    C.nmLevel(s.level), C.formatHp(C.nmHp(s.level))), SYS)
            end
            p:printToPlayer('[The Gauntlet] No Trusts. Defeat each level or take the safe path.', SYS)
        end)
    end
    return cs
end)

-- Zone-out ends the run
m:addOverride('xi.zones.Riverne-Site_A01.Zone.onZoneOut', function(player, ...)
    pcall(super, player, ...)
    if getSession(player) then
        endRun(player, 'left')
    end
end)

-- Death in the arena ends the run
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    if getSession(player) and player:getZoneID() == C.ARENA_ZONE then
        player:timer(2000, function(p) endRun(p, 'death') end)
    end
    return cs
end)

-----------------------------------
-- Override: Riverne-Site_B01 onInitialize → Hall of Champions
-----------------------------------
m:addOverride('xi.zones.Riverne-Site_B01.Zone.onInitialize', function(zone)
    super(zone)

    local champions = loadChampions()
    if #champions == 0 then return end

    local baseX = C.HALL_IN.x
    local py    = C.HALL_IN.y
    local pz    = C.HALL_IN.z - 20

    for i, c in ipairs(champions) do
        local npcX = baseX + (i - 1) * 6
        local info = c  -- capture for closure
        zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = string.format('Champion_%s', info.charname),
            packetName = string.format('%s%s', xi.icon.STAR_LARGE, info.charname),
            look       = C.CHAMPION_LOOK,
            x = npcX, y = py, z = pz,
            rotation   = 128,
            widescan   = 1,

            onTrigger = function(p, npc)
                local times = info.times or 1
                p:printToPlayer(string.format(
                    '[Hall of Champions] %s — conquered The Gauntlet %s.',
                    info.charname,
                    times == 1 and 'once' or (times .. ' times')), SYS)
                p:printToPlayer(string.format(
                    '[Hall of Champions] Last clear: %s.', info.latest or '?'), SYS)
            end,
        })
    end
end)

-----------------------------------
-- Override: GM Home onInitialize → place the Gauntlet Keeper NPC
-----------------------------------
m:addOverride('xi.zones.Leafallia.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Gauntlet_Keeper',
        packetName = string.format('%sThe Gauntlet', xi.icon.SWORD_AND_SHIELD),
        look       = 2410,
        x          = -20.000,
        y          =   0.000,
        z          =  20.000,
        rotation   =  128,
        widescan   =  1,

        onTrigger = function(player, npc)
            local clears = player:getCharVar('Gauntlet_Clears') or 0
            player:printToPlayer(
                '[The Gauntlet] Ten escalating levels of solo combat in Riverne Site A01.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Levels 1-9: Safe Path (skip) or fight the NM.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Level 10: NO safe path — defeat Shinryu and earn your legend.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Reward: 5,000,000 gil | 500 Paragon Points | 500 Infamy.', SYS)
            if clears > 0 then
                player:printToPlayer(string.format(
                    '[The Gauntlet] Your clear count: %d. The legend grows.', clears), SYS)
            end

            local options = {
                { 'Enter The Gauntlet', function(p) enterGauntlet(p) end },
                { 'About Champions',    function(p)
                    p:printToPlayer('[The Gauntlet] Champions are enshrined in Riverne Site B01.', SYS)
                end },
                { 'Close', function(p) end },
            }
            player:timer(30, function(p)
                p:customMenu({ title = 'The Gauntlet', options = options })
            end)
        end,
    })
end)

return m
