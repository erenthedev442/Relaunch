-----------------------------------
-- Assault 51 : Nyzul Isle Investigation
-----------------------------------
local ID = zones[xi.zone.NYZUL_ISLE]
-----------------------------------
local instanceObject = {}

local timeWarningMilestones =
{
    25 * 60,
    20 * 60,
    15 * 60,
    10 * 60,
     5 * 60,
     1 * 60,
    30,
}

local function sendSystemTimeWarnings(instance, elapsed)
    local remaining = math.max(0, math.floor(instance:getTimeLimit() * 60 - elapsed / 1000))
    local previous  = instance:getLocalVar('Nyzul_PreviousRemainingSeconds')
    instance:setLocalVar('Nyzul_RemainingSeconds', remaining)

    if instance:getLocalVar('Nyzul_RefreshCountdown') == 1 then
        for _, player in pairs(instance:getChars()) do
            player:countdown(remaining)
        end

        instance:setLocalVar('Nyzul_RefreshCountdown', 0)
    end

    -- Detect threshold crossings rather than backfilling every milestone below
    -- the current time. If a penalty or lag crosses more than one at once, mark
    -- all crossed thresholds consumed and announce only the most urgent one.
    local warning
    if previous > 0 then
        for _, seconds in ipairs(timeWarningMilestones) do
            local warningVar = string.format('Nyzul_TimeWarning_%d', seconds)
            if
                previous > seconds and
                remaining <= seconds and
                instance:getLocalVar(warningVar) == 0
            then
                instance:setLocalVar(warningVar, 1)
                warning = seconds
            end
        end
    end

    if warning then
        local message
        if warning == 60 then
            message = '[Nyzul] Time remaining: 1 minute.'
        elseif warning > 60 then
            message = string.format('[Nyzul] Time remaining: %d minutes.', warning / 60)
        else
            message = string.format('[Nyzul] Time remaining: %d seconds.', warning)
        end

        for _, player in pairs(instance:getChars()) do
            player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
        end
    end

    instance:setLocalVar('Nyzul_PreviousRemainingSeconds', remaining)
end

