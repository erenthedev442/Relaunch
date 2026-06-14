-----------------------------------
-- trust_auto_attack_rearm.lua
-- Restarts the !trustattack auto-attack loop after a zone or login, so the
-- toggle (charVar TrustAtkOn) survives both -- not just the zone you flipped it
-- on in. The loop itself lives in the trustattack command (xi.trustAtk.arm);
-- this module is only the onGameIn hook that kicks it back off.
--
-- NEW override module -> needs a map restart to go live. Until that restart the
-- toggle still works within the zone you enable it in; just re-run it on a zone.
-----------------------------------
require('modules/module_utils')

local m = Module:new('trust_auto_attack_rearm')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if (player:getCharVar('TrustAtkOn') or 0) == 1 and xi.trustAtk and xi.trustAtk.arm then
        -- small delay so we're fully in-zone before the loop starts ticking
        player:timer(3000, function(p)
            if p and (p:getCharVar('TrustAtkOn') or 0) == 1 and xi.trustAtk then
                xi.trustAtk.arm(p)
            end
        end)
    end
end)

return m
