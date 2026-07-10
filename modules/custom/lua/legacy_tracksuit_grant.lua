-----------------------------------
-- legacy_tracksuit_grant.lua   (RELAUNCH)
--
-- Grants the 4-piece Legendary Track Suit (items 23875-78, see
-- modules/custom/sql/legendary_tracksuit.sql) to characters who claimed it as
-- their Legacy migration reward on the portal. The portal sets charVar
-- Legacy_TrackSuit_Grant = 1 on the OFFLINE character; this hook delivers the
-- pieces on the next login (same pattern as legacy_ring_grant.lua).
--
-- CharVars:
--   Legacy_TrackSuit_Grant - 1 = owed the set. Cleared once every piece is
--                            delivered (or already owned). Partial delivery
--                            (bag fills mid-grant) keeps the flag and retries
--                            the MISSING pieces next login (hasItem-guarded,
--                            so no dupes -- the items are Rare).
-----------------------------------
require('modules/module_utils')

local m = Module:new('legacy_tracksuit_grant')

local PIECES =
{
    { id = 23875, name = 'Track Jacket'   },
    { id = 23876, name = 'Track Pants'    },
    { id = 23877, name = 'Track Shoes'    },
    { id = 23878, name = 'Legend Sweater' },
}
local CV_OWED = 'Legacy_TrackSuit_Grant'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- gameLogin == 1 marks a real login (see daily_login_bonus.lua); capture before super().
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if isLogin and player:getCharVar(CV_OWED) == 1 then
        local granted, missing = 0, 0
        for _, piece in ipairs(PIECES) do
            if not player:hasItem(piece.id) then
                if player:getFreeSlotsCount() > 0 then
                    player:addItem(piece.id)
                    granted = granted + 1
                else
                    missing = missing + 1
                end
            end
        end
        if missing == 0 then
            player:setCharVar(CV_OWED, 0)
            if granted > 0 then
                player:timer(3500, function(p)
                    p:printToPlayer('[Legacy] Your Legendary Track Suit has arrived. Wear it loud, veteran.',
                        xi.msg.channel.SYSTEM_3)
                end)
            end
        else
            player:timer(3500, function(p)
                p:printToPlayer(string.format(
                    '[Legacy] %d Track Suit piece(s) still need inventory space -- free some slots and relog.',
                    missing), xi.msg.channel.SYSTEM_3)
            end)
        end
    end
end)

return m
