-----------------------------------
-- TheGauntlet.lua
--
-- A 10-level solo challenge in Riverne-Site_A01. At each level (1-9) the
-- player must defeat an NM to advance. Level 10: defeat Shinryu or be expelled.
--
-- Clearing level 10 grants a jackpot reward and permanently spawns a named NPC
-- champion in the Hall of Champions (B01).
--
-- Rules: No Trusts (cleared on zone-in). Pets OK. Death = expulsion.
--
-- Architecture: one shared set of zone NPCs (Challenge / Final Trial)
-- spawned on Riverne-Site_A01 initialization. Callbacks read live
-- sessions[trigPlayer:getName()] so every player uses the same NPC entities
-- while keeping their own session state.
--
-- Requires ONE map restart to activate (addOverride module).
--
-- CharVars:  Gauntlet_Clears  (total level-10 clears)
-- Commands:  !gauntlet abort [name]  |  !gauntlet status  (scripts/commands/)
-- Entry NPC: "The Gauntlet" in Leafallia (relaunch hub; x=-20, z=20)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Riverne-Site_A01/Zone')
require('scripts/zones/Riverne-Site_B01/Zone')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
require('scripts/globals/job_utils/dancer')
require('scripts/globals/job_utils/white_mage')

local C         = require('modules/custom/lua/gauntlet_catalog')
local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m   = Module:new('the_gauntlet')
local SYS = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Session state (keyed by playerName)
-- phase: 'choose' | 'fight' | 'advancing'
-----------------------------------
local sessions = {}
xi._gauntlet_sessions = sessions

local function getSession(player)   return sessions[player:getName()] end
local function clearSession(player) sessions[player:getName()] = nil end

local function entityName(entity)
    local name
    if entity then
        pcall(function() name = entity:getName() end)
    end
    return name
end

local function playerOwner(entity)
    if not entity then return nil end

    local okPc, isPc = pcall(function() return entity:isPC() end)
    if okPc and isPc then
        return entity
    end

    local owner
    pcall(function() owner = entity:getMaster() end)
    if owner then
        local okOwnerPc, ownerIsPc = pcall(function() return owner:isPC() end)
        if okOwnerPc and ownerIsPc then
            return owner
        end
    end

    return nil
end

local function dismissTrusts(player)
    local ok, party = pcall(function() return player:getPartyWithTrusts() end)
    if not ok or not party then return end
    for _, member in ipairs(party) do
        pcall(function()
            if member:isTrust() and member:getLocalVar('fellowApplied') ~= 1 then
                local owner = member:getMaster()
                if owner then owner:despawnTrust(member) end
            end
        end)
    end
end

local function isGrouped(player)
    local grouped = false

    pcall(function()
        if (player:getPartySize() or 1) > 1 then
            grouped = true
        end
    end)

    pcall(function()
        local alliance = player:getAlliance()
        if alliance and #alliance > 1 then
            grouped = true
        end
    end)

    return grouped
end

local function canStartFight(player)
    dismissTrusts(player)

    if isGrouped(player) then
        player:printToPlayer(
            '[The Gauntlet] You must face this challenge alone. Leave your party or alliance before beginning.',
            SYS)
        return false
    end

    return true
end

local allowedCommandBuffs =
{
    [xi.effect.SIGNET]       = true,
    [xi.effect.SANCTION]     = true,
    [xi.effect.SIGIL]        = true,
    [xi.effect.IONIS]        = true,
    [xi.effect.REFRESH]      = true,
    [xi.effect.REGEN]        = true,
    [xi.effect.REGAIN]       = true,
    [xi.effect.COMPOSURE]    = true,
    [xi.effect.MAX_HP_BOOST] = true,
}
local BUFF_COMMAND_SOURCE_PARAM = 0x0F1B

local function stripForeignBuffs(player)
    local ownerId = player:getID()
    local effects = player:getStatusEffects() or {}
    local stripFlags = bit.bor(
        xi.effectFlag.DISPELABLE,
        xi.effectFlag.SONG,
        xi.effectFlag.ROLL,
        xi.effectFlag.AURA)

    for _, effect in pairs(effects) do
        local effectId = effect:getEffectType()
        local originId = effect:getOriginID()
        local flags    = effect:getEffectFlags()
        local commandBuff =
            allowedCommandBuffs[effectId] and
            effect:getSourceType() == xi.effectSourceType.TEMPORARY_ITEM and
            effect:getSourceTypeParam() == BUFF_COMMAND_SOURCE_PARAM

        if
            originId ~= ownerId and
            not commandBuff and
            bit.band(flags, stripFlags) ~= 0 and
            bit.band(flags, xi.effectFlag.FOOD) == 0
        then
            pcall(function() player:delStatusEffectSilent(effectId) end)
        end
    end

    if xi._paragon_refreshDailyMight then
        xi._paragon_refreshDailyMight(player, true)
    end
end

local function isActiveRunner(target)
    local runner = playerOwner(target)
    if not runner then return false, nil, nil end

    local sess = sessions[runner:getName()]
    if
        sess and
        sess.phase == 'fight' and
        sess.nm and
        runner:getZoneID() == C.ARENA_ZONE
    then
        return true, runner, sess
    end

    return false, runner, nil
end

local function shouldBlockOutsideHealing(caster, target)
    local active, runner = isActiveRunner(target)
    if not active or not runner then
        return false
    end

    local casterOwner = playerOwner(caster)
    if casterOwner and entityName(casterOwner) == runner:getName() then
        return false
    end

    return true
end

