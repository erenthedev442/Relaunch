-----------------------------------
-- Fellow Officer -- progression and customization hub
-- Zone 44: Abdhaljs Isle-Purgonorgo
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('fellow_officer')

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local officer = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Fellow_Officer',
        packetName = string.format('%sFellow Officer', xi.icon.STAR_LARGE),
        look       = 167,
        x          = 499.0043,
        y          = 0.3000,
        z          = 564.2281,
        rotation   = 194,
        widescan   = 1,

        onTrigger = function(player, npc)
            if not xi.fellow or not xi.fellow.openUpgradeMenu then
                player:printToPlayer('[Fellow] The Fellow service is temporarily unavailable.', xi.msg.channel.SYSTEM_3)
                return
            end

            player:printToPlayer(
                '[Fellow Officer] Train, rebuild, name, and dress your Adventuring Fellow.',
                xi.msg.channel.SYSTEM_3)
            xi.fellow.openUpgradeMenu(player)
        end,
    })

    utils.unused(officer)
end)

return m
