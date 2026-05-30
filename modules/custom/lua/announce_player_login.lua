-----------------------------------
-- Announce when a player logs in
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('announce_player_login')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if not zoning then
        -- Login announcement broadcast to all zones via ZMQ.
        -- Delay 2500ms: PChar->loc.zone may not be populated yet at hook time.
        player:timer(2500, function(playerArg)
            local decoratedMessage = string.format('Player %s has logged in.', playerArg:getName())
            -- Sends announcement via ZMQ to all processes and zones
            playerArg:printToArea(decoratedMessage, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
        end)

        -- MOTD tip bar — shown privately to the logging-in player only,
        -- 500ms after the broadcast so it lands below the login message.
        player:timer(3000, function(playerArg)
            local S = xi.msg.channel.SYSTEM_3
            local B = xi.msg.channel.LINKSHELL
            playerArg:printToPlayer('[Legendary] ── Quick Tips ─────────────────────────────────────', S)
            playerArg:printToPlayer('  !featured     — this week\'s bonus-mark NMs  (2x marks on 1st kill)', B)
            playerArg:printToPlayer('  !achievements — your personal milestone progress', B)
            playerArg:printToPlayer('  !progress     — full progression summary across all systems', B)
            playerArg:printToPlayer('  !hunt         — warp to Reisenjima Henge to start hunting', B)
            playerArg:printToPlayer('  Discord: discord.gg/legendary  (events, announcements, help)', B)
        end)
    end
end)

return m
