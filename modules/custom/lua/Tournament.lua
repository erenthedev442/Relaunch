-----------------------------------
-- Tournament.lua
-- Last-person-standing PvE wave tournament.
--
-- A GM opens sign-ups, players join via !tournament join, a GM starts it.
-- All registered players are warped to Qu'Bia Arena (zone 206). Mob waves
-- spawn with escalating difficulty; each player who dies is warped out and
-- eliminated. The last player standing (or all players if they clear every
-- wave) wins. Trusts are not permitted.
--
-- COMMANDS (see modules/custom/commands/tournament.lua)
--   !tournament              -- show status
--   !tournament join         -- enter during sign-up phase
--   !tournament leave        -- withdraw during sign-up phase
--   GM only:
--   !tournament open         -- open sign-ups
--   !tournament start        -- warp all entrants in and begin wave 1
--   !tournament cancel       -- abort at any time, warp survivors out
--   !tournament kick <name>  -- remove a player from sign-ups or the arena
--   !tournament add <name>   -- add a player to sign-ups (bypasses join)
--
-- Requires map restart to go live (addOverride hooks).
-----------------------------------

require('modules/module_utils')

local m = Module:new('tournament')

-- ─── config ───────────────────────────────────────────────────────────────────

local ARENA_ZONE   = 206                             -- Qu'Bia Arena
local ARENA_CX     = -241.046                        -- arena centre (zone entry)
local ARENA_CY     = -25.86
local ARENA_CZ     =  19.991
local RING_MIN     = 10                              -- mob spawn ring radii
local RING_MAX     = 20
local HOME_ZONE    = xi.zone.GM_HOME                 -- eliminated players warp here
local HOME_X, HOME_Y, HOME_Z = -4.0, 0.0, -2.0
local GROUP_ZONE   = 210                             -- GM_Home: where mob_groups live

local WAVE_DELAY   = 5   -- seconds of grace before wave 1
local CLEAR_DELAY  = 8   -- seconds between cleared wave and next one

-- Mob groups sourced from Endless Tower bands (GM_Home zone, confirmed working).
-- groupIds 11355-11369 give visual variety across waves.
local WAVES = {
    { label = 'Wave 1 — The Warm-Up',         count = 3, level = 110, hpMult = 6,   groups = { 11355, 11356 } },
    { label = 'Wave 2 — Rising Tide',          count = 4, level = 130, hpMult = 10,  groups = { 11357, 11358 } },
    { label = 'Wave 3 — Savage Company',       count = 4, level = 150, hpMult = 16,  groups = { 11359, 11360 } },
    { label = 'Wave 4 — Veteran Hunters',      count = 5, level = 170, hpMult = 24,  groups = { 11361, 11362 } },
    { label = 'Wave 5 — Elite Guard',          count = 5, level = 190, hpMult = 36,  groups = { 11363, 11364 } },
    { label = 'Wave 6 — Legendary Assault',    count = 6, level = 210, hpMult = 52,  groups = { 11365, 11366 } },
    { label = 'Wave 7 — Apex Predators',       count = 6, level = 230, hpMult = 72,  groups = { 11367, 11368 } },
    { label = 'Wave 8 — The Final Reckoning',  count = 7, level = 250, hpMult = 96,  groups = { 11368, 11369 } },
}

-- ─── state ────────────────────────────────────────────────────────────────────

local tourney = {
    phase    = 'idle',  -- 'idle' | 'open' | 'running'
    entrants = {},      -- [name]=true, pre-start
    alive    = {},      -- [name]=true, in arena
    wave     = 0,
    mobs     = {},      -- [mobId]=true, alive this wave
}

-- Expose for the command shim
xi._tournament = tourney

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
        if member:isTrust() then
            member:setHP(0)
        end
    end
end

local function warpIn(player)
    local jx = (math.random() - 0.5) * 8
    local jz = (math.random() - 0.5) * 8
    player:setPos(ARENA_CX + jx, ARENA_CY, ARENA_CZ + jz, 0, ARENA_ZONE)
end

local function warpOut(player)
    player:setCharVar('TournamentInArena', 0)
    player:setPos(HOME_X, HOME_Y, HOME_Z, 0, HOME_ZONE)
end

-- ─── forward declarations ─────────────────────────────────────────────────────

local spawnWave  -- defined below, referenced in onWaveCleared

-- ─── elimination + win detection ─────────────────────────────────────────────

local function eliminate(name, reason)
    if not tourney.alive[name] then return end
    tourney.alive[name] = nil

    local remaining = count(tourney.alive)
    announce(string.format('[Tournament] %s eliminated (%s). %d remain.', name, reason, remaining))

    -- Delayed warp so they see the death animation
    GetTimerManager():addTimer('tourney_warp_' .. name, 3000, false, function()
        local p = GetPlayerByName(name)
        if p then warpOut(p) end
    end)

    if remaining == 1 then
        local winner
        for n in pairs(tourney.alive) do winner = n end
        announce(string.format('[Tournament] *** %s is the LAST PERSON STANDING — Tournament Champion! ***', winner))
        GetTimerManager():addTimer('tourney_warp_winner', 8000, false, function()
            local w = GetPlayerByName(winner)
            if w then warpOut(w) end
        end)
        tourney.phase = 'idle'
        tourney.alive = {}
        tourney.mobs  = {}
        tourney.wave  = 0

    elseif remaining == 0 then
        announce('[Tournament] All contestants have fallen. No survivors.')
        tourney.phase = 'idle'
        tourney.alive = {}
        tourney.mobs  = {}
        tourney.wave  = 0
    end
