-- !auginfo  — sends the player's augment rank data to the Windower AugmentBrowser addon.
-- Triggered automatically by the addon on load and zone-in; players can also call it manually.
-- Format: [AUGINFO]rank=N,count=N,aff=N,hl=N,prestige=N,rebirths=N,gauntlet=N

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local function getMaxPrestigeLevel(player)
    local max = 0
    for jobId = 1, 22 do
        local lv = player:getCharVar(string.format('Prestige_Level_%d', jobId)) or 0
        if lv > max then max = lv end
    end
    return max
end

local function getTotalRebirths(player)
    local total = 0
    for jobId = 1, 22 do
        total = total + (player:getCharVar(string.format('Rebirth_Count_%d', jobId)) or 0)
    end
    return total
end

commandObj.onTrigger = function(player, _)
    local rank       = player:getCharVar('Augment_Mastery')    or 0
    local count      = player:getCharVar('Augment_Count')      or 0
    local affinities = player:getCharVar('Augment_Affinities') or 0
    local hlTier     = player:getCharVar('HL_Tier')            or 1
    local prestige   = getMaxPrestigeLevel(player)
    local rebirths   = getTotalRebirths(player)
    local gauntlet   = player:getCharVar('Gauntlet_Clears')    or 0

    player:printToPlayer(
        string.format('[AUGINFO]rank=%d,count=%d,aff=%d,hl=%d,prestige=%d,rebirths=%d,gauntlet=%d',
            rank, count, affinities, hlTier, prestige, rebirths, gauntlet),
        xi.msg.channel.SYSTEM_3
    )
end

return commandObj