local function blockOutsideHealing(caster, target)
    if not shouldBlockOutsideHealing(caster, target) then
        return false
    end

    pcall(function()
        caster:printToPlayer('[The Gauntlet] Outside healing cannot reach a player fighting their Gauntlet NM.', SYS)
    end)

    return true
end

local function isGauntletKirinTarget(mob, target)
    local active, _, sess = isActiveRunner(target)
    if not active or not sess or sess.level ~= 7 then
        return false
    end

    return sess.nm == mob and entityName(mob) == 'Kirin'
end

local function isGauntletMobTarget(mob, target)
    local active, _, sess = isActiveRunner(target)
    return active and sess and sess.nm == mob
end

local function isGauntletLevelTarget(mob, target, level)
    local active, _, sess = isActiveRunner(target)
    return active and sess and sess.nm == mob and sess.level == level
end

local function inCurseGrace(mob)
    local untilTime = 0
    pcall(function() untilTime = mob:getLocalVar('Gauntlet_CurseGraceUntil') or 0 end)
    return untilTime > os.time()
end

local function markCurseGrace(mob, seconds)
    pcall(function() mob:setLocalVar('Gauntlet_CurseGraceUntil', os.time() + (seconds or 5)) end)
end

local function holdFireLocked(mob)
    local active = 0
    local exhausted = 0
    pcall(function()
        active = mob:getLocalVar('Gauntlet_HoldFireActive') or 0
        exhausted = mob:getLocalVar('Gauntlet_HoldFireExhausted') or 0
    end)

    return active > 0 or exhausted > 0
end

