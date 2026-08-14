-----------------------------------
-- job_mastery.lua
--
-- JOB MASTERY CHALLENGES: each of the 14 weapon types has a powerful Guardian
-- boss that spawns in Walk of Echoes. Defeating your chosen Guardian earns
-- Prime Weapon Trial 4 credit (charVar PW_Trial4_Done = 1).
--
-- The fight is enforced solo: trusts are disabled zone-wide, player groups are
-- rejected, and damage from another player or their pet forfeits the run.
-- Death ends the challenge with no reward and no save.
--
-- CharVars:
--   PW_T4_<weapon>_Done   1 when that weapon's Guardian has been killed; this
--                         gates the matching forged Prime
--   PW_Trial4_Done        1 when ANY Guardian has been killed; this gates the
--                         two support Prime claims
--
-- Globals exposed for the !mastery command:
--   xi._jm_sessions       live session table
--   xi._jm_endChallenge   endChallenge(player, reason) function
--   xi._jm_guardians      GUARDIANS catalog (read-only)
--
-- NPC: Weapon Mastery Sage in Abdhaljs Isle-Purgonorgo (zone 44).
-- Needs map restart (addOverride hooks for the hub, Walk of Echoes, and death).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Walk_of_Echoes/Zone')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m         = Module:new('job_mastery')
local mechanics = require('modules/custom/lua/mob_mechanics_library')
local catalog   = require('modules/custom/lua/weapon_mastery_catalog')

-----------------------------------
-- Constants
-----------------------------------
local CHALLENGE_ZONE_ID = xi.zone.WALK_OF_ECHOES
local GROUP_ZONE_ID     = 210
-- Owner-verified landing spot in Walk of Echoes (zone 182): a stone platform
-- at (-519, 36, 236), separate from the Endless Tower's spot so the two trials
-- never overlap. The original (-380,14,10) was off the map. The boss spawns at
-- player+12 (x), so it lands just east on the same platform.
local WARP_IN  = { x = -519.013, y = 36.000, z = 235.893, rot = 226 }
local EXIT_WARP = { zoneId = 44, x = 571.471, y = -3.360, z = 512.586, rot = 65 }

local GUARDIANS     = catalog.guardians
local GUARDIAN_ORDER = catalog.order

-----------------------------------
-- Sessions
-----------------------------------
local sessions = {}
xi._jm_sessions  = sessions
xi._jm_guardians = GUARDIANS
xi._jm_order     = GUARDIAN_ORDER

-- Monotonic per-run token. Each challenge start stamps its session with a unique
-- runId; every boss closure captures the runId it was spawned under. A kill only
-- credits completion when the CURRENT session is still that same run, so a boss
-- from an aborted/abandoned run whose death is processed late (player left the
-- zone, aborted, then started a fresh run) can never complete the new run.
local nextRunId = 0

local function getSession(p)   return sessions[p:getName()] end
local function clearSession(p) sessions[p:getName()] = nil  end

-----------------------------------
-- Forward declarations
-----------------------------------
local endChallenge

