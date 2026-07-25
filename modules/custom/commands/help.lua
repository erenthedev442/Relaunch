-----------------------------------
-- func: help
-- desc: Lists all custom commands with a one-line description.
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

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player)
    player:printToPlayer('[Relaunch] == Custom Commands ===========================', H)
    player:printToPlayer("  !hunt            - Warp to Escha - Zi'Tah (hunting hub)", B)
    player:printToPlayer('  !marks           - Quick marks balance (current + lifetime)', B)
    player:printToPlayer('  !streak          - Your current kill streak status + timer', B)
    player:printToPlayer('  !tier            - Next HL tier requirements + cost', B)
    player:printToPlayer('  !week            - This week\'s objectives at a glance', B)
    player:printToPlayer('  !featured        - This week\'s featured bonus NMs (2x marks)', B)
    player:printToPlayer('  !achievements    - Your personal milestone progress', B)
    player:printToPlayer('  !reforge         - Your Reforge AF / Relic / Empy mark balances', B)
    player:printToPlayer('  !nms             - NM Encyclopedia: killed vs. remaining', B)
    player:printToPlayer('  !progress [sub]  - Full progression (hunt/reforge/weekly/guilds/etc.)', B)
    player:printToPlayer('  !profile [name]  - View any player\'s stats', B)
    player:printToPlayer('  !mystats         - Full stat dump incl. your augment/gear extras', B)
    player:printToPlayer('  !checkascend / !checkrebirth - Ascension AP / Job Rebirth progress', B)
    player:printToPlayer('  !unity [remaining] - Unity Wanted NM conquest progress by tier', B)
    player:printToPlayer('  !geas [page]     - Missing Geas Fete NMs, positions, and zones', B)
    player:printToPlayer('  !geaski <tier>   - Buy a Geas Fete pop trigger remotely', B)
    player:printToPlayer('  !who             - Who is currently online', B)
    player:printToPlayer('  !top [kills|marks|infamy] - Top 5 online players by stat', B)
    player:printToPlayer('  !events          - Upcoming seasonal bonus mark events', B)
    player:printToPlayer('  !time            - Server time + daily/weekly reset countdowns', B)
    player:printToPlayer('  !optin / !optout - Opt in or out of public leaderboards', B)
    player:printToPlayer('  =====================================================', B)
    player:printToPlayer('  Docs: www.ffxi-legendary.com', B)
end

return commandObj
