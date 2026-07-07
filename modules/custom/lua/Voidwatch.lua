-----------------------------------
-- Voidwatch.lua  --  Voidwatch-flavored rift battles (FJB relaunch)
--
-- Spirit-of-retail Voidwatch on the server's proven custom-NM patterns (pure Lua
-- + insertDynamicEntity + customMenu + entity listeners), NOT the native client
-- light/atmacite UI.
--
-- LOOP:  Voidstones (regen over time / buy with cruor) gate rift opens. Examine
-- a PLANAR RIFT out in the field -> a tier-scaled Voidwalker NM with hidden
-- WEAKNESSES claws out where you stand -> probe it with elemental magic /
-- weaponskills / ranged attacks to draw out coloured LIGHTS -> kill it -> a
-- Riftworn Pyxis pays out, shaped by your light alignment (cruor, EXP, loot
-- quality + quantity, atmacite shards). Your abyssite tier then advances. Die,
-- stray, or time out (30 min) and it fails.
--
-- LIGHTS: on rift open, 5 of the weakness pool are mapped at random to the 5
-- light colours. WEAPONSKILL_USE / MAGIC_USE / RANGE_STATE_EXIT listeners on the
-- player watch what lands on the NM; a match (off cooldown, under cap) adds that
-- colour's light + reveals the weakness. The kill tally weights the reward
-- (Green=cruor, Yellow=EXP, Red=quality, Blue=quantity, White=atmacite).
--
-- ATMACITE (Phase 2b): White lights bank atmacite shards; spend them at the
-- Refiner (the Officer's menu) on permanent Voidwatch perks (Fortune/Fervor/
-- Greed/Insight/Attunement/Flow). All perks are Voidwatch-scoped + read at
-- runtime -- no addMod, so no login-persistence/stacking headaches.
--
-- Architecture mirrors ApexTrials.lua: per-player sessions keyed by name; the
-- ownerName captured in the onMobDeath closure; reward fired on a timer (never
-- re-entrant); the shared mob_mechanics_library drives a tier-scaled fight.
--
-- ENTRY: examine a Planar Rift (one per field zone, placed from C.RIFTS) to
-- fight; visit the Voidwatch Officer in Leafallia (GM Home) for Voidstones,
-- the Atmacite Refiner, and status. Command: !voidwatch (menu/status); GM
-- !voidwatch open force-spawns a rift for testing.
--
-- Tunables in modules/custom/lua/voidwatch_catalog.lua (hot-reload). Uses
-- addOverride -> ONE map restart to load; catalog/menu tweaks hot-reload after.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

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

-- ── Currency + atmacite helpers ─────────────────────────────────────────────
local function nowTs()
    local ok, t = pcall(os.time)
    return (ok and t) or 0
end

local function getCruor(p)  return p:getCharVar(C.V.cruor) or 0 end
local function addCruor(p, n) p:setCharVar(C.V.cruor, math.max(0, getCruor(p) + math.floor(n))) end
local function getTier(p)   return p:getCharVar(C.V.tier) or 0 end
local function getShards(p) return p:getCharVar(C.V.shards) or 0 end
local function getAtm(p, key) return p:getCharVar(C.ATM_PREFIX .. key) or 0 end

-- Per-stratum clears (Voidwatch_Strat_<KEY>); effective NM tier = base + clears + 1.
local function getStratClears(p, key) return p:getCharVar(C.STRAT_PREFIX .. key) or 0 end
local function addStratClear(p, key)  p:setCharVar(C.STRAT_PREFIX .. key, getStratClears(p, key) + 1) end

-- atmacite Flow shortens the Voidstone regen interval.
local function effRegenSeconds(p)
    local r = C.REGEN_SECONDS * (1 - math.min(0.6, getAtm(p, 'FLOW') * C.ATM.FLOW_PCT))
    return math.max(300, math.floor(r))
end

local function ensureBorn(p)
    if (p:getCharVar(C.V.born) or 0) == 1 then return end
    p:setCharVar(C.V.born, 1)
    p:setCharVar(C.V.stones, C.START_STONES)
    p:setCharVar(C.V.stoneTs, nowTs())
    p:setCharVar(C.V.tier, 0)
end

