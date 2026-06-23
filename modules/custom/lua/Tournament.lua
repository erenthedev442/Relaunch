-----------------------------------
-- Tournament.lua
-- Last-team-standing PvE wave tournament.
--
-- Players register with an optional team name. Each TEAM fights their own
-- independent mob waves spawned around their position. Mobs aggro every
-- alive member of the team, so teammates share the load. A team is only
-- eliminated when ALL its members are KO'd. The last team standing wins.
-- Solo players (no team name) are a team of one.
-- Trusts are not allowed.
--
-- REGISTRATION:
--   !tournament join              -- join solo (team = your name)
--   !tournament join <teamname>   -- join or create a named team
--
-- COMMANDS (shim: modules/custom/commands/tournament.lua):
--   !tournament                   show status
--   !tournament join [teamname]   register / join a team
--   !tournament leave             withdraw (sign-up phase only)
--   GM only:
--   !tournament open              open sign-ups
--   !tournament start             warp all entrants in, begin waves
--   !tournament cancel            abort, warp everyone home
--   !tournament kick <name>       eliminate a player mid-run or remove from sign-ups
--   !tournament team <pl> <team>  reassign a player to a different team (sign-up phase)
--
-- Requires map restart (addOverride hooks).
-----------------------------------

require('modules/module_utils')

local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m = Module:new('tournament')

-- ─── config ───────────────────────────────────────────────────────────────────

local ARENA_ZONE = 206           -- Qu'Bia Arena
local ARENA_CX   = -241.046      -- arena centre
local ARENA_CY   = -25.86
local ARENA_CZ   =  19.991
local RING_MIN   = 8             -- mob spawn ring around each team's position
local RING_MAX   = 16
local TEAM_SEP   = 60            -- distance between team spawn positions
local HOME_ZONE  = xi.zone.GM_HOME
local HOME_X, HOME_Y, HOME_Z = -4.0, 0.0, -2.0
local GROUP_ZONE = 210           -- GM_Home: where mob_groups are registered

local WAVE_DELAY  = 5    -- grace seconds before wave 1
local CLEAR_DELAY = 6    -- seconds between cleared wave and the next one

-- Player spawn jitter within their team's position (spread teammates slightly)
local MEMBER_JITTER = 5

-- Mob groups from GM_Home zone (same pool as Endless Tower).
local WAVES = {
    { label = 'Wave 1',  count = 3, level = 110, hpMult = 6,   groups = { 11355, 11356 } },
    { label = 'Wave 2',  count = 4, level = 130, hpMult = 10,  groups = { 11357, 11358 } },
    { label = 'Wave 3',  count = 4, level = 150, hpMult = 16,  groups = { 11359, 11360 } },
    { label = 'Wave 4',  count = 5, level = 170, hpMult = 24,  groups = { 11361, 11362 } },
    { label = 'Wave 5',  count = 5, level = 190, hpMult = 36,  groups = { 11363, 11364 } },
    { label = 'Wave 6',  count = 6, level = 210, hpMult = 52,  groups = { 11365, 11366 } },
    { label = 'Wave 7',  count = 6, level = 230, hpMult = 72,  groups = { 11367, 11368 } },
    { label = 'Wave 8',  count = 7, level = 250, hpMult = 96,  groups = { 11368, 11369 } },
}

