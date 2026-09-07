-----------------------------------
-- Character_Upgrader.lua
-- AUTO-GRANT at character creation: on a brand-new character's first login,
-- automatically grants weapon skills, spells (non-trust), capped skills, four
-- starter trusts, all quests/missions, maps, outpost warps, homepoints, survival guides, wardrobe
-- sizes, and automaton parts -- everything the old "Unlocker" GM-Home NPC used
-- to hand out on demand. The NPC is gone (owner request 2026-06-25); the grant
-- now runs once via xi.player.onGameIn (firstLogin), sliced across ticks so
-- the 2s inactivity watchdog cannot kill xi_map. The player is Bound in
-- place until Setup Complete. Paid Void Keeper trusts are still withheld.
-----------------------------------
require('modules/module_utils')

local m = Module:new('character_upgrader')
local spellGrant = require('modules/custom/lua/player_spell_grant_catalog')
local trustGrant = require('modules/custom/lua/trust_grant_catalog')
local remaCatalog = require('modules/custom/lua/rema_ws_tier_catalog')

xi.characterUpgrade = xi.characterUpgrade or {}

local COMPLETE_VAR = 'AutoUnlock_Complete'
local STARTED_VAR  = 'AutoUnlock_Done'
local UNITY_VAR    = 'AutoUnlock_UnityGrant'
local RUNNING_VAR  = 'AutoUnlock_Running'
local SYS          = xi.msg.channel.SYSTEM_3
local LOCK_EFFECT  = xi.effect.BIND
local LOCK_SECS    = 900
local LOCK_FLAGS   = bit.bor(
    xi.effectFlag.NO_CANCEL,
    xi.effectFlag.HIDE_TIMER,
    xi.effectFlag.NO_LOSS_MESSAGE
)

-- Late-grant probes. Mount companions sit at the high end of the KI table;
-- HP 121 is unlocked after the KI pass. Missing either means they zoned
-- before the sliced first-login grant finished.
xi.characterUpgrade.SENTINEL_KIS =
{
    xi.ki.CHOCOBO_LICENSE,
    xi.ki.CHOCOBO_COMPANION,
    xi.ki.RAPTOR_COMPANION,
    xi.ki.TIGER_COMPANION,
    xi.ki.IXION_COMPANION,
    xi.ki.PHUABO_COMPANION,
    xi.ki.CRAKLAW_COMPANION,
}

-- Starter trusts (see exports/trust_cipher_drop_proposal.csv). Every other trust
-- is earned via cipher drops, direct NM grants, or the Void Keeper.
local STARTER_TRUSTS    = trustGrant.STARTER_TRUSTS
local STARTER_TRUST_SET = trustGrant.STARTER_TRUST_SET
local TRUST_SPELL_MIN   = trustGrant.TRUST_SPELL_MIN
local TRUST_SPELL_MAX   = trustGrant.TRUST_SPELL_MAX
local SKOLL_SPELL     = (xi.magic and xi.magic.spell and xi.magic.spell.SKOLL) or 901
local MEAT_SPELL      = (xi.magic and xi.magic.spell and xi.magic.spell.EXCENMILLE) or 899
local CORVUS_SPELL    = (xi.magic and xi.magic.spell and xi.magic.spell.CURILLA) or 902
local CORNELIA_SPELL  = (xi.trust and xi.trust.VOID_KEEPER_SPELL and xi.trust.VOID_KEEPER_SPELL.CORNELIA) or 1002
local MATSUI_P_SPELL  = (xi.trust and xi.trust.VOID_KEEPER_SPELL and xi.trust.VOID_KEEPER_SPELL.MATSUI_P) or 1004
local MATSUI_SEASONAL = (xi.trust and xi.trust.DISABLED_SPELL and xi.trust.DISABLED_SPELL.MATSUI_SEASONAL) or 1003
local ALDO_SPELL      = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO) or 930
local ALDO_UC_SPELL   = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO_UC) or 1007

