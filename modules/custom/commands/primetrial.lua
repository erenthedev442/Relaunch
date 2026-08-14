-----------------------------------
-- func: primetrial
-- desc: [GM] Inspect and grant Prime Armory trial completion credit.
--
-- Usage:
--   !primetrial status <player>
--   !primetrial complete <player> <1-5>
--   !primetrial next <player>
--   !primetrial undo <player> <1-5>
--   !primetrial rewardclaimed <player>
--   !primetrial markclaimed <player>
--   !primetrial unclaim <player>
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 'sss',
}

local SYS = xi.msg.channel.SYSTEM_3
local CLAIMED_VAR = 'Gauntlet_PrimeTrialRewardClaimed'

local trials =
{
    [1] = { var = 'PW_Trial1_Done', label = 'Trial 1', desc = 'Abyssea collectibles' },
    [2] = { var = 'PW_Trial2_Done', label = 'Trial 2', desc = 'Endless Tower floor 50' },
    [3] = { var = 'PW_Trial3_Done', label = 'Trial 3', desc = 'Prime Voucher' },
    [4] = { var = 'PW_Trial4_Done', label = 'Trial 4', desc = 'Weapon Guardian' },
    [5] = { var = 'PW_Trial5_Done', label = 'Trial 5', desc = 'Aht Urhgan currencies' },
}

local function usage(player)
    player:printToPlayer('Usage: !primetrial status <player> | complete <player> <1-5> | next <player> | undo <player> <1-5>', SYS)
    player:printToPlayer('       !primetrial rewardclaimed <player> | markclaimed <player> | unclaim <player>', SYS)
end

local function getTarget(player, name)
    if not name or name == '' then
        usage(player)
        return nil
    end

    local target = GetPlayerByName(name)
    if not target then
        player:printToPlayer(string.format('[primetrial] Player "%s" not found or not online.', tostring(name)), SYS)
        return nil
    end

    return target
end

local function trialNumber(value)
    local num = tonumber(value or '')
    if not num or not trials[num] then
        return nil
    end

    return num
end

local function isDone(player, num)
    return (player:getCharVar(trials[num].var) or 0) == 1
end

local function printStatus(gm, target)
    gm:printToPlayer(string.format('[primetrial] Prime trial status for %s:', target:getName()), SYS)
    for i = 1, 5 do
        local t = trials[i]
        gm:printToPlayer(string.format(
            '[primetrial]   %s %s - %s',
            isDone(target, i) and '[+]' or '[ ]',
            t.label,
            t.desc),
            SYS)
    end

    gm:printToPlayer(string.format(
        '[primetrial]   Gauntlet Prime reward claimed: %s',
        (target:getCharVar(CLAIMED_VAR) or 0) == 1 and 'yes' or 'no'),
        SYS)
end

local function completeTrial(gm, target, num)
    if isDone(target, num) then
        gm:printToPlayer(string.format('[primetrial] %s already has %s complete.', target:getName(), trials[num].label), SYS)
        return false
    end

    target:setCharVar(trials[num].var, 1)
    target:printToPlayer(string.format('[Prime Armory] %s has been completed by a GM reward credit.', trials[num].label), SYS)
    gm:printToPlayer(string.format('[primetrial] Completed %s for %s.', trials[num].label, target:getName()), SYS)
    return true
end

commandObj.onTrigger = function(player, sub, name, value)
    sub = (sub or ''):lower()

    if sub == 'status' then
        local target = getTarget(player, name)
        if target then
            printStatus(player, target)
        end

    elseif sub == 'complete' then
        local target = getTarget(player, name)
        local num = trialNumber(value)
        if not target or not num then
            usage(player)
            return
        end

        completeTrial(player, target, num)

    elseif sub == 'next' then
        local target = getTarget(player, name)
        if not target then
            return
        end

        for i = 1, 5 do
            if not isDone(target, i) then
                completeTrial(player, target, i)
                return
            end
        end

        player:printToPlayer(string.format('[primetrial] %s already has all Prime trials complete.', target:getName()), SYS)

    elseif sub == 'undo' then
        local target = getTarget(player, name)
        local num = trialNumber(value)
        if not target or not num then
            usage(player)
            return
        end

        target:setCharVar(trials[num].var, 0)
        target:printToPlayer(string.format('[Prime Armory] %s completion credit has been removed by a GM.', trials[num].label), SYS)
        player:printToPlayer(string.format('[primetrial] Removed %s completion from %s.', trials[num].label, target:getName()), SYS)

    elseif sub == 'rewardclaimed' then
        local target = getTarget(player, name)
        if target then
            player:printToPlayer(string.format(
                '[primetrial] %s Gauntlet Prime reward claimed: %s.',
                target:getName(),
                (target:getCharVar(CLAIMED_VAR) or 0) == 1 and 'yes' or 'no'),
                SYS)
        end

    elseif sub == 'markclaimed' then
        local target = getTarget(player, name)
        if target then
            target:setCharVar(CLAIMED_VAR, 1)
            player:printToPlayer(string.format('[primetrial] Marked %s Gauntlet Prime reward as claimed.', target:getName()), SYS)
        end

    elseif sub == 'unclaim' then
        local target = getTarget(player, name)
        if target then
            target:setCharVar(CLAIMED_VAR, 0)
            player:printToPlayer(string.format('[primetrial] Cleared %s Gauntlet Prime reward claimed flag.', target:getName()), SYS)
        end

    else
        usage(player)
    end
end

return commandObj