local function randomChoice(list)
    if not list or #list == 0 then
        return 0
    end

    return list[math.random(1, #list)]
end

local function chooseGauntletMobSkill(level, mob, target, skillId)
    if inCurseGrace(mob) then
        return 0
    end

    if level == 4 then -- Nidhogg: only offer Spike Flail when it can pass its positional gate.
        local skills = { 1039, 1041, 1046 }
        if not holdFireLocked(mob) and os.time() >= (mob:getLocalVar('Gauntlet_NidhoggTerrorReady') or 0) then
            table.insert(skills, 957)
        end

        if mob:getAnimationSub() ~= 1 and target and not target:isInfront(mob, 128) then
            table.insert(skills, 1040)
        end

        local selected = randomChoice(skills)
        if selected == 957 then
            mob:setLocalVar('Gauntlet_NidhoggTerrorReady', os.time() + 45)
        end

        return selected
    elseif level == 5 then -- King Behemoth: add a restrained Meteor threat.
        local skills = { 628, 629, 630, 631, 632, 633 }
        if os.time() >= (mob:getLocalVar('Gauntlet_MeteorReady') or 0) then
            table.insert(skills, 634)
        end

        local selected = randomChoice(skills)
        if selected == 634 then
            mob:setLocalVar('Gauntlet_MeteorReady', os.time() + C.bossOverrides.meteor.recastSec)
        end

        return selected
    elseif level == 6 then -- Vrtra
        local skills = { 1309, 1311, 1315, 1316 }
        if mob:getAnimationSub() ~= 1 and target and not target:isInfront(mob, 128) then
            table.insert(skills, 1310)
        end

        return randomChoice(skills)
    elseif level == 10 then -- Shinryu: skip basic attack placeholders and use real TP moves.
        local skills = { 2664, 2665, 2666, 2667, 2708, 2709 }
        local hpp = mob:getHPP()

        if hpp <= 66 then
            table.insert(skills, 2668)
            table.insert(skills, 2669)
        end

        if hpp <= 33 then
            table.insert(skills, 2670)
            table.insert(skills, 2671)
        end

        return randomChoice(skills)
    end

    return skillId
end

local function cleanupNPCs(sess)
    -- The Gauntlet NPCs are shared zone entities now; never despawn them per player.
end

-----------------------------------
-- Forward declarations
-----------------------------------
local spawnGauntletNPCs, spawnNM, advanceLevel, endRun

local function formatGil(gil)
    if gil >= 1000000 then
        if gil % 1000000 == 0 then
            return string.format('%dM', math.floor(gil / 1000000))
        end

        return string.format('%.1fM', gil / 1000000)
    elseif gil >= 1000 then
        return string.format('%dk', math.floor(gil / 1000))
    end

    return tostring(gil)
end

local function sessionHasActiveMob(sess)
    if not sess or not sess.nm then
        return false
    end

    local alive = false
    pcall(function()
        alive = sess.nm:getHP() > 0 and sess.nm:isSpawned()
    end)

    return alive
end

local function findFreeLaneSlot(laneId, playerName)
    local occupied = {}
    for name, sess in pairs(sessions) do
        if name ~= playerName and sess.lane == laneId and sess.laneSlot then
            if sess.phase == 'choose' or sess.phase == 'advancing' or sessionHasActiveMob(sess) then
                occupied[sess.laneSlot] = true
            else
                sess.lane = nil
                sess.laneSlot = nil
            end
        end
    end

    for slotId = 1, C.MAX_ACTIVE_PER_LANE do
        if not occupied[slotId] then
            return slotId
        end
    end

    return nil
end

local function assignLane(player, session, laneId)
    if session.lane then
        if session.lane ~= laneId then
            player:printToPlayer('[The Gauntlet] Your run is already bound to another arena lane.', SYS)
            return false
        end

        return true
    end

    local slotId = findFreeLaneSlot(laneId, player:getName())
    if not slotId then
        player:printToPlayer('[The Gauntlet] This arena side is full. Try the other moogle.', SYS)
        return false
    end

    session.lane = laneId
    session.laneSlot = slotId
    return true
end

-----------------------------------
-- Champion file persistence
-----------------------------------
local function loadChampions()
    local ok, fn = pcall(loadfile, C.CHAMPION_DATA_FILE)
    if ok and fn then
        local ok2, data = pcall(fn)
        if ok2 and type(data) == 'table' then return data end
    end
    return {}
end

local function saveChampion(charname, charid)
    local data = loadChampions()
    local found = false
    for _, c in ipairs(data) do
        if c.charname == charname then
            c.times  = (c.times or 1) + 1
            c.latest = os.date('%Y-%m-%d')
            found = true
            break
        end
    end
    if not found then
        table.insert(data, {
            charname = charname,
            charid   = charid,
            latest   = os.date('%Y-%m-%d'),
            times    = 1,
        })
    end

    local f = io.open(C.CHAMPION_DATA_FILE, 'w')
    if not f then return end
    f:write('-- gauntlet_champion_data.lua (auto-updated by TheGauntlet.lua)\nreturn {\n')
    for _, c in ipairs(data) do
        f:write(string.format(
            '    { charname = %q, charid = %d, latest = %q, times = %d },\n',
            c.charname, c.charid, c.latest, c.times))
    end
    f:write('}\n')
    f:close()
end

-----------------------------------
-- Per-level reward (levels 1-9 NM kill). pcall-guarded so a single bad call
-- can never block the run.
-----------------------------------
local function grantLevelReward(player, level)
    local r = C.LEVEL_REWARD(level)
    pcall(function()
        player:addGil(r.gil)
        player:setCharVar('Paragon_Points',
            (player:getCharVar('Paragon_Points') or 0) + r.pp)
        player:setCharVar('Infamy',
            (player:getCharVar('Infamy') or 0) + r.infamy)
        player:printToPlayer(string.format(
            '[The Gauntlet] Level %d reward: +%s gil, +%d Paragon Points, +%d Infamy.',
            level, formatGil(r.gil), r.pp, r.infamy), SYS)

        local milestone = C.MILESTONE_REWARDS[level]
        if milestone then
            player:addGil(milestone.gil)
            player:setCharVar('Paragon_Points',
                (player:getCharVar('Paragon_Points') or 0) + milestone.pp)
            player:setCharVar('Infamy',
                (player:getCharVar('Infamy') or 0) + milestone.infamy)
            player:printToPlayer(string.format(
                '[The Gauntlet] Milestone bonus: +%s gil, +%d Paragon Points, +%d Infamy.',
                formatGil(milestone.gil), milestone.pp, milestone.infamy), SYS)
        end
    end)
end

-----------------------------------
-- Final clear reward
-----------------------------------
local function grantFinalReward(player)
    local r = C.FINAL_REWARD
    -- Deliver currency first, guarded, so a champion-file IO error (below) can
    -- never block the actual reward.
    pcall(function()
        player:addGil(r.gil)
        player:setCharVar('Paragon_Points',
            (player:getCharVar('Paragon_Points') or 0) + r.pp)
        player:setCharVar('Infamy',
            (player:getCharVar('Infamy') or 0) + r.infamy)
        local clears = (player:getCharVar('Gauntlet_Clears') or 0) + 1
        player:setCharVar('Gauntlet_Clears', clears)

        player:printToPlayer('[The Gauntlet] *** THE GAUNTLET IS CONQUERED! ***', SYS)
        player:printToPlayer(string.format(
            '[The Gauntlet] Reward: %s gil, +%d Paragon Points, +%d Infamy.',
            formatGil(r.gil), r.pp, r.infamy), SYS)
        player:printToPlayer(
            '[The Gauntlet] Your legend is etched in the Hall of Champions forever.', SYS)

        if clears == 1 then
            player:printToPlayer(string.format(
                '[The Gauntlet] Congratulations, %s! You have conquered The Gauntlet for the first time!',
                player:getName()), SYS)
            player:printToPlayer(
                '[The Gauntlet] You have earned a one-time Prime Trial completion reward.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Please message GM Eren on Discord with proof of completion to claim your reward.', SYS)
        else
            player:printToPlayer(string.format(
                '[The Gauntlet] Congratulations, %s! You have conquered The Gauntlet again.',
                player:getName()), SYS)
            player:printToPlayer(
                '[The Gauntlet] Your one-time Prime Trial completion reward has already been earned.', SYS)
        end
    end)

    pcall(function() saveChampion(player:getName(), player:getID()) end)
end

-----------------------------------
-- End run (death / left / abort / error)
-----------------------------------
endRun = function(player, reason)
    local sess = getSession(player)
    cleanupNPCs(sess)
    clearSession(player)

    if sess and sess.nm then
        pcall(function() mechanics.cleanup(sess.nm) end)  -- free mech state + adds
        pcall(function() sess.nm:setHP(0) end)
    end

    local recoverOnExit = reason == 'death'
    if recoverOnExit and player:isDead() then
        -- Preserve the normal death EXP loss while accepting a scripted raise.
        -- The 2.5s exit delay below lets the death state finish before zoning.
        player:setCharVar('expLost', 0)
        player:forceRaise(3)
    end

    local lvl = sess and sess.level or 0
    if reason == 'death' then
        player:printToPlayer(string.format(
            '[The Gauntlet] You fell at Level %d. The Gauntlet claims another soul.', lvl), SYS)
    elseif reason == 'left' then
        player:printToPlayer('[The Gauntlet] You fled the Gauntlet. Return when worthy.', SYS)
    elseif reason == 'abort' then
        player:printToPlayer('[The Gauntlet] Run aborted.', SYS)
    elseif reason == 'grouped' then
        player:printToPlayer('[The Gauntlet] Solo challenge only. Run ended.', SYS)
    end

    player:timer(2500, function(p)
        if recoverOnExit then
            p:setHP(p:getMaxHP())
            p:setMP(p:getMaxMP())
            p:delStatusEffectSilent(xi.effect.WEAKNESS)
            p:delStatusEffectSilent(xi.effect.DISEASE)
            p:delStatusEffectSilent(xi.effect.PLAGUE)
        end

        p:setPos(C.EXIT_POS.x, C.EXIT_POS.y, C.EXIT_POS.z, C.EXIT_POS.rot, C.EXIT_POS.zoneId)
    end)
end

xi._gauntlet_endRun = endRun

-----------------------------------
-- Spawn the level's NM
-----------------------------------
spawnNM = function(player, session)
    if not canStartFight(player) then
        session.phase = 'choose'
        return
    end

    stripForeignBuffs(player)

    local level     = session.level
    local nm        = C.NM_POOL[level]
    local ownerName = player:getName()

    local px = C.WARP_IN.x
    local py = C.WARP_IN.y
    local pz = C.WARP_IN.z
    local lane = C.ARENA_LANES[session.lane or 1] or C.ARENA_LANES[1]
    local slotOffset = C.LANE_SLOT_OFFSETS[session.laneSlot or 1] or C.LANE_SLOT_OFFSETS[1]
    local mx = px + lane.nm.x + slotOffset.x
    local mz = pz + lane.nm.z + slotOffset.z

    local mob = player:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = nm.groupId,
        groupZoneId          = C.GROUP_ZONE,
        name                 = nm.name,
        x = mx, y = py, z = mz,
        rotation             = 180,
        minLevel             = C.nmLevel(level),
        maxLevel             = C.nmLevel(level),
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)   -- free mech state + despawn any adds
            local sess = sessions[ownerName]
            if not sess then return end
            if sess.level ~= level then return end

            sess.nm = nil
            if level <= 9 then
                sess.clearedLevels = (sess.clearedLevels or 0) + 1
            end
            sess.level = sess.level + 1
            sess.phase = 'advancing'
            local resolved = GetPlayerByName(ownerName)
            if not resolved then sessions[ownerName] = nil; return end
            resolved:printToPlayer(string.format(
                '[The Gauntlet] %s is defeated! Level %d cleared!',
                nm.name, level), SYS)
            -- Per-level reward for FIGHTING (levels 1-9). Level 10 pays the
            -- jackpot in grantFinalReward instead.
            if level <= 9 then
                grantLevelReward(resolved, level)
            end
            resolved:timer(2500, function(p)
                local s = sessions[p:getName()]
                if s then advanceLevel(p, s) end
            end)
        end,

        -- Hardcore mechanics ride the combat tick (all pcall-guarded in the lib).
        onMobFight = function(mfMob, mfTarget)
            local runner = GetPlayerByName(ownerName)
            local sess = sessions[ownerName]
            if sess and runner and runner:getZoneID() == C.ARENA_ZONE and isGrouped(runner) then
                runner:printToPlayer('[The Gauntlet] You cannot party while fighting in The Gauntlet. Run ended.', SYS)
                endRun(runner, 'grouped')
                return
            end

            mechanics.tick(mfMob, mfTarget)
        end,

        onMobMobskillChoose = function(msMob, msTarget, skillId)
            return chooseGauntletMobSkill(level, msMob, msTarget, skillId)
        end,
    })

    if not mob then
        player:printToPlayer('[The Gauntlet] ERROR: spawn failed. Aborting.', SYS)
        endRun(player, 'error')
        return
    end

    mob:setSpawn(mx, py, mz, 0)
    local hp = C.nmHp(level)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    if nm.skillListId then
        mob:setMobMod(xi.mobMod.SKILL_LIST, nm.skillListId)
    end
    mob:setModelSize(3)
    for modId, val in pairs(C.nmMods(level)) do
        if val ~= 0 then mob:setMod(modId, val) end
    end
    if C.RANGED_DAMAGE_REDUCTION and C.RANGED_DAMAGE_REDUCTION ~= 0 then
        mob:addMod(xi.mod.DMGRANGE, C.RANGED_DAMAGE_REDUCTION)
    end
    if C.SILENCE_RES_DOWN and C.SILENCE_RES_DOWN[level] then
        mob:addMod(xi.mod.SILENCERES, C.SILENCE_RES_DOWN[level])
    end
    for mobModId, val in pairs(C.nmMobMods(level)) do
        if val ~= 0 then mob:setMobMod(mobModId, val) end
    end
    -- Apply Gauntlet HP. setBaseHP() is a custom C++ binding that anchors the HP
    -- through mob-stat recalculations; fall back to setMaxHP() when the binding
    -- is absent in the running binary (e.g. binary predates the C++ patch).
    local _baseHpOk = pcall(function() mob:setBaseHP(hp) end)
    if not _baseHpOk then mob:setMaxHP(hp) end
    mob:setHP(hp)
    mob:addEnmity(player, 30000, 30000)

    -- Attach the level's hardcore mechanics AFTER all stats/HP are set. ownerName
    -- scopes every AoE/CC pulse to this solo runner (no bleed onto bystanders).
    mechanics.attach(mob, C.mechCfg(level), ownerName)

    session.nm    = mob
    session.phase = 'fight'

    player:printToPlayer(string.format(
        '[The Gauntlet] Level %d — %s  (Lv%d / %s HP)',
        level, nm.name, C.nmLevel(level), C.formatHp(hp)), SYS)
    player:printToPlayer('[The Gauntlet] Defeat it to advance. Death ends your run.', SYS)