local EXCLUDED_SPELLS =
{
    [SKOLL_SPELL]    = true,
    [MEAT_SPELL]     = true,
    [CORVUS_SPELL]   = true,
    [CORNELIA_SPELL] = true,
    [MATSUI_P_SPELL]  = true,
    [MATSUI_SEASONAL] = true,
    [ALDO_SPELL]     = true,
    [ALDO_UC_SPELL]  = true,
}

-- Automaton heads/frames/attachments (mirrors scripts/commands/addallattachments.lua).
local AUTOMATON_PARTS =
{
    8193, 8194, 8195, 8196, 8197, 8198, 8224, 8225, 8226, 8227,
    8449, 8450, 8451, 8452, 8453, 8454, 8455, 8456, 8457, 8458,
    8459, 8460, 8461, 8462, 8463, 8464, 8465, 8466, 8481, 8482,
    8483, 8484, 8485, 8486, 8487, 8488, 8489, 8490, 8491, 8492,
    8493, 8494, 8495, 8496, 8497, 8498, 8513, 8514, 8515, 8516,
    8517, 8518, 8519, 8520, 8521, 8522, 8523, 8524, 8525, 8526,
    8527, 8528, 8545, 8546, 8547, 8548, 8549, 8550, 8551, 8552,
    8553, 8554, 8555, 8556, 8557, 8577, 8578, 8579, 8580, 8581,
    8582, 8583, 8584, 8585, 8586, 8587, 8588, 8589, 8590, 8609,
    8610, 8611, 8612, 8613, 8614, 8615, 8616, 8617, 8618, 8619,
    8620, 8621, 8622, 8641, 8642, 8643, 8644, 8645, 8646, 8648,
    8649, 8650, 8651, 8652, 8653, 8654, 8655, 8673, 8674, 8675,
    8676, 8677, 8678, 8680, 8681, 8682, 8683,
}

-----------------------------------
-- Grant helpers (unchanged from the old Unlocker NPC; now module-scope).
-----------------------------------
local AEONIC_WS = {}
for _, entry in ipairs(remaCatalog.WEAPONS) do
    if entry.family == 'AEONIC' then AEONIC_WS[entry.wsId] = true end
end

local function giveAllWeaponSkills(player)
    for i = 1, 256 do
        -- Aeonic WSs unlock when the player begins that specific pilgrimage.
        if not AEONIC_WS[i] then pcall(function() player:addWeaponSkill(i) end) end
    end
    for _, unlockId in pairs(xi.wsUnlock) do
        pcall(function() player:addLearnedWeaponskill(unlockId) end)
    end
end

local function isTrustSpell(spellId)
    return spellId >= TRUST_SPELL_MIN and spellId <= TRUST_SPELL_MAX
end

local function shouldGrantSpell(spellId)
    if EXCLUDED_SPELLS[spellId] or spellGrant.mobOnlySpells[spellId] then
        return false
    end
    -- Trusts are not part of the spell bulk grant (starters handled separately).
    if isTrustSpell(spellId) then
        return false
    end
    return true
end

local function stripNonStarterTrusts(player)
    for spellId = TRUST_SPELL_MIN, TRUST_SPELL_MAX do
        if not STARTER_TRUST_SET[spellId] and player:hasSpell(spellId) then
            pcall(function()
                player:delSpell(spellId, { silentLog = true, saveToDB = true, sendUpdate = false })
            end)
        end
    end
end
local function stripMobOnlySpells(player)
    for spellId in pairs(spellGrant.mobOnlySpells) do
        if player:hasSpell(spellId) then
            pcall(function()
                player:delSpell(spellId, { silentLog = true, saveToDB = true, sendUpdate = false })
            end)
        end
    end
end

-- C++ MAX_SPELL_ID is 1024 and exclusive. The old 1..1024 loop called
-- hasSpell(1024) (OOB on bitset<1024>) and GetSpell(1024) (watchdog log).
local MAX_PLAYER_SPELL_ID = 1023

