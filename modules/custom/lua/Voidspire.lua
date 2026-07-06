-----------------------------------
-- Voidspire.lua
-- THE VOIDSPIRE: an endless, escalating wave gauntlet. Talk to The Voidspire
-- Warden at Escha-RuAun, descend floor by floor; every floor is harder than the
-- last; when you wipe, the run ends and your deepest CLEARED floor is recorded.
--
--   Score = best floor ever cleared (CharVar Voidspire_Best_Floor), shown in
--   game by the Warden / !voidspire and ranked on the leaderboard website.
--
-- This is the Game Master wave engine (GameMaster.lua) evolved for infinity:
--   * Floors never stop; each floor's level/HP/mods/count/affixes scale from
--     voidspire_catalog.lua.
--   * Mob LEVEL caps (~205) -- past that eva/acc outruns L99 gear -- so depth
--     escalates through mods/HP/count/AFFIXES, not raw level.
--   * Same hard-won safety: minLevel+maxLevel + detection are required;
--     releaseIdOnDisappear means we NEVER hold a cross-floor mob ref (a dangling
--     ref crashes the map server inside C++ setHP, uncatchable by pcall); the
--     session is cleared BEFORE despawning on abort; NO_CAPACITY_POINTS blocks
--     CP/JP farming.
--   * Reuses the Game Master mob pool (game_master_catalog) -- NO new SQL.
-----------------------------------
require('modules/module_utils')
local catalog   = require('modules/custom/lua/voidspire_catalog')
local gmCatalog = require('modules/custom/lua/game_master_catalog')  -- mob pools by band
local mechanics = require('modules/custom/lua/mob_mechanics_library')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))
-----------------------------------
local m = Module:new('voidspire')

