-----------------------------------
-- domain_invasion.lua
-- DOMAIN INVASION: every 3 hours, Dahaks or Lamiae assault an Escha zone.
-- Zones alternate: Zi'Tah (Dahaks + Azi Dahaka) / Ru'Aun (Lamiae + Naga Raja).
--
-- Architecture mirrors Invasion.lua (Al Zahbi). Key differences:
--   * Two independent battlefields (states keyed by zoneId).
--   * Five-wave structure: escalating trash -> boss wave with adds.
--   * Rewards via addCurrency (Escha Silt, Escha Beads, Domain Points).
--   * Domain Points have a daily cap of 80 per player (charvar-tracked).
--
-- Mob safety rails (same as Al Zahbi invasion):
--   releaseIdOnDisappear, CLAIM_TYPE=NON_EXCLUSIVE, NO_CAPACITY_POINTS,
--   minLevel=maxLevel=explicit, fresh mobsAlive set per wave, state cleared
--   BEFORE despawning on every abort path.
-----------------------------------
require('modules/module_utils')
local catalog  = require('modules/custom/lua/domain_invasion_catalog')
local mechanics = require('modules/custom/lua/mob_mechanics_library')

-----------------------------------
-- Boss hardcore mechanics configs.
-- group IDs 11481 (Azi Dahaka) and 11483 (Naga Raja) get these.
-----------------------------------
local AZI_DAHAKA_MECH =
{
    name = 'Azi Dahaka',
    enrage = { sec = 240, att = 4000, haste = 180,
               msg = 'Azi Dahaka howls with three mouths — the sky tears open!' },
    stance =
    {
        startHpp = 80, periodSec = 20,
        stances =
        {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },
              msg = "Azi Dahaka's scales harden — use magic!" },
            { mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -5000 },
              msg = "Azi Dahaka's breath unravels spells — use weapons!" },
        },
    },
    aoe   = { periodSec = 15, dmgPct = 18,
              msg = 'Azi Dahaka exhales toxic void — tri-breath!' },
    cc    = { periodSec = 25, effect = xi.effect.TERROR, dur = 4,
              msg = "Azi Dahaka's three mouths roar in unison — run!" },
    drain = { periodSec = 10, healPct = 2 },
    phases =
    {
        { hp = 50, action = 'nuke', dmgPct = 35,
          msg = 'Azi Dahaka tears a planar rift — brace yourselves!' },
        { hp = 25, action = 'fury', att = 3500, haste = 100,
          msg = 'Azi Dahaka enters a frenzied rage!' },
        { hp = 10, action = 'doom', dur = 20,
          msg = 'Azi Dahaka marks you for death!' },
    },
    doom = { startHpp = 15, dur = 25,
             msg = 'Darkness seeps in from the void!' },
}

local NAGA_RAJA_MECH =
{
    name = 'Naga Raja',
    enrage = { sec = 240, att = 4000, haste = 180,
               msg = "Naga Raja sheds her skin — her scales gleam with murderous light!" },
    aoe   = { periodSec = 12, dmgPct = 20,
              msg = "Naga Raja sweeps her serpent's tail — knockback!" },
    cc    = { periodSec = 20, effect = xi.effect.TERROR, dur = 4,
              msg = "Naga Raja's gaze paralyzes you with fear!" },
    drain = { periodSec = 10, healPct = 2 },
    phases =
    {
        { hp = 60, action = 'dispel', count = 3,
          msg = "Naga Raja's venom strips your enhancements!" },
        { hp = 30, action = 'fury', att = 3500, haste = 100,
          msg = 'Naga Raja sways into a death-dance!' },
        { hp = 10, action = 'doom', dur = 20,
          msg = 'Naga Raja marks your souls for the deep!' },
    },
    doom = { startHpp = 15, dur = 25,
             msg = 'The serpent queen claims your life!' },
}

-- Maps boss groupId -> mechanics config.
local BOSS_MECH = { [11481] = AZI_DAHAKA_MECH, [11483] = NAGA_RAJA_MECH }

local m = Module:new('domain_invasion')

