-----------------------------------
-- Voidwatch.lua  --  Voidwatch-flavored rift battles (FJB relaunch)
--
-- Spirit-of-retail Voidwatch on the server's proven custom-NM patterns (pure Lua
-- + insertDynamicEntity + customMenu), NOT the native client light/atmacite UI.
--
-- LOOP:  Voidstones (regen over time / buy with cruor) gate rift opens. Open a
-- rift in the FIELD -> a Planar Rift tears open where you stand and spawns a
-- tier-scaled Voidwalker NM -> kill it -> a Riftworn Pyxis pays Cruor + EXP and
-- your abyssite tier advances (next rift is tougher + pays more). Die, stray, or
-- time out (30 min) and the rift fails (the Voidstone is spent).
--
-- Architecture mirrors ApexTrials.lua: per-player sessions keyed by name; the
-- ownerName captured in the onMobDeath closure (never reuse the dead mob ref);
-- releaseIdOnDisappear so IDs self-reclaim; reward fired on a timer (never
-- re-entrant from the mob callback).
--
-- NPC: Voidwatch Officer in Leafallia (GM Home) -- buy Voidstones, check status.
-- Command: !voidwatch (menu) / !voidwatch open (tear a rift here).
--
-- Tunables in modules/custom/lua/voidwatch_catalog.lua (hot-reload). This file
-- uses addOverride (onPlayerDeath / onGameIn / zone onInitialize) -> ONE map
-- restart to load; after that, catalog + menu tweaks hot-reload.
--
-- PHASE 1 (this file): the core loop above. PHASE 2+: the "lights" reward grid,
-- gear loot tables, atmacite-style cruor upgrades, physical Planar Rift NPCs in
-- zones, mob_mechanics_library hardcore mechanics.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Leafallia/Zone')

local C   = require('modules/custom/lua/voidwatch_catalog')
local m   = Module:new('voidwatch')
local SYS = xi.msg.channel.SYSTEM_3

-- ── Sessions (per player, keyed by name) ────────────────────────────────────
local sessions = {}
xi._voidwatch_sessions = sessions
local function getSession(p)   return sessions[p:getName()] end
local function clearSession(p) sessions[p:getName()] = nil end

-- forward declarations
local onRiftCleared, openRift, failRift, openMenu

-- ── Currency helpers ────────────────────────────────────────────────────────
local function nowTs()
    local ok, t = pcall(os.time)
    return (ok and t) or 0
end

local function ensureBorn(p)
    if (p:getCharVar(C.V.born) or 0) == 1 then return end
    p:setCharVar(C.V.born, 1)
    p:setCharVar(C.V.stones, C.START_STONES)
    p:setCharVar(C.V.stoneTs, nowTs())
    p:setCharVar(C.V.tier, 0)
end

-- Voidstones regenerate 1 per REGEN_SECONDS; reconciled lazily on read.
local function getStones(p)
    ensureBorn(p)
    local stones = p:getCharVar(C.V.stones) or 0
    if stones >= C.MAX_STONES then
        p:setCharVar(C.V.stoneTs, nowTs())  -- keep the anchor fresh while capped
        return C.MAX_STONES
    end
    local ts, now = p:getCharVar(C.V.stoneTs) or 0, nowTs()
    if ts > 0 and now > ts and C.REGEN_SECONDS > 0 then
        local gained = math.floor((now - ts) / C.REGEN_SECONDS)
        if gained > 0 then
            stones = math.min(C.MAX_STONES, stones + gained)
            p:setCharVar(C.V.stones, stones)
            p:setCharVar(C.V.stoneTs, ts + gained * C.REGEN_SECONDS)
        end
    end
    return stones
end

local function setStones(p, n) p:setCharVar(C.V.stones, math.max(0, math.min(C.MAX_STONES, math.floor(n)))) end
local function getCruor(p)     return p:getCharVar(C.V.cruor) or 0 end
local function addCruor(p, n)  p:setCharVar(C.V.cruor, math.max(0, getCruor(p) + math.floor(n))) end
local function getTier(p)      return p:getCharVar(C.V.tier) or 0 end

-- Seconds until the next Voidstone (for the status readout).
local function secsToNextStone(p)
    if getStones(p) >= C.MAX_STONES then return 0 end
    local ts = p:getCharVar(C.V.stoneTs) or 0
    if ts == 0 then return C.REGEN_SECONDS end
    return math.max(0, (ts + C.REGEN_SECONDS) - nowTs())
