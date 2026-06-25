-----------------------------------
-- Character_Upgrader.lua
-- AUTO-GRANT at character creation: on a brand-new character's first login,
-- automatically grants weapon skills, spells, capped skills, trusts, all
-- quests/missions, maps, outpost warps, homepoints, survival guides, wardrobe
-- sizes, and automaton parts -- everything the old "Unlocker" GM-Home NPC used
-- to hand out on demand. The NPC is gone (owner request 2026-06-25); the grant
-- now runs once via xi.player.onGameIn (firstLogin), deferred a few seconds so
-- it doesn't hitch the zone-in. Paid Void Keeper trusts are still withheld.
-----------------------------------
require('modules/module_utils')

local m = Module:new('character_upgrader')

-- Skoll/Gemma (spell 901), Meat (899), Corvus (902), Aldo (930/1007) are PAID
-- custom trusts (Void Keeper, 50M gil each) sitting on real retail spell ids, so
-- they must be excluded from every bulk grant or they leak for free. Core enums
-- always resolve; the fallbacks cover module load order.
local SKOLL_SPELL   = (xi.magic and xi.magic.spell and xi.magic.spell.SKOLL) or 901
local MEAT_SPELL    = (xi.magic and xi.magic.spell and xi.magic.spell.EXCENMILLE) or 899
local CORVUS_SPELL  = (xi.magic and xi.magic.spell and xi.magic.spell.CURILLA) or 902
local ALDO_SPELL    = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO) or 930
local ALDO_UC_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO_UC) or 1007

local EXCLUDED_SPELLS = { [SKOLL_SPELL] = true, [MEAT_SPELL] = true, [CORVUS_SPELL] = true, [ALDO_SPELL] = true, [ALDO_UC_SPELL] = true }

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
    player:printToPlayer('All weapon skills granted, kupo!', 0, 'Unlocker')
end

local function giveAllSpells(player)
    for i = 1, 1024 do
        pcall(function()
            if not EXCLUDED_SPELLS[i] and not player:hasSpell(i) then
                player:addSpell(i)
            end
        end)
    end
    player:printToPlayer('All spells granted, kupo!', 0, 'Unlocker')
end

local function capAllSkills(player)
    player:capAllSkills()
    player:printToPlayer('All skills capped, kupo!', 0, 'Unlocker')
end

local function giveAllTrusts(player)
    local added = 0
    for i = 1, 10000 do
        pcall(function()
            if not EXCLUDED_SPELLS[i] then
                if player:addTrust(i) then added = added + 1 end
            end
        end)
    end
    player:printToPlayer(string.format('All trusts granted, kupo! Added: %d', added), 0, 'Unlocker')
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
    player:printToPlayer(string.format('All %d quests unlocked and completed, kupo!', count), 0, 'Unlocker')
end

local function giveAllMaps(player)
    local added = 0
    for name, kiId in pairs(xi.ki) do
        if string.sub(name, 1, 7) == 'MAP_OF_' and not player:hasKeyItem(kiId) then
            pcall(function()
                player:addKeyItem(kiId)
                added = added + 1
            end)
        end
    end
    player:printToPlayer(string.format('All maps granted, kupo! Added: %d', added), 0, 'Unlocker')
end

local function giveAllOutpostWarps(player)
    for _, nation in pairs({ xi.nation.SANDORIA, xi.nation.BASTOK, xi.nation.WINDURST }) do
        for region = xi.region.RONFAURE, xi.region.TAVNAZIANARCH do
            pcall(function() player:addTeleport(nation, region + 5) end)
        end
    end
    player:printToPlayer('All outpost warps granted, kupo!', 0, 'Unlocker')
end

local function giveAllHomepoints(player)
    for i = 0, 121 do
        local hpBit = i % 32
        local hpSet = math.floor(i / 32)
        pcall(function() player:addTeleport(xi.teleport.type.HOMEPOINT, hpBit, hpSet) end)
    end
    player:printToPlayer('All homepoints granted, kupo!', 0, 'Unlocker')
end

local function giveAllSurvivalGuides(player)
    for groupIndex = 0, 31 do
        for group = 0, 2 do
            pcall(function() player:addTeleport(xi.teleport.type.SURVIVAL, groupIndex, group) end)
        end
    end
    player:printToPlayer('All survival guides granted, kupo!', 0, 'Unlocker')
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
    player:printToPlayer(string.format('%d wardrobe(s) bumped to %d slots, kupo!', bumped, target), 0, 'Unlocker')
end

local function giveAllAttachments(player)
    for _, id in ipairs(AUTOMATON_PARTS) do
        pcall(function() player:unlockAttachment(id) end)
    end
    player:printToPlayer('All automaton frames, heads & attachments unlocked, kupo!', 0, 'Unlocker')
end

local function giveEverything(player)
    giveAllWeaponSkills(player)
    giveAllSpells(player)
    capAllSkills(player)
    giveAllTrusts(player)
    completeAllQuests(player)
    giveAllMaps(player)
    giveAllOutpostWarps(player)
    giveAllHomepoints(player)
    giveAllSurvivalGuides(player)
    bumpWardrobeSizes(player)
    giveAllAttachments(player)
    player:printToPlayer('Welcome! You\'ve been set up with everything, kupo!', 0, 'Unlocker')
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
                if id ~= SKOLL_SPELL and id ~= MEAT_SPELL and id ~= CORVUS_SPELL and id ~= ALDO_SPELL and id ~= ALDO_UC_SPELL then
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