end

-----------------------------------
-- Advance to next level (called after NM kill)
-- session.level is already the NEW level when this is called.
-----------------------------------
advanceLevel = function(player, session)
    if not session then return end
    local level = session.level  -- already incremented by caller

    if level > 10 then
        -- Post-Shinryu kill: final clear
        grantFinalReward(player)
        cleanupNPCs(getSession(player))
        clearSession(player)
        player:timer(6000, function(p)
            p:setPos(C.EXIT_POS.x, C.EXIT_POS.y, C.EXIT_POS.z, C.EXIT_POS.rot, C.EXIT_POS.zoneId)
        end)
        return
    end

    session.phase = 'choose'

    if level == 10 then
        player:printToPlayer('[The Gauntlet] Level 10: the final trial. No retreat.', SYS)
        player:printToPlayer('[The Gauntlet] Face Shinryu and earn your legend — or be expelled.', SYS)
        player:printToPlayer('[The Gauntlet] Approach the Final Trial NPC when ready.', SYS)
    else
        local nm = C.NM_POOL[level]
        player:printToPlayer(string.format('[The Gauntlet] Level %d reached.', level), SYS)
        player:printToPlayer(string.format(
            '[The Gauntlet] Approach the Challenge NPC to fight %s  (Lv%d / %s HP).',
            nm.name, C.nmLevel(level), C.formatHp(C.nmHp(level))), SYS)
    end
