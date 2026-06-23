-----------------------------------
-- Invasion.lua
-- SCHEDULED INVASIONS: every 3 hours at fixed times, the Voidsent assault
-- Al Zahbi and everyone online is called to defend it. Waves scale with
-- attendance; clear them all inside the time limit for marks + Infamy.
--
-- Clock architecture (no global tick exists in LSB Lua):
--   * Every player zoning into a hub zone gets a re-arming 30s timer
--     (the proven player_trusts pattern). Each tick checks the UTC
--     clock against catalog.windows.
--   * Server-variable stamps make warning/start fire exactly ONCE per
--     window per day no matter how many players are ticking, and they
--     survive restarts.
--   * No defenders in the zone during the grace period = the window
--     burns unused. An invasion with no one to fight it never spawns.
--
-- Mob safety rails (the hard-won set): minLevel+maxLevel+detection on
-- every spawn; releaseIdOnDisappear and a FRESH alive-set per wave (no
-- cross-wave refs - a dangling ref crashes the map server); state is
-- cleared BEFORE despawning on every abort path; NO_CAPACITY_POINTS.
-----------------------------------
require('modules/module_utils')
local catalog   = require('modules/custom/lua/invasion_catalog')
local LOOT_POOL = require('modules/custom/lua/invasion_loot_pool')
local mechanics = require('modules/custom/lua/mob_mechanics_library')

-----------------------------------
-- Hardcore mechanics config for the Voidsent Warlord (final-wave boss only).
-- Every other invader (trash, mini-bosses in waves 1-4) gets no mechanics —
-- they are numerous enough that adding ticks to all of them would be spammy
-- and chaotic. The Warlord alone gets the full treatment.
--
-- addGroupId = 11368 (w.boss.group, already in catalog.waves[5].groups + boss.group)
-- addZoneId  = 210   (catalog.groupZoneId — all invasion groups live there)
-----------------------------------
local WARLORD_MECH_CFG =
{
    name = 'Voidsent Warlord',

    -- If the raid fails to kill it in 3 min, the Warlord goes berserk.
    enrage = { sec = 180, att = 5000, haste = 200,
               msg = 'The Warlord howls — time is up, defenders!' },

    -- Stance dance: alternates between hardening to physical or magical attacks.
    -- DMGPHYS/DMGMAGIC cap at -5000 (=-50% taken) per library rules.
    stance = {
        startHpp  = 90,
        periodSec = 16,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },
              msg = 'The Warlord\'s skin hardens like iron — use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -5000 },
              msg = 'The Warlord\'s aura unravels spells — use weapons!' },
        },
    },

    -- AoE shockwave every 12s.
    aoe = { periodSec = 12, dmgPct = 22,
            msg = 'The Warlord slams the earth — shockwave!' },

    -- Terror pulse every 22s.
    cc  = { periodSec = 22, effect = xi.effect.TERROR, dur = 5,
            msg = 'The Warlord lets out a world-ending roar!' },

    -- Anti-turtle drain: heals 2% max HP every 8s.
    drain = { periodSec = 8, healPct = 2 },

    -- HP phases.
    phases = {
        -- 50% HP: devastating nuke.
        { hp = 50, action = 'nuke', dmgPct = 40,
          msg = 'The Warlord tears open a void-rift — evacuate!' },

        -- 40% HP: strips buffs.
        { hp = 40, action = 'dispel', count = 4,
          msg = 'The Warlord\'s presence unravels your enhancements!' },

        -- 25% HP: fury — speed and power surge.
        { hp = 25, action = 'fury', att = 4000, haste = 120,
          msg = 'The Warlord enters a blood-fury!' },

        -- 10% HP: doom — execute pressure, finish it fast.
        { hp = 10, action = 'doom', dur = 25,
          msg = 'The Warlord marks you all for death!' },
    },

    -- Doom aura at 12% HP (overlaps the phase above for double pressure).
    doom = { startHpp = 12, dur = 30,
             msg = 'Darkness seeps into your soul — the Warlord claims you!' },
}
local LOOT_POOL_SIZE = #LOOT_POOL
local DROP_CHANCE    = 15  -- % per mob kill
require(string.format('scripts/zones/%s/Zone', catalog.zone))