-- ─── Wave 8 Champion mechanics ────────────────────────────────────────────────
-- The final wave (Wave 8) has no explicit boss entity — all 7 mobs are level-250
-- juggernauts. The FIRST mob spawned in Wave 8 (i==1, waveNum==8) is designated
-- the "Tournament Champion" and receives the full hardcore kit. The remaining 6
-- are left vanilla (mechanics.tick() is a safe no-op on un-attached mobs).
--
-- addGroupId = 11368  (Wave 8 groups[1] — already spawned by this wave)
-- addZoneId  = 210    (GROUP_ZONE — where all Tournament mob_groups are registered)
local CHAMPION_MECH_CFG = {
    name = 'Tournament Champion',

    -- 3-minute DPS check: if it's still alive it enters a permanent frenzy.
    enrage = { sec = 180, att = 5000, haste = 200,
               msg = 'The Champion is ENRAGED — finish it NOW!' },

    -- Stance dance: alternates physical/magical resist from 90% HP downward.
    -- Caps at -5000 (=-50% taken) per library rules.
    stance = {
        startHpp  = 90,
        periodSec = 16,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },
              msg = 'The Champion fortifies against weapons — use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -5000 },
              msg = 'The Champion disperses spells — use weapons!' },
        },
    },

    -- AoE shockwave every 12s (22% of each nearby player's max HP).
    aoe   = { periodSec = 12, dmgPct = 22,
              msg = 'The Champion unleashes a thunderous shockwave!' },

    -- Terror roar every 22s.
    cc    = { periodSec = 22, effect = xi.effect.TERROR, dur = 5,
              msg = 'The Champion lets out a spine-shattering roar!' },

    -- Anti-turtle drain: heals 2% max HP every 8s.
    drain = { periodSec = 8, healPct = 2 },

    -- HP-gated phases.
    phases = {
        -- 75% HP: summons Wave-8 Heralds (adds regen hard until they die).
        { hp = 75, action = 'adds', count = 3,
          addGroupId = 11368, addZoneId = 210,
          addName = 'Tournament Herald', addLevel = 250,
          regen = 18000,
          msg = 'The Champion summons its Heralds — cut them down!' },

        -- 50% HP: void-rift nuke (40% of each player's max HP AoE).
        { hp = 50, action = 'nuke', dmgPct = 40,
          msg = 'The Champion tears open the arena floor — evacuate!' },

        -- 40% HP: dispels up to 4 buffs from every nearby player.
        { hp = 40, action = 'dispel', count = 4,
          msg = 'The Champion strips your enhancements!' },

        -- 25% HP: fury — ATT surge + haste.
        { hp = 25, action = 'fury', att = 4000, haste = 120,
          msg = 'The Champion enters a blood-fury!' },

        -- 10% HP: doom phase — finish it fast or die.
        { hp = 10, action = 'doom', dur = 25,
          msg = 'The Champion marks you for death — end this!' },
    },

    -- Doom aura at 12% HP (double pressure alongside the phase above).
    doom = { startHpp = 12, dur = 30,
             msg = 'The Champion\'s shadow consumes you!' },
}

-- ─── state ────────────────────────────────────────────────────────────────────

local tourney = {
    phase    = 'idle',  -- 'idle' | 'open' | 'running'
    -- Pre-start: entrants[playerName] = teamName
    entrants = {},
}

-- Live per-team sessions (populated at start, cleared as teams are eliminated)
-- sessions[teamName] = {
--   wave    = N,
--   mobs    = { [id] = true },    -- alive mob IDs this wave
--   mobRefs = { [id] = mob },     -- refs for cleanup on team elimination
--   alive   = { [name] = true },  -- team members still in the arena
--   spawnX  = x,
--   spawnZ  = z,
-- }
local sessions = {}

-- Reverse lookup: playerTeam[playerName] = teamName (populated at start)
local playerTeam = {}

xi._tournament = tourney  -- expose for command shim

-- ─── helpers ──────────────────────────────────────────────────────────────────

local function announce(msg)
    SendToGroup(msg, xi.msg.target.ALL)
end

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function teamsAlive()
    local n = 0
    for _ in pairs(sessions) do n = n + 1 end
    return n
end

local function dismissTrusts(player)
    local party = player:getPartyWithTrusts()
    if not party then return end
    for _, member in ipairs(party) do
        if member:isTrust() then member:setHP(0) end
    end
end

local function warpOut(player)
    player:setCharVar('TournamentInArena', 0)
    player:setPos(HOME_X, HOME_Y, HOME_Z, 0, HOME_ZONE)
end

-- Spread team spawn positions in a circle around the arena centre.
-- With TEAM_SEP=60 and ring max 16 there is a ~28-unit buffer between rings.
local function calcTeamSpawn(index, total)
    if total == 1 then return ARENA_CX, ARENA_CZ end
    local angle = ((index - 1) / total) * math.pi * 2
    return ARENA_CX + math.cos(angle) * TEAM_SEP,
           ARENA_CZ + math.sin(angle) * TEAM_SEP
end

-- Build a display string for a session: "TeamAlpha(w3, Alice,Bob)"
local function teamStatus(teamName, sess)
    local members = {}
    for n in pairs(sess.alive) do members[#members+1] = n end
    return string.format('%s(w%d: %s)', teamName, sess.wave, table.concat(members, ','))
end

-- ─── forward declaration ──────────────────────────────────────────────────────

local startWaveForTeam

-- ─── wave logic ───────────────────────────────────────────────────────────────

local function onWaveClearedForTeam(teamName, waveNum)
    if tourney.phase ~= 'running' then return end
    local sess = sessions[teamName]
    if not sess then return end

    local nextWave = waveNum + 1
    local cfg      = WAVES[nextWave]
    local rem      = teamsAlive()

    if not cfg then
        -- Cleared all 8 waves - this team wins
        announce(string.format('[Tournament] *** Team %s CLEARED ALL WAVES - Champions! *** (%d team(s) remain)',
            teamName, rem - 1))
        -- Warp survivors out
        for pname in pairs(sess.alive) do
            GetTimerManager():addTimer('tourney_warp_' .. pname, 5000, false, function()
                local p = GetPlayerByName(pname)
                if p then warpOut(p) end
            end)
        end
        sessions[teamName] = nil
        if teamsAlive() == 0 then tourney.phase = 'idle' end
        return
    end

    announce(string.format('[Tournament] Team %s cleared wave %d! %s in %ds. (%d team(s) alive)',
        teamName, waveNum, cfg.label, CLEAR_DELAY, rem))

    GetTimerManager():addTimer('tourney_next_' .. teamName, CLEAR_DELAY * 1000, false, function()
        if tourney.phase == 'running' and sessions[teamName] then
            startWaveForTeam(teamName, nextWave)
        end
    end)
end

startWaveForTeam = function(teamName, waveNum)
    if tourney.phase ~= 'running' then return end
    local sess = sessions[teamName]
    if not sess then return end

    local cfg  = WAVES[waveNum]
    if not cfg then onWaveClearedForTeam(teamName, waveNum - 1); return end

    sess.wave    = waveNum
    sess.mobs    = {}
    sess.mobRefs = {}

    local zone = GetZone(ARENA_ZONE)
    if not zone then return end

    -- Scale mob HP with team size so larger teams still have a challenge
    local teamSize = count(sess.alive)
    local hpScale  = cfg.hpMult * math.max(1, teamSize * 0.6)

    -- Notify members
    for pname in pairs(sess.alive) do
        local p = GetPlayerByName(pname)
        if p then
            p:printToPlayer(string.format('[Tournament] %s - %d mobs, level %d.',
                cfg.label, cfg.count, cfg.level))
        end
    end

    for i = 1, cfg.count do
        local angle   = math.random() * math.pi * 2
        local dist    = RING_MIN + math.random() * (RING_MAX - RING_MIN)
        local mx      = sess.spawnX + math.cos(angle) * dist
        local mz      = sess.spawnZ + math.sin(angle) * dist
        local groupId = cfg.groups[((i - 1) % #cfg.groups) + 1]

        local mob = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = groupId,
            groupZoneId          = GROUP_ZONE,
            name                 = teamName .. ' Wave ' .. waveNum,
            x                    = mx,
            y                    = ARENA_CY,
            z                    = mz,
            rotation             = math.random(0, 255),
            minLevel             = cfg.level,
            maxLevel             = cfg.level,
            detection            = xi.detects.SIGHT_AND_HEARING,
            isAggroable          = true,
            releaseIdOnDisappear = true,

            onMobDeath = function(deadMob, killer)
                mechanics.cleanup(deadMob)  -- frees champion state + despawns its Heralds (no-op on non-champion mobs)
                local s = sessions[teamName]
                if not s then return end
                s.mobs[deadMob:getID()]    = nil
                s.mobRefs[deadMob:getID()] = nil
                if not next(s.mobs) then
                    onWaveClearedForTeam(teamName, waveNum)
                end
            end,

            -- Mechanics tick: no-op for any mob without an attached config
            -- (all non-champion mobs), so safe to call unconditionally here.
            onMobFight = function(mfMob, mfTarget)
                mechanics.tick(mfMob, mfTarget)
            end,
        })

        if mob then
            mob:setSpawn(mx, ARENA_CY, mz, 0)
            mob:spawn()
            mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
            local newMax = math.floor(mob:getMaxHP() * hpScale)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
            -- Wave 8, first mob spawned (i==1) is the Tournament Champion.
            -- Attach the full hardcore kit AFTER spawn + HP setup so the library
            -- reads the correct max HP. The other 6 Wave-8 mobs and ALL mobs in
            -- waves 1-7 are left vanilla — mechanics.tick() no-ops for them.
            if waveNum == 8 and i == 1 then
                mechanics.attach(mob, CHAMPION_MECH_CFG)
            end
            -- Aggro every alive member of this team
            for pname in pairs(sess.alive) do
                local p = GetPlayerByName(pname)
                if p then mob:addEnmity(p, 30000, 30000) end
            end
            sess.mobs[mob:getID()]    = true
            sess.mobRefs[mob:getID()] = mob
        end
    end
end

-- ─── team elimination ─────────────────────────────────────────────────────────

local function eliminateTeam(teamName, reason)
    local sess = sessions[teamName]
    if not sess then return end

    -- Kill any remaining mobs so they don't wander
    local savedRefs = sess.mobRefs
    sessions[teamName] = nil  -- nil first so onMobDeath callbacks bail early
    for _, mob in pairs(savedRefs) do
        if mob then mob:setHP(0) end
    end

    local rem = teamsAlive()
    announce(string.format('[Tournament] Team %s eliminated (%s). %d team(s) remain.',
        teamName, reason, rem))

    if rem == 1 then
        local winner
        for n in pairs(sessions) do winner = n end
        local ws = sessions[winner]
        local names = {}
        if ws then for n in pairs(ws.alive) do names[#names+1] = n end end
        announce(string.format('[Tournament] *** Team %s is the LAST TEAM STANDING - Champions! *** (%s)',
            winner, table.concat(names, ', ')))
        -- Warp winners out after a moment
        if ws then
            for _, pname in ipairs(names) do
                GetTimerManager():addTimer('tourney_warp_' .. pname, 8000, false, function()
                    local p = GetPlayerByName(pname)
                    if p then warpOut(p) end
                end)
            end
        end
        sessions[winner]   = nil
        tourney.phase      = 'idle'

    elseif rem == 0 then
        announce('[Tournament] All teams have been eliminated. No winners.')
        tourney.phase = 'idle'
    end
end

tourney.eliminateTeam = eliminateTeam  -- expose for command shim

-- ─── player death override ────────────────────────────────────────────────────

m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    if tourney.phase ~= 'running' then return end

    local pname = player:getName()
    local tname = playerTeam[pname]
    if not tname then return end

    local sess = sessions[tname]
    if not sess or not sess.alive[pname] then return end

    sess.alive[pname]  = nil
    playerTeam[pname]  = nil

    local membersLeft = count(sess.alive)

    -- Delayed warp
    GetTimerManager():addTimer('tourney_warp_' .. pname, 3000, false, function()
        local p = GetPlayerByName(pname)
        if p then warpOut(p) end
    end)

    if membersLeft > 0 then
        -- Team still has survivors - just announce the KO
        announce(string.format('[Tournament] %s (Team %s) was KO\'d. %d teammate(s) remain.',
            pname, tname, membersLeft))
        -- Re-assert enmity on remaining members so mobs don't go idle
        for mobId, mob in pairs(sess.mobRefs) do
            for remainingName in pairs(sess.alive) do
                local rp = GetPlayerByName(remainingName)
                if rp then mob:addEnmity(rp, 1000, 1000) end
            end
        end
    else
        -- Last member down - team is out
        eliminateTeam(tname, pname .. ' KO (last member)')
    end
end)

-- ─── trust blocking ───────────────────────────────────────────────────────────

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if caster:getCharVar('TournamentInArena') == 1 then
        caster:printToPlayer('[Tournament] Trusts are not permitted in the arena.')
        return xi.msg.basic.TRUST_NO_CAST_TRUST
    end
    return super(caster, spell, notAllowedTrustIds)
end)

m:addOverride('xi.zones.QuBia_Arena.Zone.onZoneIn', function(player, prevZone)
    super(player, prevZone)
    local tname = playerTeam[player:getName()]
    if tname and sessions[tname] then
        dismissTrusts(player)
    end
end)

-- ─── command handler ──────────────────────────────────────────────────────────

tourney.handleCmd = function(player, sub, a2, a3)
    local isGM   = player:getGMLevel() >= 1
    local pname  = player:getName()
    sub = sub and string.lower(sub) or ''

    -- ── STATUS ───────────────────────────────────────────────────────────────
    if sub == '' or sub == 'status' then
        if tourney.phase == 'idle' then
            player:printToPlayer('[Tournament] No tournament is running.')

        elseif tourney.phase == 'open' then
            -- Group entrants by team for display
            local teams = {}
            for name, tname in pairs(tourney.entrants) do
                teams[tname] = teams[tname] or {}
                teams[tname][#teams[tname]+1] = name
            end
            local lines = {}
            for tname, members in pairs(teams) do
                lines[#lines+1] = string.format('  %s: %s', tname, table.concat(members, ', '))
            end
            player:printToPlayer(string.format('[Tournament] SIGN-UPS OPEN - %d team(s):', #lines))
            for _, line in ipairs(lines) do player:printToPlayer(line) end
            player:printToPlayer('[Tournament] !tournament join [teamname] to enter.')

        else
            local parts = {}
            for tname, sess in pairs(sessions) do
                parts[#parts+1] = teamStatus(tname, sess)
            end
            player:printToPlayer(string.format('[Tournament] RUNNING - %d team(s): %s',
                #parts, table.concat(parts, '  |  ')))
        end

    -- ── JOIN ─────────────────────────────────────────────────────────────────
    elseif sub == 'join' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Sign-ups are not open.'); return
        end
        if tourney.entrants[pname] then
            player:printToPlayer(string.format('[Tournament] Already registered (Team %s). Use !tournament leave to switch.',
                tourney.entrants[pname])); return
        end
        local tname = (a2 and a2 ~= '') and a2 or pname  -- default = solo team
        tourney.entrants[pname] = tname

        -- Count how many are now on this team
        local n = 0
        for _, t in pairs(tourney.entrants) do if t == tname then n = n + 1 end end

        if n == 1 then
            announce(string.format('[Tournament] %s joined as Team %s!', pname, tname))
        else
            announce(string.format('[Tournament] %s joined Team %s (%d members).', pname, tname, n))
        end

    -- ── LEAVE ────────────────────────────────────────────────────────────────
    elseif sub == 'leave' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Cannot withdraw after the tournament starts.'); return
        end
        if not tourney.entrants[pname] then
            player:printToPlayer('[Tournament] You are not registered.'); return
        end
        local tname = tourney.entrants[pname]
        tourney.entrants[pname] = nil
        announce(string.format('[Tournament] %s left Team %s.', pname, tname))

    elseif not isGM then
        player:printToPlayer('[Tournament] Subcommands: join [teamname], leave, status.')

    -- ── GM: OPEN ─────────────────────────────────────────────────────────────
    elseif sub == 'open' then
        if tourney.phase ~= 'idle' then
            player:printToPlayer('[Tournament] A tournament is already active.'); return
        end
        tourney.phase    = 'open'
        tourney.entrants = {}
        announce('[Tournament] A Tournament has opened! Use !tournament join [teamname] to enter.')
        announce('[Tournament] Teams share mob waves. No trusts. Last team standing wins.')

    -- ── GM: START ────────────────────────────────────────────────────────────
    elseif sub == 'start' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Not in sign-up phase.'); return
        end
        if count(tourney.entrants) == 0 then
            player:printToPlayer('[Tournament] No entrants.'); return
        end

        -- Build team map: teamName -> [playerNames]
        local teamMap = {}
        for name, tname in pairs(tourney.entrants) do
            teamMap[tname] = teamMap[tname] or {}
            teamMap[tname][#teamMap[tname]+1] = name
        end

        tourney.phase = 'running'
        sessions      = {}
        playerTeam    = {}

        local teamList = {}
        for tname in pairs(teamMap) do teamList[#teamList+1] = tname end
        local numTeams = #teamList

        announce(string.format('[Tournament] TOURNAMENT BEGINS! %d team(s), %d player(s) total.',
            numTeams, count(tourney.entrants)))

        for i, tname in ipairs(teamList) do
            local members = teamMap[tname]
            local sx, sz  = calcTeamSpawn(i, numTeams)

            sessions[tname] = { wave = 0, mobs = {}, mobRefs = {}, alive = {}, spawnX = sx, spawnZ = sz }

            for j, mname in ipairs(members) do
                local p = GetPlayerByName(mname)
                if p and p:isOnline() then
                    dismissTrusts(p)
                    p:setCharVar('TournamentInArena', 1)
                    -- Spread teammates slightly around the team spawn
                    local jx = (math.random() - 0.5) * MEMBER_JITTER * 2
                    local jz = (math.random() - 0.5) * MEMBER_JITTER * 2
                    p:setPos(sx + jx, ARENA_CY, sz + jz, 0, ARENA_ZONE)
                    sessions[tname].alive[mname] = true
                    playerTeam[mname]            = tname
                end
            end
        end
        tourney.entrants = {}

        -- Stagger team wave-1 starts slightly to spread server load
        for i, tname in ipairs(teamList) do
            if sessions[tname] and count(sessions[tname].alive) > 0 then
                local delay = (WAVE_DELAY + (i - 1) * 0.5) * 1000
                GetTimerManager():addTimer('tourney_wave1_' .. tname, delay, false, function()
                    if tourney.phase == 'running' and sessions[tname] then
                        startWaveForTeam(tname, 1)
                    end
                end)
            end
        end

    -- ── GM: CANCEL ───────────────────────────────────────────────────────────
    elseif sub == 'cancel' then
        if tourney.phase == 'idle' then
            player:printToPlayer('[Tournament] Nothing to cancel.'); return
        end
        announce('[Tournament] Tournament cancelled by GM.')
        for tname, sess in pairs(sessions) do
            for name in pairs(sess.alive) do
                local p = GetPlayerByName(name)
                if p then warpOut(p) end
            end
            for _, mob in pairs(sess.mobRefs) do
                if mob then mob:setHP(0) end
            end
        end
        tourney.phase    = 'idle'
        tourney.entrants = {}
        sessions         = {}
        playerTeam       = {}

    -- ── GM: KICK ─────────────────────────────────────────────────────────────
    elseif sub == 'kick' then
        local target = a2
        if not target then
            player:printToPlayer('[Tournament] Usage: !tournament kick <name>'); return
        end
        if tourney.entrants[target] then
            local tname = tourney.entrants[target]
            tourney.entrants[target] = nil
            player:printToPlayer(string.format('[Tournament] %s removed from Team %s sign-ups.', target, tname))
        elseif playerTeam[target] then
            -- Simulate a death for mid-run kicks
            local tname = playerTeam[target]
            local sess  = sessions[tname]
            if sess then
                sess.alive[target] = nil
                playerTeam[target] = nil
                local tp = GetPlayerByName(target)
                if tp then warpOut(tp) end
                announce(string.format('[Tournament] %s (Team %s) removed by GM.', target, tname))
                if count(sess.alive) == 0 then
                    eliminateTeam(tname, 'all members removed')
                end
            end
        else
            player:printToPlayer(string.format('[Tournament] %s is not in the tournament.', target))
        end

    -- ── GM: TEAM (reassign during sign-ups) ──────────────────────────────────
    elseif sub == 'team' then
        local target = a2
        local tname  = a3
        if not target or not tname then
            player:printToPlayer('[Tournament] Usage: !tournament team <player> <teamname>'); return
        end
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Can only reassign teams during sign-up phase.'); return
        end
        if not tourney.entrants[target] then
            player:printToPlayer(string.format('[Tournament] %s is not registered.', target)); return
        end
        local old = tourney.entrants[target]
        tourney.entrants[target] = tname
        player:printToPlayer(string.format('[Tournament] Moved %s from Team %s to Team %s.', target, old, tname))

    else
        player:printToPlayer('[Tournament] Subcommands: join [team], leave, status')
        player:printToPlayer('[Tournament] GM: open, start, cancel, kick <name>, team <player> <teamname>')
    end
end

return m
