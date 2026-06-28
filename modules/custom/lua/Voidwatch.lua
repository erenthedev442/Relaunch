-----------------------------------
-- Voidwatch.lua  --  Voidwatch-flavored rift battles (FJB relaunch)
--
-- Spirit-of-retail Voidwatch on the server's proven custom-NM patterns (pure Lua
-- + insertDynamicEntity + customMenu + entity listeners), NOT the native client
-- light/atmacite UI.
--
-- LOOP:  Voidstones (regen over time / buy with cruor) gate rift opens. Open a
-- rift in the FIELD -> a Planar Rift tears open where you stand and spawns a
-- tier-scaled Voidwalker NM with hidden WEAKNESSES -> probe it with elemental
-- magic / weaponskills / ranged attacks to draw out coloured LIGHTS -> kill it
-- -> a Riftworn Pyxis pays out, shaped by your light alignment (cruor, EXP, loot
-- quality + quantity, atmacite shards). Your abyssite tier then advances (next
-- rift is tougher + pays more). Die, stray, or time out (30 min) and it fails.
--
-- LIGHTS (Phase 2): on rift open, 5 of the weakness pool are mapped at random to
-- the 5 light colours. WEAPONSKILL_USE / MAGIC_USE / RANGE_STATE_EXIT listeners
-- on the player watch what you land on the NM; a match (off cooldown, under cap)
-- adds that colour's light + reveals the weakness. The tally at the kill weights
-- the reward (Green=cruor, Yellow=EXP, Red=quality, Blue=quantity, White=atmacite).
--
-- Architecture mirrors ApexTrials.lua: per-player sessions keyed by name; the
-- ownerName captured in the onMobDeath closure (never reuse the dead mob ref);
-- reward fired on a timer (never re-entrant from the mob callback); the shared
-- mob_mechanics_library drives a tier-scaled hardcore fight.
--
-- NPC: Voidwatch Officer in Leafallia (GM Home). Command: !voidwatch [open].
-- Tunables in modules/custom/lua/voidwatch_catalog.lua (hot-reload). Uses
-- addOverride -> ONE map restart to load; catalog/menu tweaks hot-reload after.
--
-- PHASE 2b (next): the Atmacite Refiner -- spend banked atmacite shards on
-- permanent Voidwatch perks. Shards bank now; the refiner menu comes next.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Leafallia/Zone')

local C         = require('modules/custom/lua/voidwatch_catalog')
local mechanics = require('modules/custom/lua/mob_mechanics_library')
local m         = Module:new('voidwatch')
local SYS       = xi.msg.channel.SYSTEM_3

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
        p:setCharVar(C.V.stoneTs, nowTs())
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
local function getShards(p)    return p:getCharVar(C.V.shards) or 0 end

local function secsToNextStone(p)
    if getStones(p) >= C.MAX_STONES then return 0 end
    local ts = p:getCharVar(C.V.stoneTs) or 0
    if ts == 0 then return C.REGEN_SECONDS end
    return math.max(0, (ts + C.REGEN_SECONDS) - nowTs())
end

-- ── Lights / weakness engine ────────────────────────────────────────────────
-- Map 5 random pool entries to the 5 colours; build a reverse lookup for fast
-- listener matching; zero the tallies + cooldowns.
local function assignWeaknesses(sess)
    local pool = {}
    for i, t in ipairs(C.WEAKNESS_POOL) do pool[i] = t end
    for i = #pool, 2, -1 do                       -- Fisher-Yates
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    sess.weak, sess.trigMap, sess.lights, sess.lastTrig = {}, {}, {}, {}
    for idx, color in ipairs(C.LIGHTS.order) do
        local trig = pool[idx]
        sess.weak[color]       = trig
        sess.trigMap[trig.key] = color
        sess.lights[color]     = 0
        sess.lastTrig[color]   = 0
    end
end

local function announceLight(player, sess, color)
    local cname = C.LIGHTS.names[color]
    local trig  = sess.weak[color]
    player:printToPlayer(string.format(
        '[Voidwatch] Weakness struck by %s -- %s Light!  (%s %d/%d  ->  %s)',
        trig.label, cname, cname, sess.lights[color], C.LIGHTS.cap, C.LIGHTS.boon[color]), SYS)
end

