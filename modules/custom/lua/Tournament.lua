-----------------------------------
-- Tournament.lua
-- Last-person-standing PvE wave tournament.
--
-- Each contestant fights their OWN independent mob waves spawned around them.
-- Mobs only aggro their assigned player, so there is no shared carry.
-- Players are spread across Qu'Bia Arena so rings don't overlap.
-- The last player still alive wins. Trusts are not allowed.
--
-- COMMANDS (thin shim at modules/custom/commands/tournament.lua):
--   !tournament              show current status
--   !tournament join         register during sign-up phase
--   !tournament leave        withdraw during sign-up phase
--   !tournament open   (GM)  open sign-ups
--   !tournament start  (GM)  warp all entrants in, begin individual waves
--   !tournament cancel (GM)  abort and warp survivors home
--   !tournament kick <n>(GM) eliminate a player
--   !tournament add  <n>(GM) force-add to sign-ups
--
-- Requires map restart (addOverride hooks).
-----------------------------------

require('modules/module_utils')

local m = Module:new('tournament')

-- ─── config ───────────────────────────────────────────────────────────────────

local ARENA_ZONE  = 206          -- Qu'Bia Arena
local ARENA_CX    = -241.046     -- zone entry / arena centre
local ARENA_CY    = -25.86
local ARENA_CZ    =  19.991
local RING_MIN    = 8            -- mob spawn ring around each player
local RING_MAX    = 16
local PLAYER_SEP  = 60           -- distance between player start positions
local HOME_ZONE   = xi.zone.GM_HOME
local HOME_X, HOME_Y, HOME_Z = -4.0, 0.0, -2.0
local GROUP_ZONE  = 210          -- GM_Home: where mob_groups are registered

local WAVE_DELAY  = 5    -- seconds of grace before wave 1
local CLEAR_DELAY = 6    -- seconds between a cleared wave and the next one

-- Mob groups from GM_Home zone (same pool Endless Tower uses).
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

-- ─── state ────────────────────────────────────────────────────────────────────

-- Tournament-level state
local tourney = {
    phase    = 'idle',  -- 'idle' | 'open' | 'running'
    entrants = {},      -- [name]=true, pre-start
    alive    = {},      -- [name]=true, currently in-arena
}

-- Per-player session: tracks each player's independent wave progress
-- sessions[playerName] = { wave=N, mobs={[id]=true}, spawnX=x, spawnZ=z }
local sessions = {}

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

-- Spread players in a circle around the arena centre so their mob rings
-- (radius RING_MAX=16) don't overlap. With PLAYER_SEP=60, up to ~12 players
-- fit without any ring touching another player's start position.
local function calcSpawnPos(index, total)
    if total == 1 then
        return ARENA_CX, ARENA_CZ
    end
    local angle = ((index - 1) / total) * math.pi * 2
    return ARENA_CX + math.cos(angle) * PLAYER_SEP,
           ARENA_CZ + math.sin(angle) * PLAYER_SEP
end

-- ─── forward declarations ─────────────────────────────────────────────────────

local startWaveForPlayer  -- defined below

-- ─── per-player wave logic ────────────────────────────────────────────────────

local function onWaveClearedForPlayer(playerName, waveNum)
    if tourney.phase ~= 'running' then return end
    local sess = sessions[playerName]
    if not sess then return end

    local nextWave = waveNum + 1
    local cfg      = WAVES[nextWave]

    -- Broadcast each clear so bystanders can follow the action
    local remaining = count(tourney.alive)
    if cfg then
        announce(string.format('[Tournament] %s cleared wave %d! Starting %s in %ds. (%d alive)',
            playerName, waveNum, cfg.label, CLEAR_DELAY, remaining))
    else
        -- Cleared all 8 waves — this player is a champion
        announce(string.format('[Tournament] *** %s CLEARED ALL WAVES! Champion! *** (%d alive)', playerName, remaining))
        sessions[playerName] = nil
        tourney.alive[playerName] = nil
        GetTimerManager():addTimer('tourney_warp_' .. playerName, 5000, false, function()
            local p = GetPlayerByName(playerName)
            if p then warpOut(p) end
        end)
        -- Check if they were the last one
        if count(tourney.alive) == 0 then
            tourney.phase = 'idle'
        end
        return
    end

    GetTimerManager():addTimer('tourney_next_' .. playerName, CLEAR_DELAY * 1000, false, function()
        if tourney.phase == 'running' and sessions[playerName] then
            startWaveForPlayer(playerName, nextWave)
        end
    end)