end

-- ── Spawn one tier-scaled Voidwalker at the player ──────────────────────────
local function spawnVoidwalker(owner, tier)
    local px, py, pz = owner:getXPos(), owner:getYPos(), owner:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = C.SPAWN_DIST_MIN + math.random() * (C.SPAWN_DIST_MAX - C.SPAWN_DIST_MIN)
    local mx, mz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist
    local ownerName = owner:getName()
    local entry = C.ROSTER[math.random(#C.ROSTER)]
    local level = C.nmLevel(tier)

    local mob = owner:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = entry.group,
        groupZoneId          = entry.zone,
        name                 = entry.name,
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
            sess.dead = true
            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            resolved:timer(10, function(p) onRiftCleared(p) end)  -- never re-entrant from the callback
        end,
    })

    if not mob then return nil end
    mob:setSpawn(mx, py, mz, 0)
    mob:spawn()
    pcall(function() mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1) end)
    for modId, val in pairs(C.nmMods(tier)) do
        if val ~= 0 then mob:setMod(modId, val) end
    end
    local hp = C.nmHp(tier)
    mob:setMaxHP(hp)
    mob:setHP(hp)
    pcall(function() mob:addEnmity(owner, 30000, 30000) end)
    return mob, entry.name, level
end

-- ── Rift cleared -> reward + advance tier ───────────────────────────────────
onRiftCleared = function(player)
    local sess = getSession(player)
    if not sess then return end
    clearSession(player)
    local tier = sess.tier

    if tier > getTier(player) then player:setCharVar(C.V.tier, tier) end

    local cruor = C.cruorReward(tier)
    addCruor(player, cruor)
    pcall(function() player:addExp(C.expReward(tier)) end)

    player:printToPlayer(string.format(
        '[Voidwatch] The void recedes -- a Riftworn Pyxis materializes!  +%d cruor.  (total: %d)',
        cruor, getCruor(player)), SYS)
    player:printToPlayer(string.format(
        '[Voidwatch] Tier %d cleared -- your abyssite resonates at tier %d. The next rift will be fiercer.',
        tier, getTier(player)), SYS)
end

-- ── Fail a rift (death / left / timeout) ────────────────────────────────────
failRift = function(player, reason)
    local sess = getSession(player)
    if not sess then return end
    clearSession(player)
    if sess.mob then pcall(function() sess.mob:setHP(0) end) end
    if reason == 'death' then
        player:printToPlayer('[Voidwatch] You fell to the void. The rift seals -- battle failed.', SYS)
    elseif reason == 'left' then
        player:printToPlayer('[Voidwatch] You strayed from the rift -- the void reclaims its monster. Battle failed.', SYS)
    elseif reason == 'timeout' then
        player:printToPlayer('[Voidwatch] The rift destabilized -- the void reclaims its monster. Battle failed.', SYS)
    end
end

-- ── Open a rift here ────────────────────────────────────────────────────────
openRift = function(player)
    ensureBorn(player)
    if getSession(player) then
        player:printToPlayer('[Voidwatch] You are already locked in a rift battle.', SYS)
        return
    end
    if not player:canUseMisc(xi.zoneMisc.PET) then
        player:printToPlayer('[Voidwatch] A rift cannot be torn open in a safe area. Travel to the field first.', SYS)
        return
    end
    local stones = getStones(player)
    if stones < C.RIFT_COST then
        player:printToPlayer(string.format(
            '[Voidwatch] You need %d Voidstone (you have %d). They regenerate over time, or buy them with cruor at the Officer.',
            C.RIFT_COST, stones), SYS)
        return
    end
    setStones(player, stones - C.RIFT_COST)

    local tier = getTier(player) + 1
    sessions[player:getName()] = { tier = tier, dead = false, zoneId = player:getZoneID() }

    local mob, name, level = spawnVoidwalker(player, tier)
    if not mob then
        clearSession(player)
        setStones(player, getStones(player) + C.RIFT_COST)  -- refund
        player:printToPlayer('[Voidwatch] The rift collapsed before it formed (spawn failed). Voidstone refunded.', SYS)
        return
    end
    local sess = getSession(player)
    if sess then sess.mob = mob end

    player:printToPlayer(string.format(
        '[Voidwatch] A Planar Rift tears open!  TIER %d  --  %s (Lv.%d) claws its way out of the void!',
        tier, (name:gsub('_', ' ')), level), SYS)

    -- Battle timer: void out the NM if it isn't slain in time.
    player:timer(C.BATTLE_SECONDS * 1000, function(p)
        local s = sessions[p:getName()]
        if s and not s.dead and s.tier == tier then failRift(p, 'timeout') end
    end)
