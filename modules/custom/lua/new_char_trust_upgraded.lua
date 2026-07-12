-----------------------------------
-- Grants the base trust upgrade tier to new characters.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------
local m = Module:new('new_char_trust_upgraded')

m:addOverride('xi.player.charCreate', function(player)
    super(player)

    player:setCharVar('TrustUpgraded', 1)
end)

return m
