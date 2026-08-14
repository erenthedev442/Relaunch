-----------------------------------
-- !gmhelp
-- Curated support-GM command guide.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

local SYS = xi.msg.channel.SYSTEM_3

local categories =
{
    {
        label = 'Find & Inspect',
        lines =
        {
            '!seek [filter] - find online players across zones',
            '!gminspect <player> - support summary and active sessions',
            '!hasitem / !haskeyitem - read-only ownership checks',
            '!checkquest / !checkmission - read-only progression checks',
            '!geteffects <player> - active status effects',
        },
    },
    {
        label = 'Rescue & Travel',
        lines =
        {
            '!gmrelease <player> <reason> - gentle event recovery',
            '!rescue <player> - hard rescue, online or offline; forces relog',
            '!goto <player> / !bring <player> - support travel',
            '!send <player> <destination> - send a player elsewhere',
            '!raise <power> <player> - offer a Raise menu',
        },
    },
    {
        label = 'Items & Key Items',
        lines =
        {
            '!gmitem add|remove <player> <id> <amount> <reason>',
            '!gmkeyitem add|remove <player> <id|KEY_NAME> <reason>',
            'All restoration actions require a reason and are audited.',
            'Augmented items and bulk inventory surgery require GM5.',
        },
    },
    {
        label = 'Quest & Mission Repair',
        lines =
        {
            '!gmrepair quest|mission status <player> <log> <id>',
            '!gmrepair quest|mission add <player> <log> <id> <reason>',
            'Actions: add, complete, delete, clearvars.',
            'Inspect first; only change the minimum broken state.',
        },
    },
    {
        label = 'Moderation',
        lines =
        {
            '!gmkick <player> <reason> - disconnect without jail',
            '!gmjail <player> <cell> <reason> - move to Mordion Gaol',
            '!gmpardon <player> <reason> - release from jail',
            '!announce <message> - server-wide notice',
            '!hide / !togglegm - staff visibility controls',
        },
    },
    {
        label = 'Content Cleanup',
        lines =
        {
            '!gmcontent status <player> - active session summary',
            '!gmcontent reset <system> <player> <reason>',
            'Systems: dungeon, wave, tower, gauntlet, apex, trial.',
            'Cleanup aborts sessions; it never grants credit or rewards.',
        },
    },
    {
        label = 'Escalate to Owners',
        lines =
        {
            'Escalate currencies, levels, skills and progression grants.',
            'Escalate augmented gear, bulk deletion and account changes.',
            'Escalate world events, spawns, reloads and server operations.',
            'GM1 commands are logged; include a clear reason where requested.',
        },
    },
}

local showRoot

local function showCategory(gm, category)
    gm:printToPlayer(string.format('[GM Help] == %s ==', category.label), SYS)
    for _, line in ipairs(category.lines) do
        gm:printToPlayer('  ' .. line, SYS)
    end
    gm:timer(30, function(player)
        showRoot(player)
    end)
end

showRoot = function(gm)
    local options = {}
    for _, category in ipairs(categories) do
        local categoryRef = category
        options[#options + 1] =
        {
            categoryRef.label,
            function(player)
                showCategory(player, categoryRef)
            end,
        }
    end
    options[#options + 1] = { 'Close', function() end }

    gm:timer(30, function(player)
        player:customMenu({
            title = 'GM1 Support Commands',
            options = options,
        })
    end)
end

commandObj.onTrigger = function(gm)
    showRoot(gm)
end

return commandObj