-- Voidstones regenerate 1 per effRegenSeconds; reconciled lazily on read.
local function getStones(p)
    ensureBorn(p)
    local stones = p:getCharVar(C.V.stones) or 0
    if stones >= C.MAX_STONES then
        p:setCharVar(C.V.stoneTs, nowTs())
        return C.MAX_STONES
    end
    local regen = effRegenSeconds(p)
    local ts, now = p:getCharVar(C.V.stoneTs) or 0, nowTs()
    if ts > 0 and now > ts and regen > 0 then
        local gained = math.floor((now - ts) / regen)
        if gained > 0 then
            stones = math.min(C.MAX_STONES, stones + gained)
            p:setCharVar(C.V.stones, stones)
            p:setCharVar(C.V.stoneTs, ts + gained * regen)
        end
    end
    return stones
end

local function setStones(p, n) p:setCharVar(C.V.stones, math.max(0, math.min(C.MAX_STONES, math.floor(n)))) end

local function secsToNextStone(p)
    if getStones(p) >= C.MAX_STONES then return 0 end
    local ts = p:getCharVar(C.V.stoneTs) or 0
    if ts == 0 then return effRegenSeconds(p) end
    return math.max(0, (ts + effRegenSeconds(p)) - nowTs())
end

-- ── Lights / weakness engine ────────────────────────────────────────────────
local function lightCap(player) return C.LIGHTS.cap + getAtm(player, 'INSIGHT') * C.ATM.INSIGHT_CAP end

-- Each NM has its OWN fixed weakness set, derived deterministically from its name
-- (so players can learn it; a Periapt reveals it). Returns trigMap {key -> {color,
-- label}} + an ordered list for the reveal.
local function nmSeed(name)
    local h = 0
    for i = 1, #name do h = (h * 31 + name:byte(i)) % 2147483647 end
    return h
end

