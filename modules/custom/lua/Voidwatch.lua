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
-- fight; visit the Voidwatch Officer in the zone-44 hub for Voidstones,
-- the Atmacite Refiner, and status. Command: !voidwatch (menu/status); GM
-- !voidwatch open force-spawns a rift for testing.
--
-- Tunables in modules/custom/lua/voidwatch_catalog.lua (hot-reload). Uses
-- addOverride -> ONE map restart to load; catalog/menu tweaks hot-reload after.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/voidwalker')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local C         = require('modules/custom/lua/voidwatch_catalog')
local mechanics = require('modules/custom/lua/mob_mechanics_library')
local unityProgress = require('modules/custom/lua/unity_wanted_progress')
local waveProgress  = require('modules/custom/lua/game_master_progress')
local m         = Module:new('voidwatch')
local SYS       = xi.msg.channel.SYSTEM_3

-- ── Sessions (per player, keyed by name) ────────────────────────────────────
local sessions = {}
xi._voidwatch_sessions = sessions
local function getSession(p)   return sessions[p:getName()] end
local function clearSession(p) sessions[p:getName()] = nil end
local nextSessionId = 0

-- forward declarations
local onRiftCleared, openRift, confirmRift, failRift, openMenu
local openWarpMenu, openWarpStratum

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

local function addMarks(player, amount)
    if amount <= 0 then return end
    player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + math.floor(amount))
end

local function creditUniqueKill(player, nmName)
    if not player or not nmName then return false end
    local key = 'VW_NM_' .. nmName
    if (player:getCharVar(key) or 0) ~= 0 then return false end
    player:setCharVar(key, 1)
    player:setCharVar('VW_Unique_Kills', (player:getCharVar('VW_Unique_Kills') or 0) + 1)
    addMarks(player, C.FIRST_NM_MARK_BONUS)
    player:printToPlayer(string.format(
        '[Voidwatch] First defeat of %s recorded. +%d Hunt Marks.',
        nmName:gsub('_', ' '), C.FIRST_NM_MARK_BONUS), SYS)
    return true
end

