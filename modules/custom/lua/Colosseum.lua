-----------------------------------
-- Colosseum.lua
-- ASYNC RANKED PVP: fight AI replicas of other players' champions.
--
-- Enroll at the Arena Herald (GM Home) to put your champion on the
-- ladder. Challenge any enrolled champion - the Herald conjures a
-- replica wearing their name and race, scaled to their CURRENT Elo
-- rating. Beat it and your rating rises while theirs falls (yes, even
-- while they sleep - it's a ladder, not a handshake). Lose - by death,
-- fleeing the zone, or the 5-minute bell - and the swing reverses.
--
-- Built on the proven dynamic-entity playbook (GameMaster/Voidspire):
--   * minLevel+maxLevel+detection always set; releaseIdOnDisappear and
--     NO cross-fight mob refs; session cleared BEFORE despawn on every
--     abort path; NO_CAPACITY_POINTS so replicas can't be CP-farmed.
--   * Cross-player state lives in SERVER variables (int-only), the
--     only Lua-reachable store that works while the owner is offline.
--     Names are packed 4 ASCII chars per int (see nameCodec below).
--
-- v1 scope notes:
--   * Replica difficulty tracks the champion's RATING (gear can't be
--     read cross-player from Lua). Climbing the ladder hardens your
--     own replica - the ladder defends itself.
--   * Trusts are allowed in duels. They're every soloer's "build" on
--     this server; the replica's stat sheet assumes the help.
-----------------------------------
require('modules/module_utils')
local catalog   = require('modules/custom/lua/colosseum_catalog')
local ptCat     = require('modules/custom/lua/player_trusts_catalog')  -- raceModels
local mechanics = require('modules/custom/lua/mob_mechanics_library')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('colosseum')

-----------------------------------
-- Server-variable keys
-----------------------------------
local function svCount()        return '[Col]Count' end
local function svRoster(i)      return '[Col]Roster_' .. i end
local function svIdx(charId)    return '[Col]Idx_'    .. charId end
local function svOn(charId)     return '[Col]On_'     .. charId end
local function svRating(charId) return '[Col]Rt_'     .. charId end
local function svRace(charId)   return '[Col]Race_'   .. charId end
local function svJob(charId)    return '[Col]Job_'    .. charId end
local function svLvl(charId)    return '[Col]Lvl_'    .. charId end
local function svName(charId, i) return string.format('[Col]Nm_%d_%d', charId, i) end

-----------------------------------
-- Name codec - server variables hold ints only. FFXI names are <= 15
-- ASCII chars, so 4 ints of 4 chars each cover any name. Per-int max
-- is 0x7F7F7F7F = 2,139,062,143 - inside signed-32 range.
-----------------------------------
local function packName(charId, name)
    name = tostring(name or ''):sub(1, 16)
    for chunk = 1, 4 do
        local v = 0
        for pos = 4, 1, -1 do
            local c = name:byte((chunk - 1) * 4 + pos) or 0
            if c > 127 then c = 63 end  -- '?' for any non-ASCII surprise
            v = v * 256 + c
        end
        SetServerVariable(svName(charId, chunk), v)
    end
end