-- Called by the player listeners: trigKey is 'elem:N' / 'ws' / 'ranged'.
local function tryTrigger(player, target, trigKey)
    local sess = sessions[player:getName()]
    if not sess or not sess.mobId or not sess.trigMap then return end
    if not target then return end
    local okId, tid = pcall(function() return target:getID() end)
    if not okId or tid ~= sess.mobId then return end
    local color = sess.trigMap[trigKey]
    if not color then return end                              -- not a weakness this rift
    if (sess.lights[color] or 0) >= C.LIGHTS.cap then return end
    local now = nowTs()
    if (now - (sess.lastTrig[color] or 0)) < C.WEAKNESS_COOLDOWN then return end
    sess.lastTrig[color] = now
    sess.lights[color]   = (sess.lights[color] or 0) + 1
    announceLight(player, sess, color)
end

local function registerListeners(player)
    pcall(function() player:removeListener('VOIDWATCH_MAGIC') end)
    pcall(function() player:removeListener('VOIDWATCH_WS') end)
    pcall(function() player:removeListener('VOIDWATCH_RANGED') end)
    player:addListener('MAGIC_USE', 'VOIDWATCH_MAGIC', function(caster, target, spell, action)
        pcall(function() tryTrigger(caster, target, 'elem:' .. tostring(spell:getElement())) end)
    end)
    player:addListener('WEAPONSKILL_USE', 'VOIDWATCH_WS', function(attacker, target, skill, tp, action, damage)
        pcall(function() tryTrigger(attacker, target, 'ws') end)
    end)
    player:addListener('RANGE_STATE_EXIT', 'VOIDWATCH_RANGED', function(attacker, target, action)
        pcall(function() tryTrigger(attacker, target, 'ranged') end)
    end)
end

local function removeListeners(player)
    pcall(function() player:removeListener('VOIDWATCH_MAGIC') end)
    pcall(function() player:removeListener('VOIDWATCH_WS') end)
    pcall(function() player:removeListener('VOIDWATCH_RANGED') end)
end

-- ── Loot ────────────────────────────────────────────────────────────────────
local function giveItem(player, itemid)
    if not itemid or itemid <= 0 then return false end
    local ok, res = pcall(function()
        if player:getFreeSlotsCount() <= 0 then return false end
        return player:addItem(itemid)
    end)
    return (ok and res) and true or false
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
            pcall(function() mechanics.cleanup(deadMob) end)
            local sess = sessions[ownerName]
            if not sess then return end
            sess.dead = true
            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            resolved:timer(10, function(p) onRiftCleared(p) end)   -- never re-entrant
        end,

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
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
    pcall(function() mechanics.attach(mob, C.mechCfg(tier), ownerName) end)  -- AFTER stats/HP
    return mob, entry.name, level
end

