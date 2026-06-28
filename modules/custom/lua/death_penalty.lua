-----------------------------------
-- death_penalty.lua
-- Deducts a small number of Hunt Marks when a player dies inside the
-- Hunting League zone (Escha ZiTah).  Adds stakes to hunts without
-- being punishing enough to discourage participation.
--
-- Penalty:  10 marks per death (floor 0 - balance never goes negative).
-- Scope:    Only fires in xi.zone.ESCHA_ZITAH.
-- Exempt:   Players with < EXEMPT_KILLS total NM kills (new-player grace).
-----------------------------------
require('modules/module_utils')

local m = Module:new('death_penalty')

local PENALTY     = 10   -- marks lost per death
local EXEMPT_KILLS = 50  -- players below this kill count are exempt
local HUNT_ZONE   = xi.zone.ESCHA_ZITAH

local PARDON_VAR = 'MysteryMog_Pardon'  -- set by Mystery Mog Death's Pardon prize

m:addOverride('xi.player.onPlayerDeath', function(player, killer, isKO)
    super(player, killer, isKO)

    -- Only penalise inside the hunt zone.
    if player:getZoneID() ~= HUNT_ZONE then return end

    -- New-player grace: exempt players who haven't hunted much yet.
    local totalKills = player:getCharVar('Custom_NM_Kills') or 0
    if totalKills < EXEMPT_KILLS then return end

    -- Death's Pardon: Mystery Mog prize that absorbs one death penalty.
    if (player:getCharVar(PARDON_VAR) or 0) > 0 then
        player:setCharVar(PARDON_VAR, 0)
        player:printToPlayer(
            "[Hunting League] The Mog's pardon absorbed the death penalty! " ..
            "(Your Hunt Marks are safe.)",
            xi.msg.channel.SYSTEM_3)
        return
    end

    local current = player:getCharVar('HL_Points') or 0
    local newBal  = math.max(0, current - PENALTY)
    player:setCharVar('HL_Points', newBal)

    player:printToPlayer(
        string.format('[Hunting League] Fallen in the hunt zone: -%d marks!  (Balance: %d)',
            PENALTY, newBal),
        xi.msg.channel.SYSTEM_3)
end)

return m