local function pickSetPoint(instance)
    local chars        = instance:getChars()
    local currentFloor = instance:getLocalVar('Nyzul_Current_Floor')

    -- Random the floor layout
    instance:setLocalVar('Nyzul_Isle_FloorLayout', math.random(1, #xi.nyzul.FloorLayout))
    instance:setLocalVar('gearObjective', 0)

    -- Condition for floors
    -- hard set objective and floor to boss stage for every 20th floor
    if currentFloor % 20 == 0 then
        instance:setStage(xi.nyzul.objective.ELIMINATE_ENEMY_LEADER)
        instance:setLocalVar('Nyzul_Isle_FloorLayout', 0)
    -- 3.33% for a free floor
    elseif math.random(1, 30) == 1 and instance:getLocalVar('freeFloor') == 0 then -- 3.33% for a free floor
        instance:setStage(xi.nyzul.objective.FREE_FLOOR)
        instance:setLocalVar('freeFloor', 1)

        GetNPCByID(ID.npc.RUNE_OF_TRANSFER_ENTRANCE, instance):timer(9000,
        function(m)
            local currentInstance = m:getInstance()
            currentInstance:setProgress(15)
        end) -- Completes objective for free floor
    else
        -- All retail objective categories remain available. Relaunch replaces
        -- the party-only lamp variants with a solo-friendly scavenger floor.
        local objective = {}

        for i = xi.nyzul.objective.ELIMINATE_ENEMY_LEADER, xi.nyzul.objective.ELIMINATE_ALL_ENEMIES do
            table.insert(objective, i)
        end

        -- Don't repeat the previous floor's objective (skip in the staging room
        -- or right after a free floor).
        local prevStage = instance:getStage()
        if prevStage ~= 0 and prevStage ~= xi.nyzul.objective.FREE_FLOOR then
            for idx, obj in ipairs(objective) do
                if obj == prevStage then
                    table.remove(objective, idx)
                    break
                end
            end
        end

        -- Randomly pick the objective from the generated list
        instance:setStage(utils.randomEntry(objective))

        if
            instance:getStage() ~= xi.nyzul.objective.ACTIVATE_ALL_LAMPS and
            math.random(1, 30) <= 5
        then
            instance:setLocalVar('gearObjective', math.random(xi.nyzul.gearObjective.AVOID_AGRO, xi.nyzul.gearObjective.DO_NOT_DESTROY))
        end
    end

    -- Setup points to travel to
    local layoutPoint = xi.nyzul.FloorLayout[instance:getLocalVar('Nyzul_Isle_FloorLayout')]
    local posX        = layoutPoint[1] local posY = layoutPoint[2] local posZ = layoutPoint[3]

    -- Set Rune of Transfer to Point
    for npcID = ID.npc.RUNE_OF_TRANSFER_OFFSET, ID.npc.RUNE_OF_TRANSFER_OFFSET + 1 do
        local runeOfTransfer = GetNPCByID(npcID, instance)

        if
            runeOfTransfer and
            runeOfTransfer:getStatus() == xi.status.DISAPPEAR
        then
            runeOfTransfer:setAnimationSub(0)
            runeOfTransfer:setPos(posX, posY, posZ)
            runeOfTransfer:setStatus(xi.status.NORMAL)

            break
        end
    end

    -- Set players to Point and messaging
    for _, players in pairs(chars) do
        players:setPos(posX, posY, posZ)
        players:messageName(ID.text.WELCOME_TO_FLOOR, players, currentFloor, currentFloor)
        players:printToPlayer(
            string.format(
                '[Nyzul] Floor %d objective: %s',
                currentFloor,
                xi.nyzul.getObjectiveText(instance)),
            xi.msg.channel.SYSTEM_3)

        if instance:getStage() ~= xi.nyzul.objective.FREE_FLOOR then
            players:messageName(ID.text.OBJECTIVE_TEXT_OFFSET + instance:getStage(), players)

            local gearObjective = instance:getLocalVar('gearObjective')

            if gearObjective > 0 then
                players:messageSpecial(ID.text.ELIMINATE_ALL_ENEMIES + gearObjective)
                local restriction = gearObjective == xi.nyzul.gearObjective.AVOID_AGRO
                    and 'Avoid discovery by archaic gears.'
                    or  'Do not destroy archaic gears.'
                players:printToPlayer(
                    '[Nyzul] Additional restriction: ' .. restriction,
                    xi.msg.channel.SYSTEM_3)
            end
        end
    end

    -- Set Rune of Transfer Menu
    instance:setLocalVar('menuChoice', math.random(1, 20))
end

-- Requirements for the first player registering the instance
instanceObject.registryRequirements = function(player)
    return player:hasKeyItem(xi.ki.NYZUL_ISLE_ASSAULT_ORDERS)
end

-- Requirements for further players entering an already-registered instance
instanceObject.entryRequirements = function(player)
    return player:hasKeyItem(xi.ki.NYZUL_ISLE_ASSAULT_ORDERS)
end

-- Called on the instance once it is created and ready
instanceObject.onInstanceCreated = function(instance)
end

-- Once the instance is ready inform the requester that it's ready
instanceObject.onInstanceCreatedCallback = function(player, instance)
    xi.instance.onInstanceCreatedCallback(player, instance)

    -- Kill the Nyzul Isle update spam
    for _, v in ipairs(player:getParty()) do
        if v:getZoneID() == instance:getEntranceZoneID() then
            v:updateEvent(405, 3, 3, 3, 3, 3, 3, 3)
        end
    end
end

-- When the player zones into the instance
instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()

    player:messageName(ID.text.COMMENCE, player, 51)
    player:messageName(ID.text.TIME_TO_COMPLETE, player, instance:getTimeLimit())
    local remaining = instance:getLocalVar('Nyzul_RemainingSeconds')
    if remaining <= 0 then
        remaining = instance:getTimeLimit() * 60
        instance:setLocalVar('Nyzul_RefreshCountdown', 1)
    end

    player:countdown(remaining)
    player:printToPlayer(
        string.format('[Nyzul] Visible countdown started: %d seconds remaining.', remaining),
        xi.msg.channel.SYSTEM_3)

    player:addTempItem(xi.item.UNDERSEA_RUINS_FIREFLIES)
    player:setCharVar('assaultEntered', 1)
    if player:hasKeyItem(xi.ki.NYZUL_ISLE_ASSAULT_ORDERS) then
        player:delKeyItem(xi.ki.NYZUL_ISLE_ASSAULT_ORDERS)
        player:messageSpecial(ID.text.KEYITEM_LOST, xi.ki.NYZUL_ISLE_ASSAULT_ORDERS)
    end
end

-- Instance 'tick'
instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
    sendSystemTimeWarnings(instance, elapsed)
    xi.instance.updateInstanceTime(instance, elapsed, ID.text)
end

-- On fail
instanceObject.onInstanceFailure = function(instance)
    local chars = instance:getChars()

    for _, players in ipairs(chars) do
        players:messageSpecial(ID.text.MISSION_FAILED, 10, 10)
        players:startCutscene(1)
    end
end

-- When something in the instance calls: instance:setProgress(...)
instanceObject.onInstanceProgressUpdate = function(instance, progress)
    if progress > 0 then
        if xi.nyzul.handleProgress(instance, progress) then
            xi.nyzul.activateRuneOfTransfer(instance)
        end
    end
end

-- On win
instanceObject.onInstanceComplete = function(instance)
end

-- Standard event hooks, these will take priority over everything apart from m_event.Script
-- Omitting this will fallthrough to the same calls in the Zone.lua
instanceObject.onEventUpdate = function(player, csid, option, npc)
    if csid == 95 then
        local instance = player:getInstance()

        if instance:getLocalVar('runeHandler') == player:getID() then
            pickSetPoint(instance)
        end
    end
end

instanceObject.onEventFinish = function(player, csid, option, npc)
    local instance = player:getInstance()
    local chars    = instance:getChars()

    if csid == 1 then
        for _, players in ipairs(chars) do
            -- RELAUNCH: return to the Mhaura hub (Sorrowful Sage). Retail dumps
            -- players in Alzadaal Undersea Ruins (72), which is ToAU-locked and
            -- unreachable without the Runic Portal -- it would strand them.
            players:setPos(-25.0, -15.99, 52.5, 100, xi.zone.MHAURA)
        end
    elseif csid == 95 then
        if instance:getLocalVar('runeHandler') == player:getID() then
            xi.nyzul.prepareMobs(instance)
            xi.nyzul.removePathos(instance)
            xi.nyzul.addFloorPathos(instance)
            instance:setLocalVar('runeHandler', 0)
        end
    end
end

return instanceObject