local function eligiblePlayers(owner)
    local out, seen, members = {}, {}, nil
    pcall(function() members = owner:getAlliance() end)
    if not members or #members == 0 then
        pcall(function() members = owner:getParty() end)
    end
    members = members or {}
    members[#members + 1] = owner

    for _, member in ipairs(members) do
        pcall(function()
            local name = member:getName()
            if member:isPC() and member:getZoneID() == owner:getZoneID() and not seen[name] then
                seen[name] = true
                out[#out + 1] = member
            end
        end)
    end
    return out
end

local function groupRiftOwner(player)
    for _, member in ipairs(eligiblePlayers(player)) do
        if getSession(member) then return member:getName() end
    end
    return nil
end

local function stratumUnlocked(player, stratum)
    local key = stratum and stratum.key or 'CRIMSON'
    if key == 'CRIMSON' then
        return (player:getCharVar('HL_Tier') or 1) >= 3,
            'reach Hunting League Rank 3'
    elseif key == 'INDIGO' or key == 'JADE' then
        return (player:getCharVar('Voidspire_Best_Floor') or 0) >= 10
                and waveProgress.hasThrough(player, 3),
            'reach Voidspire floor 10 and clear Wave Master through Hard'
    elseif key == 'WHITE' or key == 'ASHEN' then
        return (player:getCharVar('Voidspire_Best_Floor') or 0) >= 40
                and unityProgress.tierComplete(player, 2),
            'reach Voidspire floor 40 and conquer Unity Wanted Tier 2'
    elseif key == 'HYACINTH' then
        return (player:getCharVar('Voidspire_Best_Floor') or 0) >= 75
                and waveProgress.hasThrough(player, 4),
            'reach Voidspire floor 75 and clear Wave Master Insane'
    elseif key == 'AMBER' then
        return (player:getCharVar('Nyzul_F100_Cleared') or 0) == 1
                or (player:getCharVar('Voidspire_Best_Floor') or 0) >= 90,
            'record Nyzul floor 100 or reach Voidspire floor 90'
    end
    return true, ''
end

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

local function announceLight(player, color, label, n, cap)
    player:printToPlayer(string.format(
        '[Voidwatch] Weakness struck by %s -- %s Light!  (%s %d/%d  ->  %s)',
        label, C.LIGHTS.names[color], C.LIGHTS.names[color], n, cap, C.LIGHTS.boon[color]), SYS)
end

-- Called by the player listeners: trigKey is 'elem:N' / 'ws' / 'ranged'.
local function tryTrigger(player, target, trigKey, ownerName)
    local sess = sessions[ownerName or player:getName()]
    if not sess or not sess.mobId or not sess.trigMap then return end
    if not target then return end
    local okId, tid = pcall(function() return target:getID() end)
    if not okId or tid ~= sess.mobId then return end
    local entry = sess.trigMap[trigKey]
    if not entry then return end                              -- not a weakness of this NM
    local owner = GetPlayerByName(sess.ownerName) or player
    local color, cap = entry.color, lightCap(owner)
    if (sess.lights[color] or 0) >= cap then return end
    local now = nowTs()
    local cd  = math.max(1, C.WEAKNESS_COOLDOWN - getAtm(owner, 'ATTUNEMENT') * C.ATM.ATTUNE_CD)
    if (now - (sess.lastTrig[color] or 0)) < cd then return end
    sess.lastTrig[color] = now
    sess.lights[color]   = (sess.lights[color] or 0) + 1
    announceLight(player, color, entry.label, sess.lights[color], cap)

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

local function registerListeners(player, ownerName)
    local magicId = 'VOIDWATCH_MAGIC_' .. ownerName
    local wsId = 'VOIDWATCH_WS_' .. ownerName
    local rangedId = 'VOIDWATCH_RANGED_' .. ownerName
    pcall(function() player:removeListener(magicId) end)
    pcall(function() player:removeListener(wsId) end)
    pcall(function() player:removeListener(rangedId) end)
    player:addListener('MAGIC_USE', magicId, function(caster, target, spell, action)
        pcall(function() tryTrigger(caster, target, 'elem:' .. tostring(spell:getElement()), ownerName) end)
    end)
    player:addListener('WEAPONSKILL_USE', wsId, function(attacker, target, skill, tp, action, damage)
        pcall(function() tryTrigger(attacker, target, 'ws', ownerName) end)
    end)
    player:addListener('RANGE_STATE_EXIT', rangedId, function(attacker, target, action)
        pcall(function() tryTrigger(attacker, target, 'ranged', ownerName) end)
    end)
end

local function removeListeners(player, ownerName)
    pcall(function() player:removeListener('VOIDWATCH_MAGIC_' .. ownerName) end)
    pcall(function() player:removeListener('VOIDWATCH_WS_' .. ownerName) end)
    pcall(function() player:removeListener('VOIDWATCH_RANGED_' .. ownerName) end)
end

local function registerPartyListeners(owner, sess)
    sess.listenerPlayers = {}
    for _, member in ipairs(eligiblePlayers(owner)) do
        registerListeners(member, sess.ownerName)
        sess.listenerPlayers[#sess.listenerPlayers + 1] = member
    end
end

local function removeSessionListeners(sess)
    for _, player in ipairs((sess and sess.listenerPlayers) or {}) do
        removeListeners(player, sess.ownerName)
    end
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
            -- Credit every present alliance member. Helpers should not need to
            -- reopen all 19 rifts as owners to satisfy Mythic Stage II.
            for _, member in ipairs(eligiblePlayers(resolved)) do
                pcall(function() creditUniqueKill(member, sess.nmName) end)
            end
            resolved:timer(10, function(p) onRiftCleared(p) end)   -- never re-entrant
        end,

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
            xi.voidwalker.applyCombatBehavior(mfMob)
        end,
    })

    if not mob then return nil end
    mob:setSpawn(mx, py, mz, 0)
    mob:spawn()
    pcall(function() mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1) end)
    for modId, val in pairs(C.nmMods(tier)) do mob:setMod(modId, val) end
    -- Dynamic entities inherit their donor pool. Clear healing authoritatively
    -- so stale SQL/template values cannot recreate the reported regen wall.
    mob:setMod(xi.mod.REGEN, 0)
    local hp = C.nmHp(tier)
    mob:setMaxHP(hp)
    mob:setHP(hp)
    xi.voidwalker.applySpawnBehavior(mob)
    pcall(function() mob:addEnmity(owner, 30000, 30000) end)
    pcall(function() mechanics.attach(mob, C.mechCfg(tier)) end)  -- AFTER stats/HP; target party takes mechanics
    return mob, entry.name, level
