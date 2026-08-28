-----------------------------------
-- Nyzul Isle Global
-----------------------------------
local ID = zones[xi.zone.NYZUL_ISLE]
-----------------------------------
xi = xi or {}
xi.nyzul = xi.nyzul or {}

-- Item IDs kept for later DAT reuse. Drops are retired; see vigilWeaponDrop.
xi.nyzul.baseWeapons =
{
    [xi.job.WAR] = xi.item.STURDY_AXE,
    [xi.job.MNK] = xi.item.BURNING_FISTS,
    [xi.job.WHM] = xi.item.WEREBUSTER,
    [xi.job.BLM] = xi.item.MAGES_STAFF,
    [xi.job.RDM] = xi.item.VORPAL_SWORD,
    [xi.job.THF] = xi.item.SWORDBREAKER,
    [xi.job.PLD] = xi.item.BRAVE_BLADE,
    [xi.job.DRK] = xi.item.DEATH_SICKLE,
    [xi.job.BST] = xi.item.DOUBLE_AXE,
    [xi.job.BRD] = xi.item.DANCING_DAGGER,
    [xi.job.RNG] = xi.item.KILLER_BOW,
    [xi.job.SAM] = xi.item.WINDSLICER,
    [xi.job.NIN] = xi.item.SASUKE_KATANA,
    [xi.job.DRG] = xi.item.RADIANT_LANCE,
    [xi.job.SMN] = xi.item.SCEPTER_STAFF,
    [xi.job.BLU] = xi.item.WIGHTSLAYER,
    [xi.job.COR] = xi.item.QUICKSILVER,
    [xi.job.PUP] = xi.item.INFERNO_CLAWS,
    [xi.job.DNC] = xi.item.MAIN_GAUCHE,
    [xi.job.SCH] = xi.item.ELDER_STAFF,
}

xi.nyzul.objective =
{
    ELIMINATE_ENEMY_LEADER      = 1,
    ELIMINATE_SPECIFIED_ENEMIES = 2,
    ACTIVATE_ALL_LAMPS          = 3,
    ELIMINATE_SPECIFIED_ENEMY   = 4,
    ELIMINATE_ALL_ENEMIES       = 5,
    FREE_FLOOR                  = 6,
}

xi.nyzul.lampsObjective =
{
    REGISTER     = 1,
    ACTIVATE_ALL = 2,
    ORDER        = 3,
    SCAVENGER    = 4, -- Relaunch: find and light every lamp before the floor timer expires.
}

xi.nyzul.scavengerLampCount      = 5
xi.nyzul.scavengerLampTimeMs     = 120000
xi.nyzul.scavengerLampPenaltyMin = 1

xi.nyzul.gearObjective =
{
    AVOID_AGRO     = 1,
    DO_NOT_DESTROY = 2,
}

xi.nyzul.penalty =
{
    TIME   = 1,
    TOKENS = 2,
    PATHOS = 3,
}

local objectiveText =
{
    [xi.nyzul.objective.ELIMINATE_ENEMY_LEADER]      = 'Find and eliminate the enemy leader.',
    [xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMIES] = 'Eliminate all specified enemies.',
    [xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMY]   = 'Eliminate the target that checks as Impossible to Gauge.',
    [xi.nyzul.objective.ELIMINATE_ALL_ENEMIES]       = 'Eliminate every enemy on the floor.',
    [xi.nyzul.objective.FREE_FLOOR]                  = 'Free floor. Proceed to the Rune of Transfer.',
}

xi.nyzul.getObjectiveText = function(instance)
    if instance:getStage() == xi.nyzul.objective.ACTIVATE_ALL_LAMPS then
        return string.format(
            'Find and light all %d runic lamps within %d minutes.',
            xi.nyzul.scavengerLampCount,
            xi.nyzul.scavengerLampTimeMs / 60000)
    end

    return objectiveText[instance:getStage()] or 'Complete the displayed floor objective.'
end

