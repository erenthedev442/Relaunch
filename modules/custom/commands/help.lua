-----------------------------------
-- func: help
-- desc: Categorized player-command help menu.
--
-- Usage: !help
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local SYS = xi.msg.channel.SYSTEM_3

local categories =
{
    {
        label = 'Travel & Recovery',
        lines =
        {
            '!hub - return to the Relaunch hub',
            '!warp - open the player warp menu',
            '!home - return to your home point',
            '!unstick - safely recover from a stuck event',
            '!warpty - party leader summons online party members',
            '!pos - display your current coordinates',
        },
    },
    {
        label = 'Progress & Rewards',
        lines =
        {
            '!progress [section] - overall progression summary',
            '!marks / !streak / !tier - Hunting League status',
            '!week / !featured - weekly objectives and bonuses',
            '!achievements / !nms / !unity - completion trackers',
            '!reforge / !forgegates / !empyaby - forge progress',
            '!mastery / !empower - endgame progression status',
            '!checkascend / !checkrebirth - prestige progress',
        },
    },
    {
        label = 'Battle Content',
        lines =
        {
            '!geas [page] / !geaski <tier> - Geas Fete tools',
            '!voidwatch / !ambuscade - battle helpers and status',
            '!tower / !apex / !gauntlet - climb status and abort',
            '!paragon - Paragon Board status',
            '!visitant - extend Visitant status inside Abyssea',
            '!tournament - tournament information',
        },
    },
    {
        label = 'Character & Gear',
        lines =
        {
            '!shop / !ah - shops and auction house',
            '!buff - apply your personal support package',
            '!autojp / !automerits - spend your own points',
            '!profile [name] / !mystats / !reallevel - stats',
            '!catalysts - catalyst inventory',
            '!reroll <slot> - augment reroll preview',
            '!offhand - Cross-Job Dual Wield equipment',
            '!hovershot - use the Ranger Hover Shot workaround',
        },
    },
    {
        label = 'Companions',
        lines =
        {
            '!fellow - Adventuring Fellow controls',
            '!fellowname - rename your Fellow',
            '!fellowstats - Fellow build summary',
            '!pup - Automaton controls',
            '!petstats - current pet stats',
            '!autoready [on|off|status] - BST jug auto-Ready',
            '!trustattack - Trust targeting controls',
        },
    },
    {
        label = 'Community & Server',
        lines =
        {
            '!who - online players',
            '!top [kills|marks|infamy] - online leaderboard',
            '!events - upcoming bonus events',
            '!time - server time and reset countdowns',
            '!optin / !optout - public leaderboard privacy',
            'Docs: www.ffxi-legendary.com',
        },
    },
}

local showRoot

local function showCategory(player, category)
    player:printToPlayer(string.format('[Help] == %s ==', category.label), SYS)
    for _, line in ipairs(category.lines) do
        player:printToPlayer('  ' .. line, SYS)
    end

    player:timer(30, function(p)
        showRoot(p)
    end)
end

showRoot = function(player)
    local options = {}
    for _, category in ipairs(categories) do
        local categoryRef = category
        options[#options + 1] =
        {
            categoryRef.label,
            function(p)
                showCategory(p, categoryRef)
            end,
        }
    end
    options[#options + 1] = { 'Close', function() end }

    player:timer(30, function(p)
        p:customMenu({
            title = 'Relaunch Player Commands',
            options = options,
        })
    end)
end

commandObj.onTrigger = function(player)
    showRoot(player)
end

return commandObj