-- Prime Weapons are forge-ONLY (the GM Home Prime Armory, trial-gated). The
-- auto-generated LOOT_POOL is a dump of ALL item_weapon/item_equipment, so it
-- sweeps the 12 Prime IDs in -- skip them here so an invasion can never drop one.
local PRIME_WEAPONS =
{
    [21531] = true, [21534] = true, [21589] = true, [21621] = true,
    [21642] = true, [21781] = true, [21833] = true, [21887] = true,
    [21999] = true, [22102] = true, [22155] = true, [22159] = true,
}

local function tryDrop(killer)
    if not killer then return end
    if killer:getObjType() ~= xi.objType.PC then return end
    if math.random(100) > DROP_CHANCE then return end
    local itemId = LOOT_POOL[math.random(LOOT_POOL_SIZE)]
    if PRIME_WEAPONS[itemId] then return end  -- never drop a Prime Weapon (forge-only)
    pcall(function() killer:addItem(itemId, 1) end)
end

local m = Module:new('invasion')

-----------------------------------
-- Event state (runtime only - a restart mid-event simply ends it; the
-- daily stamp keeps it from re-firing).
--   wave         current wave number (1..#catalog.waves)
--   mobsAlive    { mobId -> mobEntity } CURRENT wave only
--   participants { playerName -> true } anyone present at any wave start
--   endsAt       os.time() deadline
--   startedAt    token guarding stale timers
-----------------------------------
local state = nil

local function svWarn(idx)  return '[Inv]Warn_' .. idx end
local function svDone(idx)  return '[Inv]Done_' .. idx end

local function currentUtcDay()
    return math.floor(os.time() / 86400)
end

-- Seconds-of-day for a window, and for "now" (UTC).
local function windowSecOfDay(w)
    return w.hour * 3600 + w.min * 60
end

local function nowSecOfDay()
    return os.time() % 86400
end

-----------------------------------
-- Broadcast helpers - printToArea needs SOME player entity to send
-- through; callers pass whichever player is at hand (the ticking
-- player or a defender).
-----------------------------------
local function broadcast(viaPlayer, msg)
    if not viaPlayer then return end
    pcall(function()
        viaPlayer:printToArea(msg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
    end)
end

-- Alive players currently in the hub zone.
local function defendersInZone(zone)
    local out = {}
    local ok, players = pcall(function() return zone:getPlayers() end)
    if not ok or not players then return out end
    for _, p in pairs(players) do
        if p and p:getHP() > 0 then
            out[#out + 1] = p
        end
    end
    return out
end

-- Everyone in the zone (any HP) - reward / message distribution.
local function playersInZone(zone)
    local out = {}
    local ok, players = pcall(function() return zone:getPlayers() end)
    if not ok or not players then return out end
    for _, p in pairs(players) do
        if p then out[#out + 1] = p end
    end
    return out
end

local function addMarks(player, n)
    player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + n)
end

-- forward declarations
local nextWave, endInvasion

-----------------------------------
-- Spawn one invader near a defender.
-----------------------------------
local function spawnInvader(zone, anchor, def, level, mods, hpMult, opts)
    opts = opts or {}
    local fs = catalog.fixedSpawn
    local px = fs and fs.x or anchor:getXPos()
    local py = fs and fs.y or anchor:getYPos()
    local pz = fs and fs.z or anchor:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = catalog.spawnRingMin
        + math.random() * (catalog.spawnRingMax - catalog.spawnRingMin)
    local mx, mz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = def.groupId,
        groupZoneId          = catalog.groupZoneId,
        name                 = def.name,
        x = mx, y = py, z = mz,
        rotation             = math.random(0, 255),
        minLevel             = level,   -- REQUIRED (else L255 garbage)
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,  -- REQUIRED
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)  -- free boss mechanics state + despawn its adds (no-op on trash)
            if not state then return end

            -- Per-kill item drop from full item DB.
            pcall(tryDrop, killer)

            state.mobsAlive[deadMob:getID()] = nil

            if killer then
                killer:setCharVar('Custom_NM_Kills',
                    (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
                killer:setCharVar('Inv_Kills',
                    (killer:getCharVar('Inv_Kills') or 0) + 1)
            end

            for _ in pairs(state.mobsAlive) do return end  -- wave still up

            -- Wave cleared. Pay the room, breathe, escalate.
            local z = deadMob:getZone()
            local everyone = playersInZone(z)
            for _, p in ipairs(everyone) do
                addMarks(p, catalog.reward.perWaveMarks)
                p:printToPlayer(string.format(
                    '[Invasion] Wave %d repelled! +%d marks.',
                    state.wave, catalog.reward.perWaveMarks),
                    xi.msg.channel.SYSTEM_3)
            end

            local token = state.startedAt
            local anyP  = everyone[1]
            if anyP then
                anyP:timer(catalog.interWaveDelaySec * 1000, function(pp)
                    if state and state.startedAt == token then
                        nextWave(pp:getZone())
                    end
                end)
            else
                -- Nobody left in zone to carry the timer - call it off.
                endInvasion(z, 'abandoned')
            end
        end,

        -- Mechanics tick: the library no-ops for any mob without an attached config
        -- (all trash invaders), so it is safe to put the call here unconditionally.
        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    })

    if mob then
        mob:setSpawn(mx, py, mz, 0)
        mob:spawn()
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
        -- FJB: NonExclusive claim so the WHOLE raid can fight every invader, not just the
        -- party that tagged it first. The engine's IsMobOwner/isMobOwner checks treat a
        -- CLAIM_TYPE=NonExclusive mob as free-for-all; kill credit goes to the killer
        -- (handled in onMobDeath) and the wave-clear reward pays everyone in the zone.
        mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
        for modId, val in pairs(mods) do mob:setMod(modId, val) end
        if hpMult and hpMult > 1.0 then
            local newMax = math.floor(mob:getMaxHP() * hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
        if opts.modelSize then
            pcall(function() mob:setModelSize(opts.modelSize) end)
        end
        mob:addEnmity(anchor, 1, 1)   -- seed enmity on the spawn anchor; NonExclusive claim (set above) lets the whole raid join in
    end
    return mob
end

-----------------------------------
-- Wave launcher.
-----------------------------------
nextWave = function(zone)
    if not state then return end
    state.wave = state.wave + 1
    local waveNum = state.wave
    local w = catalog.waves[waveNum]

    if not w then
        endInvasion(zone, 'victory')
        return
    end

    local defenders = defendersInZone(zone)
    if #defenders == 0 then
        endInvasion(zone, 'abandoned')
        return
    end
    for _, p in ipairs(defenders) do
        state.participants[p:getName()] = true
    end

    state.mobsAlive = {}   -- FRESH set - never carry prior-wave refs

    local count = w.base + w.perDefender * #defenders
    for i = 1, count do
        local anchor = defenders[math.random(#defenders)]
        local def = {
            groupId = w.groups[math.random(#w.groups)],
            name    = w.names[math.random(#w.names)],
        }
        local mob = spawnInvader(zone, anchor, def, w.level, w.mods, w.hpMult)
        if mob then state.mobsAlive[mob:getID()] = mob end
    end

    -- Final wave: the Warlord rides in with its retinue.
    if w.boss then
        local anchor = defenders[math.random(#defenders)]
        local mob = spawnInvader(zone, anchor,
            { groupId = w.boss.group, name = w.boss.name },
            w.boss.level, w.boss.mods, w.boss.hpMult,
            { modelSize = w.boss.modelSize })
        if mob then
            state.mobsAlive[mob:getID()] = mob
            -- Attach hardcore mechanics to the Warlord AFTER spawn + stat/HP setup
            -- (spawnInvader sets mods + hpMult internally before returning).
            -- Trash invaders in this and earlier waves get nothing — WARLORD_MECH_CFG
            -- is the ONLY attach call in the whole system. The library's tick() is a
            -- no-op for any mob without an attached state, so the unconditional
            -- onMobFight in spawnInvader is safe for all trash.
            mechanics.attach(mob, WARLORD_MECH_CFG)
        end
    end

    -- Spawn sanity: an empty wave must not soft-lock the event.
    local any = false
    for _ in pairs(state.mobsAlive) do any = true break end
    if not any then
        endInvasion(zone, 'error')
        return
    end

    local secondsLeft = math.max(0, state.endsAt - os.time())
    for _, p in ipairs(playersInZone(zone)) do
        p:printToPlayer(string.format(
            '[Invasion] WAVE %d/%d - %s! (%d foes, Lv.%d%s) %dm %ds on the clock.',
            waveNum, #catalog.waves, w.label,
            count + (w.boss and 1 or 0), w.level,
            w.boss and (' + ' .. w.boss.name) or '',
            math.floor(secondsLeft / 60), secondsLeft % 60),
            xi.msg.channel.SYSTEM_3)
    end
end

-----------------------------------
-- End of event - victory / timeout / abandoned / error.
-----------------------------------
endInvasion = function(zone, reason)
    if not state then return end
    local mobsToDespawn = state.mobsAlive
    local participants  = state.participants
    state = nil   -- clear BEFORE touching mobs (re-entrancy guard)
    xi._any_invasion_active = false

    for _, mob in pairs(mobsToDespawn or {}) do
        if type(mob) == 'userdata' then
            pcall(function()
                if mob:getHP() > 0 then mob:setHP(0) end
            end)
        end
    end

    local everyone = playersInZone(zone)
    if reason == 'victory' then
        for _, p in ipairs(everyone) do
            if participants[p:getName()] then
                addMarks(p, catalog.reward.victoryMarks)
                p:setCharVar('Infamy',
                    (p:getCharVar('Infamy') or 0) + catalog.reward.victoryInfamy)
                p:setCharVar('Infamy_Lifetime',
                    (p:getCharVar('Infamy_Lifetime') or 0) + catalog.reward.victoryInfamy)
                p:setCharVar('Inv_Wins', (p:getCharVar('Inv_Wins') or 0) + 1)

                -- Gear-vendor seal loot: guaranteed silver medals, plus a
                -- chance at the gold (Demons) medal. Seals stack to 99, so a
                -- best-effort addItem lands for anyone with a stack or a free
                -- slot; pcall keeps a full inventory from breaking the payout.
                local sealMsg = ''
                for _, s in ipairs(catalog.reward.victorySeals or {}) do
                    pcall(function() p:addItem(s.id, s.qty) end)
                    sealMsg = sealMsg .. string.format(', +%d %s', s.qty, s.name)
                end
                local gold = catalog.reward.victoryGoldSeal
                if gold and math.random(100) <= (gold.chancePercent or 0) then
                    pcall(function() p:addItem(gold.id, gold.qty or 1) end)
                    sealMsg = sealMsg .. string.format(' + a %s!', gold.name)
                end

                p:printToPlayer(string.format(
                    '[Invasion] AL ZAHBI STANDS! +%d marks, +%d Infamy%s.',
                    catalog.reward.victoryMarks, catalog.reward.victoryInfamy, sealMsg),
                    xi.msg.channel.SYSTEM_3)

                local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
                if okAch and ach and ach.onInvasionResult then
                    pcall(function() ach.onInvasionResult(p) end)
                end
                local okWh, wh = pcall(require, 'modules/custom/lua/weekly_hunts')
                if okWh and wh and wh.fire then
                    pcall(function() wh.fire(p, 'invasion_win', {}) end)
                end
            end
        end
        broadcast(everyone[1],
            '[Invasion] Al Zahbi stands! The Voidsent are repelled - glory to the defenders!')
    elseif reason == 'timeout' then
        for _, p in ipairs(everyone) do
            if participants[p:getName()] then
                addMarks(p, catalog.reward.failMarks)
            end
            p:printToPlayer(string.format(
                '[Invasion] The Voidsent withdraw on their own terms... defense failed. +%d marks for the effort.',
                catalog.reward.failMarks), xi.msg.channel.SYSTEM_3)
        end
    elseif reason == 'abandoned' then
        broadcast(everyone[1], '[Invasion] The Voidsent assault fizzles - no defenders remained.')
    end
end

-----------------------------------
-- The clock. Runs on every hub player's re-arming timer; server-var
-- day stamps make each phase fire exactly once per window per day.
-----------------------------------
local function checkClock(player)
    local now    = nowSecOfDay()
    local today  = currentUtcDay()

    -- Active event bookkeeping: deadline enforcement rides the same
    -- tick (defenders are in a tick zone by construction).
    if state then
        if os.time() > state.endsAt then
            endInvasion(player:getZone(), 'timeout')
        end
        return
    end

    for idx, w in ipairs(catalog.windows) do
        local target = windowSecOfDay(w)

        -- Pre-event warning, once per day per window.
        local warnAt = target - catalog.warnMinutes * 60
        local warnWraps = warnAt < 0
        if warnWraps then warnAt = warnAt + 86400 end
        local inWarn = warnWraps
            and (now >= warnAt or now < target)
            or  (now >= warnAt and now < target)
        if inWarn and (GetServerVariable(svWarn(idx)) or 0) ~= today then
            SetServerVariable(svWarn(idx), today)
            broadcast(player, string.format(
                '[Invasion] The Voidsent march on Al Zahbi - assault begins in ~%d minutes! Type !iwarp to join the defense!',
                catalog.warnMinutes))
        end

        -- Launch window: [target, target + grace). First tick with a
        -- defender present wins the mutex and starts the event.
        if now >= target and now < target + catalog.graceMinutes * 60
           and (GetServerVariable(svDone(idx)) or 0) ~= today then
            local zone = player:getZone()
            if player:getZoneID() == catalog.zoneId
               and #defendersInZone(zone) > 0 then
                SetServerVariable(svDone(idx), today)
                state = {
                    wave         = 0,
                    mobsAlive    = {},
                    participants = {},
                    startedAt    = os.time(),
                    endsAt       = os.time() + catalog.timeLimitSec,
                }
                xi._any_invasion_active = true
                broadcast(player,
                    '[Invasion] THE VOIDSENT ARE HERE! Al Zahbi is under attack - type !iwarp to join the fight!')
                nextWave(zone)
            end
        end
    end
end

-- Re-arming per-player ticker (player_trusts pattern), hub zones only.
local function armClock(player)
    player:timer(catalog.tickSeconds * 1000, function(p)
        if p then
            pcall(function() checkClock(p) end)
            armClock(p)
        end
    end)
end

local TICK_ZONES = { 'Al_Zahbi', 'Reisenjima_Henge' }
for _, zoneName in ipairs(TICK_ZONES) do
    require(string.format('scripts/zones/%s/Zone', zoneName))
    m:addOverride(string.format('xi.zones.%s.Zone.onZoneIn', zoneName), function(player, prevZone)
        local result = super(player, prevZone)
        player:timer(3000, function(p) armClock(p) end)
        return result
    end)
end

-----------------------------------
-- Public API for the !invasion GM command.
-- Lives here so closures can reach state, nextWave, endInvasion, etc.
-----------------------------------
xi._invasion_api = {
    isActive = function()
        return state ~= nil
    end,

    info = function()
        if not state then return nil end
        return { wave = state.wave, total = #catalog.waves, endsAt = state.endsAt }
    end,

    -- Initiating player must be inside Al Zahbi so their position can
    -- anchor the first wave's mob spawns.
    forceStart = function(zone)
        if state then return false, 'Invasion already in progress.' end
        state = {
            wave         = 0,
            mobsAlive    = {},
            participants = {},
            startedAt    = os.time(),
            endsAt       = os.time() + catalog.timeLimitSec,
        }
        local players = zone:getPlayers()
        broadcast(players[1],
            '[Invasion] THE VOIDSENT ARE HERE! Al Zahbi is under attack - type !iwarp to join the fight!')
        nextWave(zone)
        return true
    end,

    -- Zone-independent abort: mirrors endInvasion's despawn path but
    -- skips reward distribution (GM abort gives no rewards).
    forceEnd = function()
        if not state then return false, 'No active invasion.' end
        local mobs = state.mobsAlive
        state = nil   -- clear before touching mobs (re-entrancy guard)
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