-----------------------------------
-- Complete a guardian challenge
-----------------------------------
local function completeChallenge(player, weaponKey)
    clearSession(player)

    local g = GUARDIANS[weaponKey]
    player:setCharVar(catalog.completionVar(weaponKey), 1)

    player:printToPlayer(string.format(
        '[Mastery] The %s has been defeated! %s Challenge complete!',
        g.bossName, g.label), xi.msg.channel.SYSTEM_3)

    if (player:getCharVar('PW_Trial4_Done') or 0) == 0 then
        player:setCharVar('PW_Trial4_Done', 1)
        player:printToPlayer(
            '[Mastery] Trial 4 complete! This Guardian now authorizes its matching Prime weapon.',
            xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer(
            '[Mastery] Additional Guardian mastered. Each family authorizes its matching Prime.',
            xi.msg.channel.SYSTEM_3)
    end

    player:timer(3000, function(p)
        p:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
    end)
end

-----------------------------------
-- End the challenge early (death / abort / zone-leave)
-----------------------------------
endChallenge = function(player, reason)
    local sess = getSession(player)
    clearSession(player)

    if sess and sess.boss then
        pcall(function() sess.boss:setHP(0) end)
    end

    if reason == 'death' then
        player:printToPlayer('[Mastery] You were defeated. The Guardian endures.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'abort' then
        player:printToPlayer('[Mastery] Challenge aborted.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'left' then
        player:printToPlayer('[Mastery] You left the arena. Challenge forfeited.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'grouped' then
        player:printToPlayer('[Mastery] Another adventurer joined you. A mastery trial must be faced alone.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'external' then
        player:printToPlayer('[Mastery] Another adventurer interfered. The Guardian rejects the challenge.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'weapon' then
        player:printToPlayer('[Mastery] You abandoned the chosen weapon family. Challenge forfeited.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'timeout' then
        player:printToPlayer('[Mastery] Ten minutes have passed. The Guardian ends the trial.', xi.msg.channel.SYSTEM_3)
    end

    -- 'left' means the player is already mid-transition OUT of the arena (an
    -- external warp / home point / GM teleport). Don't yank them to the exit warp
    -- on top of their own zone change -- just forfeit in place. Death/abort happen
    -- while the player is still standing in the arena, so those DO warp out.
    if reason ~= 'left' then
        player:timer(2000, function(p)
            p:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
        end)
    end
end

xi._jm_endChallenge = endChallenge

local function clearSoloFailEffects(player)
    if not player then return end
    for _, effectId in ipairs(catalog.soloFailEffects) do
        pcall(function() player:delStatusEffectSilent(effectId) end)
    end
end

local function playerOwner(entity)
    if not entity then return nil, false end
    local isPlayer = false
    pcall(function() isPlayer = entity:isPC() end)
    if isPlayer then return entity, true end

    local master
    local objType
    pcall(function() master = entity:getMaster() end)
    pcall(function() objType = entity:getObjType() end)
    if master then
        pcall(function()
            if not master:isPC() then master = nil end
        end)
    end
    return master, objType == xi.objType.PET
end

local function queueForfeit(ownerName, runId, reason)
    local sess = sessions[ownerName]
    if not sess or sess.runId ~= runId or sess.ending then return end
    sess.ending = true
    local owner = GetPlayerByName(ownerName)
    if owner then
        owner:timer(1, function(p)
            local current = sessions[ownerName]
            if current and current.runId == runId then endChallenge(p, reason) end
        end)
    else
        pcall(function()
            if sess.boss then sess.boss:setHP(0) end
        end)
        sessions[ownerName] = nil
    end
end

-----------------------------------
-- Spawn the Guardian
-----------------------------------
local function spawnGuardian(player, weaponKey)
    local g         = GUARDIANS[weaponKey]
    local ownerName = player:getName()
    local runId     = sessions[ownerName] and sessions[ownerName].runId

    local px, py, pz = player:getXPos(), player:getYPos(), player:getZPos()
    local mx = px + 12
    local mz = pz

    local mob = player:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = g.groupId,
        groupZoneId          = GROUP_ZONE_ID,
        name                 = g.bossName,
        x = mx, y = py, z = mz,
        rotation             = 128,
        minLevel             = g.level,
        maxLevel             = g.level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)
            -- Bind the credit to THIS run. If the active session belongs to a
            -- different (newer) run -- or there is no session at all -- this is a
            -- stale boss from an aborted/abandoned run; killing it must NOT
            -- complete whatever the player is doing now.
            local s = sessions[ownerName]
            if not s or s.runId ~= runId or s.ending or s.externalDamage then return end
            sessions[ownerName] = nil
            local resolved = GetPlayerByName(ownerName)
            if resolved then completeChallenge(resolved, weaponKey) end
        end,

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
            local owner = GetPlayerByName(ownerName)
            local s = sessions[ownerName]
            if not owner or not s or s.runId ~= runId or s.ending then return end

            clearSoloFailEffects(owner)
            if catalog.isGrouped(owner) then
                queueForfeit(ownerName, runId, 'grouped')
                return
            end

            if catalog.hasRequiredWeapon(owner, g) then
                s.invalidWeaponTicks = 0
            else
                s.invalidWeaponTicks = (s.invalidWeaponTicks or 0) + 1
                if s.invalidWeaponTicks >= catalog.weaponGraceTicks then
                    queueForfeit(ownerName, runId, 'weapon')
                end
            end
        end,
    })

    if not mob then
        player:printToPlayer('[Mastery] ERROR: Guardian failed to spawn. Aborting.', xi.msg.channel.SYSTEM_3)
        endChallenge(player, 'abort')
        return
    end

    mob:setSpawn(mx, py, mz, 128)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setModelSize(3)

    for modId, val in pairs(g.mods) do mob:setMod(modId, val) end
    mob:setMaxHP(g.hp)
    mob:setHP(g.hp)
    mob:setLocalVar('GeasFeteMobSkillDamageCap', g.damageCap)
    mob:addEnmity(player, 30000, 30000)

    mechanics.attach(mob, g.mechanics, ownerName)
    mob:addListener('TAKE_DAMAGE', 'MASTERY_SOLO_' .. tostring(mob:getID()),
        function(damagedMob, amount, attacker)
            local strikerOwner, allowedSource = playerOwner(attacker)
            if
                strikerOwner and
                (strikerOwner:getName() ~= ownerName or not allowedSource)
            then
                local s = sessions[ownerName]
                if s and s.runId == runId then s.externalDamage = true end
                queueForfeit(ownerName, runId, 'external')
            end
        end)

    -- Store ref for abort/death cleanup.
    local sess = sessions[ownerName]
    if sess then sess.boss = mob end

    -- Idle despawn: if the mob hasn't taken any damage after 45s, remove it.
    -- Clear the session first so onMobDeath's completion guard fires and exits.
    local spawnHp = g.hp
    player:timer(45000, function(p)
        local s = sessions[ownerName]
        if not s or s.runId ~= runId or s.boss ~= mob then return end   -- session gone, new run, or boss replaced
        local hp = 0
        local ok = pcall(function() hp = mob:getHP() end)
        if not ok then return end                    -- mob already gone
        if hp < spawnHp then return end              -- player is fighting; leave it alone
        sessions[ownerName] = nil
        pcall(function() mob:setHP(0) end)
        p:printToPlayer('[Mastery] The Guardian vanished — engage within 45 seconds next time.', xi.msg.channel.SYSTEM_3)
        p:timer(2000, function(pp)
            pp:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
        end)
    end)

    player:timer(catalog.hardTimeoutSec * 1000, function(p)
        local s = sessions[ownerName]
        if s and s.runId == runId then queueForfeit(ownerName, runId, 'timeout') end
    end)

    player:printToPlayer(string.format(
        '[Mastery] The %s appears with %d HP. Mob skills are capped at %d damage.',
        g.bossName, g.hp, g.damageCap), xi.msg.channel.SYSTEM_3)
end

-----------------------------------
-- Zone-in trigger (called after the warp lands)
-----------------------------------
local function entryFailureMessage(reason, guardian)
    if reason == 'level' then
        return 'Reach level 99 before attempting Weapon Mastery.'
    elseif reason == 'prior_trials' then
        return 'Complete Prime Trials 1, 2, and 3 before attempting Trial 4.'
    elseif reason == 'aeonic' then
        return 'Complete one Aeonic weapon through the Weapon Forge first.'
    elseif reason == 'grouped' then
        return 'This is a solo trial. Leave all player parties and alliances first.'
    elseif reason == 'weapon' then
        return string.format('Equip an item-level 119 %s before entering.', guardian.type)
    end
    return 'This mastery challenge is unavailable.'
end

local function startChallenge(player, weaponKey)
    local g = GUARDIANS[weaponKey]
    local eligible, reason = catalog.entryCheck(player, g)
    if not eligible then
        player:printToPlayer('[Mastery] ' .. entryFailureMessage(reason, g), xi.msg.channel.SYSTEM_3)
        endChallenge(player, 'abort')
        return
    end
    player:printToPlayer(string.format(
        '[Mastery] %s Mastery Challenge! Defeat the %s. Good luck.',
        g.label, g.bossName), xi.msg.channel.SYSTEM_3)
    player:timer(2000, function(p)
        if sessions[p:getName()] then spawnGuardian(p, weaponKey) end
    end)
end

-----------------------------------
-- NPC menu (paginated 6 per page; each page <=150 bytes incl. title + labels)
-----------------------------------
local function showMasteryMenu(player, page)
    -- Print completion status above the menu.
    local doneList = {}
    for _, key in ipairs(GUARDIAN_ORDER) do
        if catalog.isComplete(player, key) then
            doneList[#doneList + 1] = GUARDIANS[key].label
        end
    end
    if #doneList > 0 then
        player:printToPlayer('[Mastery] Guardians defeated: ' .. table.concat(doneList, ', '), xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer('[Mastery] No Weapon Guardians defeated yet. Trial 4 incomplete.', xi.msg.channel.SYSTEM_3)
    end

    local PER_PAGE   = 6
    local totalPages = math.ceil(#GUARDIAN_ORDER / PER_PAGE)
    page = math.max(1, math.min(page or 1, totalPages))
    local title    = 'Mastery ' .. page .. '/' .. totalPages
    local opts     = {}
    local idxStart = (page - 1) * PER_PAGE + 1
    local idxEnd   = math.min(page * PER_PAGE, #GUARDIAN_ORDER)

    for i = idxStart, idxEnd do
        local key    = GUARDIAN_ORDER[i]
        local g      = GUARDIANS[key]
        local isDone = catalog.isComplete(player, key)
        local eligible = catalog.entryCheck(player, g)
        local lbl
        if isDone then
            lbl = g.label .. ' [Done]'
        elseif not eligible then
            lbl = g.label .. ' [Locked]'
        else
            lbl = g.label
        end

        local capturedKey = key
        local capturedGuardian = g
        local capturedPage = page
        table.insert(opts, {
            lbl,
            function(p)
                if getSession(p) then
                    p:printToPlayer('[Mastery] Active challenge. !mastery abort to reset.', xi.msg.channel.SYSTEM_3)
                    return
                end
                local eligible, reason = catalog.entryCheck(p, capturedGuardian)
                if not eligible then
                    p:printToPlayer(
                        '[Mastery] ' .. entryFailureMessage(reason, capturedGuardian),
                        xi.msg.channel.SYSTEM_3)
                    showMasteryMenu(p, capturedPage)
                    return
                end
                p:printToPlayer(string.format(
                    '[Mastery] %s -> %s. %s',
                    capturedGuardian.type, capturedGuardian.primeName, capturedGuardian.signature),
                    xi.msg.channel.SYSTEM_3)
                p:printToPlayer(string.format(
                    '[Mastery] %d HP | %d-second enrage | %d-second limit | %d damage cap.',
                    capturedGuardian.hp, catalog.softEnrageSec, catalog.hardTimeoutSec,
                    capturedGuardian.damageCap), xi.msg.channel.SYSTEM_3)

                local confirm =
                {
                    title = capturedGuardian.label .. ' Mastery',
                    options =
                    {
                        { 'Begin solo challenge', function(challenger)
                            local stillEligible, newReason = catalog.entryCheck(challenger, capturedGuardian)
                            if not stillEligible then
                                challenger:printToPlayer(
                                    '[Mastery] ' .. entryFailureMessage(newReason, capturedGuardian),
                                    xi.msg.channel.SYSTEM_3)
                                showMasteryMenu(challenger, capturedPage)
                                return
                            end
                            if getSession(challenger) then return end
                            nextRunId = nextRunId + 1
                            sessions[challenger:getName()] =
                            {
                                weapon = capturedKey,
                                boss = nil,
                                runId = nextRunId,
                                invalidWeaponTicks = 0,
                                externalDamage = false,
                            }
                            challenger:setPos(
                                WARP_IN.x, WARP_IN.y, WARP_IN.z, WARP_IN.rot, CHALLENGE_ZONE_ID)
                        end },
                        { 'Return to list', function(challenger)
                            showMasteryMenu(challenger, capturedPage)
                        end },
                    },
                }
                p:timer(30, function(challenger) challenger:customMenu(confirm) end)
            end,
        })
    end

    if page > 1 then
        table.insert(opts, { '<- Back', function(p) showMasteryMenu(p, page - 1) end })
    end
    if page < totalPages then
        table.insert(opts, { 'Next ->', function(p) showMasteryMenu(p, page + 1) end })
    end
    table.insert(opts, { 'Leave', function(p) end })

    local snap = { title = title, options = opts }
    player:timer(30, function(p) p:customMenu(snap) end)
end

-----------------------------------
-- Module overrides
-----------------------------------

-- GM Home: right side of the mastery conversation semicircle.
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Weapon_Mastery_Sage',
        packetName = 'Weapon Mastery',
        look       = 212,
        x          = 540.9993,
        y          =  -3.4665,
        z          = 498.0069,
        rotation   = 90,
        widescan   =  1,

        onTrigger = function(player, npc)
            if getSession(player) then
                player:printToPlayer('[Mastery] You have an active challenge. Use !mastery abort to reset.', xi.msg.channel.SYSTEM_3)
                return
            end
            player:printToPlayer(
                '[Mastery] Trial 4 is a true solo duel. Complete Trials 1-3 and one Aeonic, then equip an item-level 119 weapon of the family you choose.',
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer(
                '[Mastery] Each Guardian authorizes only its matching forged Prime. Any one clear authorizes a support Prime.',
                xi.msg.channel.SYSTEM_3)
            showMasteryMenu(player, 1)
        end,
    })
    utils.unused(npc)
end)

-- Walk of Echoes: start the challenge after zone-in.
m:addOverride('xi.zones.Walk_of_Echoes.Zone.onZoneIn', function(player, prevZone)
    local cs   = super(player, prevZone)
    local sess = getSession(player)
    -- Only fire if we have a session and the boss hasn't spawned yet.
    if sess and sess.boss == nil and sess.weapon then
        startChallenge(player, sess.weapon)
    end
    return cs
end)

-- Leaving the arena by ANY means (warp scroll, home point, GM teleport, etc.)
-- forfeits the run and despawns the stranded Guardian. Closes the "strand the
-- boss in a dormant zone, start a fresh run, let the old boss's queued death
-- credit the new run" exploit at the source, and prevents the session soft-lock
-- (an abandoned session would otherwise block starting another challenge until
-- the player manually ran !mastery abort). endChallenge clears the session
-- BEFORE killing the boss, so the boss's onMobDeath awards no credit.
m:addOverride('xi.zones.Walk_of_Echoes.Zone.onZoneOut', function(player, ...)
    pcall(super, player, ...)
    if getSession(player) then
        endChallenge(player, 'left')
    end
end)

-- Death ends the challenge.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    local sess = getSession(player)
    if sess then
        local runId = sess.runId
        sess.ending = true
        player:timer(2000, function(p)
            local current = getSession(p)
            if current and current.runId == runId then endChallenge(p, 'death') end
        end)
    end
    return cs
end)

return m