xi.nyzul.FloorLayout =
{
    [ 0] = {   -20, -0.5, -380 }, -- boss floors 20, 40, 60, 80
--  [ ?] = {  -491, -4.0, -500 }, -- boss floor 20 confirmed
    [ 1] = {   380, -0.5, -500 },
    [ 2] = {   500, -0.5,  -20 },
    [ 3] = {   500, -0.5,   60 },
    [ 4] = {   500, -0.5, -100 },
    [ 5] = {   540, -0.5, -140 },
    [ 6] = {   460, -0.5, -219 },
    [ 7] = {   420, -0.5,  500 },
    [ 8] = {    60, -0.5, -335 },
    [ 9] = {    20, -0.5, -500 },
    [10] = {   -95, -0.5,   60 },
    [11] = {   100, -0.5,  100 },
    [12] = {  -460, -4.0, -180 },
    [13] = {  -304, -0.5, -380 },
    [14] = {  -380, -0.5, -500 },
    [15] = {  -459, -4.0, -540 },
    [16] = {  -465, -4.0, -340 },
    [17] = { 504.5,  0.0,  -60 },
--  [18] = {   580,  0.0,  340 },
--  [19] = {   455,  0.0, -140 },
--  [20] = {   500,  0.0,   20 },
--  [21] = {   500,    0,  380 },
--  [22] = {   460,    0,  100 },
--  [23] = {   100,    0, -380 },
--  [24] = { -64.5,    0,   60 },
}

xi.nyzul.floorCost =
{
    [ 1] = { level =  1, cost =    0 },
    [ 2] = { level =  6, cost =  500 },
    [ 3] = { level = 11, cost =  550 },
    [ 4] = { level = 16, cost =  600 },
    [ 5] = { level = 21, cost =  650 },
    [ 6] = { level = 26, cost =  700 },
    [ 7] = { level = 31, cost =  750 },
    [ 8] = { level = 36, cost =  800 },
    [ 9] = { level = 41, cost =  850 },
    [10] = { level = 46, cost =  900 },
    [11] = { level = 51, cost = 1000 },
    [12] = { level = 56, cost = 1100 },
    [13] = { level = 61, cost = 1200 },
    [14] = { level = 66, cost = 1300 },
    [15] = { level = 71, cost = 1400 },
    [16] = { level = 76, cost = 1500 },
    [17] = { level = 81, cost = 1600 },
    [18] = { level = 86, cost = 1700 },
    [19] = { level = 91, cost = 1800 },
    [20] = { level = 96, cost = 1900 },
}

-- Local functions
local function getTokenRate(instance)
    local partySize = instance:getLocalVar('partySize')
    local rate      = 1

    if partySize > 3 then
        rate = rate - (partySize - 3) * 0.1
    end

    return rate
end

local function calculateTokens(instance)
    local relativeFloor   = xi.nyzul.getRelativeFloor(instance)
    local rate            = getTokenRate(instance)
    local potentialTokens = instance:getLocalVar('potential_tokens')
    local floorBonus      = 0

    if relativeFloor > 1 then
        floorBonus = 10 * math.floor((relativeFloor - 1) / 5)
    end

    potentialTokens = math.floor(potentialTokens + (200 + floorBonus) * rate)

    return potentialTokens
end

-- Global functions
xi.nyzul.getRelativeFloor = function(instance)
    local currentFloor  = instance:getLocalVar('Nyzul_Current_Floor')
    local startingFloor = instance:getLocalVar('Nyzul_Isle_StartingFloor')

    if currentFloor < startingFloor then
        return currentFloor + 100
    end

    return currentFloor
end