end

-- Expose so the command file can call eliminate() for !tournament kick mid-run
tourney.eliminate = eliminate

-- ─── wave logic ───────────────────────────────────────────────────────────────

local function onWaveCleared()
    if tourney.phase ~= 'running' then return end

    local remaining = count(tourney.alive)
    if remaining == 0 then return end  -- eliminate() already handled this

    local nextWave = tourney.wave + 1
    local cfg      = WAVES[nextWave]

    if not cfg then
        -- Cleared all 8 waves — all survivors share the win
        announce('[Tournament] *** ALL WAVES CLEARED! ***')
        local winners = {}
        for n in pairs(tourney.alive) do winners[#winners+1] = n end
        announce(string.format('[Tournament] Co-Champions: %s', table.concat(winners, ', ')))
        for _, n in ipairs(winners) do
            tourney.alive[n] = nil
            GetTimerManager():addTimer('tourney_warp_' .. n, 5000, false, function()
                local p = GetPlayerByName(n)
                if p then warpOut(p) end
            end)
        end
        tourney.phase = 'idle'
        tourney.alive = {}
        tourney.mobs  = {}
        tourney.wave  = 0
        return
    end

    announce(string.format('[Tournament] Wave %d cleared! %d alive. %s begins in %ds.',
        tourney.wave, remaining, cfg.label, CLEAR_DELAY))

    GetTimerManager():addTimer('tourney_nextwave', CLEAR_DELAY * 1000, false, function()
        if tourney.phase == 'running' then
            spawnWave(nextWave)
        end
    end)
end

spawnWave = function(waveNum)
    if tourney.phase ~= 'running' then return end

    local cfg  = WAVES[waveNum]
    local zone = GetZone(ARENA_ZONE)
    if not cfg or not zone then return end

    tourney.wave = waveNum
    tourney.mobs = {}

    local alive = count(tourney.alive)
    -- Scale HP so the wave stays challenging as the arena thins out.
    -- 1 player gets 1× the listed multiplier; 4 players get ~2.5×.
    local hpScale = cfg.hpMult * (1 + (alive - 1) * 0.5)

    announce(string.format('[Tournament] -- %s -- %d mobs, level %d. %d contestant(s) remain.',
        cfg.label, cfg.count, cfg.level, alive))

    for i = 1, cfg.count do
        local angle   = math.random() * math.pi * 2
        local dist    = RING_MIN + math.random() * (RING_MAX - RING_MIN)
        local mx      = ARENA_CX + math.cos(angle) * dist
        local mz      = ARENA_CZ + math.sin(angle) * dist
        local groupId = cfg.groups[((i - 1) % #cfg.groups) + 1]

        local mob = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = groupId,
            groupZoneId          = GROUP_ZONE,
            name                 = cfg.label .. ' Challenger',
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
                tourney.mobs[deadMob:getID()] = nil
                if not next(tourney.mobs) then
                    onWaveCleared()
                end
            end,
        })

        if mob then
            mob:setSpawn(mx, ARENA_CY, mz, 0)
            mob:spawn()
            mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
            local newMax = math.floor(mob:getMaxHP() * hpScale)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
            -- Aggro all alive contestants immediately
            for pname in pairs(tourney.alive) do
                local p = GetPlayerByName(pname)
                if p then mob:addEnmity(p, 30000, 30000) end
            end
            tourney.mobs[mob:getID()] = true
        end
    end
end

tourney.spawnWave = spawnWave  -- expose for debugging if needed

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

-- Block trust casting for any player with TournamentInArena=1.
m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if caster:getCharVar('TournamentInArena') == 1 then
        caster:printToPlayer('[Tournament] Trusts are not permitted in the arena.')
        return xi.msg.basic.TRUST_NO_CAST_TRUST
    end
    return super(caster, spell, notAllowedTrustIds)
end)

-- Dismiss any trusts on zone-in (catches re-zones during a running tournament)
m:addOverride('xi.zones.QuBia_Arena.Zone.onZoneIn', function(player, prevZone)
    super(player, prevZone)
    if tourney.alive[player:getName()] then
        dismissTrusts(player)
    end
end)

-- ─── GM command handler (called from modules/custom/commands/tournament.lua) ──