-- ── Rift cleared -> light-weighted Riftworn Pyxis + tier advance ─────────────
onRiftCleared = function(player)
    local sess = getSession(player)
    if not sess then return end
    removeListeners(player)
    clearSession(player)
    local tier = sess.tier
    if tier > getTier(player) then player:setCharVar(C.V.tier, tier) end

    local L      = sess.lights or {}
    local red    = L.RED or 0
    local blue   = L.BLUE or 0
    local green  = L.GREEN or 0
    local yellow = L.YELLOW or 0
    local white  = L.WHITE or 0
    local total  = red + blue + green + yellow + white

    -- cruor (Verdant) + EXP (Amber)
    local cruor = math.floor(C.cruorReward(tier) * (1 + green * C.CRUOR_PER_GREEN))
    local exp   = math.floor(C.expReward(tier)   * (1 + yellow * C.EXP_PER_YELLOW))
    addCruor(player, cruor)
    pcall(function() player:addExp(exp) end)

    -- atmacite shards (Pearl)
    local shards = white * C.SHARD_PER_WHITE
    if shards > 0 then player:setCharVar(C.V.shards, getShards(player) + shards) end

    -- loot: Cerulean = rolls, Vermillion = quality, Pearl >= N = bonus rare
    local rolls = 1 + math.floor(blue / 2) * C.ROLLS_PER_2_BLUE
    local got = 0
    for _ = 1, rolls do
        local q = math.random(100) + red * C.QUALITY_PER_RED
        local tbl = (q >= C.QUALITY_RARE_AT and C.LOOT.rare)
                 or (q >= C.QUALITY_UNCOMMON_AT and C.LOOT.uncommon)
                 or C.LOOT.common
        if giveItem(player, tbl[math.random(#tbl)]) then got = got + 1 end
    end
    if white >= C.WHITE_BONUS_RARE_AT then
        if giveItem(player, C.LOOT.rare[math.random(#C.LOOT.rare)]) then got = got + 1 end
    end

    -- Riftworn Pyxis report
    player:printToPlayer(string.format(
        '[Voidwatch] The void recedes -- a Riftworn Pyxis forms from %d Light%s!',
        total, (total == 1) and '' or 's'), SYS)
    if total > 0 then
        player:printToPlayer(string.format('  Alignment:  R%d  B%d  G%d  Y%d  W%d', red, blue, green, yellow, white), SYS)
    end
    player:printToPlayer(string.format('  Reward:  +%d cruor    +%d EXP    %d item%s%s',
        cruor, exp, got, (got == 1) and '' or 's',
        (shards > 0) and string.format('    +%d atmacite shard%s', shards, (shards == 1) and '' or 's') or ''), SYS)
    player:printToPlayer(string.format(
        '[Voidwatch] Tier %d cleared -- your abyssite resonates at tier %d. The next rift will be fiercer.',
        tier, getTier(player)), SYS)
end

-- ── Fail a rift (death / left / timeout) ────────────────────────────────────
failRift = function(player, reason)
    local sess = getSession(player)
    if not sess then return end
    removeListeners(player)
    clearSession(player)
    if sess.mob then
        pcall(function() mechanics.cleanup(sess.mob) end)
        pcall(function() sess.mob:setHP(0) end)
    end
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
    local sess = { tier = tier, dead = false, zoneId = player:getZoneID() }
    assignWeaknesses(sess)
    sessions[player:getName()] = sess

    local mob, name, level = spawnVoidwalker(player, tier)
    if not mob then
        clearSession(player)
        setStones(player, getStones(player) + C.RIFT_COST)
        player:printToPlayer('[Voidwatch] The rift collapsed before it formed (spawn failed). Voidstone refunded.', SYS)
        return
    end
    sess.mob   = mob
    sess.mobId = mob:getID()
    registerListeners(player)

    player:printToPlayer(string.format(
        '[Voidwatch] A Planar Rift tears open!  TIER %d  --  %s (Lv.%d) claws its way out of the void!',
        tier, (name:gsub('_', ' ')), level), SYS)
    player:printToPlayer(
        '[Voidwatch] Five hidden weaknesses pulse within. Probe with elemental magic, weaponskills, and ranged attacks to draw out the Lights -- they shape your reward.', SYS)

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
    local nxtStr = (getStones(player) >= C.MAX_STONES) and 'capped'
                or string.format('next in %dm', math.ceil(secsToNextStone(player) / 60))
    player:printToPlayer(string.format('  Voidstones: %d/%d (%s)    Cruor: %d    Atmacite shards: %d',
        getStones(player), C.MAX_STONES, nxtStr, getCruor(player), getShards(player)), SYS)
    player:printToPlayer('  Go to the field and "!voidwatch open" to tear a rift. Probe weaknesses to build Lights.', SYS)
end

-- ── Menu (shared by the NPC + the command) ──────────────────────────────────
local function show(p, title, options)
    local snap = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snap) end)
end

openMenu = function(player)
    ensureBorn(player)
    player:printToPlayer(string.format('[Voidwatch] Tier %d  |  Voidstones %d/%d  |  Cruor %d  |  Shards %d',
        getTier(player), getStones(player), C.MAX_STONES, getCruor(player), getShards(player)), SYS)
    show(player, 'Voidwatch', {
        { 'Open a Rift (here)', function(p) openRift(p) end },
        { string.format('Buy Voidstone (%d cruor)', C.STONE_CRUOR), function(p) buyStone(p); openMenu(p) end },
        { 'Status',             function(p) status(p) end },
        { 'Close',              function(p) end },
    })
end

-- ── Death / leave / relog end the rift ──────────────────────────────────────
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
        if not sess then return end
        if gameLogin then
            removeListeners(player)     -- stale session from a mid-rift logout; clear quietly
            clearSession(player)
        elseif player:getZoneID() ~= sess.zoneId then
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
xi.voidwatch.menu       = function(p) openMenu(p) end
xi.voidwatch.open       = function(p) openRift(p) end
xi.voidwatch.status     = function(p) status(p) end
xi.voidwatch.grantCruor = function(p, n) ensureBorn(p); addCruor(p, math.max(0, n)) end  -- GM test

return m
