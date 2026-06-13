-----------------------------------
-- weekly_recap.lua
-- On the first login of each ISO week, sends the player a brief
-- summary of their current weekly objective status so they always
-- know what's left to do without having to type a command.
--
-- "First login of the week" is detected via CharVar Recap_Week:
--   if Recap_Week < current ISO-week index -> show recap, update var.
--
-- ISO week index: math.floor(os.time() / 604800)
-- Shown 5 seconds after login so it doesn't collide with MOTD,
-- login bonus, and streak messages.
-----------------------------------
require('modules/module_utils')

local m = Module:new('weekly_recap')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

-- Days until next Monday 00:00 UTC.  Returns 7 when already Monday
-- so the value is always a full remaining week (not "0 days").
local function daysToMonday(now)
    local weekday = tonumber(os.date('!%w', now)) or 0
    if weekday == 1 then return 7 end
    return (8 - weekday) % 7
end

m:addOverride('xi.player.onGameIn', function(player, isZoning)
    super(player, isZoning)
    if isZoning then return end

    local now     = os.time()
    local weekIdx = math.floor(now / 604800)
    local lastWeek = player:getCharVar('Recap_Week') or -1

    -- Already shown a recap this week.
    if lastWeek >= weekIdx then return end
    player:setCharVar('Recap_Week', weekIdx)

    -- Delay so login bonuses + MOTD fire first.
    player:timer(5000, function(p)
        local catalog        = require('modules/custom/lua/hunting_league_catalog')
        local dungeonCatalog = require('modules/custom/lua/dungeon_catalog')

        -- Weekly Hunts progress
        local whWeek     = p:getCharVar('WH_Week') or -1
        local huntsTotal = 5
        local huntsDone  = 0
        if whWeek == weekIdx then
            for i = 1, huntsTotal do
                if (p:getCharVar('WH_S' .. i .. '_Done') or 0) ~= 0 then
                    huntsDone = huntsDone + 1
                end
            end
        end

        -- Featured NMs killed this week
        local featTotal = #catalog.tiers
        local featDone  = 0
        for _, tierDef in ipairs(catalog.tiers) do
            local tierMobs = tierDef.mobs
            local featIdx  = (weekIdx % #tierMobs) + 1
            local featMob  = tierMobs[featIdx]
            if featMob then
                local wv = string.format('HL_Featured_%d_%d', weekIdx, featMob.groupId)
                if (p:getCharVar(wv) or 0) ~= 0 then
                    featDone = featDone + 1
                end
            end
        end

        -- Bonus dungeon status
        local bonusLabel = 'N/A'
        local bonusDone  = false
        local enabled    = {}
        for _, d in ipairs(dungeonCatalog.dungeons or {}) do
            if not d._disabled then table.insert(enabled, d) end
        end
        if #enabled > 0 then
            local bd    = enabled[(weekIdx % #enabled) + 1]
            bonusLabel  = bd.label
            local bcv   = string.format('DB_Bonus_%d_%s', weekIdx, bd.id)
            bonusDone   = (p:getCharVar(bcv) or 0) == 1
        end

        local resetIn = daysToMonday(now)

        p:printToPlayer('[Weekly Reset] == New Week, New Objectives! ==========', H)
        p:printToPlayer(
            string.format('  Resets in %d day(s)  (Monday 00:00 UTC)', resetIn), B)
        p:printToPlayer(
            string.format('  Weekly Hunts:    %d / %d  (!featured to see which NMs)', huntsDone, huntsTotal), B)
        p:printToPlayer(
            string.format('  Featured NMs:    %d / %d killed this week', featDone, featTotal), B)
        p:printToPlayer(
            string.format('  Bonus Dungeon:   %s  [%s]  (!bonus_dungeon for details)',
                bonusLabel, bonusDone and 'DONE!' or 'not cleared'),
            B)
        p:printToPlayer('  Good luck out there, hunter!  !help - command list', B)
    end)
end)

return m