-----------------------------------
-- Active event states, keyed by zoneId.
-- Each state = { wave, mobsAlive, participants, startedAt, endsAt }
-----------------------------------
local states = {}
-- Explicit !diwarp opt-ins, keyed by zoneId then player name. Values are
-- expiry timestamps so an abandoned pre-window registration cannot leak into
-- a later invasion. Merely being in an Escha zone never makes a player a
-- defender.
local volunteers = {}

local function svWarn(idx) return '[DI]Warn_' .. idx end
local function svDone(idx) return '[DI]Done_' .. idx end

local function currentUtcDay()
    return math.floor(os.time() / 86400)
end

local function windowSecOfDay(w)
    return w.hour * 3600 + w.min * 60
end

local function nowSecOfDay()
    return os.time() % 86400
end

local function broadcast(viaPlayer, msg)
    if not viaPlayer then return end
    pcall(function()
        viaPlayer:printToArea(msg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
    end)
end

local function defendersInZone(zone, zoneId)
    local out = {}
    local ok, players = pcall(function() return zone:getPlayers() end)
    if not ok or not players then return out end
    local zoneVolunteers = volunteers[zoneId] or {}
    local now = os.time()
    for _, p in pairs(players) do
        local expiry = p and zoneVolunteers[p:getName()]
        if expiry and expiry >= now and p:getHP() > 0 then
            out[#out + 1] = p
        end
    end
    return out
end

local function playersInZone(zone)
    local out = {}
    local ok, players = pcall(function() return zone:getPlayers() end)
    if not ok or not players then return out end
    for _, p in pairs(players) do
        if p then out[#out + 1] = p end
    end
    return out
end

-----------------------------------
-- Daily Domain Point cap helpers.
-- Tracks per-player earning in charvar DI_Points_Today, reset by
-- comparing DI_Points_Day (UTC day integer) to the current day.
-----------------------------------
local function awardCurrency(player, silt, beads, points)
    local rew   = catalog.reward
    local cap   = rew.dailyPointCap
    local today = currentUtcDay()
    local stamp = player:getCharVar('DI_Points_Day') or 0
    local soFar = (stamp == today) and (player:getCharVar('DI_Points_Today') or 0) or 0
    local canEarn   = math.max(0, cap - soFar)
    local actualPts = math.min(points, canEarn)

    if silt  > 0 then pcall(function() player:addCurrency('escha_silt',  silt)  end) end
    if beads > 0 then pcall(function() player:addCurrency('escha_beads', beads) end) end
    if actualPts > 0 then
        pcall(function() player:addCurrency('domain_points', actualPts) end)
        player:setCharVar('DI_Points_Today', soFar + actualPts)
        player:setCharVar('DI_Points_Day',   today)
    end
    return actualPts
end

-- forward declarations
local nextWave, endDomainInvasion, beginAssault

-----------------------------------
-- Spawn one mob at the zone's curated invasion battlefield, entirely
-- stat-overridden in Lua. The defender remains the enmity target, but is not
-- used as the spawn origin; this prevents waves appearing in !hunt arenas.
-- zone and zoneId are captured in the onMobDeath closure so wave
-- progression uses the REAL Escha zone, not the groupZoneId (210).
-----------------------------------
local function spawnMob(zone, zoneCfg, zoneId, anchor, def, level, mods, hpMult, opts)
    opts = opts or {}
    local anchorOk, anchorValid = pcall(function()
        return anchor and anchor:getZoneID() == zoneId and anchor:getHP() > 0
    end)
    if not anchorOk or not anchorValid then return nil end

    local points = zoneCfg.spawnPoints or {}
    local origin = points[math.random(math.max(1, #points))] or zoneCfg.rallyPos
    if not origin then return nil end

    local px, py, pz = origin.x, origin.y, origin.z
    local mx, mz
    for _ = 1, catalog.spawnTries or 8 do
        local angle = math.random() * math.pi * 2
        local dist  = catalog.spawnRingMin
                  + math.random() * (catalog.spawnRingMax - catalog.spawnRingMin)
        local cx, cz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist
        local navOk, navigable = pcall(function()
            return zone:isNavigablePoint({ x = cx, y = py, z = cz })
        end)
        if navOk and navigable then
            mx, mz = cx, cz
            break
        end
    end
    -- Never fall back to the origin: it is also the volunteer rally point.
    -- Failing this spawn is safer than materialising an invader on players;
    -- the empty-wave guard below terminates the event if every spawn fails.
    if not mx or not mz then return nil end

    local inserted, mob = pcall(function() return zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = def.groupId,
        groupZoneId          = catalog.groupZoneId,
        name                 = def.name,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = level,
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)
            local st = states[zoneId]
            if not st then return end
            st.mobsAlive[deadMob:getID()] = nil

            if killer and killer:getObjType() == xi.objType.PC then
                killer:setCharVar('Custom_NM_Kills',
                    (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
                killer:setCharVar('DI_Kills',
                    (killer:getCharVar('DI_Kills') or 0) + 1)
            end

            -- Check if all mobs in this wave are gone.
            for _ in pairs(st.mobsAlive) do return end

            -- Wave cleared: pay silt to everyone in zone (not just participants).
            local everyone = playersInZone(zone)
            for _, p in ipairs(everyone) do
                pcall(function()
                    p:addCurrency('escha_silt', catalog.reward.perWaveSilt)
                    p:printToPlayer(string.format(
                        '[Domain Invasion] Wave %d repelled! +%d Escha Silt.',
                        st.wave, catalog.reward.perWaveSilt),
                        xi.msg.channel.SYSTEM_3)
                end)
            end

            local token = st.startedAt
            local anyP  = everyone[1]
            if anyP then
                anyP:timer(catalog.interWaveDelaySec * 1000, function(pp)
                    local cst = states[zoneId]
                    if cst and cst.startedAt == token then
                        nextWave(zone, zoneCfg, zoneId)
                    end
                end)
            else
                endDomainInvasion(zone, zoneCfg, zoneId, 'abandoned')
            end
        end,

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    }) end)

    if not inserted or not mob then return nil end

    local configured = pcall(function()
        mob:setSpawn(mx, py, mz, 0)
        mob:spawn()
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
        mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
        for modId, val in pairs(mods) do mob:setMod(modId, val) end
        if hpMult and hpMult > 1.0 then
            local newMax = math.floor(mob:getMaxHP() * hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
        if opts.modelSize then
            mob:setModelSize(opts.modelSize)
        end
        mob:addEnmity(anchor, 1, 1)
    end)
    if not configured then
        pcall(function() mob:despawn() end)
        return nil
    end

    return mob
end

-----------------------------------
-- Wave launcher.
-----------------------------------
nextWave = function(zone, zoneCfg, zoneId)
    local st = states[zoneId]
    if not st then return end
    st.wave = st.wave + 1
    local waveNum = st.wave
    local w = zoneCfg.waves[waveNum]

    if not w then
        endDomainInvasion(zone, zoneCfg, zoneId, 'victory')
        return
    end

    local defenders = defendersInZone(zone, zoneId)
    if #defenders == 0 then
        endDomainInvasion(zone, zoneCfg, zoneId, 'abandoned')
        return
    end
    for _, p in ipairs(defenders) do
        st.participants[p:getName()] = true
    end

    st.mobsAlive = {}   -- FRESH set — no cross-wave refs

    local count = w.base + w.perDefender * #defenders
    for _ = 1, count do
        local anchor = defenders[math.random(#defenders)]
        local def = {
            groupId = w.groups[math.random(#w.groups)],
            name    = w.names[math.random(#w.names)],
        }
        local mob = spawnMob(zone, zoneCfg, zoneId, anchor, def, w.level, w.mods, w.hpMult)
        if mob then st.mobsAlive[mob:getID()] = mob end
    end

    -- Boss wave: add the named NM on top of the trash.
    if w.boss then
        local anchor = defenders[math.random(#defenders)]
        local mob = spawnMob(zone, zoneCfg, zoneId, anchor,
            { groupId = w.boss.group, name = w.boss.name },
            w.boss.level, w.boss.mods, w.boss.hpMult,
            { modelSize = w.boss.modelSize })
        if mob then
            st.mobsAlive[mob:getID()] = mob
            local mechCfg = BOSS_MECH[w.boss.group]
            if mechCfg then mechanics.attach(mob, mechCfg) end
        end
    end

    -- Spawn sanity: an empty wave must not soft-lock the event.
    local any = false
    for _ in pairs(st.mobsAlive) do any = true; break end
    if not any then
        endDomainInvasion(zone, zoneCfg, zoneId, 'error')
        return
    end

    local secondsLeft = math.max(0, st.endsAt - os.time())
    for _, p in ipairs(playersInZone(zone)) do
        p:printToPlayer(string.format(
            '[Domain Invasion] WAVE %d/%d — %s! (%d foes, Lv.%d%s) %dm %ds on the clock.',
            waveNum, #zoneCfg.waves, w.label,
            count + (w.boss and 1 or 0), w.level,
            w.boss and (' + ' .. w.boss.name) or '',
            math.floor(secondsLeft / 60), secondsLeft % 60),
            xi.msg.channel.SYSTEM_3)
    end
end

-----------------------------------
-- Event end: victory / timeout / abandoned / error.
-- Clears state BEFORE despawning mobs (re-entrancy guard).
-- Only participants (present at a wave start) get the final reward.
-----------------------------------
endDomainInvasion = function(zone, zoneCfg, zoneId, reason)
    local st = states[zoneId]
    if not st then return end
    local mobsToDespawn = st.mobsAlive
    local participants  = st.participants
    states[zoneId] = nil   -- clear first
    volunteers[zoneId] = nil

    for _, mob in pairs(mobsToDespawn or {}) do
        if type(mob) == 'userdata' then
            pcall(function()
                if mob:getHP() > 0 then mob:setHP(0) end
            end)
        end
    end

    local everyone = playersInZone(zone)
    local rew      = catalog.reward

    if reason == 'victory' then
        for _, p in ipairs(everyone) do
            if participants[p:getName()] then
                local pts = awardCurrency(p, rew.victorySilt, rew.victoryBeads, rew.victoryPoints)
                local ptMsg = pts > 0
                    and string.format(', +%d Domain Points', pts)
                    or  ' (daily Domain Point cap reached)'
                p:printToPlayer(string.format(
                    '[Domain Invasion] Victory! +%d Escha Silt, +%d Escha Beads%s.',
                    rew.victorySilt, rew.victoryBeads, ptMsg),
                    xi.msg.channel.SYSTEM_3)
                p:setCharVar('DI_Wins', (p:getCharVar('DI_Wins') or 0) + 1)
            end
        end
        broadcast(everyone[1], string.format(
            '[Domain Invasion] %s is defended! The Escha assault is repelled!',
            zoneCfg.label))

    elseif reason == 'timeout' then
        for _, p in ipairs(everyone) do
            if participants[p:getName()] then
                local pts = awardCurrency(p, rew.timeoutSilt, rew.timeoutBeads, rew.timeoutPoints)
                p:printToPlayer(string.format(
                    '[Domain Invasion] Time expired! Consolation: +%d Silt, +%d Beads%s.',
                    rew.timeoutSilt, rew.timeoutBeads,
                    pts > 0 and string.format(', +%d Domain Points', pts) or ''),
                    xi.msg.channel.SYSTEM_3)
            end
        end
        broadcast(everyone[1], string.format(
            '[Domain Invasion] The Escha forces overwhelm %s — defense failed!',
            zoneCfg.label))

    elseif reason == 'abandoned' then
        broadcast(everyone[1], string.format(
            '[Domain Invasion] The assault on %s fizzles — no defenders remained.',
            zoneCfg.label))
    end
end

-----------------------------------
-- Muster / warm-up before wave 1.
-- The event STARTS (state created, !diwarp works) the instant the window fires,
-- but the first wave is held back musterDelaySec so late defenders can rally in
-- -- fixing "it can be over by the time you warp in". Mirrors the inter-wave
-- token guard (startedAt) so a cancelled/replaced event can't spawn a late wave.
-- endsAt already includes musterDelaySec (set at launch), so the fighting clock
-- is unaffected by the warm-up.
-----------------------------------
beginAssault = function(zone, zoneCfg, zoneId)
    local st = states[zoneId]
    if not st then return end
    local muster = catalog.musterDelaySec or 0
    local anchor = defendersInZone(zone, zoneId)[1]
    if muster <= 0 or not anchor then
        nextWave(zone, zoneCfg, zoneId)   -- no warm-up configured / nobody to time it: start now
        return
    end
    local token = st.startedAt
    broadcast(anchor, string.format(
        '[Domain Invasion] %s is under assault! First wave in %d seconds. !diwarp opts in; other Escha players remain outside the defense.',
        zoneCfg.label, muster))
    anchor:timer(muster * 1000, function(pp)
        local cst = states[zoneId]
        if cst and cst.startedAt == token and cst.wave == 0 then
            nextWave(zone, zoneCfg, zoneId)
        end
    end)
end

-----------------------------------
-- Clock. Per-player re-arming timer in tick zones — checks for invasion
-- start windows and enforces the time-limit deadline.
-----------------------------------
local function checkClock(player)
    local now    = nowSecOfDay()
    local today  = currentUtcDay()
    local zoneId = player:getZoneID()

    -- Deadline check for an active invasion in THIS player's zone.
    local st = states[zoneId]
    if st then
        if os.time() > st.endsAt then
            local zone = player:getZone()
            for _, zc in ipairs(catalog.zones) do
                if zc.zoneId == zoneId then
                    endDomainInvasion(zone, zc, zoneId, 'timeout')
                    break
                end
            end
        end
        return
    end

    -- Check each scheduled window.
    for idx, w in ipairs(catalog.windows) do
        local target    = windowSecOfDay(w)
        local warnAt    = target - catalog.warnMinutes * 60
        local warnWraps = warnAt < 0
        if warnWraps then warnAt = warnAt + 86400 end

        local inWarn = warnWraps
            and (now >= warnAt or now < target)
            or  (now >= warnAt and now < target)

        if inWarn and (GetServerVariable(svWarn(idx)) or 0) ~= today then
            SetServerVariable(svWarn(idx), today)
            local zc = catalog.zones[w.zoneIdx]
            broadcast(player, string.format(
                '[Domain Invasion] Escha beasts mass in %s — attack in ~%d minutes! Type !diwarp to opt in. Hunting League players are not defenders.',
                zc.label, catalog.warnMinutes))
        end

        -- Launch: first tick from a defender in the correct zone wins the mutex.
        if now >= target and now < target + catalog.graceMinutes * 60
           and (GetServerVariable(svDone(idx)) or 0) ~= today then
            local zc = catalog.zones[w.zoneIdx]
            if zoneId == zc.zoneId then
                local zone      = player:getZone()
                local defenders = defendersInZone(zone, zc.zoneId)
                if #defenders > 0 then
                    SetServerVariable(svDone(idx), today)
                    states[zc.zoneId] = {
                        wave         = 0,
                        mobsAlive    = {},
                        participants = {},
                        startedAt    = os.time(),
                        endsAt       = os.time() + (catalog.musterDelaySec or 0) + catalog.timeLimitSec,
                    }
                    broadcast(player, string.format(
                        '[Domain Invasion] THE ESCHA ATTACK! %s is under assault — type !diwarp to opt in and join!',
                        zc.label))
                    beginAssault(zone, zc, zc.zoneId)
                end
            end
        end
    end
end

local CLOCK_ARMED_VAR = 'DI_ClockArmed'
local TICK_ZONE_IDS = { [288] = true, [289] = true }

local function armClock(player)
    player:timer(catalog.tickSeconds * 1000, function(p)
        if not p then return end

        local inTickZone = false
        pcall(function() inTickZone = TICK_ZONE_IDS[p:getZoneID()] == true end)
        if not inTickZone then
            pcall(function() p:setLocalVar(CLOCK_ARMED_VAR, 0) end)
            return
        end

        pcall(function() checkClock(p) end)
        armClock(p)
    end)
end

-- Hook into both Escha zones' onZoneIn to arm the clock.
local TICK_ZONES = { 'Escha_ZiTah', 'Escha_RuAun' }
for _, zoneName in ipairs(TICK_ZONES) do
    require(string.format('scripts/zones/%s/Zone', zoneName))
    m:addOverride(string.format('xi.zones.%s.Zone.onZoneIn', zoneName), function(player, prevZone)
        local result = super(player, prevZone)
        if player:getLocalVar(CLOCK_ARMED_VAR) == 0 then
            player:setLocalVar(CLOCK_ARMED_VAR, 1)
            player:timer(3000, function(p)
                if p then armClock(p) end
            end)
        end
        return result
    end)
end

-- Resolve the warning/grace window in which !diwarp may register before an
-- event exists. Handles the five-minute warning before the midnight window.
local function upcomingVolunteerZone()
    local now = nowSecOfDay()
    local today = currentUtcDay()

    for idx, w in ipairs(catalog.windows) do
        local target = windowSecOfDay(w)
        local warnAt = target - catalog.warnMinutes * 60
        local warnWraps = warnAt < 0
        if warnWraps then warnAt = warnAt + 86400 end

        local inWarn = warnWraps
            and (now >= warnAt or now < target)
            or  (now >= warnAt and now < target)
        local inGrace = now >= target and now < target + catalog.graceMinutes * 60
        local alreadyDone = inGrace and (GetServerVariable(svDone(idx)) or 0) == today

        if (inWarn or inGrace) and not alreadyDone then
            return catalog.zones[w.zoneIdx]
        end
    end

    return nil
end

-----------------------------------
-- Public API (for !di GM command and !diwarp).
-----------------------------------
xi._domain_invasion_api =
{
    isActive = function(zoneId)
        if zoneId then return states[zoneId] ~= nil end
        for _ in pairs(states) do return true end
        return false
    end,

    -- Returns the zoneId of an active DI zone, or nil.
    activeZoneId = function()
        for zid in pairs(states) do return zid end
        return nil
    end,

    -- !diwarp is the explicit opt-in boundary. Register before/during the
    -- muster or while an assault is active, then return the curated rally
    -- position for the command to use.
    volunteer = function(player)
        local zc
        for zid in pairs(states) do
            for _, candidate in ipairs(catalog.zones) do
                if candidate.zoneId == zid then
                    zc = candidate
                    break
                end
            end
            if zc then break end
        end
        zc = zc or upcomingVolunteerZone()

        if not zc or not zc.rallyPos then
            return false, 'No Domain Invasion is active or mustering right now.'
        end

        volunteers[zc.zoneId] = volunteers[zc.zoneId] or {}
        local st = states[zc.zoneId]
        local expiry = st and (st.endsAt + 60)
            or (os.time() + (catalog.warnMinutes + catalog.graceMinutes + 2) * 60)
        volunteers[zc.zoneId][player:getName()] = expiry
        if st then
            st.participants[player:getName()] = true
        end

        return true, zc.zoneId, zc.rallyPos, zc.label
    end,

    info = function(zoneId)
        local st = states[zoneId]
        if not st then return nil end
        for _, zc in ipairs(catalog.zones) do
            if zc.zoneId == zoneId then
                return {
                    label   = zc.label,
                    wave    = st.wave,
                    total   = #zc.waves,
                    endsAt  = st.endsAt,
                }
            end
        end
        return nil
    end,

    forceStart = function(zone)
        local zid = zone:getID()
        if states[zid] then return false, 'Domain Invasion already in progress here.' end
        for _, zc in ipairs(catalog.zones) do
            if zc.zoneId == zid then
                volunteers[zid] = {}
                local expiry = os.time() + (catalog.musterDelaySec or 0) + catalog.timeLimitSec + 60
                for _, player in pairs(zone:getPlayers()) do
                    if player and player:getHP() > 0 then
                        volunteers[zid][player:getName()] = expiry
                    end
                end
                states[zid] = {
                    wave         = 0,
                    mobsAlive    = {},
                    participants = {},
                    startedAt    = os.time(),
                    endsAt       = os.time() + (catalog.musterDelaySec or 0) + catalog.timeLimitSec,
                }
                local players = zone:getPlayers()
                broadcast(players[1], string.format(
                    '[Domain Invasion] THE ESCHA ATTACK! %s is under assault!', zc.label))
                beginAssault(zone, zc, zid)
                return true
            end
        end
        return false, 'Not a Domain Invasion zone.'
    end,

    forceEnd = function(zoneId)
        local st = states[zoneId]
        if not st then return false, 'No active Domain Invasion in that zone.' end
        local mobs = st.mobsAlive
        states[zoneId] = nil
        volunteers[zoneId] = nil
        for _, mob in pairs(mobs or {}) do
            if type(mob) == 'userdata' then
                pcall(function()
                    if mob:getHP() > 0 then mob:setHP(0) end
                end)
            end
        end
        return true
    end,
}

return m