end

-- ── Riftworn Pyxis (physical reward chest; examine within PYXIS_SECONDS) ─────
local pendingPyxis = {}   -- [playerName] = { reward, mob, id }

-- Despawn a Pyxis so every client actually SEES it go. setStatus(DISAPPEAR)
-- alone sends no packet, and the dynamic-entity reaper then deletes the NPC
-- while silently erasing it from each client's spawn list -- leaving a
-- clickable ghost chest whose next click soft-locks the client (movement
-- lock until zoning; live report 2026-07-10, W. Sarutabaruta rift).
-- hideNPC() broadcasts a real ENTITY_DESPAWN before flipping the status;
-- releaseIdOnDisappear then reaps the entity on the next zone tick, and the
-- hide's queued "reappear" dies with the entity. The setStatus fallback
-- covers a chest whose status already left NORMAL (hideNPC no-ops there).
local function despawnPyxis(chest)
    pcall(function() chest:hideNPC(3600) end)
    pcall(function() chest:setStatus(xi.status.DISAPPEAR) end)
end

local function deliverPyxis(player, reward)
    addCruor(player, reward.cruor)
    addMarks(player, reward.marks or 0)
    pcall(function() player:addExp(reward.exp) end)
    if reward.shards  > 0 then player:setCharVar(C.V.shards, getShards(player) + reward.shards) end
    if reward.periapt > 0 then player:setCharVar(C.V.periapts, (player:getCharVar(C.V.periapts) or 0) + reward.periapt) end
    local got = 0
    for _, itemid in ipairs(reward.items) do if giveItem(player, itemid) then got = got + 1 end end
    player:printToPlayer(string.format(
        '[Voidwatch] The Riftworn Pyxis yields: +%d cruor  +%d EXP  +%d marks  %d item%s%s  +%d Periapt',
        reward.cruor, reward.exp, reward.marks or 0, got, (got == 1) and '' or 's',
        (reward.shards > 0) and string.format('    +%d shard%s', reward.shards, (reward.shards == 1) and '' or 's') or '',
        reward.periapt), SYS)
end

local function spawnPyxis(player, reward)
    local name = player:getName()
    local old  = pendingPyxis[name]
    if old then                                  -- auto-claim + clear any stale Pyxis first
        pendingPyxis[name] = nil
        despawnPyxis(old.mob)
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
            -- Owner only, a claim still pending, and THIS chest is the pending
            -- one (id check: a stale chest must never pay out or eat the new
            -- chest's claim). A bare return is safe -- the engine releases the
            -- client after a no-event trigger on a live entity.
            local pend = pendingPyxis[name]
            if trig:getName() ~= name or not pend or pend.id ~= npc:getID() then
                return
            end
            pendingPyxis[name] = nil
            despawnPyxis(npc)   -- despawn FIRST: a loot hiccup can never strand the chest
            local ok, err = pcall(function() deliverPyxis(trig, reward) end)
            if not ok then
                print(string.format('[voidwatch] deliverPyxis failed for %s: %s', name, tostring(err)))
                trig:printToPlayer('[Voidwatch] The Pyxis crumbles strangely -- if your reward is missing, contact a GM.', SYS)
            end
        end,
    })
    if not pyxis then deliverPyxis(player, reward); return end   -- spawn failed -> deliver inline
    pendingPyxis[name] = { reward = reward, mob = pyxis, id = pyxis:getID() }
    player:printToPlayer(string.format(
        '[Voidwatch] A Riftworn Pyxis coalesces from the rift -- examine it within %d min to claim your reward.',
        math.floor(C.PYXIS_SECONDS / 60)), SYS)
    player:timer(C.PYXIS_SECONDS * 1000, function(p)
        local pend = pendingPyxis[p:getName()]
        if pend and pend.reward == reward then                  -- still THIS Pyxis -> safety-net claim
            pendingPyxis[p:getName()] = nil
            despawnPyxis(pend.mob)
            deliverPyxis(p, reward)
            p:printToPlayer('[Voidwatch] The Riftworn Pyxis dissolved -- its contents drift to you anyway.', SYS)
        end
    end)