-- Inactivity watchdog kills xi_map if one tick exceeds 2000ms. First-login
-- used to grant every spell/quest/mission/KI in one timer callback; addKeyItem
-- also UPDATE chars.keyitems on every KI. Slice the work across ticks.
local STEP_GAP_MS    = 250
local SPELL_BATCH    = 64
local QUEST_BATCH    = 25
local KEY_ITEM_BATCH = 15
local MISSION_BATCH  = 12

local function isValidPlayer(player)
    return player ~= nil and player:isPC()
end

-- Bind holds a real client still without the fade-to-black cutscene lock.
-- Warp commands still go through refuseTravel because setPos ignores Bind.
local function lockPlayer(player)
    if not isValidPlayer(player) then
        return
    end

    pcall(function()
        if player:hasStatusEffect(LOCK_EFFECT) then
            player:delStatusEffectSilent(LOCK_EFFECT)
        end

        player:addStatusEffect(LOCK_EFFECT, {
            origin   = player,
            power    = 1,
            duration = LOCK_SECS,
            flag     = LOCK_FLAGS,
            silent   = true,
        })
    end)
end

local function unlockPlayer(player)
    if not player then
        return
    end

    pcall(function()
        if player.hasStatusEffect and player:hasStatusEffect(LOCK_EFFECT) then
            player:delStatusEffectSilent(LOCK_EFFECT)
        end
    end)
end

xi.characterUpgrade.applyMovementLock = lockPlayer
xi.characterUpgrade.clearMovementLock = unlockPlayer

local function runJobs(player, jobs, index)
    if not isValidPlayer(player) then
        return
    end

    local job = jobs[index]
    if not job then
        return
    end

    pcall(job, player)

    if jobs[index + 1] then
        local bound = false
        pcall(function()
            bound = player:hasStatusEffect(LOCK_EFFECT)
        end)
        if not bound then
            lockPlayer(player)
        end

        if index % 80 == 0 then
            player:printToPlayer('Still setting up -- you cannot move until Setup Complete, kupo!', 0, 'Unlocker')
        end

        player:timer(STEP_GAP_MS, function(nextPlayer)
            runJobs(nextPlayer, jobs, index + 1)
        end)
    end
end

local function startJobs(player, delayMs, jobs)
    if not jobs or #jobs == 0 then
        return
    end

    player:timer(delayMs, function(nextPlayer)
        runJobs(nextPlayer, jobs, 1)
    end)
end