local function unpackName(charId)
    local out = {}
    for chunk = 1, 4 do
        local v = GetServerVariable(svName(charId, chunk)) or 0
        for _ = 1, 4 do
            local c = v % 256
            v = math.floor(v / 256)
            if c == 0 then break end
            out[#out + 1] = string.char(c)
        end
    end
    local name = table.concat(out)
    if name == '' then name = string.format('Champion #%d', charId) end
    return name
end

-----------------------------------
-- Ladder primitives
-----------------------------------
local function getRating(charId)
    local r = GetServerVariable(svRating(charId)) or 0
    if r <= 0 then r = catalog.elo.start end
    return r
end

local function setRating(charId, r)
    SetServerVariable(svRating(charId), math.max(catalog.elo.floor, math.floor(r + 0.5)))
end

local function isEnrolled(charId)
    return (GetServerVariable(svOn(charId)) or 0) == 1
end

-- Append to the roster index on FIRST enrollment; later enrollments
-- just flip the On bit (slots are never freed - the walk skips Off).
local function ensureRosterSlot(charId)
    if (GetServerVariable(svIdx(charId)) or 0) > 0 then return end
    local count = (GetServerVariable(svCount()) or 0) + 1
    SetServerVariable(svCount(), count)
    SetServerVariable(svRoster(count), charId)
    SetServerVariable(svIdx(charId), count)
end

-- Every enrolled champion except `exceptId`, as { id, rating, name }.
local function listChampions(exceptId)
    local out = {}
    local count = GetServerVariable(svCount()) or 0
    for i = 1, count do
        local id = GetServerVariable(svRoster(i)) or 0
        if id > 0 and id ~= exceptId and isEnrolled(id) then
            out[#out + 1] = { id = id, rating = getRating(id), name = unpackName(id) }
        end
    end
    return out
end

-- Standard Elo expectation + swing. Returns the (positive) number of
-- points that move from loser to winner.
local function eloSwing(winnerR, loserR)
    local expected = 1 / (1 + 10 ^ ((loserR - winnerR) / 400))
    return math.max(1, math.floor(catalog.elo.k * (1 - expected) + 0.5))
end

-----------------------------------
-- Replica scaling
-----------------------------------
local function replicaLevel(rating)
    local r = catalog.replica
    local lvl = r.levelBase + math.max(0, math.floor((rating - r.ratingBase) / r.levelPerRating))
    return math.min(lvl, r.levelCap)
end

local function replicaHpMult(rating)
    local r = catalog.replica
    local mult = r.hpBase + (rating - 1200) / r.hpRatingDiv
    return math.max(r.hpMin, math.min(mult, r.hpMax))
end

-- Linear interpolation across catalog.replica.modRows.
local function replicaMods(level)
    local rows = catalog.replica.modRows
    if level <= rows[1].level then return rows[1].mods end
    if level >= rows[#rows].level then return rows[#rows].mods end
    for i = 1, #rows - 1 do
        local a, b = rows[i], rows[i + 1]
        if level >= a.level and level <= b.level then
            local t = (level - a.level) / (b.level - a.level)
            local mods = {}
            for modId, av in pairs(a.mods) do
                local bv = b.mods[modId] or av
                mods[modId] = math.floor(av + (bv - av) * t)
            end
            return mods
        end
    end
    return rows[#rows].mods
end

-----------------------------------
-- Duel sessions - keyed by player name (same convention as Voidspire).
--   opp        { id, rating, name }
--   mobId      replica entity id (for alive checks only)
--   zoneId     arena zone
--   startedAt  os.time() token; also guards stale timers
-----------------------------------
local sessions = {}
local function getSession(player)  return sessions[player:getName()] end

local currentUtcDay = function()
    return math.floor(os.time() / 86400)
end

local function lastFoughtCv(oppId) return 'Col_LastDay_' .. oppId end

-- forward declarations
local endDuel, showHeraldMenu

-----------------------------------
-- Result processing. `won` = the challenger killed the replica.
-- Always: session is already cleared by the caller (re-entrancy guard);
-- this only moves ratings/marks/stats and prints.
-----------------------------------
local function applyResult(player, opp, won)
    local meId    = player:getID()
    local myR     = getRating(meId)
    local oppR    = getRating(opp.id)

    player:setCharVar(lastFoughtCv(opp.id), currentUtcDay())

    local swing
    if won then
        swing = eloSwing(myR, oppR)
        setRating(meId,  myR  + swing)
        setRating(opp.id, oppR - swing)
        player:setCharVar('Col_Wins', (player:getCharVar('Col_Wins') or 0) + 1)
        -- Track daily wins for the cap
        local today    = currentUtcDay()
        local winDay   = player:getCharVar('Col_WinDay')   or 0
        local dayWins  = winDay == today and (player:getCharVar('Col_DayWins') or 0) or 0
        player:setCharVar('Col_WinDay',  today)
        player:setCharVar('Col_DayWins', dayWins + 1)
    else
        swing = eloSwing(oppR, myR)
        setRating(meId,  myR  - swing)
        setRating(opp.id, oppR + swing)
        player:setCharVar('Col_Losses', (player:getCharVar('Col_Losses') or 0) + 1)
    end

    -- Mirror MY rating into charvars for the website leaderboards
    -- (docgen reads char_vars; server vars are the cross-player truth).
    local newR = getRating(meId)
    player:setCharVar('Col_Rating', newR)
    local best = player:getCharVar('Col_Best_Rating') or 0
    if newR > best then
        player:setCharVar('Col_Best_Rating', newR)
    end

    if won then
        local marks = catalog.reward.winBase
            + math.max(0, math.floor((oppR - myR) / catalog.reward.underdogDiv))
        player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + marks)
        player:printToPlayer(string.format(
            '[Colosseum] VICTORY over %s! Rating %d -> %d (+%d). +%d marks.',
            opp.name, myR, newR, swing, marks), xi.msg.channel.SYSTEM_3)
    else
        local marks = catalog.reward.lossMarks
        player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + marks)
        player:printToPlayer(string.format(
            '[Colosseum] Defeated by %s. Rating %d -> %d (-%d). +%d marks for the attempt.',
            opp.name, myR, newR, swing, marks), xi.msg.channel.SYSTEM_3)
    end

    -- Guarded achievements hook (ships alongside this module).
    local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
    if okAch and ach and ach.onColosseumResult then
        pcall(function() ach.onColosseumResult(player) end)
    end

    -- Weekly-hunt board event (no-op until an objective uses it).
    local okWh, wh = pcall(require, 'modules/custom/lua/weekly_hunts')
    if okWh and wh and wh.fire then
        pcall(function()
            wh.fire(player, won and 'colosseum_win' or 'colosseum_loss',
                { oppId = opp.id })
        end)
    end
end

-----------------------------------
-- End a duel for any reason except the replica dying.
--   reason: 'death' | 'left' | 'timeout' | 'forfeit' | 'logout'
-- Clears the session FIRST, then despawns, then (if the player entity
-- is still reachable) applies the loss.
-----------------------------------
endDuel = function(playerName, reason)
    local sess = sessions[playerName]
    if not sess then return end
    sessions[playerName] = nil  -- BEFORE touching the mob (re-entrancy)

    local mob = sess.mob
    if mob and type(mob) == 'userdata' then
        pcall(function()
            if mob:getHP() > 0 then mob:setHP(0) end
        end)
    end

    local player = GetPlayerByName(playerName)
    if player then
        local why = (reason == 'death'   and 'You fell')
                 or (reason == 'left'    and 'You left the arena')
                 or (reason == 'timeout' and 'The bell rang - time expired')
                 or (reason == 'forfeit' and 'You forfeited')
                 or 'The duel ended'
        player:printToPlayer(string.format('[Colosseum] %s - the duel is lost.', why),
            xi.msg.channel.SYSTEM_3)
        applyResult(player, sess.opp, false)
    else
        -- Player vanished (logout/crash): dock their ladder rating via
        -- server vars; their charvar mirror catches up on next visit.
        local meId = sess.ownerId
        local myR, oppR = getRating(meId), getRating(sess.opp.id)
        local swing = eloSwing(oppR, myR)
        setRating(meId,        myR  - swing)
        setRating(sess.opp.id, oppR + swing)
    end
end

-----------------------------------
-- Spawn the replica and start the duel.
-----------------------------------
local function startDuel(player, opp)
    if getSession(player) then
        player:printToPlayer('[Colosseum] You are already mid-duel!', xi.msg.channel.SYSTEM_3)
        return
    end
    if player:getZoneID() ~= catalog.arenaZoneId then
        player:printToPlayer('[Colosseum] Duels are fought here at the arena only.',
            xi.msg.channel.SYSTEM_3)
        return
    end
    if player:getHP() <= 0 then
        player:printToPlayer('[Colosseum] Revive first, then fight.', xi.msg.channel.SYSTEM_3)
        return
    end
    if catalog.duel.dailyWinCap then
        local today   = currentUtcDay()
        local winDay  = player:getCharVar('Col_WinDay')  or 0
        local dayWins = winDay == today and (player:getCharVar('Col_DayWins') or 0) or 0
        if dayWins >= catalog.duel.dailyWinCap then
            player:printToPlayer(string.format(
                '[Colosseum] Daily win limit reached (%d wins). Resets at 00:00 UTC.',
                catalog.duel.dailyWinCap), xi.msg.channel.SYSTEM_3)
            return
        end
    end
    if catalog.duel.perOpponentPerDay
       and (player:getCharVar(lastFoughtCv(opp.id)) or 0) == currentUtcDay() then
        player:printToPlayer(string.format(
            '[Colosseum] You have already faced %s today. The ladder resets at 00:00 UTC.',
            opp.name), xi.msg.channel.SYSTEM_3)
        return
    end

    local rating  = getRating(opp.id)
    local level   = replicaLevel(rating)
    local mods    = replicaMods(level)
    local hpMult  = replicaHpMult(rating)
    local race    = GetServerVariable(svRace(opp.id)) or 0
    local ownerName = player:getName()

    player:printToPlayer(string.format(
        '[Colosseum] %s (rating %d) answers your challenge! Steel yourself - %d seconds.',
        opp.name, rating, catalog.duel.countdownSec), xi.msg.channel.SYSTEM_3)

    player:timer(catalog.duel.countdownSec * 1000, function(p)
        if sessions[ownerName] then return end  -- raced into another duel somehow
        if p:getZoneID() ~= catalog.arenaZoneId or p:getHP() <= 0 then return end

        -- Ring spawn around the player - geometry-safe at the hub.
        local px, py, pz = p:getXPos(), p:getYPos(), p:getZPos()
        local angle = math.random() * math.pi * 2
        local r     = catalog.replica
        local dist  = r.spawnRingMin + math.random() * (r.spawnRingMax - r.spawnRingMin)
        local mx, mz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist

        local zone = p:getZone()
        local mob = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = r.groupId,
            groupZoneId          = r.groupZoneId,
            name                 = opp.name,
            x = mx, y = py, z = mz,
            rotation             = math.random(0, 255),
            minLevel             = level,   -- REQUIRED (else L255 garbage)
            maxLevel             = level,
            detection            = xi.detects.SIGHT_AND_HEARING,  -- REQUIRED
            isAggroable          = true,
            releaseIdOnDisappear = true,

            onMobDeath = function(deadMob, killer)
                mechanics.cleanup(deadMob)  -- free mechanics state + despawn any adds
                local sess = sessions[ownerName]
                if not sess then return end
                sessions[ownerName] = nil  -- clear BEFORE result processing

                if killer then
                    killer:setCharVar('Custom_NM_Kills',
                        (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
                end
                local owner = GetPlayerByName(ownerName)
                if owner then
                    applyResult(owner, sess.opp, true)
                end
            end,

            onMobFight = function(mfMob, mfTarget)
                mechanics.tick(mfMob, mfTarget)
            end,
        })

        if not mob then
            p:printToPlayer('[Colosseum] The replica failed to materialize. No contest.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        mob:setSpawn(mx, py, mz, 0)
        mob:spawn()
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
        for modId, val in pairs(mods) do mob:setMod(modId, val) end
        if hpMult > 1.0 then
            local newMax = math.floor(mob:getMaxHP() * hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
        -- Wear the champion's face: PC-look model by race (shared map
        -- with the Player Trust system). Cosmetic - pcall'd because
        -- model packets on dynamic mobs are the least-proven part.
        local model = ptCat.raceModels[race]
        if model then
            pcall(function() mob:setModelId(model) end)
        end
        mob:updateClaim(p)
        mob:addEnmity(p, 30000, 30000)

        -- Every replica IS the boss-tier mob in Colosseum (no trash mobs).
        -- Apply the full hardcore kit; tier scales with the champion's Elo rating.
        local mechCfg = (rating >= catalog.mechanicsEliteThreshold)
                        and catalog.mechanicsElite
                        or  catalog.mechanicsStandard
        mechanics.attach(mob, mechCfg)

        local startedAt = os.time()
        sessions[ownerName] = {
            opp       = opp,
            ownerId   = p:getID(),
            mob       = mob,
            mobId     = mob:getID(),
            zoneId    = catalog.arenaZoneId,
            startedAt = startedAt,
        }

        p:printToPlayer(string.format(
            '[Colosseum] FIGHT! Fell %s within %d minutes.',
            opp.name, math.floor(catalog.duel.timeLimitSec / 60)),
            xi.msg.channel.SYSTEM_3)

        -- Time limit (player PAI - dies if they zone, which the
        -- watchdog below covers).
        p:timer(catalog.duel.timeLimitSec * 1000, function(pp)
            local sess = sessions[ownerName]
            if sess and sess.startedAt == startedAt then
                endDuel(ownerName, 'timeout')
            end
        end)

        -- Watchdog on the MOB's PAI: if the challenger vanished (zoned,
        -- logged, crashed), end the duel as a loss and clean up - never
        -- leave a live replica roaming the hub. Re-arms itself while
        -- the duel is on.
        local function armWatchdog(watchedMob)
            watchedMob:timer(catalog.duel.watchdogSec * 1000, function(mobNow)
                local sess = sessions[ownerName]
                if not sess or sess.startedAt ~= startedAt then return end
                local owner = GetPlayerByName(ownerName)
                if not owner or owner:getZoneID() ~= catalog.arenaZoneId then
                    endDuel(ownerName, owner and 'left' or 'logout')
                    return
                end
                if mobNow and mobNow:getHP() > 0 then
                    armWatchdog(mobNow)
                end
            end)
        end
        armWatchdog(mob)
    end)
end

-----------------------------------
-- Enrollment / refresh
-----------------------------------
local function enroll(player)
    local meId = player:getID()
    ensureRosterSlot(meId)
    local already = isEnrolled(meId)
    SetServerVariable(svOn(meId), 1)
    if (GetServerVariable(svRating(meId)) or 0) <= 0 then
        SetServerVariable(svRating(meId), catalog.elo.start)
    end
    SetServerVariable(svRace(meId), player:getRace() or 0)
    SetServerVariable(svJob(meId),  player:getMainJob() or 0)
    SetServerVariable(svLvl(meId),  player:getMainLvl() or 99)
    packName(meId, player:getName())

    player:setCharVar('Col_Rating', getRating(meId))
    if (player:getCharVar('Col_Best_Rating') or 0) == 0 then
        player:setCharVar('Col_Best_Rating', getRating(meId))
    end

    player:printToPlayer(string.format(
        '[Colosseum] %s - champion %s. Rating: %d. Others can now challenge your replica any time.',
        already and 'Champion refreshed' or 'ENROLLED', player:getName(), getRating(meId)),
        xi.msg.channel.SYSTEM_3)
end

local function retire(player)
    local meId = player:getID()
    SetServerVariable(svOn(meId), 0)
    player:printToPlayer(
        '[Colosseum] Champion retired - removed from the ladder listing. Your rating is kept.',
        xi.msg.channel.SYSTEM_3)
end

-----------------------------------
-- Menus
-----------------------------------
local function sendMenu(player, title, options)
    local m = { title = title, options = options }
    player:timer(30, function(p) p:customMenu(m) end)
end

local function showOpponentMenu(player, page)
    page = page or 1
    local meId = player:getID()
    local myR  = getRating(meId)

    local champs = listChampions(meId)
    if #champs == 0 then
        player:printToPlayer(
            '[Colosseum] No other champions are enrolled yet. Recruit a rival!',
            xi.msg.channel.SYSTEM_3)
        showHeraldMenu(player)
        return
    end

    -- Closest-rating first: the fairest fight tops the list.
    table.sort(champs, function(a, b)
        return math.abs(a.rating - myR) < math.abs(b.rating - myR)
    end)

    local pageSize = catalog.rosterPageSize
    local nPages   = math.max(1, math.ceil(#champs / pageSize))
    page = math.max(1, math.min(page, nPages))

    local options = {}
    for i = (page - 1) * pageSize + 1, math.min(page * pageSize, #champs) do
        local c = champs[i]
        options[#options + 1] = {
            string.format('%s R%d', c.name:sub(1, 14), c.rating),
            function(p)
                p:printToPlayer(string.format(
                    '[Colosseum] %s - rating %d, replica Lv.%d. Win: ~+%d / Lose: ~-%d rating.',
                    c.name, c.rating, replicaLevel(c.rating),
                    eloSwing(getRating(p:getID()), c.rating),
                    eloSwing(c.rating, getRating(p:getID()))),
                    xi.msg.channel.SYSTEM_3)
                startDuel(p, c)
            end,
        }
    end
    if page > 1 then
        options[#options + 1] = { string.format('<< Prev (%d/%d)', page - 1, nPages),
            function(p) showOpponentMenu(p, page - 1) end }
    end
    if page < nPages then
        options[#options + 1] = { string.format('Next >> (%d/%d)', page + 1, nPages),
            function(p) showOpponentMenu(p, page + 1) end }
    end
    options[#options + 1] = { '<< Back', function(p) showHeraldMenu(p) end }

    local title = (nPages > 1) and string.format('Pick rival (%d/%d)', page, nPages)
                                or 'Pick your rival'
    sendMenu(player, title, options)
end

showHeraldMenu = function(player)
    local meId    = player:getID()
    local options = {}

    if getSession(player) then
        options[#options + 1] = { 'Forfeit the duel', function(p)
            endDuel(p:getName(), 'forfeit')
        end }
    else
        if isEnrolled(meId) then
            options[#options + 1] = { 'Challenge a champion', function(p)
                showOpponentMenu(p)
            end }
            options[#options + 1] = { 'Refresh my champion', function(p)
                enroll(p)
            end }
            options[#options + 1] = { 'Retire from the ladder', function(p)
                retire(p)
            end }
        else
            options[#options + 1] = { 'Enroll my champion', function(p)
                enroll(p)
            end }
        end
        options[#options + 1] = { 'My record', function(p)
            local w, l = p:getCharVar('Col_Wins') or 0, p:getCharVar('Col_Losses') or 0
            p:printToPlayer(string.format(
                '[Colosseum] Rating %d (best %d) | %d-%d | Ladder size: %d. Rankings: legendary-ffxi.pages.dev',
                getRating(meId), p:getCharVar('Col_Best_Rating') or 0, w, l,
                #listChampions(-1)),
                xi.msg.channel.SYSTEM_3)
        end }
    end
    options[#options + 1] = { 'Close', function(p) end }

    sendMenu(player, 'Arena Herald', options)
end

-----------------------------------
-- NPC + hooks
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    local herald = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Arena_Herald',
        packetName = string.format('%sArena Herald', xi.icon.STAR_LARGE),
        look       = 3017,
        x = catalog.npcPos.x, y = catalog.npcPos.y, z = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            local meId = player:getID()
            if isEnrolled(meId) then
                player:printToPlayer(string.format(
                    '[Arena Herald] The ladder remembers you, %s. Rating: %d.',
                    player:getName(), getRating(meId)), xi.msg.channel.SYSTEM_3)
            else
                player:printToPlayer(
                    '[Arena Herald] Enroll your champion and your replica fights for your glory - even while you sleep.',
                    xi.msg.channel.SYSTEM_3)
            end
            showHeraldMenu(player)
        end,
    })
    utils.unused(herald)
end)

-- Death during a duel = loss. Composes with other modules' death hooks.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    if getSession(player) then
        endDuel(player:getName(), 'death')
    end
end)

return m
