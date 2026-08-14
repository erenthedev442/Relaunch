-----------------------------------
-- !gmadmin
-- Curated owner/developer command guide.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = '',
}

local SYS = xi.msg.channel.SYSTEM_3

local categories =
{
    {
        label = 'Economy & Rewards',
        lines =
        {
            '!giveitem / !additem / !delitem - item surgery',
            '!givegil / !setgil / !takegil - gil controls',
            '!givemarks / !giveinfamy / !givereforge - currencies',
            '!primevoucher / !givetrust / !givegfkit - custom rewards',
            '!setbonus <multiplier> <hours> - global Hunt Mark event',
        },
    },
    {
        label = 'Character Surgery',
        lines =
        {
            '!setplayerlevel / !setskill / !setjobpoints',
            '!setplayervar / !setmissionstatus / !setquestvar',
            '!masterjob / !addallspells / !addalltrusts',
            '!racechange / !promote - character and staff administration',
            '!delallinventory - destructive; verify the target first',
        },
    },
    {
        label = 'Content & World Events',
        lines =
        {
            '!worldboss status|spawn|kill|reset',
            '!affinitypop - force affinity event spawns',
            '!mastery grant|reset / !primetrial - progression repair',
            '!tower / !gauntlet admin subcommands - session surgery',
            'Retired invasion tooling remains owner-only.',
        },
    },
    {
        label = 'Server Operations',
        lines =
        {
            '!announce / !shutdown - player communication',
            '!grantpearls - mass linkshell distribution',
            '!despawnzone / !provokeall - zone-wide operations',
            '!uptime - process uptime',
            'Actual restart/deploy remains external to the game command layer.',
        },
    },
    {
        label = 'Live Reload & Dev',
        lines =
        {
            '!reloadglobal / !reloadquest / !reloadinteraction',
            '!reloadrecipes / !reloadmagians / !reloadbattlefield',
            '!reloadnavmesh / !rebuildnavmesh',
            '!exec - arbitrary Lua; use only when the code path is understood',
            '!inject / !injectaction - packet-level testing',
        },
    },
    {
        label = 'Combat Testing',
        lines =
        {
            '!godmode / !immortal / !wallhack / !speed',
            '!spawnmob / !despawnmob / !mobhere',
            '!setmoblevel / !setmobmod / !setmobflags',
            '!affinitypop / !worldboss - controlled content tests',
        },
    },
    {
        label = 'Destructive Tools',
        lines =
        {
            '!crash / !sleep - process disruption',
            '!delallinventory / !breaklinkshell - irreversible data loss',
            '!despawnzone / !provokeall - broad live-world impact',
            'GM5 owner commands are intentionally not written to GM1 audit.',
        },
    },
}

local showRoot

local function showCategory(gm, category)
    gm:printToPlayer(string.format('[GM Admin] == %s ==', category.label), SYS)
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
            title = 'GM5 Owner and Dev Commands',
            options = options,
        })
    end)
end

commandObj.onTrigger = function(gm)
    showRoot(gm)
end

return commandObj