xi.nyzul.clearChests = function(instance)
    for cofferID = ID.npc.TREASURE_COFFER_OFFSET, ID.npc.TREASURE_COFFER_OFFSET + 2 do
        local coffer = GetNPCByID(cofferID, instance)

        if coffer and coffer:getStatus() ~= xi.status.DISAPPEAR then
            coffer:setStatus(xi.status.DISAPPEAR)
            coffer:setAnimationSub(0)
            coffer:resetLocalVars()
        end
    end

    if xi.settings.main.ENABLE_NYZUL_CASKETS then
        for casketID = ID.npc.TREASURE_CASKET_OFFSET, ID.npc.TREASURE_CASKET_OFFSET + 3 do
            local casket = GetNPCByID(casketID, instance)

            if casket and casket:getStatus() ~= xi.status.DISAPPEAR then
                casket:setStatus(xi.status.DISAPPEAR)
                casket:setAnimationSub(0)
                casket:resetLocalVars()
            end
        end
    end
end

xi.nyzul.handleRunicKey = function(mob)
    local instance = mob:getInstance()

    if instance:getLocalVar('Nyzul_Current_Floor') == 100 then
        local diskHolder = GetPlayerByID(instance:getLocalVar('diskHolder'))
        local startFloor = instance:getLocalVar('Nyzul_Isle_StartingFloor')

        -- Relaunch Mythic progression is personal. Only the player whose Runic
        -- Disc selected this climb records floor 100; party members may help,
        -- but cannot receive five simultaneous trial completions on one clear.
        if
            diskHolder and
            diskHolder:getInstance() == instance and
            diskHolder:hasKeyItem(xi.ki.RUNIC_DISC) and
            diskHolder:getCharVar('NyzulFloorProgress') + 1 >= startFloor
        then
            diskHolder:setCharVar('NyzulFloorProgress', 100)
            diskHolder:setCharVar('Nyzul_F100_Cleared', 1)

            if not diskHolder:hasKeyItem(xi.ki.RUNIC_KEY) then
                npcUtil.giveKeyItem(diskHolder, xi.ki.RUNIC_KEY)
            end
        end
    end
end

xi.nyzul.handleProgress = function(instance, progress)
    local stage      = instance:getStage()
    local isComplete = false

    if
        ((stage == xi.nyzul.objective.FREE_FLOOR or
        stage == xi.nyzul.objective.ELIMINATE_ENEMY_LEADER or
        stage == xi.nyzul.objective.ACTIVATE_ALL_LAMPS or
        stage == xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMY) and
        progress == 15)
        or
        ((stage == xi.nyzul.objective.ELIMINATE_ALL_ENEMIES or stage == xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMIES) and
        progress >= instance:getLocalVar('Eliminate'))
    then
        local chars        = instance:getChars()
        local currentFloor = instance:getLocalVar('Nyzul_Current_Floor')

        instance:setProgress(0)
        instance:setLocalVar('Eliminate', 0)
        instance:setLocalVar('potential_tokens', calculateTokens(instance))

        for _, players in ipairs(chars) do
            players:messageSpecial(ID.text.OBJECTIVE_COMPLETE, currentFloor)
            players:printToPlayer(
                string.format(
                    '[Nyzul] Floor %d objective complete. Rune of Transfer activated.',
                    currentFloor),
                xi.msg.channel.SYSTEM_3)
        end

        isComplete = true
    end

    return isComplete
end

-- onMobDeath is dispatched once per eligible participant. Claim objective
-- credit once per mob per floor, regardless of whether the killing blow came
-- from a player, Trust, Fellow, pet, or another party-controlled entity.
xi.nyzul.claimDeathCredit = function(mob)
    local instance = mob and mob:getInstance()
    if not instance then
        return false
    end

    local currentFloor = instance:getLocalVar('Nyzul_Current_Floor')
    if mob:getLocalVar('NyzulDeathCreditFloor') == currentFloor then
        return false
    end

    mob:setLocalVar('NyzulDeathCreditFloor', currentFloor)
    return true
end

xi.nyzul.enemyLeaderKill = function(mob)
    if not xi.nyzul.claimDeathCredit(mob) then
        return
    end

    local instance = mob:getInstance()
    instance:setProgress(15)
end

xi.nyzul.specifiedGroupKill = function(mob)
    if not xi.nyzul.claimDeathCredit(mob) then
        return
    end

    local instance = mob:getInstance()

    if instance:getStage() == xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMIES then
        instance:setProgress(instance:getProgress() + 1)
    end
