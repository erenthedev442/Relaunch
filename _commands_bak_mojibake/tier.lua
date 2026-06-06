-----------------------------------
-- func: tier
-- desc: Shows the player's current Hunting League tier, the NMs
--       available at that tier, and exactly what is needed to unlock
--       the next rank.
--
-- Usage: !tier
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local catalog = require('modules/custom/lua/hunting_league_catalog')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.LINKSHELL

commandObj.onTrigger = function(player)
    local tier    = player:getCharVar('HL_Tier') or 1
    if tier < 1 then tier = 1 end
    local pts     = player:getCharVar('HL_Points') or 0
    local maxTier = #catalog.tiers
    local tierDef = catalog.tiers[tier]

    if not tierDef then
        player:printToPlayer('[Tier] Could not read tier data.', H)
        return
    end

    player:printToPlayer(
        string.format('[Tier] ── Rank %d: %s ────────────────────────────', tier, tierDef.name), H)
    player:printToPlayer(string.format('  Current marks:  %d', pts), B)
    player:printToPlayer('  NMs at your rank:', B)
    for _, mob in ipairs(tierDef.mobs) do
        player:printToPlayer(
            string.format('    • %-22s  +%d marks/kill', mob.label, mob.points), B)
    end

    -- Next tier information
    player:printToPlayer('  ──────────────────────────────────────────────────', B)
    if tier >= maxTier then
        player:printToPlayer('  You have reached the maximum rank.  Legend status achieved!', B)
        return
    end

    local nextDef = catalog.tiers[tier + 1]
    local cost    = nextDef.unlockCost
    if pts >= cost then
        player:printToPlayer(
            string.format('  ★ READY to unlock %s!', nextDef.name), B)
        player:printToPlayer(
            string.format('    Cost: %d marks  (you have %d)', cost, pts), B)
        player:printToPlayer(
            '    Visit the Hunt Seals NPC in Reisenjima Henge to unlock.', B)
    else
        local needed = cost - pts
        player:printToPlayer(
            string.format('  Next rank:  %s  (costs %d marks)', nextDef.name, cost), B)
        player:printToPlayer(
            string.format('    You need %d more marks  (have %d / %d)', needed, pts, cost), B)
    end

    -- Preview next tier NMs
    player:printToPlayer(string.format('  NMs at %s:', nextDef.name), B)
    for _, mob in ipairs(nextDef.mobs) do
        player:printToPlayer(
            string.format('    • %-22s  +%d marks/kill', mob.label, mob.points), B)
    end
end

return commandObj