end

-- ── Rift cleared -> roll the reward, advance the stratum, drop the Pyxis ─────
onRiftCleared = function(player)
    local sess = getSession(player)
    if not sess then return end
    removeSessionListeners(sess)
    clearSession(player)
    local tier = sess.tier
    local skey = sess.stratumKey or 'CRIMSON'
    if tier > getTier(player) then
        player:setCharVar(C.V.tier, tier)
    end
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
        marks   = C.markReward(tier),
    }
    local loot  = C.nmLoot(sess.nmName)   -- this NM's own rare/uncommon (+ shared common)
    local rolls = 1 + math.floor(blue / 2) * C.ROLLS_PER_2_BLUE + getAtm(player, 'GREED') * C.ATM.GREED_ROLLS
    for _ = 1, rolls do
        local q = math.random(100) + red * C.QUALITY_PER_RED
        -- Every roll picks from this NM's own rare/uncommon/common tables based
        -- on the quality tier. The tier-gated GEAR_BANDS gearRoll was REMOVED
        -- 2026-07-13 (owner: drops must match the docs; the bands silently
        -- injected 53 items -- Nyame / Malignance / Sakpata / Idris / Epeolatry
        -- / Trust-Prestige-Sworn apex sets / etc. -- that never appeared on the
        -- site's Voidwatch page). See voidwatch_catalog.lua for the removal.
        local tbl = (q >= C.QUALITY_RARE_AT and loot.rare)
                 or (q >= C.QUALITY_UNCOMMON_AT and loot.uncommon)
                 or loot.common
        reward.items[#reward.items + 1] = tbl[math.random(#tbl)]
    end
    if white >= C.WHITE_BONUS_RARE_AT then
        reward.items[#reward.items + 1] = loot.rare[math.random(#loot.rare)]
    end
    -- Sortie earrings use an independent alignment-shaped roll. They no longer
    -- replace the NM's signature item inside the rare table.
    if loot.earrings and #loot.earrings > 0 then
        local chance = math.min(75, C.EARRING_ROLL_CHANCE + red * 5)
        if math.random(100) <= chance then
            reward.items[#reward.items + 1] = loot.earrings[math.random(#loot.earrings)]
        end
    end

    -- Clear report, then drop the chest.
    local strat = C.STRATUM_BY_KEY[skey]
    local sname = strat and strat.name or 'Voidwatch'
    player:printToPlayer(string.format(
        '[Voidwatch] %s cleared (%s)! Your abyssite advances to rank %d.',
        sname, C.difficultyName(tier), getStratClears(player, skey)), SYS)
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
    removeSessionListeners(sess)
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

local function monitorRift(player, sessionId)
    player:timer(3000, function(p)
        local sess = getSession(p)
        if not sess or sess.id ~= sessionId or sess.dead then return end
        if p:getZoneID() ~= sess.zoneId then
            failRift(p, 'left')
            return
        end

        local dx = p:getXPos() - sess.originX
        local dz = p:getZPos() - sess.originZ
        if (dx * dx + dz * dz) > (80 * 80) then
            failRift(p, 'left')
            return
        end
        monitorRift(p, sessionId)
    end)
end

-- ── Open a rift here (called by the Planar Rift NPC; GM via !voidwatch open) ──
openRift = function(player, stratumKey, bypassGate)
    ensureBorn(player)
    local activeOwner = groupRiftOwner(player)
    if activeOwner then
        player:printToPlayer(string.format(
            '[Voidwatch] Your group already has an active rift opened by %s.', activeOwner), SYS)
        return
    end
    if not player:canUseMisc(xi.zoneMisc.PET) then
        player:printToPlayer('[Voidwatch] This rift will not stir in a safe area.', SYS)
        return
    end
    local stratum = C.STRATUM_BY_KEY[stratumKey] or C.STRATA[1]
    local unlocked, requirement = stratumUnlocked(player, stratum)
    if not bypassGate and not unlocked then
        player:printToPlayer(string.format(
            '[Voidwatch] %s is sealed. To unlock it: %s.',
            stratum.name, requirement), SYS)
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

    local tier = C.effectiveTier(stratum, getStratClears(player, stratum.key))
    nextSessionId = nextSessionId + 1
    local sess =
    {
        id = nextSessionId,
        tier = tier, stratumKey = stratum.key, dead = false,
        zoneId = player:getZoneID(), ownerName = player:getName(),
        originX = player:getXPos(), originZ = player:getZPos(),
    }
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
    registerPartyListeners(player, sess)

    player:printToPlayer(string.format(
        '[Voidwatch] A Planar Rift tears open! %s -- %s difficulty (Lv.%d, %d HP) -- %s emerges!',
        stratum.name, C.difficultyName(tier), level, C.nmHp(tier), (name:gsub('_', ' '))), SYS)
    player:printToPlayer(string.format(
        '[Voidwatch] %d hidden weaknesses lurk within. Probe with magic / weaponskills / ranged -- or "!voidwatch reveal" (spends a Periapt) to expose them. Chain weaknesses fast for a Synchronic Blitz.', #sess.weakList), SYS)

    monitorRift(player, sess.id)
    player:timer(C.BATTLE_SECONDS * 1000, function(p)
        local s = sessions[p:getName()]
        if s and not s.dead and s.id == sess.id then failRift(p, 'timeout') end
    end)
end

-- ── Menu helper ─────────────────────────────────────────────────────────────
local function show(p, title, options)
    local snap = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snap) end)
end

confirmRift = function(player, stratumKey)
    ensureBorn(player)
    local activeOwner = groupRiftOwner(player)
    if activeOwner then
        player:printToPlayer(string.format(
            '[Voidwatch] Your group already has an active rift opened by %s.', activeOwner), SYS)
        return
    end

    local stratum = C.STRATUM_BY_KEY[stratumKey] or C.STRATA[1]
    local unlocked, requirement = stratumUnlocked(player, stratum)
    if not unlocked then
        player:printToPlayer(string.format(
            '[Voidwatch] %s is sealed. To unlock it: %s.',
            stratum.name, requirement), SYS)
        return
    end

    local tier = C.effectiveTier(stratum, getStratClears(player, stratum.key))
    local level, hp = C.nmLevel(tier), C.nmHp(tier)
    player:printToPlayer(string.format(
        '[Voidwatch] Confirm %s: %s difficulty, Lv.%d, %d HP, cost %d stone. Current stones: %d.',
        stratum.name, C.difficultyName(tier), level, hp, C.RIFT_COST, getStones(player)), SYS)
    local confirmZoneId = player:getZoneID()
    show(player, 'Confirm Planar Rift', {
        { string.format('Open %s rift', C.difficultyName(tier)),
          function(p)
              if p:getZoneID() ~= confirmZoneId then
                  p:printToPlayer('[Voidwatch] That rift confirmation has expired.', SYS)
                  return
              end
              openRift(p, stratum.key, false)
          end },
        { 'Cancel', function(p) end },
    })
end

openWarpStratum = function(player, stratum)
    local options = {}
    for _, rift in ipairs(C.RIFTS) do
        if C.ZONE_STRATUM[rift.zone] == stratum.key then
            local destination = rift
            options[#options + 1] = {
                destination.zone:gsub('_', ' '),
                function(p)
                    if groupRiftOwner(p) then
                        p:printToPlayer('[Voidwatch] Close your active group rift before warping.', SYS)
                        return
                    end
                    local zoneId = xi.zone[destination.zone:upper()]
                    if not zoneId then
                        p:printToPlayer('[Voidwatch] That rift destination is unavailable.', SYS)
                        return
                    end
                    p:setPos(destination.x + 3, destination.y, destination.z + 3,
                        destination.rot or 0, zoneId)
                end,
            }
        end
    end
    options[#options + 1] = { 'Back', function(p) openWarpMenu(p) end }
    show(player, stratum.name .. ' Rifts', options)
end

openWarpMenu = function(player)
    local options = {}
    for _, stratum in ipairs(C.STRATA) do
        local unlocked = stratumUnlocked(player, stratum)
        local selected = stratum
        options[#options + 1] = {
            unlocked and stratum.name or (stratum.name .. ' [Locked]'),
            function(p)
                local ok, requirement = stratumUnlocked(p, selected)
                if not ok then
                    p:printToPlayer(string.format('[Voidwatch] Unlock requirement: %s.', requirement), SYS)
                    return
                end
                openWarpStratum(p, selected)
            end,
        }
    end
    options[#options + 1] = { 'Back', function(p) openMenu(p) end }
    show(player, 'Warp to Planar Rift', options)
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
        local tier = C.effectiveTier(s, clears)
        local unlocked = stratumUnlocked(player, s)
        player:printToPlayer(string.format('  %-16s rank %d  (%s, Lv.%d)%s',
            s.name, clears, C.difficultyName(tier), C.nmLevel(tier), unlocked and '' or ' [LOCKED]'), SYS)
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
        { 'Warp to Planar Rift', function(p) openWarpMenu(p) end },
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
        local name = player:getName()
        local pend = pendingPyxis[name]
        if pend then
            -- A disconnect or zone change can destroy the dynamic chest before
            -- it is examined. Recover the already-rolled reward after login
            -- initialization instead of leaving an unclaimable ghost Pyxis.
            pendingPyxis[name] = nil
            despawnPyxis(pend.mob)
            player:timer(2500, function(p)
                deliverPyxis(p, pend.reward)
                p:printToPlayer('[Voidwatch] Your unclaimed Pyxis reward was recovered after zoning.', SYS)
            end)
        end

        local sess = getSession(player)
        if not sess then return end
        if gameLogin then
            failRift(player, 'left') -- despawn the orphan before allowing a new rift
        elseif player:getZoneID() ~= sess.zoneId then
            failRift(player, 'left')
        end
    end)
end)

-- ── Voidwatch Officer NPC (zone-44 hub) ─────────────────────────────────────
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Voidwatch_Officer',
        packetName = string.format('%sVoidwatch Officer', xi.icon.STAR_LARGE),
        look       = 244,
        x          = 596.000,
        y          =   -3.360,
        z          =  521.500,
        rotation   = 135,
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
                    confirmRift(player, stratumKey)
                end,
            })
            utils.unused(npc)
        end)
    end
end

-- ── Public API (for commands/voidwatch.lua) ─────────────────────────────────
xi.voidwatch = xi.voidwatch or {}
xi.voidwatch.menu       = function(p) openMenu(p) end
xi.voidwatch.open       = function(p, key) openRift(p, key, true) end -- GM-gated in command
xi.voidwatch.status     = function(p) status(p) end
xi.voidwatch.reveal     = function(p) revealWeaknesses(p) end
xi.voidwatch.refiner    = function(p) openRefiner(p) end
xi.voidwatch.grantCruor = function(p, n) ensureBorn(p); addCruor(p, math.max(0, n)) end  -- GM test
xi.voidwatch.grantShards = function(p, n) ensureBorn(p); p:setCharVar(C.V.shards, getShards(p) + math.max(0, n)) end  -- GM test

-- Cross-module read for the Weapon Forge Mythic Stage II preflight
-- ("All Voidwatch NMs killed"). Comparison: getCharVar('VW_Unique_Kills')
-- >= xi.voidwatch.uniqueNmCount.
xi.voidwatch.uniqueNmCount = C.UNIQUE_NM_COUNT

return m