-- Per-player run state, keyed by char name.
--   floor        - floor currently being fought (1..)
--   clearedFloor - highest floor fully cleared this run (the run's result)
--   mobsAlive    - { mobId -> mobEntity } for the CURRENT floor only. Empty =
--                  cleared. Reset every floor so we never hold a freed
--                  prior-floor entity (dangling ref = map crash).
--   zoneId       - zone the run is in (must match current zone)
--   kills        - total kills this run
--   affixOrder   - per-run shuffled affix list; floor N uses the first
--                  affixCountForFloor(N) entries
--   bannersShown - { floor -> true } depth banners already shown this run
local sessions = {}
local function getSession(player)  return sessions[player:getName()] end
local function clearSession(player) sessions[player:getName()] = nil end

-- forward declarations (assigned below; referenced earlier via upvalues)
local startFloor, endRun, showWardenMenu, onFloorCleared

-----------------------------------
-- Scaling helpers (read voidspire_catalog)
-----------------------------------

-- clamp(base + per*(F-1), .., cap)
local function ramp(spec, floor)
    local v = spec.base + spec.per * (floor - 1)
    if spec.cap then v = math.min(v, spec.cap) end
    return v
end

local function bandDiffForFloor(floor)
    for _, b in ipairs(catalog.bands) do
        if floor <= b.upTo then return b.diff end
    end
    return catalog.bands[#catalog.bands].diff
end

local function mobPoolForFloor(floor)
    local def = gmCatalog.difficulties[bandDiffForFloor(floor)]
    return (def and def.mobs) or gmCatalog.difficulties.Easy.mobs
end

local function mobCountForFloor(floor)
    local n = catalog.scaling.mobsBase + math.floor(floor / catalog.scaling.mobsStep)
    return math.max(1, math.min(n, catalog.scaling.mobsCap))
end

local function affixCountForFloor(floor)
    if floor < catalog.affixStartFloor then return 0 end
    local n = 1 + math.floor((floor - catalog.affixStartFloor) / catalog.affixStep)
    return math.min(n, catalog.affixCap)
end

-- active affixes for a floor = first N of the run's shuffled order
local function activeAffixes(sess, floor)
    local n, out = affixCountForFloor(floor), {}
    for i = 1, math.min(n, #sess.affixOrder) do out[i] = sess.affixOrder[i] end
    return out
end

-- combined per-mob mods (base scaling + affix deltas) in ONE pass, so an affix
-- that touches a base-scaled mod ADDS to it instead of overwriting (setMod is
-- absolute). Result is applied with a single setMod per mod after spawn().
local function floorMods(floor, affixes)
    local mods = {}
    for modId, spec in pairs(catalog.scaling.mods) do
        mods[modId] = math.floor(ramp(spec, floor))
    end
    for _, a in ipairs(affixes) do
        if a.mods then
            for modId, delta in pairs(a.mods) do
                mods[modId] = (mods[modId] or 0) + delta
            end
        end
    end
    return mods
end

local function floorHpMult(floor, affixes)
    local mult = ramp(catalog.scaling.hpBoost, floor)
    for _, a in ipairs(affixes) do
        if a.hpMult then mult = mult * a.hpMult end
    end
    return mult
end

local function floorLevel(floor)
    return math.floor(ramp(catalog.scaling.level, floor))
end

-- Fisher-Yates shuffle of a copy of the affix catalog for a fresh run
local function rollAffixOrder()
    local pool = {}
    for i, a in ipairs(catalog.affixes) do pool[i] = a end
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return pool
end

-----------------------------------
-- Pick the mechCfg for a given floor (highest floorMechanics key <= floor).
-----------------------------------
local function floorMechCfg(floor)
    local best = nil
    for key, cfg in pairs(catalog.floorMechanics or {}) do
        if floor >= key and (best == nil or key > best) then
            best = key
        end
    end
    return best and catalog.floorMechanics[best] or nil
end

-----------------------------------
-- Spawn one floor mob (mirrors GameMaster.spawnWaveMob)
-----------------------------------
local function spawnFloorMob(owner, mobDef, level, mods, hpMult, floor)
    local px, py, pz = owner:getXPos(), owner:getYPos(), owner:getZPos()
    local angle = math.random() * math.pi * 2
    local ring  = catalog.spawnRing
    local dist  = ring.minRadius + math.random() * (ring.maxRadius - ring.minRadius)
    local mx, mz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist
    local rot       = math.random(0, 255)
    local ownerName = owner:getName()
    local zone      = owner:getZone()

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = mobDef.groupId,
        groupZoneId          = catalog.npcPos.zoneId,
        name                 = mobDef.name,
        x = mx, y = py, z = mz, rotation = rot,
        minLevel             = level,   -- REQUIRED (else L255 garbage)
        maxLevel             = level,
        detection            = xi.detects.SIGHT_AND_HEARING,  -- REQUIRED for aggro
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)              -- free mechanics state + despawn its adds
            local sess = sessions[ownerName]
            if not sess then return end
            sess.mobsAlive[deadMob:getID()] = nil
            sess.kills = sess.kills + 1

            -- Killing-blow credit goes to whoever landed it (owner or a helper).
            if killer then
                killer:setCharVar('Custom_NM_Kills',
                    (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
            end

            -- Any floor mob still alive? (All floor mobs spawn upfront, so there
            -- are no pending spawns to wait on -- unlike the GM's staggered wave.)
            for _ in pairs(sess.mobsAlive) do return end  -- still alive -> bail

            -- Floor cleared. Resolve the owner from the live list (captured ref
            -- may be stale after a zone+return) and hand off to onFloorCleared,
            -- which schedules the next floor on a TIMER -- so this callback is
            -- NOT re-entrant (no synchronous endRun loop like GM's abort path).
            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            onFloorCleared(resolved, sess)
        end,

        -- Mechanics ride the combat tick (all pcall-guarded in the library).
        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    })

    if mob then
        mob:setSpawn(mx, py, mz, rot)
        mob:spawn()
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)        -- no CP/JP farm
        for modId, val in pairs(mods) do mob:setMod(modId, val) end  -- AFTER spawn()
        if hpMult and hpMult > 1.0 then
            local newMax = math.floor(mob:getMaxHP() * hpMult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
        mob:updateClaim(owner)                 -- owner gets claim + kill credit
        mob:addEnmity(owner, 30000, 30000)     -- pursue the owner immediately

        -- Attach hardcore mechanics AFTER stats/HP are finalized (library is pcall-safe).
        mechanics.attach(mob, floorMechCfg(floor or 1))
    end
    return mob
end

-----------------------------------
-- Floor cleared -> reward, best, milestones, next floor
-----------------------------------
onFloorCleared = function(player, sess)
    local floor = sess.floor
    sess.clearedFloor = floor

    -- Floor-clear marks (modest -- the prize is the score, not a mark farm).
    local marks = catalog.markBase + catalog.markPerFloor * floor
    player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + marks)

    -- Personal best.
    local best, newBest = player:getCharVar('Voidspire_Best_Floor') or 0, false
    if floor > best then
        player:setCharVar('Voidspire_Best_Floor', floor)
        newBest = true
    end

    -- Depth milestones (bonus marks; title via achievement hook). RELAUNCH:
    -- ONCE PER UTC WEEK PER CHARACTER. The bonus was re-awardable every descent
    -- (floor 25 = 10k marks/run = an unlimited mark farm that bypassed HL); now
    -- each floor's milestone pays only on its first clear of the current ISO week,
    -- gated by VS_MS<floor>_Week. (The TITLE is still one-time via the achievement
    -- hook below; granting an owned title no-ops.)
    local msWeek = tonumber(os.date('!%G%V'))  -- ISO week-year+week, e.g. 202626
    for _, ms in ipairs(catalog.milestones) do
        if floor == ms.floor then
            local wkCv = string.format('VS_MS%d_Week', ms.floor)
            if (player:getCharVar(wkCv) or 0) ~= msWeek then
                player:setCharVar(wkCv, msWeek)
                player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + ms.marks)
                player:printToPlayer(string.format(
                    '[Voidspire] DEPTH %d -- weekly milestone bonus +%d marks!', ms.floor, ms.marks),
                    xi.msg.channel.SYSTEM_3)
            else
                player:printToPlayer(string.format(
                    '[Voidspire] Depth %d milestone already claimed this week.', ms.floor),
                    xi.msg.channel.SYSTEM_1)
            end
        end
    end

    -- Achievement hook. GUARDED: the hook is added to achievements.lua in a
    -- later step; the module must not crash if it isn't there yet.
    local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
    if okAch and ach and ach.onVoidspireFloor then
        pcall(function() ach.onVoidspireFloor(player, floor) end)
    end

    player:printToPlayer(string.format(
        '[Voidspire] Floor %d cleared! +%d marks.%s', floor, marks,
        newBest and ' -- NEW PERSONAL BEST!' or ''),
        xi.msg.channel.SYSTEM_3)

    -- Descend after a short breather. Guard against the run ending (logout /
    -- zone / abort) while the timer is pending.
    player:timer(catalog.floorDelay * 1000, function(p)
        local s = sessions[p:getName()]
        if not s or s.floor ~= floor then return end
        startFloor(p)
    end)
end

-----------------------------------
-- Start the next floor
-----------------------------------
startFloor = function(player)
    local sess = getSession(player)
    if not sess then return end
    if player:getZoneID() ~= sess.zoneId then  -- left the arena
        endRun(player, 'left')
        return
    end

    sess.floor     = sess.floor + 1
    local floor    = sess.floor
    sess.mobsAlive = {}   -- fresh set; never carries a freed prior-floor ref

    local level   = floorLevel(floor)
    local affixes = activeAffixes(sess, floor)
    local mods    = floorMods(floor, affixes)
    local hpMult  = floorHpMult(floor, affixes)
    local count   = mobCountForFloor(floor)
    local pool    = mobPoolForFloor(floor)

    -- Depth banner (first crossing this run).
    for _, b in ipairs(catalog.depthBanners) do
        if floor == b.floor and not sess.bannersShown[b.floor] then
            sess.bannersShown[b.floor] = true
            player:printToPlayer('[Voidspire] ' .. b.text, xi.msg.channel.SYSTEM_3)
        end
    end

    -- Floor announce + active affixes.
    local labels = {}
    for _, a in ipairs(affixes) do labels[#labels + 1] = a.label end
    local affixStr = (#labels > 0) and (' [' .. table.concat(labels, ', ') .. ']') or ''
    player:printToPlayer(string.format(
        '[Voidspire] Floor %d -- %d foe(s), Lv.%d%s', floor, count, level, affixStr),
        xi.msg.channel.SYSTEM_3)

    -- Spawn the whole floor at once (<= mobsCap mobs -- no stagger needed).
    for _ = 1, count do
        local mobDef = pool[math.random(#pool)]
        local mob = spawnFloorMob(player, mobDef, level, mods, hpMult, floor)
        if mob then sess.mobsAlive[mob:getID()] = mob end
    end

    -- Safety: if nothing spawned (pool/engine issue) don't soft-lock the run.
    local any = false
    for _ in pairs(sess.mobsAlive) do any = true; break end
    if not any then
        player:printToPlayer('[Voidspire] Spawn failed -- ending run.', xi.msg.channel.SYSTEM_3)
        endRun(player, 'error')
    end
end

-----------------------------------
-- End the run
-----------------------------------
endRun = function(player, reason)
    local sess = getSession(player)
    if not sess then return end
    local mobsToDespawn = sess.mobsAlive
    local diedOn  = sess.floor or 0
    local cleared = sess.clearedFloor or 0

    -- Clear BEFORE touching mobs: setHP(0) -> Die -> onMobDeath, which would
    -- otherwise re-enter via the floor-clear path. With the session gone the
    -- callback hits its `if not sess` guard and bails.
    clearSession(player)

    local best = player:getCharVar('Voidspire_Best_Floor') or 0
    if reason == 'death' then
        player:printToPlayer(string.format(
            '[Voidspire] You fell on floor %d. Deepest clear this run: %d. Best ever: %d.',
            diedOn, cleared, best), xi.msg.channel.SYSTEM_3)
    elseif reason == 'left' then
        player:printToPlayer(string.format(
            '[Voidspire] You left the spire. Deepest clear this run: %d. Best ever: %d.',
            cleared, best), xi.msg.channel.SYSTEM_3)
    elseif reason == 'abort' then
        player:printToPlayer(string.format(
            '[Voidspire] Descent abandoned. Deepest clear this run: %d.', cleared),
            xi.msg.channel.SYSTEM_3)
    end

    -- Despawn the CURRENT floor's live mobs only (prior floors are already
    -- freed; touching them would crash). Same guard as the Game Master.
    for _, mob in pairs(mobsToDespawn or {}) do
        if type(mob) == 'userdata' and mob:getHP() > 0 then
            pcall(function() mob:setHP(0) end)
        end
    end

    player:setCharVar('Voidspire_Runs_Total',
        (player:getCharVar('Voidspire_Runs_Total') or 0) + 1)
end

-----------------------------------
-- The Voidspire Warden NPC + menu
-----------------------------------
local function sendMenu(player, options)
    local m = { title = 'The Voidspire', options = options }
    player:timer(30, function(p) p:customMenu(m) end)
end

showWardenMenu = function(player)
    local options = {}
    if getSession(player) then
        options[#options + 1] = { 'Abandon current descent', function(p) endRun(p, 'abort') end }
    else
        options[#options + 1] = { 'Descend into the Voidspire', function(p)
            if getSession(p) then return end
            sessions[p:getName()] = {
                floor = 0, clearedFloor = 0, mobsAlive = {}, zoneId = p:getZoneID(),
                kills = 0, affixOrder = rollAffixOrder(), bannersShown = {},
            }
            p:printToPlayer(string.format(
                '[Voidspire] The spire opens. First foes in %d seconds -- survive as deep as you can!',
                catalog.graceDelay), xi.msg.channel.SYSTEM_3)
            p:timer(catalog.graceDelay * 1000, function(pp) startFloor(pp) end)
        end }
    end
    options[#options + 1] = { 'How does the Voidspire work?', function(p)
        p:printToPlayer('[Voidspire] Endless floors, each harder than the last. Clear a floor to descend; wipe and the run ends. Your deepest floor is your score, ranked on the leaderboards. No top -- only how deep you dare.',
            xi.msg.channel.SYSTEM_3)
    end }
    sendMenu(player, options)
end

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    -- One interchangeable Warden per position so multiple players can each run
    -- their own descent at once. All copies share name/look/menu.
    for _, pos in ipairs(catalog.npcPositions or { catalog.npcPos }) do
        local warden = zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = 'Voidspire_Warden',
            packetName = string.format('%sThe Voidspire Warden', xi.icon.STAR_LARGE),
            look       = 19,   -- distinctive; swap for a darker model if you like
            x = pos.x, y = pos.y, z = pos.z,
            rotation   = pos.rot or 128,
            widescan   = 1,
            onTrigger  = function(player, npc)
                local best = player:getCharVar('Voidspire_Best_Floor') or 0
                player:printToPlayer(string.format(
                    '[ The Voidspire Warden ] The spire has no bottom -- only the depth you can survive. Your deepest descent: floor %d.', best),
                    xi.msg.channel.SYSTEM_3)
                showWardenMenu(player)
            end,
        })
        utils.unused(warden)
    end
end)

-- Death -> end the run (despawns the live floor). Composes with other modules'
-- onPlayerDeath handlers via the override system, same as the Game Master.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    if getSession(player) then
        endRun(player, 'death')
    end
end)

return m