end

-----------------------------------
-- Spawn the shared Gauntlet NPCs exactly once when Riverne-Site_A01 initializes.
-- Each callback uses the triggering player's name to find that player's session.
-----------------------------------
spawnGauntletNPCs = function(zone)
    local px = C.WARP_IN.x
    local py = C.WARP_IN.y
    local pz = C.WARP_IN.z

    for laneId, lane in ipairs(C.ARENA_LANES) do
        local thisLaneId = laneId
        local thisLane   = lane

        zone:insertDynamicEntity({
            objtype              = xi.objType.NPC,
            name                 = string.format('G_Challenge_%d', thisLaneId),
            packetName           = string.format('%sChallenge', xi.icon.SWORD),
            look                 = 2419,
            x = px + thisLane.challenge.x, y = py, z = pz + thisLane.challenge.z,
            rotation             = 0,
            widescan             = 0,

            onTrigger = function(trigPlayer, npc)
                local playerName = trigPlayer:getName()
                local sess = sessions[playerName]
                if not sess or sess.phase ~= 'choose' or sess.level > 9 then return end
                if not canStartFight(trigPlayer) then return end
                if not assignLane(trigPlayer, sess, thisLaneId) then return end
                if (sess.clearedLevels or 0) ~= sess.level - 1 then
                    trigPlayer:printToPlayer(
                        '[The Gauntlet] Your progress is out of sequence. Restart the run.', SYS)
                    return
                end

                sess.phase = 'fight'
                spawnNM(trigPlayer, sess)
            end,
        })

        zone:insertDynamicEntity({
            objtype              = xi.objType.NPC,
            name                 = string.format('G_Final_Trial_%d', thisLaneId),
            packetName           = string.format('%sFinal Trial', xi.icon.STAR_LARGE),
            look                 = 2419,
            x = px + thisLane.final.x, y = py, z = pz + thisLane.final.z,
            rotation             = 0,
            widescan             = 0,

            onTrigger = function(trigPlayer, npc)
                local playerName = trigPlayer:getName()
                local sess = sessions[playerName]
                if not sess or sess.phase ~= 'choose' then return end
                if sess.level ~= 10 or (sess.clearedLevels or 0) ~= 9 then
                    trigPlayer:printToPlayer(
                        '[The Gauntlet] This path opens only after clearing levels 1-9.', SYS)
                    return
                end
                if not canStartFight(trigPlayer) then return end
                if not assignLane(trigPlayer, sess, thisLaneId) then return end

                sess.phase = 'fight'

                trigPlayer:printToPlayer('[The Gauntlet] Shinryu descends!', SYS)
                spawnNM(trigPlayer, sess)
            end,
        })
    end
end

-----------------------------------
-- Enter The Gauntlet (called by entry NPC)
-----------------------------------
local function enterGauntlet(player)
    if getSession(player) then
        player:printToPlayer('[The Gauntlet] You are already in a run. Use !gauntlet abort to reset.', SYS)
        return
    end
    dismissTrusts(player)
    sessions[player:getName()] = { level = 1, phase = 'choose', nm = nil, clearedLevels = 0 }
    player:printToPlayer('[The Gauntlet] Entering the arena. Trusts are not permitted.', SYS)
    player:setPos(C.WARP_IN.x, C.WARP_IN.y, C.WARP_IN.z, C.WARP_IN.rot, C.ARENA_ZONE)
end

-----------------------------------
-- Override: Riverne-Site_A01 onInitialize -> shared Gauntlet NPCs
-----------------------------------
m:addOverride('xi.zones.Riverne-Site_A01.Zone.onInitialize', function(zone)
    super(zone)
    spawnGauntletNPCs(zone)
end)