local function appendRangeJobs(jobs, firstIdx, lastIdx, batchSize, makeJob)
    local startIdx = firstIdx
    while startIdx <= lastIdx do
        local stopIdx = math.min(startIdx + batchSize - 1, lastIdx)
        local fromIdx, toIdx = startIdx, stopIdx
        jobs[#jobs + 1] = function(player)
            makeJob(player, fromIdx, toIdx)
        end
        startIdx = stopIdx + 1
    end
end

local function giveSpellRange(player, fromId, toId)
    for spellId = fromId, toId do
        pcall(function()
            if shouldGrantSpell(spellId) and not player:hasSpell(spellId) then
                player:addSpell(spellId, { silentLog = true })
            end
        end)
    end
end

local function capAllSkills(player)
    player:capAllSkills()
end

local function giveStarterTrusts(player)
    for _, spellId in ipairs(STARTER_TRUSTS) do
        pcall(function()
            if xi.trustGrant and xi.trustGrant.grantSpell then
                xi.trustGrant.grantSpell(player, spellId, { silentLog = true })
            else
                player:addSpell(spellId, { silentLog = true })
            end
        end)
    end
end

local function grantMissionRange(player, logId, fromId, toId)
    for missionId = fromId, toId do
        pcall(function()
            player:addMission(logId, missionId)
            player:completeMission(logId, missionId)
        end)
    end
end

local function grantMissionList(player, logId, missionIds, fromIdx, toIdx)
    for i = fromIdx, toIdx do
        local missionId = missionIds[i]
        pcall(function()
            player:addMission(logId, missionId)
            player:completeMission(logId, missionId)
        end)
    end
end

local function appendMissionRangeJobs(jobs, logId, lastId)
    appendRangeJobs(jobs, 0, lastId, MISSION_BATCH, function(player, fromId, toId)
        grantMissionRange(player, logId, fromId, toId)
    end)
end

local function appendMissionListJobs(jobs, logId, missionIds)
    appendRangeJobs(jobs, 1, #missionIds, MISSION_BATCH, function(player, fromIdx, toIdx)
        grantMissionList(player, logId, missionIds, fromIdx, toIdx)
    end)
end

local missionSOA =
{
    0,1,3,5,6,7,8,9,11,12,13,14,15,16,17,18,19,20,21,23,26,27,29,
    30,31,34,35,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,
    55,56,57,58,59,61,62,63,66,67,69,70,71,72,73,74,75,76,77,78,79,
    80,81,82,84,85,86,87,88,89,90,91,92,93,94,95,96,98,99,100,101,
    102,103,104,105,107,108,109,110,111,112,113,114,116,117,118,120,
    121,123,125,129,
}

local missionROV =
{
    0,2,3,4,6,10,12,18,20,22,26,28,30,32,34,36,40,42,44,46,48,50,
    52,54,56,60,62,64,66,68,70,72,78,80,83,86,92,94,96,98,100,102,
    103,104,106,108,110,114,116,118,120,122,124,126,130,132,136,142,
    144,146,150,152,154,155,156,158,160,161,162,164,166,170,172,174,
    178,180,184,188,190,192,194,196,198,200,202,206,210,212,216,218,
    220,222,224,226,
}

local function appendMissionJobs(jobs)
    -- San d'Oria / Bastok / Windurst / RoZ / CoP / ToAU / WotG / ACP / AMK / ASA / TVR / SoA / RoV
    appendMissionRangeJobs(jobs, 0, 23)
    jobs[#jobs + 1] = function(player)
        player:setRank(10)
    end
    appendMissionRangeJobs(jobs, 1, 23)
    appendMissionRangeJobs(jobs, 2, 23)
    appendMissionRangeJobs(jobs, 3, 31)
    -- completeMission resets CoP current to 0; THE_LAST_VERSE=850 marks earlier complete.
    jobs[#jobs + 1] = function(player)
        pcall(function() player:addMission(6, 850) end)
    end
    -- completeMission resets ToAU current to 0 and locks Assault; push to ETERNAL_MERCENARY.
    appendMissionRangeJobs(jobs, 4, 47)
    jobs[#jobs + 1] = function(player)
        pcall(function() player:addMission(4, 47) end)
    end
    appendMissionRangeJobs(jobs, 5, 53)
    appendMissionRangeJobs(jobs, 9, 11)
    appendMissionRangeJobs(jobs, 10, 14)
    appendMissionRangeJobs(jobs, 11, 14)
    appendMissionRangeJobs(jobs, 14, 46)
    appendMissionListJobs(jobs, 12, missionSOA)
    jobs[#jobs + 1] = function(player)
        pcall(function() player:addMission(12, 130) end)
    end
    appendMissionListJobs(jobs, 13, missionROV)
    jobs[#jobs + 1] = function(player)
        pcall(function() player:addMission(13, 227) end)
        player:setCharVar('MissionClearanceReceived', 1)
    end
end

local questEntries = nil

local function getQuestEntries()
    if questEntries then
        return questEntries
    end

    questEntries = {}
    for logId, areaKey in pairs(xi.quest.area) do
        if logId >= 0 then
            local areaQuests = xi.quest.id[areaKey]
            if areaQuests then
                for _, questId in pairs(areaQuests) do
                    questEntries[#questEntries + 1] = { logId, questId }
                end
            end
        end
    end

    return questEntries
end

local function appendQuestJobs(jobs)
    local entries = getQuestEntries()
    appendRangeJobs(jobs, 1, #entries, QUEST_BATCH, function(player, fromIdx, toIdx)
        for i = fromIdx, toIdx do
            local entry = entries[i]
            pcall(function()
                player:addQuest(entry[1], entry[2])
                player:completeQuest(entry[1], entry[2])
            end)
        end
    end)
end

local keyItemIds = nil

local function getKeyItemIds()
    if keyItemIds then
        return keyItemIds
    end

    keyItemIds = {}
    for _, kiId in pairs(xi.ki) do
        if type(kiId) == 'number' then
            keyItemIds[#keyItemIds + 1] = kiId
        end
    end

    return keyItemIds
end

local function appendKeyItemJobs(jobs)
    local items = getKeyItemIds()
    appendRangeJobs(jobs, 1, #items, KEY_ITEM_BATCH, function(player, fromIdx, toIdx)
        for i = fromIdx, toIdx do
            local kiId = items[i]
            if not player:hasKeyItem(kiId) then
                pcall(function() player:addKeyItem(kiId) end)
            end
        end
    end)
end

local function giveAllOutpostWarps(player)
    for _, nation in pairs({ xi.nation.SANDORIA, xi.nation.BASTOK, xi.nation.WINDURST }) do
        for region = xi.region.RONFAURE, xi.region.TAVNAZIANARCH do
            pcall(function() player:addTeleport(nation, region + 5) end)
        end
    end
end

local function giveAllHomepoints(player)
    for i = 0, 121 do
        local hpBit = i % 32
        local hpSet = math.floor(i / 32)
        pcall(function() player:addTeleport(xi.teleport.type.HOMEPOINT, hpBit, hpSet) end)
    end
end

local function giveAllSurvivalGuides(player)
    for groupIndex = 0, 31 do
        for group = 0, 2 do
            pcall(function() player:addTeleport(xi.teleport.type.SURVIVAL, groupIndex, group) end)
        end
    end
end

local function bumpWardrobeSizes(player)
    local target = xi.settings.main.START_INVENTORY
    local locations = {
        xi.inv.WARDROBE,  xi.inv.WARDROBE2, xi.inv.WARDROBE3, xi.inv.WARDROBE4,
        xi.inv.WARDROBE5, xi.inv.WARDROBE6, xi.inv.WARDROBE7, xi.inv.WARDROBE8,
    }
    local bumped = 0
    for _, loc in ipairs(locations) do
        local delta = target - player:getContainerSize(loc)
        if delta > 0 then
            player:changeContainerSize(loc, delta)
            bumped = bumped + 1
        end
    end
end

local function giveAllAttachments(player)
    for _, id in ipairs(AUTOMATON_PARTS) do
        pcall(function() player:unlockAttachment(id) end)
    end
end

local function hasLateHomepoint(player)
    -- giveAllHomepoints unlocks 0..121. Bit 25 of set 3 is index 121.
    return player:hasTeleport(xi.teleport.type.HOMEPOINT, 25, 3)
end

local function hasAllSentinelKeyItems(player)
    for _, kiId in ipairs(xi.characterUpgrade.SENTINEL_KIS) do
        if kiId and not player:hasKeyItem(kiId) then
            return false
        end
    end

    return true
end

xi.characterUpgrade.isComplete = function(player)
    if not player then
        return false
    end

    if (player:getCharVar(COMPLETE_VAR) or 0) == 1 then
        return true
    end

    -- Legacy characters finished before AutoUnlock_Complete existed.
    if hasAllSentinelKeyItems(player) and hasLateHomepoint(player) then
        player:setCharVar(COMPLETE_VAR, 1)
        return true
    end

    return false
end

local function finishSetup(player)
    if (player:getCharVar(UNITY_VAR) or 0) == 0 then
        player:addCurrency('unity_accolades', 500)
        player:setCharVar(UNITY_VAR, 1)
        player:printToPlayer('Starter Unity Accolades granted (Unity Wanted Board in Library)', SYS)
    end

    player:setCharVar(COMPLETE_VAR, 1)
    player:setLocalVar(RUNNING_VAR, 0)
    unlockPlayer(player)
    player:printToPlayer('[ Setup Complete ]', SYS)
    player:printToPlayer('Spells, weapon skills & job abilities', SYS)
    player:printToPlayer('Starter trusts: Shantotto, Kupipi, Trion, Tenzen', SYS)
    player:printToPlayer('All quests & missions completed', SYS)
    player:printToPlayer('All key items, maps, mounts, homepoints, survival guides & outpost warps', SYS)
    player:printToPlayer('Full wardrobes & automaton parts', SYS)
    player:printToPlayer('Welcome! Type !help to get started.', SYS)
end

local function buildFirstLoginJobs()
    local jobs = {}

    jobs[#jobs + 1] = function(player)
        player:setLevelCap(99)
        player:printToPlayer('Level cap raised to 99, kupo!', 0, 'Unlocker')
        player:unlockJob(0)
        player:printToPlayer('Subjob unlocked, kupo!', 0, 'Unlocker')
        giveAllWeaponSkills(player)
    end

    appendRangeJobs(jobs, 1, MAX_PLAYER_SPELL_ID, SPELL_BATCH, giveSpellRange)

    jobs[#jobs + 1] = function(player)
        capAllSkills(player)
        giveStarterTrusts(player)
    end

    appendQuestJobs(jobs)
    appendMissionJobs(jobs)
    appendKeyItemJobs(jobs)

    jobs[#jobs + 1] = function(player)
        giveAllOutpostWarps(player)
        giveAllHomepoints(player)
    end
    jobs[#jobs + 1] = function(player)
        giveAllSurvivalGuides(player)
        bumpWardrobeSizes(player)
        giveAllAttachments(player)
    end

    jobs[#jobs + 1] = function(player)
        stripMobOnlySpells(player)
        stripNonStarterTrusts(player)
        giveStarterTrusts(player)
        if player:getCurrentMission(xi.mission.log_id.TOAU) <= xi.mission.id.toau.PRESIDENT_SALAHEEM then
            player:addMission(xi.mission.log_id.TOAU, xi.mission.id.toau.ETERNAL_MERCENARY)
        end
        finishSetup(player)
    end

    return jobs
end

local function buildMaintenanceJobs(player)
    local jobs = {}

    if (player:getCharVar('AutoMissions_Done') or 0) == 0 then
        player:setCharVar('AutoMissions_Done', 1)
        appendMissionJobs(jobs)
    end

    if (player:getCharVar('ToAUMissionFix') or 0) == 0 then
        player:setCharVar('ToAUMissionFix', 1)
        jobs[#jobs + 1] = function(p)
            if p:getCurrentMission(xi.mission.log_id.TOAU) <= xi.mission.id.toau.PRESIDENT_SALAHEEM then
                p:addMission(xi.mission.log_id.TOAU, xi.mission.id.toau.ETERNAL_MERCENARY)
            end
        end
    end

    if (player:getCharVar('MobSpellGrantFix') or 0) == 0 then
        player:setCharVar('MobSpellGrantFix', 1)
        jobs[#jobs + 1] = stripMobOnlySpells
    end

    if (player:getCharVar('TrustRosterFix') or 0) == 0 then
        player:setCharVar('TrustRosterFix', 1)
        jobs[#jobs + 1] = function(p)
            stripNonStarterTrusts(p)
            giveStarterTrusts(p)
        end
    end

    return jobs
end

-- Re-run the sliced grant. Jobs are idempotent (hasKeyItem / hasSpell /
-- already-complete quests). Used on first login, after a mid-setup zone,
-- and by !setup / !unlockfix. The player is Bound in place until
-- finishSetup. Hub / home / warp / waypoint / warpty also refuse
-- travel through travel_guard; !unstick does not.
xi.characterUpgrade.resume = function(player, opts)
    opts = opts or {}
    if not isValidPlayer(player) then
        return false
    end

    if not opts.force and xi.characterUpgrade.isComplete(player) then
        return false
    end

    if player:getLocalVar(RUNNING_VAR) == 1 then
        lockPlayer(player)
        return true
    end

    player:setLocalVar(RUNNING_VAR, 1)
    player:setCharVar(STARTED_VAR, 1)
    player:setCharVar('AutoMissions_Done', 1)
    player:setCharVar('ToAUMissionFix', 1)
    player:setCharVar('MobSpellGrantFix', 1)
    player:setCharVar('TrustRosterFix', 1)

    local delayMs = opts.delayMs or 3000
    if opts.force or (player:getCharVar(COMPLETE_VAR) or 0) == 1 then
        player:setCharVar(COMPLETE_VAR, 0)
    end

    if opts.silent then
        -- still start the work
    elseif (player:getCharVar(COMPLETE_VAR) or 0) == 0 and not opts.force and not opts.firstLogin then
        player:printToPlayer('Finishing your character setup -- you cannot move until Setup Complete, kupo!', 0, 'Unlocker')
    else
        player:printToPlayer('Setting up your new character -- you cannot move until Setup Complete, kupo!', 0, 'Unlocker')
    end

    lockPlayer(player)
    startJobs(player, delayMs, buildFirstLoginJobs())
    return true
end

xi.characterUpgrade.refuseTravel = function(player)
    if not player then
        return false
    end

    local running = player:getLocalVar(RUNNING_VAR) == 1
    local started = (player:getCharVar(STARTED_VAR) or 0) == 1
    local done    = xi.characterUpgrade.isComplete(player)
    if not running and not (started and not done) then
        return false
    end

    if not running then
        xi.characterUpgrade.resume(player, { delayMs = 500 })
    end

    player:printToPlayer('You cannot move until Setup Complete, kupo! Mounts and key items are still being granted.', 0, 'Unlocker')
    return true
end

-----------------------------------
-- Auto-grant at character creation. Work is sliced across ticks so the
-- 2s inactivity watchdog cannot kill xi_map mid-setup.
-- AutoUnlock_Done used to be set at the START, so zoning cancelled the
-- remaining KI/mount timers and never came back. Complete is now stamped
-- only in finishSetup; an interrupted grant resumes on the next login
-- or zone-in.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    local isLogin = player:getLocalVar('gameLogin') == 1
    super(player, firstLogin, zoning)

    if not xi.characterUpgrade.isComplete(player) then
        xi.characterUpgrade.resume(player, { firstLogin = firstLogin, delayMs = isLogin and 3000 or 500 })
        return
    end

    if isLogin then
        startJobs(player, 3000, buildMaintenanceJobs(player))
    end
end)

-----------------------------------
-- Withhold the paid custom trusts from the GM-only "!addalltrusts" command too
-- (it mirrors the old bulk grant). Wrap addallspells to strip the paid ids from
-- the forwarded list, run the stock command via super, then restore.
-----------------------------------
m:addOverride('xi.commands.addalltrusts.onTrigger', function(player, target)
    local addallspells = xi.commands.addallspells
    if not (addallspells and type(addallspells.onTrigger) == 'function') then
        return super(player, target)
    end

    local realOnTrigger = addallspells.onTrigger
    addallspells.onTrigger = function(p, t, spellList)
        if spellList then
            local filtered = {}
            for _, id in ipairs(spellList) do
                if id ~= SKOLL_SPELL and id ~= MEAT_SPELL and id ~= CORVUS_SPELL
                    and id ~= CORNELIA_SPELL and id ~= MATSUI_P_SPELL
                    and id ~= MATSUI_SEASONAL
                    and id ~= ALDO_SPELL and id ~= ALDO_UC_SPELL
                    and not spellGrant.mobOnlySpells[id] then
                    filtered[#filtered + 1] = id
                end
            end
            spellList = filtered
        end
        return realOnTrigger(p, t, spellList)
    end

    local ok, err = pcall(super, player, target)
    addallspells.onTrigger = realOnTrigger
    if not ok then
        error(err)
    end
end)

return m