end

xi.nyzul.specifiedEnemySet = function(mob)
    local instance = mob:getInstance()

    if instance:getStage() == xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMY then
        if instance:getLocalVar('Nyzul_Specified_Enemy') == 0 then
            mob:setMobMod(xi.mobMod.CHECK_AS_NM, 1)
        end
    end
end

xi.nyzul.specifiedEnemyKill = function(mob)
    if not xi.nyzul.claimDeathCredit(mob) then
        return
    end

    local instance = mob:getInstance()
    local stage    = instance:getStage()

    -- Eliminate specified enemy
    if stage == xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMY then
        if instance:getLocalVar('Nyzul_Specified_Enemy') == mob:getID() then
            instance:setProgress(15)
            instance:setLocalVar('Nyzul_Specified_Enemy', 0)
        end

    -- Eliminiate all enemies
    elseif stage == xi.nyzul.objective.ELIMINATE_ALL_ENEMIES then
        instance:setProgress(instance:getProgress() + 1)
    end
end

xi.nyzul.eliminateAllKill = function(mob)
    if not xi.nyzul.claimDeathCredit(mob) then
        return
    end

    local instance = mob:getInstance()

    if instance:getStage() == xi.nyzul.objective.ELIMINATE_ALL_ENEMIES then
        instance:setProgress(instance:getProgress() + 1)
    end
end

xi.nyzul.activateRuneOfTransfer = function(instance)
    for runeID = ID.npc.RUNE_OF_TRANSFER_OFFSET, ID.npc.RUNE_OF_TRANSFER_OFFSET + 1 do
        if GetNPCByID(runeID, instance):getStatus() == xi.status.NORMAL then
            GetNPCByID(runeID, instance):setAnimationSub(1)

            break
        end
    end
end

xi.nyzul.vigilWeaponDrop = function(player, mob)
    -- Retired. Vigil weapons are not used by the live Mythic path, and the
    -- item IDs are reserved for later DAT reuse. Floor 100 still grants the
    -- Runic Key / disc progress through the existing Nyzul reward flow.
    return
end

xi.nyzul.spawnChest = function(mob, player)
    local instance = mob:getInstance()
    local mobID    = mob:getID()

    -- NM chest spawn.
    if
        mobID >= ID.mob.NM_OFFSET and
        mobID <= ID.mob.TAISAIJIN
    then
        xi.nyzul.vigilWeaponDrop(player, mob)

    for cofferID = ID.npc.TREASURE_COFFER_OFFSET, ID.npc.TREASURE_COFFER_OFFSET + 2 do
            local coffer = GetNPCByID(cofferID, instance)

            if coffer and coffer:getStatus() == xi.status.DISAPPEAR then
                local pos = mob:getPos()
                coffer:setUntargetable(false)
                coffer:setPos(pos.x, pos.y, pos.z, pos.rot)
                coffer:setLocalVar('appraisalItem', mobID)
                coffer:setStatus(xi.status.NORMAL)

                break
            end
        end

    -- NM casket spawn.
    elseif
        mobID < ID.mob.BOSS_OFFSET and
        xi.settings.main.ENABLE_NYZUL_CASKETS
    then
        if math.random(1, 100) <= 6 then
            for casketID = ID.npc.TREASURE_CASKET_OFFSET, ID.npc.TREASURE_CASKET_OFFSET + 3 do
                local casket = GetNPCByID(casketID, instance)

                if casket and casket:getStatus() == xi.status.DISAPPEAR then
                    local pos = mob:getPos()
                    casket:setPos(pos.x, pos.y, pos.z, pos.rot)
                    casket:setStatus(xi.status.NORMAL)

                    break
                end
            end
        end
    end
end

xi.nyzul.getTokenPenalty = function(instance)
    local floorPenalities = instance:getLocalVar('tokenPenalty')
    local rate            = getTokenRate(instance)

    return math.floor(117 * rate * floorPenalities)
end