-----------------------------------
-- Override: Riverne-Site_A01 zone-in → start the run
-----------------------------------
m:addOverride('xi.zones.Riverne-Site_A01.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    local sess = getSession(player)
    if sess then
        dismissTrusts(player)
        player:delStatusEffect(xi.effect.LEVEL_RESTRICTION)
        player:timer(2000, function(p)
            local s = sessions[p:getName()]
            if not s then return end
            -- Announce current state
            if s.level == 10 then
                p:printToPlayer('[The Gauntlet] Level 10: defeat Shinryu. No retreat.', SYS)
                p:printToPlayer('[The Gauntlet] Approach the Final Trial NPC when ready.', SYS)
            else
                local nm = C.NM_POOL[s.level]
                p:printToPlayer(string.format(
                    '[The Gauntlet] Level %d — Challenge: %s  (Lv%d / %s HP).',
                    s.level, nm and nm.name or '?',
                    C.nmLevel(s.level), C.formatHp(C.nmHp(s.level))), SYS)
            end
            p:printToPlayer('[The Gauntlet] No Trusts. Defeat each NM to advance.', SYS)
        end)
    end
    return cs
end)

-- Trusts are blocked only for players who are currently in a Gauntlet run.
m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if caster:getZoneID() == C.ARENA_ZONE and getSession(caster) then
        caster:printToPlayer('[The Gauntlet] Trusts are not permitted in The Gauntlet.', SYS)
        return xi.msg.basic.TRUST_NO_CAST_TRUST
    end

    return super(caster, spell, notAllowedTrustIds)
end)

m:addOverride('xi.mobskills.mobPhysicalMove', function(mob, target, skill, action, skillParams)
    if isGauntletMobTarget(mob, target) and skillParams then
        skillParams.skipParry = true
        skillParams.skipGuard = true
        skillParams.skipBlock = true
    end

    return super(mob, target, skill, action, skillParams)
end)

m:addOverride('xi.mobskills.mobStatusEffectMove', function(mob, target, typeEffect, power, tick, duration, subType, subPower, tier)
    local result = super(mob, target, typeEffect, power, tick, duration, subType, subPower, tier)
    if
        result ~= xi.msg.basic.SKILL_MISS and
        (typeEffect == xi.effect.CURSE_I or typeEffect == xi.effect.CURSE_II) and
        isGauntletMobTarget(mob, target)
    then
        markCurseGrace(mob, 5)
    end

    return result
end)

m:addOverride('xi.actions.mobskills.earthbreaker.onMobWeaponSkill', function(mob, target, skill, action)
    local ov = C.bossOverrides.earthbreaker
    if not isGauntletLevelTarget(mob, target, ov.level) then
        return super(mob, target, skill, action)
    end

    local params =
    {
        baseDamage      = mob:getMainLvl() + 2,
        fTP             = { 4, 4, 4 },
        element         = xi.element.EARTH,
        attackType      = xi.attackType.MAGICAL,
        damageType      = xi.damageType.EARTH,
        shadowBehavior  = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
        dStatMultiplier = 1,
    }

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    info.damage = math.min(info.damage, ov.damageCap)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.STUN, 1, 0, ov.stunSec)
    end

    return info.damage
end)

m:addOverride('xi.actions.mobskills.sable_breath.onMobWeaponSkill', function(mob, target, skill, action)
    local ov = C.bossOverrides.sableBreath
    if not isGauntletLevelTarget(mob, target, ov.level) then
        return super(mob, target, skill, action)
    end

    local params =
    {
        percentMultipier = ov.hpPct,
        damageCap        = ov.damageCap,
        bonusDamage      = 0,
        mAccuracyBonus   = { 0, 0, 0 },
        resistStat       = xi.mod.INT,
        element          = xi.element.DARK,
        attackType       = xi.attackType.BREATH,
        damageType       = xi.damageType.DARK,
        shadowBehavior   = xi.mobskills.shadowBehavior.IGNORE_SHADOWS,
    }

    local info = xi.mobskills.mobBreathMove(mob, target, skill, action, params)
    info.damage = utils.conalDamageAdjustment(mob, target, skill, info.damage, 0.2)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end)

m:addOverride('xi.actions.mobskills.spike_flail.onMobWeaponSkill', function(mob, target, skill, action)
    local ov = C.bossOverrides.spikeFlail
    local onLevel = false
    for _, lv in ipairs(ov.levels) do
        if isGauntletLevelTarget(mob, target, lv) then
            onLevel = true
            break
        end
    end
    if not onLevel then
        return super(mob, target, skill, action)
    end

    local params =
    {
        baseDamage       = mob:getWeaponDmg(),
        numHits          = 3,
        fTP              = { 4.0, 4.0, 4.0 },
        attackType       = xi.attackType.PHYSICAL,
        damageType       = xi.damageType.SLASHING,
        shadowBehavior   = xi.mobskills.shadowBehavior.NUMSHADOWS_3,
        attackMultiplier = { 5.0, 5.0, 5.0 },
        skipParry        = true,
        skipGuard        = true,
        skipBlock        = true,
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
    info.damage = math.max(info.damage, ov.damageFloor)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end)

m:addOverride('xi.actions.mobskills.absolute_terror.onMobWeaponSkill', function(mob, target, skill, action)
    local ov = C.bossOverrides.absoluteTerror
    if not isGauntletLevelTarget(mob, target, ov.level) then
        return super(mob, target, skill, action)
    end

    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 30, 0, math.random(ov.terrorMinSec, ov.terrorMaxSec)))
    return xi.effect.TERROR
end)

