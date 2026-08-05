-----------------------------------
-- Character_Upgrader.lua
-- AUTO-GRANT at character creation: on a brand-new character's first login,
-- automatically grants weapon skills, spells (non-trust), capped skills, four
-- starter trusts, all quests/missions, maps, outpost warps, homepoints, survival guides, wardrobe
-- sizes, and automaton parts -- everything the old "Unlocker" GM-Home NPC used
-- to hand out on demand. The NPC is gone (owner request 2026-06-25); the grant
-- now runs once via xi.player.onGameIn (firstLogin), deferred a few seconds so
-- it doesn't hitch the zone-in. Paid Void Keeper trusts are still withheld.
-----------------------------------
require('modules/module_utils')

local m = Module:new('character_upgrader')
local spellGrant = require('modules/custom/lua/player_spell_grant_catalog')
local trustGrant = require('modules/custom/lua/trust_grant_catalog')

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
local MATSUI_P_SPELL  = (xi.trust and xi.trust.VOID_KEEPER_SPELL and xi.trust.VOID_KEEPER_SPELL.MATSUI_P) or 1003
local ALDO_SPELL      = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO) or 930
local ALDO_UC_SPELL   = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO_UC) or 1007

local EXCLUDED_SPELLS =
{
    [SKOLL_SPELL]    = true,
    [MEAT_SPELL]     = true,
    [CORVUS_SPELL]   = true,
    [CORNELIA_SPELL] = true,
    [MATSUI_P_SPELL] = true,
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
local function giveAllWeaponSkills(player)
    for i = 1, 256 do
        pcall(function() player:addWeaponSkill(i) end)
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

local function giveAllSpells(player)
    for i = 1, 1024 do
        pcall(function()
            if shouldGrantSpell(i) and not player:hasSpell(i) then
                player:addSpell(i, { silentLog = true })
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

local function completeAllMissions(player)
    -- San d'Oria (log_id 0)
    for i = 0, 23 do pcall(function() player:addMission(0, i) player:completeMission(0, i) end) end
    player:setRank(10)
    -- Bastok (log_id 1)
    for i = 0, 23 do pcall(function() player:addMission(1, i) player:completeMission(1, i) end) end
    -- Windurst (log_id 2)
    for i = 0, 23 do pcall(function() player:addMission(2, i) player:completeMission(2, i) end) end
    -- Rise of the Zilart (log_id 3) — final mission THE_LAST_VERSE = 31
    for i = 0, 31 do pcall(function() player:addMission(3, i) player:completeMission(3, i) end) end
    -- Chains of Promathia (log_id 6) — completeMission resets CoP current to 0; push current to
    -- THE_LAST_VERSE=850 instead so every earlier mission reads as complete.
    player:addMission(6, 850)
    -- Treasures of Aht Urhgan (log_id 4) — final = ETERNAL_MERCENARY = 47.
    -- Like CoP/SoA above, completeMission resets ToAU current to 0. That trips
    -- Rytaal's gate (getCurrentMission(TOAU) <= IMMORTAL_SENTRIES=1 -> "authorized
    -- mercenaries of level 50 or above" reject), locking Assault out entirely.
    -- Push current past PRESIDENT_SALAHEEM(2) so the mercenary content unlocks.
    for i = 0, 47 do pcall(function() player:addMission(4, i) player:completeMission(4, i) end) end
    player:addMission(4, 47)
    -- Wings of the Goddess (log_id 5)
    for i = 0, 53 do pcall(function() player:addMission(5, i) player:completeMission(5, i) end) end
    -- A Crystalline Prophecy (log_id 9) — final = A_CRYSTALLINE_PROPHECY_FIN = 11
    for i = 0, 11 do pcall(function() player:addMission(9, i) player:completeMission(9, i) end) end
    -- A Moogle Kupo d'Etat (log_id 10) — final = A_MOOGLE_KUPO_DETAT_FIN = 14
    for i = 0, 14 do pcall(function() player:addMission(10, i) player:completeMission(10, i) end) end
    -- A Shantotto Ascension (log_id 11) — final = A_SHANTOTTO_ASCENSION_FIN = 14
    for i = 0, 14 do pcall(function() player:addMission(11, i) player:completeMission(11, i) end) end
    -- The Voracious Resurgence (log_id 14) — final = EPILOGUE = 46
    for i = 0, 46 do pcall(function() player:addMission(14, i) player:completeMission(14, i) end) end
    -- Seekers of Adoulin (log_id 12) — ids >=64 need current pushed past the last (130)
    local missionSOA = {
        0,1,3,5,6,7,8,9,11,12,13,14,15,16,17,18,19,20,21,23,26,27,29,
        30,31,34,35,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,
        55,56,57,58,59,61,62,63,66,67,69,70,71,72,73,74,75,76,77,78,79,
        80,81,82,84,85,86,87,88,89,90,91,92,93,94,95,96,98,99,100,101,
        102,103,104,105,107,108,109,110,111,112,113,114,116,117,118,120,
        121,123,125,129,
    }
    for _, id in ipairs(missionSOA) do
        pcall(function() player:addMission(12, id) player:completeMission(12, id) end)
    end
    player:addMission(12, 130)
    -- Rhapsodies of Vana'diel (log_id 13) — same current-pointer fix; push to 227
    local missionROV = {
        0,2,3,4,6,10,12,18,20,22,26,28,30,32,34,36,40,42,44,46,48,50,
        52,54,56,60,62,64,66,68,70,72,78,80,83,86,92,94,96,98,100,102,
        103,104,106,108,110,114,116,118,120,122,124,126,130,132,136,142,
        144,146,150,152,154,155,156,158,160,161,162,164,166,170,172,174,
        178,180,184,188,190,192,194,196,198,200,202,206,210,212,216,218,
        220,222,224,226,
    }
    for _, id in ipairs(missionROV) do
        pcall(function() player:addMission(13, id) player:completeMission(13, id) end)
    end
    player:addMission(13, 227)
    -- Mirror the Mission Moogle charvar so it won't prompt existing chars who got this path
    player:setCharVar('MissionClearanceReceived', 1)
end

local function completeAllQuests(player)
    local count = 0
    for logId, areaKey in pairs(xi.quest.area) do
        if logId >= 0 then
            local areaQuests = xi.quest.id[areaKey]
            if areaQuests then
                for _, questId in pairs(areaQuests) do
                    pcall(function()
                        player:addQuest(logId, questId)
                        player:completeQuest(logId, questId)
                        count = count + 1
                    end)
                end
            end
        end
    end
end

local function giveAllKeyItems(player)
    for _, kiId in pairs(xi.ki) do
        if not player:hasKeyItem(kiId) then
            pcall(function() player:addKeyItem(kiId) end)
        end
    end
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

local function giveEverything(player)
    player:setLevelCap(99)
    player:printToPlayer('Level cap raised to 99, kupo!', 0, 'Unlocker')
    player:unlockJob(0)
    player:printToPlayer('Subjob unlocked, kupo!', 0, 'Unlocker')
    giveAllWeaponSkills(player)
    giveAllSpells(player)
    capAllSkills(player)
    giveStarterTrusts(player)
    completeAllQuests(player)
    completeAllMissions(player)
    giveAllKeyItems(player)
    giveAllOutpostWarps(player)
    giveAllHomepoints(player)
    giveAllSurvivalGuides(player)
    bumpWardrobeSizes(player)
    giveAllAttachments(player)
    local SYS = xi.msg.channel.SYSTEM_3
    player:printToPlayer('[ Setup Complete ]', SYS)
    player:printToPlayer('Spells, weapon skills & job abilities', SYS)
    player:printToPlayer('Starter trusts: Shantotto, Kupipi, Trion, Tenzen', SYS)
    player:printToPlayer('All quests & missions completed', SYS)
    player:printToPlayer('All key items, maps, homepoints, survival guides & outpost warps', SYS)
    player:printToPlayer('Full wardrobes & automaton parts', SYS)
    -- Starter accolades so new players can immediately try Unity Wanted Tier 1
    player:addCurrency('unity_accolades', 500)
    player:printToPlayer('Starter Unity Accolades granted (Unity Wanted Board in Library)', SYS)
    player:printToPlayer('Welcome! Type !help to get started.', SYS)
end

-----------------------------------
-- Auto-grant once, at character creation (first login). Deferred ~3s so the
-- heavy synchronous grant (all quests/spells/trusts) doesn't hitch the zone-in.
-- gameLogin==1 + firstLogin gates a real first login (see reference_ongamein_
-- login_detection); the charvar makes it idempotent.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    local isLogin = player:getLocalVar('gameLogin') == 1
    super(player, firstLogin, zoning)

    if isLogin and firstLogin and (player:getCharVar('AutoUnlock_Done') or 0) == 0 then
        player:setCharVar('AutoUnlock_Done', 1)
        player:printToPlayer('Setting up your new character -- one moment, kupo!', 0, 'Unlocker')
        player:timer(3000, function(p) giveEverything(p) end)
    elseif isLogin and (player:getCharVar('AutoMissions_Done') or 0) == 0 then
        -- Backfill missions for existing chars that were set up before missions were auto-granted.
        player:setCharVar('AutoMissions_Done', 1)
        player:timer(3000, function(p) completeAllMissions(p) end)
    end

    -- One-time ToAU current-mission backfill. Chars set up before the ToAU fix
    -- above were left at getCurrentMission(TOAU)=0, which locks them out of
    -- Assault (Rytaal's "authorized mercenaries" reject). Runs on any login,
    -- independent of AutoMissions_Done, so already-set-up chars self-heal.
    if isLogin and (player:getCharVar('ToAUMissionFix') or 0) == 0 then
        player:setCharVar('ToAUMissionFix', 1)
        if player:getCurrentMission(xi.mission.log_id.TOAU) <= xi.mission.id.toau.PRESIDENT_SALAHEEM then
            player:addMission(xi.mission.log_id.TOAU, xi.mission.id.toau.ETERNAL_MERCENARY)
        end
    end

    -- One-time strip of mob-only spells wrongly bulk-granted before the filter.
    if isLogin and (player:getCharVar('MobSpellGrantFix') or 0) == 0 then
        player:setCharVar('MobSpellGrantFix', 1)
        player:timer(4000, function(p) stripMobOnlySpells(p) end)
    end

    -- One-time strip of bulk-granted trusts (old giveAllTrusts + spell loop).
    if isLogin and (player:getCharVar('TrustRosterFix') or 0) == 0 then
        player:setCharVar('TrustRosterFix', 1)
        player:timer(4500, function(p)
            stripNonStarterTrusts(p)
            giveStarterTrusts(p)
        end)
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