tourney.handleCmd = function(player, sub, a2, a3)
    local isGM = player:getGMLevel() >= 1
    sub = sub and string.lower(sub) or ''

    -- ── STATUS ───────────────────────────────────────────────────────────────
    if sub == '' or sub == 'status' then
        if tourney.phase == 'idle' then
            player:printToPlayer('[Tournament] No tournament is running. A GM can open one with !tournament open.')
        elseif tourney.phase == 'open' then
            local names = {}
            for n in pairs(tourney.entrants) do names[#names+1] = n end
            player:printToPlayer(string.format('[Tournament] SIGN-UPS OPEN — %d registered: %s',
                #names, #names > 0 and table.concat(names, ', ') or 'none yet'))
            player:printToPlayer('[Tournament] Type !tournament join to enter.')
        else
            local names = {}
            for n in pairs(tourney.alive) do names[#names+1] = n end
            player:printToPlayer(string.format('[Tournament] RUNNING — Wave %d, %d alive: %s',
                tourney.wave, #names, table.concat(names, ', ')))
        end

    -- ── JOIN ─────────────────────────────────────────────────────────────────
    elseif sub == 'join' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Sign-ups are not currently open.'); return
        end
        local name = player:getName()
        if tourney.entrants[name] then
            player:printToPlayer('[Tournament] You are already registered.'); return
        end
        tourney.entrants[name] = true
        announce(string.format('[Tournament] %s enters the tournament! (%d registered)',
            name, count(tourney.entrants)))

    -- ── LEAVE ────────────────────────────────────────────────────────────────
    elseif sub == 'leave' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] The tournament has already started or is not open.'); return
        end
        local name = player:getName()
        if not tourney.entrants[name] then
            player:printToPlayer('[Tournament] You are not registered.'); return
        end
        tourney.entrants[name] = nil
        announce(string.format('[Tournament] %s has withdrawn. (%d registered)',
            name, count(tourney.entrants)))

    -- ── GM: OPEN ─────────────────────────────────────────────────────────────
    elseif not isGM then
        player:printToPlayer('[Tournament] Unknown subcommand. Try: join, leave, status.')

    elseif sub == 'open' then
        if tourney.phase ~= 'idle' then
            player:printToPlayer('[Tournament] A tournament is already active.'); return
        end
        tourney.phase    = 'open'
        tourney.entrants = {}
        announce('[Tournament] A Tournament has opened! Type !tournament join to compete.')
        announce('[Tournament] Rules: No trusts. Last person standing wins. Clear all 8 waves for a shared victory.')

    -- ── GM: START ────────────────────────────────────────────────────────────
    elseif sub == 'start' then
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Not in sign-up phase.'); return
        end
        if count(tourney.entrants) == 0 then
            player:printToPlayer('[Tournament] No entrants have registered.'); return
        end

        tourney.phase = 'running'
        tourney.alive = {}
        tourney.wave  = 0
        tourney.mobs  = {}

        local n = count(tourney.entrants)
        announce(string.format('[Tournament] TOURNAMENT BEGINS! Warping %d contestant(s) to the arena...', n))

        for pname in pairs(tourney.entrants) do
            local p = GetPlayerByName(pname)
            if p and p:isOnline() then
                dismissTrusts(p)
                p:setCharVar('TournamentInArena', 1)
                warpIn(p)
                tourney.alive[pname] = true
            end
        end
        tourney.entrants = {}

        GetTimerManager():addTimer('tourney_wave1', WAVE_DELAY * 1000, false, function()
            if tourney.phase == 'running' then spawnWave(1) end
        end)

    -- ── GM: CANCEL ───────────────────────────────────────────────────────────
    elseif sub == 'cancel' then
        if tourney.phase == 'idle' then
            player:printToPlayer('[Tournament] Nothing to cancel.'); return
        end
        announce('[Tournament] The tournament has been cancelled by a GM.')
        for pname in pairs(tourney.alive) do
            local p = GetPlayerByName(pname)
            if p then warpOut(p) end
        end
        tourney.phase    = 'idle'
        tourney.entrants = {}
        tourney.alive    = {}
        tourney.mobs     = {}
        tourney.wave     = 0

    -- ── GM: KICK ─────────────────────────────────────────────────────────────
    elseif sub == 'kick' then
        local target = a2
        if not target then
            player:printToPlayer('[Tournament] Usage: !tournament kick <name>'); return
        end
        if tourney.entrants[target] then
            tourney.entrants[target] = nil
            announce(string.format('[Tournament] %s removed from sign-ups.', target))
        elseif tourney.alive[target] then
            eliminate(target, 'removed by GM')
        else
            player:printToPlayer(string.format('[Tournament] %s is not in the tournament.', target))
        end

    -- ── GM: ADD (force-add to sign-ups) ──────────────────────────────────────
    elseif sub == 'add' then
        local target = a2
        if not target then
            player:printToPlayer('[Tournament] Usage: !tournament add <name>'); return
        end
        if tourney.phase ~= 'open' then
            player:printToPlayer('[Tournament] Can only add players during sign-up phase.'); return
        end
        tourney.entrants[target] = true
        announce(string.format('[Tournament] %s added to sign-ups by GM. (%d registered)',
            target, count(tourney.entrants)))

    else
        player:printToPlayer('[Tournament] Subcommands: join, leave, status')
        player:printToPlayer('[Tournament] GM: open, start, cancel, kick <name>, add <name>')
    end
end

return m