m:addOverride('xi.actions.mobskills.medusa_javelin.onMobWeaponSkill', function(mob, target, skill, action)
    local ov = C.bossOverrides.medusaJavelin
    if not isGauntletLevelTarget(mob, target, ov.level) then
        return super(mob, target, skill, action)
    end

    local params =
    {
        baseDamage     = mob:getWeaponDmg(),
        numHits        = 1,
        fTP            = { 2.0, 2.0, 2.0 },
        attackType     = xi.attackType.PHYSICAL,
        damageType     = xi.damageType.PIERCING,
        shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1,
        canCrit        = true,
        criticalChance = { 0.10, 0.20, 0.25 },
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        -- Retail petrification is 30-60s and too punishing in the solo Gauntlet.
        -- Keep the control threat, but let the player keep acting.
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, ov.bindSec)
    end

    return info.damage
end)

m:addOverride('xi.actions.mobskills.meteor.onMobWeaponSkill', function(mob, target, skill, action)
    local ov = C.bossOverrides.meteor
    if not isGauntletLevelTarget(mob, target, ov.level) then
        return super(mob, target, skill, action)
    end

    local damage = ov.damage
    damage = math.floor(damage * xi.combat.damage.calculateDamageAdjustment(target, false, true, false, false))
    damage = math.floor(target:handleSevereDamage(damage, false))
    damage = utils.handlePhalanx(target, damage)
    damage = utils.handleOneForAll(target, damage)
    damage = utils.handleStoneskin(target, damage)

    target:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.NONE)
    return damage
end)

m:addOverride('xi.actions.mobskills.meteor.onMobSkillFinalize', function(mob, skill)
    if mob:getLocalVar('Gauntlet_MeteorReady') > 0 then
        return
    end

    return super(mob, skill)
end)

-- Kirin's spell damage caps: Stonega IV (AoE), Stone V (single), and Quake (single)
-- all deal too much raw damage given Kirin's INT/MATT stat block. Cap each at 5000
-- so they stay threatening without one-shotting well-geared players. Magic spells
-- bypass Utsusemi by design (shadow absorption is physical-only) -- the cap is the
-- intended mitigation, not shadows.
local function kirinSpellCap(caster, target, spell)
    local ov = C.bossOverrides.kirinSpellCap
    if not isGauntletLevelTarget(caster, target, ov.level) then
        return super(caster, target, spell)
    end

    local previousCap = target:getMod(xi.mod.RECEIVED_DAMAGE_CAP)
    target:setMod(xi.mod.RECEIVED_DAMAGE_CAP, ov.damageCap)
    local damage = super(caster, target, spell)
    target:setMod(xi.mod.RECEIVED_DAMAGE_CAP, previousCap)

    return damage
end

m:addOverride('xi.actions.spells.black.stonega_iv.onSpellCast', kirinSpellCap)
m:addOverride('xi.actions.spells.black.stone_v.onSpellCast',    kirinSpellCap)
m:addOverride('xi.actions.spells.black.quake.onSpellCast',      kirinSpellCap)

-- Kirin's physical TP moves are a Gauntlet pressure point; bypass parry only
-- for the active Gauntlet Kirin fight so normal world mobskills remain retail.
m:addOverride('xi.actions.mobskills.deadly_hold.onMobWeaponSkill', function(mob, target, skill, action)
    if not isGauntletKirinTarget(mob, target) then
        return super(mob, target, skill, action)
    end

    local params =
    {
        baseDamage       = mob:getWeaponDmg(),
        numHits          = 1,
        fTP              = { 1.5, 1.5, 1.5 },
        attackType       = xi.attackType.PHYSICAL,
        damageType       = xi.damageType.BLUNT,
        shadowBehavior   = xi.mobskills.shadowBehavior.NUMSHADOWS_1,
        attackMultiplier = { 2.0, 2.0, 2.0 },
        canCrit          = true,
        criticalChance   = { 0.30, 0.30, 0.30 },
        skipParry        = true,
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end)

m:addOverride('xi.actions.mobskills.tail_swing.onMobWeaponSkill', function(mob, target, skill, action)
    if not isGauntletKirinTarget(mob, target) then
        return super(mob, target, skill, action)
    end

    local params =
    {
        baseDamage     = mob:getWeaponDmg(),
        numHits        = 1,
        fTP            = { 1.5, 1.5, 1.5 },
        attackType     = xi.attackType.PHYSICAL,
        damageType     = xi.damageType.SLASHING,
        shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1,
        skipParry      = true,
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 90)
    end

    return info.damage
end)

m:addOverride('xi.actions.mobskills.tail_smash.onMobWeaponSkill', function(mob, target, skill, action)
    if not isGauntletKirinTarget(mob, target) then
        return super(mob, target, skill, action)
    end

    local params =
    {
        baseDamage     = mob:getWeaponDmg(),
        numHits        = 1,
        fTP            = { 1.5, 1.5, 1.5 },
        attackType     = xi.attackType.PHYSICAL,
        damageType     = xi.damageType.SLASHING,
        shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1,
        skipParry      = true,
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 90)
    end

    return info.damage
end)

local healingSpellOverrides =
{
    'white.cure',
    'white.cure_ii',
    'white.cure_iii',
    'white.cure_iv',
    'white.cure_v',
    'white.cure_vi',
    'white.curaga',
    'white.curaga_ii',
    'white.curaga_iii',
    'white.curaga_iv',
    'white.curaga_v',
    'white.cura',
    'white.cura_ii',
    'white.cura_iii',
    'white.regen',
    'white.regen_ii',
    'white.regen_iii',
    'white.regen_iv',
    'white.regen_v',
    'blue.plenilune_embrace',
}

for _, spellPath in ipairs(healingSpellOverrides) do
    m:addOverride(string.format('xi.actions.spells.%s.onSpellCast', spellPath), function(caster, target, spell)
        if blockOutsideHealing(caster, target) then
            pcall(function() spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT) end)
            return 0
        end

        return super(caster, target, spell)
    end)