end

startWaveForPlayer = function(playerName, waveNum)
    if tourney.phase ~= 'running' then return end
    local sess = sessions[playerName]
    local p    = GetPlayerByName(playerName)
    if not sess or not p then return end

    local cfg  = WAVES[waveNum]
    if not cfg then
        onWaveClearedForPlayer(playerName, waveNum - 1)
        return
    end

    sess.wave = waveNum
    sess.mobs = {}

    local zone = GetZone(ARENA_ZONE)
    if not zone then return end

    p:printToPlayer(string.format('[Tournament] %s — %d mobs, level %d. Fight!',
        cfg.label, cfg.count, cfg.level))

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
            name                 = playerName .. "'s " .. cfg.label,
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
                local s = sessions[playerName]
                if not s then return end
                s.mobs[deadMob:getID()] = nil
                if not next(s.mobs) then
                    onWaveClearedForPlayer(playerName, waveNum)
                end
            end,
        })

        if mob then
            mob:setSpawn(mx, ARENA_CY, mz, 0)
            mob:spawn()
            mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
            local newMax = math.floor(mob:getMaxHP() * cfg.hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
            -- Only aggro THIS player — no shared carry
            mob:addEnmity(p, 30000, 30000)
            sess.mobs[mob:getID()] = true
        end
    end
end

-- ─── elimination ─────────────────────────────────────────────────────────────

local function eliminate(name, reason)
    if not tourney.alive[name] then return end

    tourney.alive[name] = nil
    sessions[name]      = nil

    local remaining = count(tourney.alive)
    announce(string.format('[Tournament] %s eliminated (%s). %d remain.', name, reason, remaining))

    GetTimerManager():addTimer('tourney_warp_' .. name, 3000, false, function()
        local p = GetPlayerByName(name)
        if p then warpOut(p) end
    end)

    if remaining == 1 then
        local winner
        for n in pairs(tourney.alive) do winner = n end
        announce(string.format('[Tournament] *** %s is the LAST PERSON STANDING — Tournament Champion! ***', winner))
        tourney.alive[winner] = nil
        sessions[winner]      = nil
        GetTimerManager():addTimer('tourney_warp_winner', 8000, false, function()
            local w = GetPlayerByName(winner)
            if w then warpOut(w) end
        end)
        tourney.phase = 'idle'

    elseif remaining == 0 then
        announce('[Tournament] All contestants have fallen. No survivors.')
        tourney.phase = 'idle'
    end
end

tourney.eliminate = eliminate  -- expose for command shim

-- ─── player death override ────────────────────────────────────────────────────

m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    if tourney.phase ~= 'running' then return end
    local name = player:getName()
    if tourney.alive[name] then
        eliminate(name, 'KO')
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
    if tourney.alive[player:getName()] then
        dismissTrusts(player)
    end
end)

-- ─── command handler (called from modules/custom/commands/tournament.lua) ─────