end

-- ── Buy a Voidstone with cruor ──────────────────────────────────────────────
local function buyStone(player)
    ensureBorn(player)
    if getStones(player) >= C.MAX_STONES then
        player:printToPlayer(string.format('[Voidwatch] You are already at the Voidstone cap (%d).', C.MAX_STONES), SYS)
        return
    end
    if getCruor(player) < C.STONE_CRUOR then
        player:printToPlayer(string.format('[Voidwatch] A Voidstone costs %d cruor (you have %d).', C.STONE_CRUOR, getCruor(player)), SYS)
        return
    end
    addCruor(player, -C.STONE_CRUOR)
    setStones(player, getStones(player) + 1)
    player:printToPlayer(string.format('[Voidwatch] Voidstone acquired. (%d stones, %d cruor)', getStones(player), getCruor(player)), SYS)
end

-- ── Status ──────────────────────────────────────────────────────────────────
local function status(player)
    ensureBorn(player)
    player:printToPlayer(string.format('=== Voidwatch ===  Abyssite tier %d   (next rift: tier %d)', getTier(player), getTier(player) + 1), SYS)
    local nxt = secsToNextStone(player)
    local nxtStr = (getStones(player) >= C.MAX_STONES) and 'capped' or string.format('next in %dm', math.ceil(nxt / 60))
    player:printToPlayer(string.format('  Voidstones: %d/%d  (%s)   |   Cruor: %d', getStones(player), C.MAX_STONES, nxtStr, getCruor(player)), SYS)
    player:printToPlayer('  Go to the field and use "!voidwatch open" to tear open a rift.', SYS)
end

-- ── Menu (shared by the NPC + the command) ──────────────────────────────────
local function show(p, title, options)
    local snap = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snap) end)
end

openMenu = function(player)
    ensureBorn(player)
    player:printToPlayer(string.format('[Voidwatch] Tier %d  |  Voidstones %d/%d  |  Cruor %d',
        getTier(player), getStones(player), C.MAX_STONES, getCruor(player)), SYS)
    show(player, 'Voidwatch', {
        { 'Open a Rift (here)', function(p) openRift(p) end },
        { string.format('Buy Voidstone (%d cruor)', C.STONE_CRUOR), function(p) buyStone(p); openMenu(p) end },
        { 'Status',             function(p) status(p) end },
        { 'Close',              function(p) end },
    })
end

-- ── Death / leave end the rift ──────────────────────────────────────────────
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    if getSession(player) then
        player:timer(2000, function(p) failRift(p, 'death') end)
    end
    return cs
end)

m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)
    pcall(function()
        local sess = getSession(player)
        if sess and player:getZoneID() ~= sess.zoneId then
            failRift(player, 'left')
        end
    end)
end)

-- ── Voidwatch Officer NPC (Leafallia / GM Home) ─────────────────────────────
m:addOverride('xi.zones.Leafallia.Zone.onInitialize', function(zone)
    super(zone)
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Voidwatch_Officer',
        packetName = string.format('%sVoidwatch Officer', xi.icon.STAR_LARGE),
        look       = 2401,
        x          = -13.000,
        y          =   0.000,
        z          =  15.000,
        rotation   =  128,
        widescan   =  1,
        onTrigger  = function(player, npcEnt)
            openMenu(player)
        end,
    })
    utils.unused(npc)
end)

-- ── Public API (for commands/voidwatch.lua) ─────────────────────────────────
xi.voidwatch = xi.voidwatch or {}
xi.voidwatch.menu   = function(p) openMenu(p) end
xi.voidwatch.open   = function(p) openRift(p) end
xi.voidwatch.status = function(p) status(p) end
xi.voidwatch.grantCruor = function(p, n) ensureBorn(p); addCruor(p, math.max(0, n)) end  -- GM test

return m
