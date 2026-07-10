-----------------------------------
-- legacy_ring_grant.lua   (RELAUNCH)
--
-- Grants the Legendary Ring (item 26169, see modules/custom/sql/legendary_ring.sql)
-- to any character who claimed it as their Legacy migration reward on the portal.
-- The portal sets charVar Legacy_Ring_Grant = 1 on the OFFLINE character; this
-- hook hands over the actual item on their next login (offline DBs cannot safely
-- push items into inventory containers, so the grant is deferred to login).
--
-- CharVars:
--   Legacy_Ring_Grant - 1 = owed the ring (set by the portal claim). Cleared to 0
--                       once the ring is delivered (or already owned).
--
-- Real-login gate + grant is idempotent and inventory-safe: if the bag is full we
-- keep the flag set and retry on the next login rather than dropping the item.
-----------------------------------
require('modules/module_utils')

local m = Module:new('legacy_ring_grant')

local LEGENDARY_RING = 26169
local CV_OWED        = 'Legacy_Ring_Grant'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- gameLogin == 1 marks a real login; `not zoning` misfires on zone-ins
    -- (see announce_player_login.lua / daily_login_bonus.lua). Capture before super() clears it.
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if isLogin and player:getCharVar(CV_OWED) == 1 then
        if player:hasItem(LEGENDARY_RING) then
            -- Already holding it (e.g. re-claim / prior grant) -- just clear the flag.
            player:setCharVar(CV_OWED, 0)
        elseif player:getFreeSlotsCount() > 0 then
            player:addItem(LEGENDARY_RING)
            player:setCharVar(CV_OWED, 0)
            player:timer(3500, function(p)
                p:printToPlayer('[Legacy] Your Legendary Ring has arrived. Wear it with pride, veteran.',
                    xi.msg.channel.SYSTEM_3)
            end)
        else
            -- Inventory full: keep the flag and nudge; retry next login.
            player:timer(3500, function(p)
                p:printToPlayer('[Legacy] Free an inventory slot to receive your Legendary Ring.',
                    xi.msg.channel.SYSTEM_3)
            end)
        end
    end
end)

return m
