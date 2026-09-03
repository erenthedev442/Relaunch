-----------------------------------
-- Legendary linkpearl for new players, but not until chat unlocks.
-- Public chat (including linkshell) is C++ gated at map.MIN_CHAT_LEVEL (10)
-- once xi_map is rebuilt. Until then, do not hand a pearl to level-1s.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------
local m = Module:new('new_player_linkshell')

local LS_NAME      = 'Legendary'
local MIN_LS_LEVEL = 10
local PEARL_ID     = 515
local SACK_ID      = 514

local function highestJobLevel(player)
    local best = player:getMainLvl() or 0
    for job = xi.job.WAR, xi.job.RUN do
        local lv = player:getJobLevel(job)
        if lv and lv > best then
            best = lv
        end
    end
    return best
end

local function grantPearlIfReady(player)
    if highestJobLevel(player) < MIN_LS_LEVEL then
        return
    end

    if player:hasItem(PEARL_ID) or player:hasItem(SACK_ID) then
        return
    end

    if player:addLinkpearl(LS_NAME, false) then
        player:printToPlayer(
            string.format('[Legendary] Level %d reached -- a Legendary linkpearl is in your inventory.', MIN_LS_LEVEL),
            xi.msg.channel.SYSTEM_3)
    end
end

-- Do not hook charCreate -- that is what used to hand a pearl to level 1s.

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    grantPearlIfReady(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    grantPearlIfReady(player)
end)

return m
