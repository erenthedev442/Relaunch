-----------------------------------
-- Re-apply a jail sentence if the character logged in or zoned
-- somewhere other than Mordion while inJail is still set.
-----------------------------------
require('modules/module_utils')
local jail = require('modules/custom/lua/mordion_jail')

local m = Module:new('mordion_jail_guard')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    jail.enforceSentence(player)
end)

return m
