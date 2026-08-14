-----------------------------------
-- func: grantpearls
-- desc: Adds the Legendary linkpearl to every ONLINE character that
--       doesn't already have one (515) or a pearlsack (514).
--
--       For offline characters, also prints a SQL one-liner to run on
--       the Azure box that inserts the pearl into char_inventory directly.
--
-- Usage: !grantpearls
-- Permission: GM level 5
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = ''
}

local LS_NAME  = 'Legendary'
local PEARL_ID = 515   -- linkpearl (non-GM)
local SACK_ID  = 514   -- pearlsack (GM)

commandObj.onTrigger = function(player)
    local granted = 0
    local skipped = 0
    local failed  = 0

    for zoneId = 1, 299 do
        local zone = GetZone(zoneId)
        if zone then
            for _, targ in pairs(zone:getPlayers()) do
                if targ then
                    if targ:hasItem(PEARL_ID) or targ:hasItem(SACK_ID) then
                        skipped = skipped + 1
                    elseif targ:addLinkpearl(LS_NAME, false) then
                        granted = granted + 1
                    else
                        failed = failed + 1
                    end
                end
            end
        end
    end

    local say = function(msg)
        player:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
    end

    say(string.format(
        '[grantpearls] Online players: %d granted, %d already had one, %d failed.',
        granted, skipped, failed))

    say('[grantpearls] For offline characters, SSH to the box and run:')
    say('  sudo mysql xidb < ~/server/tools/sql/grant_pearls_offline.sql')
    say('  (or paste the file contents into HeidiSQL on the live DB)')
end

return commandObj