local function nmWeaknesses(name)
    local base  = nmSeed(name)
    local count = C.NM_WEAK_MIN + (base % C.NM_WEAK_SPAN)         -- 5..9, fixed per NM
    local s     = base
    local function rnd() s = (s * 1103515245 + 12345) % 2147483648; return s end
    local pool = {}
    for i, t in ipairs(C.WEAKNESS_POOL) do pool[i] = t end
    for i = #pool, 2, -1 do local j = (rnd() % i) + 1; pool[i], pool[j] = pool[j], pool[i] end
    local trigMap, ordered = {}, {}
    for i = 1, math.min(count, #pool) do
        local trig  = pool[i]
        local color = C.LIGHTS.order[((i - 1) % #C.LIGHTS.order) + 1]
        trigMap[trig.key]     = { color = color, label = trig.label }
        ordered[#ordered + 1] = { color = color, label = trig.label }
    end
    return trigMap, ordered
end

-- Zero the light tallies + blitz state (after the NM's weaknesses are assigned).
local function initLights(sess)
    sess.lights, sess.lastTrig = {}, {}
    for _, color in ipairs(C.LIGHTS.order) do
        sess.lights[color]   = 0
        sess.lastTrig[color] = 0
    end
    sess.blitz, sess.lastWeakTs = 0, 0
end

local function announceLight(player, color, label, n)
    player:printToPlayer(string.format(
        '[Voidwatch] Weakness struck by %s -- %s Light!  (%s %d/%d  ->  %s)',
        label, C.LIGHTS.names[color], C.LIGHTS.names[color], n, lightCap(player), C.LIGHTS.boon[color]), SYS)
end

-- Called by the player listeners: trigKey is 'elem:N' / 'ws' / 'ranged'.
local function tryTrigger(player, target, trigKey)
    local sess = sessions[player:getName()]
    if not sess or not sess.mobId or not sess.trigMap then return end
    if not target then return end
    local okId, tid = pcall(function() return target:getID() end)
    if not okId or tid ~= sess.mobId then return end
    local entry = sess.trigMap[trigKey]
    if not entry then return end                              -- not a weakness of this NM
    local color, cap = entry.color, lightCap(player)
    if (sess.lights[color] or 0) >= cap then return end
    local now = nowTs()
    local cd  = math.max(1, C.WEAKNESS_COOLDOWN - getAtm(player, 'ATTUNEMENT') * C.ATM.ATTUNE_CD)
    if (now - (sess.lastTrig[color] or 0)) < cd then return end
    sess.lastTrig[color] = now
    sess.lights[color]   = (sess.lights[color] or 0) + 1
    announceLight(player, color, entry.label, sess.lights[color])

    -- Synchronic Blitz: chaining weaknesses quickly grants bonus Lights.
    sess.blitz = ((now - (sess.lastWeakTs or 0)) <= C.BLITZ_WINDOW) and ((sess.blitz or 0) + 1) or 1
    sess.lastWeakTs = now
    if sess.blitz >= C.BLITZ_BONUS_EVERY and (sess.blitz % C.BLITZ_BONUS_EVERY == 0) then
        local bc = C.LIGHTS.order[math.random(#C.LIGHTS.order)]
        if (sess.lights[bc] or 0) < cap then sess.lights[bc] = (sess.lights[bc] or 0) + 1 end
        player:printToPlayer(string.format(
            '[Voidwatch] *** SYNCHRONIC BLITZ x%d -- bonus %s Light! ***', sess.blitz, C.LIGHTS.names[bc]), SYS)
    end
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

-- ── Spawn one tier-scaled Voidwalker (from a stratum roster) at the player ──
local function spawnVoidwalker(owner, tier, roster)
    local px, py, pz = owner:getXPos(), owner:getYPos(), owner:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = C.SPAWN_DIST_MIN + math.random() * (C.SPAWN_DIST_MAX - C.SPAWN_DIST_MIN)
    local mx, mz = px + math.cos(angle) * dist, pz + math.sin(angle) * dist
    local ownerName = owner:getName()
    local entry = roster[math.random(#roster)]
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

-- ── Riftworn Pyxis (physical reward chest; examine within PYXIS_SECONDS) ─────
local pendingPyxis = {}   -- [playerName] = { reward, mob }

local function deliverPyxis(player, reward)
    addCruor(player, reward.cruor)
    pcall(function() player:addExp(reward.exp) end)
    if reward.shards  > 0 then player:setCharVar(C.V.shards, getShards(player) + reward.shards) end
    if reward.periapt > 0 then player:setCharVar(C.V.periapts, (player:getCharVar(C.V.periapts) or 0) + reward.periapt) end
    local got = 0
    for _, itemid in ipairs(reward.items) do if giveItem(player, itemid) then got = got + 1 end end
    player:printToPlayer(string.format(
        '[Voidwatch] The Riftworn Pyxis yields:  +%d cruor    +%d EXP    %d item%s%s    +%d Periapt',
        reward.cruor, reward.exp, got, (got == 1) and '' or 's',
        (reward.shards > 0) and string.format('    +%d shard%s', reward.shards, (reward.shards == 1) and '' or 's') or '',
        reward.periapt), SYS)
end

local function spawnPyxis(player, reward)
    local name = player:getName()
    local old  = pendingPyxis[name]
    if old then                                  -- auto-claim + clear any stale Pyxis first
        pendingPyxis[name] = nil
        pcall(function() old.mob:setStatus(xi.status.DISAPPEAR) end)
        deliverPyxis(player, old.reward)
    end
    local pyxis = player:getZone():insertDynamicEntity({
        objtype              = xi.objType.NPC,
        name                 = 'Riftworn_Pyxis',
        packetName           = 'Riftworn Pyxis',
        look                 = C.PYXIS_LOOK,
        x = player:getXPos(), y = player:getYPos(), z = player:getZPos(),
        rotation             = 0,
        widescan             = 1,
        releaseIdOnDisappear = true,
        onTrigger            = function(trig, npc)
            if trig:getName() ~= name or not pendingPyxis[name] then return end
            pendingPyxis[name] = nil
            deliverPyxis(trig, reward)
            pcall(function() npc:setStatus(xi.status.DISAPPEAR) end)
        end,
    })
    if not pyxis then deliverPyxis(player, reward); return end   -- spawn failed -> deliver inline
    pendingPyxis[name] = { reward = reward, mob = pyxis }
    player:printToPlayer(string.format(
        '[Voidwatch] A Riftworn Pyxis coalesces from the rift -- examine it within %d min to claim your reward.',
        math.floor(C.PYXIS_SECONDS / 60)), SYS)
    player:timer(C.PYXIS_SECONDS * 1000, function(p)
        local pend = pendingPyxis[p:getName()]
        if pend and pend.reward == reward then                  -- still THIS Pyxis -> safety-net claim
            pendingPyxis[p:getName()] = nil
            pcall(function() pend.mob:setStatus(xi.status.DISAPPEAR) end)
            deliverPyxis(p, reward)
            p:printToPlayer('[Voidwatch] The Riftworn Pyxis dissolved -- its contents drift to you anyway.', SYS)
        end
    end)
end

-- ── Rift cleared -> roll the reward, advance the stratum, drop the Pyxis ─────
onRiftCleared = function(player)
    local sess = getSession(player)
    if not sess then return end
    removeListeners(player)
    clearSession(player)
    local tier = sess.tier
    local skey = sess.stratumKey or 'CRIMSON'
    addStratClear(player, skey)

    local L      = sess.lights or {}
    local red    = L.RED or 0
    local blue   = L.BLUE or 0
    local green  = L.GREEN or 0
    local yellow = L.YELLOW or 0
    local white  = L.WHITE or 0
    local total  = red + blue + green + yellow + white

    -- Roll the reward (delivered when the Pyxis is opened).
    local reward =
    {
        cruor   = math.floor(C.cruorReward(tier) * (1 + green * C.CRUOR_PER_GREEN + getAtm(player, 'FORTUNE') * C.ATM.FORTUNE_PCT)),
        exp     = math.floor(C.expReward(tier)   * (1 + yellow * C.EXP_PER_YELLOW + getAtm(player, 'FERVOR') * C.ATM.FERVOR_PCT)),
        shards  = white * C.SHARD_PER_WHITE,
        periapt = 1,
        items   = {},
    }
    local loot  = C.nmLoot(sess.nmName)   -- this NM's own rare/uncommon (+ shared common)
    local rolls = 1 + math.floor(blue / 2) * C.ROLLS_PER_2_BLUE + getAtm(player, 'GREED') * C.ATM.GREED_ROLLS
    for _ = 1, rolls do
        local q = math.random(100) + red * C.QUALITY_PER_RED
        -- A top-quality roll on an abyssite-unlocked band yields a gear piece
        -- (the infamy-unique weapons/armor); otherwise a mat from this NM's table.
        local gear = (q >= C.GEAR_QUALITY_AT) and C.gearRoll(tier) or nil
        if gear then
            reward.items[#reward.items + 1] = gear
        else
            local tbl = (q >= C.QUALITY_RARE_AT and loot.rare)
                     or (q >= C.QUALITY_UNCOMMON_AT and loot.uncommon)
                     or loot.common
            reward.items[#reward.items + 1] = tbl[math.random(#tbl)]
        end
    end
    if white >= C.WHITE_BONUS_RARE_AT then
        reward.items[#reward.items + 1] = loot.rare[math.random(#loot.rare)]
    end

    -- Clear report, then drop the chest.
    local strat = C.STRATUM_BY_KEY[skey]
    local sname = strat and strat.name or 'Voidwatch'
    player:printToPlayer(string.format(
        '[Voidwatch] %s cleared at Tier %d! Your %s abyssite advances to rank %d.',
        sname, tier, sname, getStratClears(player, skey)), SYS)
    if total > 0 then
        player:printToPlayer(string.format('  Alignment:  R%d  B%d  G%d  Y%d  W%d   (%d Lights shape the Pyxis)',
            red, blue, green, yellow, white, total), SYS)
    end
    spawnPyxis(player, reward)
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

-- ── Open a rift here (called by the Planar Rift NPC; GM via !voidwatch open) ──
openRift = function(player, stratumKey)
    ensureBorn(player)
    if getSession(player) then
        player:printToPlayer('[Voidwatch] You are already locked in a rift battle.', SYS)
        return
    end
    if not player:canUseMisc(xi.zoneMisc.PET) then
        player:printToPlayer('[Voidwatch] This rift will not stir in a safe area.', SYS)
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

    local stratum = C.STRATUM_BY_KEY[stratumKey] or C.STRATA[1]
    local tier    = stratum.base + getStratClears(player, stratum.key) + 1
    local sess = { tier = tier, stratumKey = stratum.key, dead = false, zoneId = player:getZoneID() }
    sessions[player:getName()] = sess

    local mob, name, level = spawnVoidwalker(player, tier, stratum.roster)
    if not mob then
        clearSession(player)
        setStones(player, getStones(player) + C.RIFT_COST)
        player:printToPlayer('[Voidwatch] The rift collapsed before it formed (spawn failed). Voidstone refunded.', SYS)
        return
    end
    sess.mob    = mob
    sess.mobId  = mob:getID()
    sess.nmName = name                                 -- for per-NM loot at reward time
    sess.trigMap, sess.weakList = nmWeaknesses(name)   -- this NM's specific weakness set
    initLights(sess)
    registerListeners(player)

    player:printToPlayer(string.format(
        '[Voidwatch] A Planar Rift tears open!  %s, Tier %d  --  %s (Lv.%d) claws its way out of the void!',
        stratum.name, tier, (name:gsub('_', ' ')), level), SYS)
    player:printToPlayer(string.format(
        '[Voidwatch] %d hidden weaknesses lurk within. Probe with magic / weaponskills / ranged -- or "!voidwatch reveal" (spends a Periapt) to expose them. Chain weaknesses fast for a Synchronic Blitz.', #sess.weakList), SYS)

    player:timer(C.BATTLE_SECONDS * 1000, function(p)
        local s = sessions[p:getName()]
        if s and not s.dead and s.tier == tier then failRift(p, 'timeout') end
    end)
end

-- ── Menu helper ─────────────────────────────────────────────────────────────
local function show(p, title, options)
    local snap = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snap) end)
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
    player:printToPlayer('=== Voidwatch ===', SYS)
    local nxtStr = (getStones(player) >= C.MAX_STONES) and 'capped'
                or string.format('next in %dm', math.ceil(secsToNextStone(player) / 60))
    player:printToPlayer(string.format('  Voidstones: %d/%d (%s)    Cruor: %d    Shards: %d    Periapts: %d',
        getStones(player), C.MAX_STONES, nxtStr, getCruor(player), getShards(player), player:getCharVar(C.V.periapts) or 0), SYS)
    for _, s in ipairs(C.STRATA) do
        local clears = getStratClears(player, s.key)
        player:printToPlayer(string.format('  %-16s rank %d  (next rift: Tier %d)', s.name, clears, s.base + clears + 1), SYS)
    end
    player:printToPlayer('  Examine a Planar Rift in the field (each zone belongs to a stratum) to fight. Probe weaknesses to build Lights.', SYS)
end

-- ── Periapt of Emergence: reveal the current NM's weaknesses ────────────────
local function revealWeaknesses(player)
    local sess = getSession(player)
    if not sess or not sess.weakList then
        player:printToPlayer('[Voidwatch] You are not in a rift battle.', SYS)
        return
    end
    local per = player:getCharVar(C.V.periapts) or 0
    if per < 1 then
        player:printToPlayer('[Voidwatch] You have no Periapts of Emergence. (You earn 1 per rift cleared.)', SYS)
        return
    end
    player:setCharVar(C.V.periapts, per - 1)
    player:printToPlayer('[Voidwatch] You crack a Periapt of Emergence -- the void recoils, its weaknesses laid bare:', SYS)
    for _, w in ipairs(sess.weakList) do
        player:printToPlayer(string.format('   %-16s ->  %s Light  (%s)', w.label, C.LIGHTS.names[w.color], C.LIGHTS.boon[w.color]), SYS)
    end
end

-- ── Atmacite Refiner ────────────────────────────────────────────────────────
local function buyPerk(player, key)
    ensureBorn(player)
    local perk
    for _, pk in ipairs(C.ATMACITE) do if pk.key == key then perk = pk break end end
    if not perk then return end
    local lvl = getAtm(player, key)
    if lvl >= perk.max then
        player:printToPlayer(string.format('[Atmacite] %s is already at max (%d).', perk.name, perk.max), SYS)
        return
    end
    local cost = C.atmCost(lvl + 1)
    if getShards(player) < cost then
        player:printToPlayer(string.format('[Atmacite] %s Lv%d needs %d shards (you have %d).', perk.name, lvl + 1, cost, getShards(player)), SYS)
        return
    end
    player:setCharVar(C.V.shards, getShards(player) - cost)
    player:setCharVar(C.ATM_PREFIX .. key, lvl + 1)
    player:printToPlayer(string.format('[Atmacite] %s -> Lv%d.  (%d shards left)', perk.name, lvl + 1, getShards(player)), SYS)
end

local function openRefiner(player)
    ensureBorn(player)
    player:printToPlayer(string.format('=== Atmacite Refiner ===   Shards: %d', getShards(player)), SYS)
    local opts = {}
    for _, pk in ipairs(C.ATMACITE) do
        local lvl   = getAtm(player, pk.key)
        local label = (lvl >= pk.max) and string.format('%s %d MAX', pk.name, lvl)
                                       or  string.format('%s %d (%dsh)', pk.name, lvl, C.atmCost(lvl + 1))
        player:printToPlayer(string.format('  %s [%d/%d] -- %s', pk.name, lvl, pk.max, pk.desc), SYS)
        local key = pk.key
        opts[#opts + 1] = { label, function(p) buyPerk(p, key); openRefiner(p) end }
    end
    opts[#opts + 1] = { 'Close', function(p) end }
    show(player, 'Atmacite Refiner', opts)
end

-- ── Officer menu (shared by the NPC + the command) ──────────────────────────
openMenu = function(player)
    ensureBorn(player)
    player:printToPlayer(string.format('[Voidwatch] Voidstones %d/%d  |  Cruor %d  |  Atmacite shards %d   (Status = per-stratum ranks)',
        getStones(player), C.MAX_STONES, getCruor(player), getShards(player)), SYS)
    show(player, 'Voidwatch Officer', {
        { string.format('Buy Voidstone (%d cruor)', C.STONE_CRUOR), function(p) buyStone(p); openMenu(p) end },
        { 'Atmacite Refiner', function(p) openRefiner(p) end },
        { 'Status',           function(p) status(p) end },
        { 'Close',            function(p) end },
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
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Voidwatch_Officer',
        packetName = string.format('%sVoidwatch Officer', xi.icon.STAR_LARGE),
        look       = 244,
        x          = 554.971,
        y          =   -3.360,
        z          =  544.586,
        rotation   =  64,
        widescan   =  1,
        onTrigger  = function(player, npcEnt)
            openMenu(player)
        end,
    })
    utils.unused(npc)
end)

-- ── Planar Rift NPCs (one per field zone; examine to open a rift) ───────────
for _, r in ipairs(C.RIFTS) do
    local okReq = pcall(function() require('scripts/zones/' .. r.zone .. '/Zone') end)
    if okReq then
        local stratumKey = C.ZONE_STRATUM[r.zone] or 'CRIMSON'
        m:addOverride('xi.zones.' .. r.zone .. '.Zone.onInitialize', function(zone)
            super(zone)
            local npc = zone:insertDynamicEntity({
                objtype    = xi.objType.NPC,
                name       = 'Planar_Rift',
                packetName = 'Planar Rift',
                look       = C.RIFT_LOOK,
                x          = r.x,
                y          = r.y,
                z          = r.z,
                rotation   = r.rot,
                widescan   = 1,
                onTrigger  = function(player, npcEnt)
                    openRift(player, stratumKey)
                end,
            })
            utils.unused(npc)
        end)
    end
end

-- ── Public API (for commands/voidwatch.lua) ─────────────────────────────────
xi.voidwatch = xi.voidwatch or {}
xi.voidwatch.menu       = function(p) openMenu(p) end
xi.voidwatch.open       = function(p, key) openRift(p, key) end   -- GM-gated in the command (key optional)
xi.voidwatch.status     = function(p) status(p) end
xi.voidwatch.reveal     = function(p) revealWeaknesses(p) end
xi.voidwatch.refiner    = function(p) openRefiner(p) end
xi.voidwatch.grantCruor = function(p, n) ensureBorn(p); addCruor(p, math.max(0, n)) end  -- GM test
xi.voidwatch.grantShards = function(p, n) ensureBorn(p); p:setCharVar(C.V.shards, getShards(p) + math.max(0, n)) end  -- GM test

return m