tourney.handleCmd = function(player, sub, a2, a3)
    local isGM = player:getGMLevel() >= 1
    sub = sub and string.lower(sub) or ''

    if sub == '' or sub == 'status' then
        if tourney.phase == 'idle' then
            player:printToPlayer('[Tournament] No tournament is running.')
        elseif tourney.phase == 'open' then
            local names = {}
            for n in pairs(tourney.entrants) do names[#names+1] = n end
            player:printToPlayer(string.format('[Tournament] SIGN-UPS OPEN — %d registered: %s',
                #names, #names > 0 and table.concat(names, ', ') or 'none yet'))
            player:printToPlayer('[Tournament] Type !tournament join to enter.')
        else
            local entries = {}
            for n, sess in pairs(sessions) do
                entries[#entries+1] = string.format('%s(w%d)', n, sess.wave)
            end
            player:printToPlayer(string.format('[Tournament] RUNNING — %d alive: %s',
                count(tourney.alive), table.concat(entries, ', ')))
        end

    elseif sub == 'join' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Sign-ups are not open.'); return
        end
        local name = player:getName()
        if tourney.entrants[name] then
            player:printToPlayer('[Tournament] You are already registered.'); return
        end
        tourney.entrants[name] = true
        announce(string.format('[Tournament] %s enters! (%d registered)', name, count(tourney.entrants)))

    elseif sub == 'leave' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Cannot withdraw after the tournament starts.'); return
        end
        local name = player:getName()
        if not tourney.entrants[name] then
            player:printToPlayer('[Tournament] You are not registered.'); return
        end
        tourney.entrants[name] = nil
        announce(string.format('[Tournament] %s withdraws. (%d registered)', name, count(tourney.entrants)))

    elseif not isGM then
        player:printToPlayer('[Tournament] Subcommands: join, leave, status.')

    elseif sub == 'open' then
        if tourney.phase ~= 'idle' then
            player:printToPlayer('[Tournament] A tournament is already active.'); return
        end
        tourney.phase    = 'open'
        tourney.entrants = {}
        announce('[Tournament] A Tournament has opened! Type !tournament join to compete.')
        announce('[Tournament] Rules: Each player fights their own mob waves. No trusts. Last one alive wins.')

    elseif sub == 'start' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Not in sign-up phase.'); return
        end
        if count(tourney.entrants) == 0 then
            player:printToPlayer('[Tournament] No entrants.'); return
        end

        tourney.phase = 'running'
        tourney.alive = {}
        sessions      = {}

        local names = {}
        for n in pairs(tourney.entrants) do names[#names+1] = n end
        local total = #names

        announce(string.format('[Tournament] TOURNAMENT BEGINS! %d contestant(s) warping to the arena...', total))

        for i, pname in ipairs(names) do
            local p = GetPlayerByName(pname)
            if p and p:isOnline() then
                local sx, sz = calcSpawnPos(i, total)
                dismissTrusts(p)
                p:setCharVar('TournamentInArena', 1)
                p:setPos(sx, ARENA_CY, sz, 0, ARENA_ZONE)
                tourney.alive[pname] = true
                sessions[pname]      = { wave = 0, mobs = {}, spawnX = sx, spawnZ = sz }
            end
        end
        tourney.entrants = {}

        -- Stagger wave 1 starts slightly so spawn doesn't all hit at once
        for i, pname in ipairs(names) do
            if sessions[pname] then
                local delay = (WAVE_DELAY + (i - 1) * 0.5) * 1000
                GetTimerManager():addTimer('tourney_wave1_' .. pname, delay, false, function()
                    if tourney.phase == 'running' and sessions[pname] then
                        startWaveForPlayer(pname, 1)
                    end
                end)
            end
        end

    elseif sub == 'cancel' then
        if tourney.phase == 'idle' then
            player:printToPlayer('[Tournament] Nothing to cancel.'); return
        end
        announce('[Tournament] Tournament cancelled by GM.')
        for pname in pairs(tourney.alive) do
            local p = GetPlayerByName(pname)
            if p then warpOut(p) end
        end
        tourney.phase    = 'idle'
        tourney.entrants = {}
        tourney.alive    = {}
        sessions         = {}

    elseif sub == 'kick' then
        local target = a2
        if not target then
            player:printToPlayer('[Tournament] Usage: !tournament kick <name>'); return
        end
        if tourney.entrants[target] then
            tourney.entrants[target] = nil
            player:printToPlayer(string.format('[Tournament] %s removed from sign-ups.', target))
        elseif tourney.alive[target] then
            eliminate(target, 'removed by GM')
        else
            player:printToPlayer(string.format('[Tournament] %s is not in the tournament.', target))
        end

    elseif sub == 'add' then
        local target = a2
        if not target then
            player:printToPlayer('[Tournament] Usage: !tournament add <name>'); return
        end
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Can only add players during sign-up phase.'); return
        end
        tourney.entrants[target] = true
        announce(string.format('[Tournament] %s added by GM. (%d registered)', target, count(tourney.entrants)))

    else
        player:printToPlayer('[Tournament] Subcommands: join, leave, status')
        player:printToPlayer('[Tournament] GM: open, start, cancel, kick <name>, add <name>')
    end
end

return m
