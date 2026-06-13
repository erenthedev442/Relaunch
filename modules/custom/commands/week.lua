-----------------------------------
-- func: week
-- desc: Shows the player's current weekly objectives at a glance:
--       Weekly Hunt Board progress, featured NMs killed, and bonus
--       dungeon status.  Resets each Monday 00:00 UTC.
--
-- Usage: !week
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local catalog        = require('modules/custom/lua/hunting_league_catalog')
local dungeonCatalog = require('modules/custom/lua/dungeon_catalog')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_3

-- Returns the number of days until the next Monday 00:00 UTC.
-- os.date '!%w': 0=Sun, 1=Mon ... 6=Sat.
local function daysToMonday(now)
    local weekday = tonumber(os.date('!%w', now)) or 0
    if weekday == 1 then
        -- Already Monday: count to NEXT Monday so the number is never 0.
        return 7
    end
    return (8 - weekday) % 7
end

commandObj.onTrigger = function(player)
    local now     = os.time()
    local weekIdx = math.floor(now / 604800)
    local resetIn = daysToMonday(now)

    -- == Weekly Hunt Board ==========================================
    -- CharVars: WH_Week (week index when board was assigned),
    --           WH_S1_Done ... WH_S5_Done (slot completion flags).
    local whWeek     = player:getCharVar('WH_Week') or -1
    local huntsTotal = 5
    local huntsDone  = 0
    if whWeek == weekIdx then
        for i = 1, huntsTotal do
            if (player:getCharVar('WH_S' .. i .. '_Done') or 0) ~= 0 then
                huntsDone = huntsDone + 1
            end
        end
    end

    -- == Featured NMs killed this week =============================
    -- One NM per tier rotates deterministically by weekIdx.
    -- CharVar: HL_Featured_<weekIdx>_<groupId> = 1 when earned.
    local featTotal = #catalog.tiers
    local featDone  = 0
    for _, tierDef in ipairs(catalog.tiers) do
        local tierMobs = tierDef.mobs
        local featIdx  = (weekIdx % #tierMobs) + 1
        local featMob  = tierMobs[featIdx]
        if featMob then
            local weekVar = string.format('HL_Featured_%d_%d', weekIdx, featMob.groupId)
            if (player:getCharVar(weekVar) or 0) ~= 0 then
                featDone = featDone + 1
            end
        end
    end

    -- == Weekly Bonus Dungeon =======================================
    -- One dungeon per week earns 2x Infamy on first clear.
    -- CharVar: DB_Bonus_<weekIdx>_<dungeonId> = 1 when earned.
    local bonusDungeonName = nil
    local bonusDungeonDone = false
    local enabledDungeons  = {}
    for _, d in ipairs(dungeonCatalog.dungeons or {}) do
        -- Skip dungeons explicitly disabled (uses a flag set by DungeonSystem
        -- at load time; the flag may not be present when loaded from here,
        -- but any dungeon that never gets _disabled stays in the list).
        if not d._disabled then
            table.insert(enabledDungeons, d)
        end
    end
    if #enabledDungeons > 0 then
        local bd      = enabledDungeons[(weekIdx % #enabledDungeons) + 1]
        bonusDungeonName = bd.label
        local bonusCv = string.format('DB_Bonus_%d_%s', weekIdx, bd.id)
        bonusDungeonDone = (player:getCharVar(bonusCv) or 0) == 1
    end

    -- == Output ====================================================
    player:printToPlayer('[Weekly] == This Week\'s Objectives ==================', H)
    player:printToPlayer(
        string.format('  Reset in:        %d day(s)  (Monday 00:00 UTC)', resetIn), B)
    player:printToPlayer(
        string.format('  Weekly Hunts:    %d / %d complete', huntsDone, huntsTotal), B)
    player:printToPlayer(
        string.format('  Featured NMs:    %d / %d killed this week', featDone, featTotal), B)

    if bonusDungeonName then
        player:printToPlayer(
            string.format('  Bonus Dungeon:   %s  [%s]',
                bonusDungeonName, bonusDungeonDone and 'DONE!' or 'not cleared'),
            B)
    else
        player:printToPlayer('  Bonus Dungeon:   None available', B)
    end

    player:printToPlayer('  !featured - this week\'s NMs  |  !bonus_dungeon - bonus dungeon', B)
end

return commandObj