end

m:addOverride('xi.job_utils.dancer.useWaltzAbility', function(player, target, ability, action)
    if blockOutsideHealing(player, target) then
        pcall(function() ability:setMsg(xi.msg.basic.JA_NO_EFFECT) end)
        return 0
    end

    return super(player, target, ability, action)
end)

m:addOverride('xi.job_utils.white_mage.useBenediction', function(player, target, ability)
    if blockOutsideHealing(player, target) then
        pcall(function() ability:setMsg(xi.msg.basic.JA_NO_EFFECT) end)
        return 0
    end

    return super(player, target, ability)
end)

m:addOverride('xi.job_utils.white_mage.useMartyr', function(player, target, ability, action)
    if blockOutsideHealing(player, target) then
        pcall(function() ability:setMsg(xi.msg.basic.JA_NO_EFFECT) end)
        return 0
    end

    return super(player, target, ability, action)
end)

local petHealingAbilityOverrides =
{
    'healing_ruby',
    'healing_ruby_ii',
    'whispering_wind',
    'spring_water',
    'mending_halation',
}

for _, abilityName in ipairs(petHealingAbilityOverrides) do
    m:addOverride(string.format('xi.actions.abilities.pets.%s.onPetAbility', abilityName), function(target, pet, petskill, summoner, action)
        if blockOutsideHealing(pet or summoner, target) then
            pcall(function() petskill:setMsg(xi.msg.basic.JA_NO_EFFECT) end)
            return 0
        end

        return super(target, pet, petskill, summoner, action)
    end)
end

-- Zone-out ends the run
m:addOverride('xi.zones.Riverne-Site_A01.Zone.onZoneOut', function(player, ...)
    pcall(super, player, ...)
    if getSession(player) then
        endRun(player, 'left')
    end
end)

-- Death in the arena ends the run
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    if getSession(player) and player:getZoneID() == C.ARENA_ZONE then
        player:timer(2000, function(p) endRun(p, 'death') end)
    end
    return cs
end)

-----------------------------------
-- Override: Riverne-Site_B01 onInitialize → Hall of Champions
-----------------------------------
m:addOverride('xi.zones.Riverne-Site_B01.Zone.onInitialize', function(zone)
    super(zone)

    local champions = loadChampions()
    if #champions == 0 then return end

    local baseX = C.HALL_IN.x
    local py    = C.HALL_IN.y
    local pz    = C.HALL_IN.z - 20

    for i, c in ipairs(champions) do
        local npcX = baseX + (i - 1) * 6
        local info = c  -- capture for closure
        zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = string.format('Champion_%s', info.charname),
            packetName = string.format('%s%s', xi.icon.STAR_LARGE, info.charname),
            look       = C.CHAMPION_LOOK,
            x = npcX, y = py, z = pz,
            rotation   = 128,
            widescan   = 1,

            onTrigger = function(p, npc)
                local times = info.times or 1
                p:printToPlayer(string.format(
                    '[Hall of Champions] %s — conquered The Gauntlet %s.',
                    info.charname,
                    times == 1 and 'once' or (times .. ' times')), SYS)
                p:printToPlayer(string.format(
                    '[Hall of Champions] Last clear: %s.', info.latest or '?'), SYS)
            end,
        })
    end
end)

-----------------------------------
-- Override: Leafallia onInitialize → place the Gauntlet Keeper NPC
-- (relaunch hub; live server uses GM_Home instead)
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Gauntlet_Keeper',
        packetName = string.format('%sThe Gauntlet', xi.icon.SWORD_AND_SHIELD),
        look       = 2410,
        x          = 606.1380,
        y          =  -3.2550,
        z          = 515.1959,
        rotation   = 135,
        widescan   =  1,

        onTrigger = function(player, npc)
            local clears = player:getCharVar('Gauntlet_Clears') or 0
            player:printToPlayer(
                '[The Gauntlet] Ten escalating levels of solo combat in Riverne Site A01.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Levels 1-9: Defeat each NM to advance to the next level.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Level 10: Defeat Shinryu and earn your legend.', SYS)
            player:printToPlayer(
                '[The Gauntlet] Reward: 5M gil | 500 Paragon Points | 500 Infamy.', SYS)
            if clears > 0 then
                player:printToPlayer(string.format(
                    '[The Gauntlet] Your clear count: %d. The legend grows.', clears), SYS)
            end

            local options = {
                { 'Enter The Gauntlet', function(p) enterGauntlet(p) end },
                { 'Rules / Strategy',   function(p)
                    p:printToPlayer('[The Gauntlet] Solo challenge. Trusts are removed; pets are allowed.', SYS)
                    p:printToPlayer('[The Gauntlet] Death, leaving the arena, or aborting ends the run.', SYS)
                    p:printToPlayer('[The Gauntlet] Defeat levels 1-9 in order to unlock the Final Trial.', SYS)
                    p:printToPlayer('[The Gauntlet] Each boss has its own behaviour. Watch animations and messages.', SYS)
                    p:printToPlayer('[The Gauntlet] Rewards build as you progress, with milestone bonuses at 3, 6, and 9.', SYS)
                end },
                { 'About Champions',    function(p)
                    p:printToPlayer('[The Gauntlet] Champions are enshrined in Riverne Site B01.', SYS)
                end },
                { 'Close', function(p) end },
            }
            player:timer(30, function(p)
                p:customMenu({ title = 'The Gauntlet', options = options })
            end)
        end,
    })
end)

return m
