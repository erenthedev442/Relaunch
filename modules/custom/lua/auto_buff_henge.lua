-----------------------------------
-- auto_buff_henge.lua
-- Automatically applies the standard !buff package when a player zones
-- into Escha - Zi'Tah (Hunting League hub) so they can hunt immediately.
-- Uses modules/custom/lua/buff_sustain.lua (same potencies as !buff).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Escha_ZiTah/Zone')

local m = Module:new('auto_buff_henge')
local sustain = require('modules/custom/lua/buff_sustain')

m:addOverride('xi.zones.Escha_ZiTah.Zone.onZoneIn', function(player, prevZone)
    super(player, prevZone)

    -- 1500ms delay: let zone-in animation and stat calculations finish first.
    player:timer(1500, function(p)
        local _, refreshPower, regenPower, regainPower = sustain.apply(p, p)

        p:printToPlayer(
            string.format(
                '[Relaunch] Auto-buff: Regen %d/tick | Refresh %d/tick | Regain %d/tick | Composure | Reraise III (5 hr). Happy hunting!',
                regenPower, refreshPower, regainPower),
            xi.msg.channel.SYSTEM_3)
    end)
end)

return m
