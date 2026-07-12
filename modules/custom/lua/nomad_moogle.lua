-----------------------------------
-- nomad_moogle.lua
-- A retail-style Nomad Moogle at the !hub landing (Abdhaljs Isle-Purgonorgo,
-- zone 44, floor 2) so players can change main/support job, open the
-- Delivery Box, and use the other mog-menu services without leaving the hub.
--
-- How it works (two halves, BOTH required):
--   1. This NPC calls player:sendMenu(xi.menuType.MOOGLE) on trigger -- the
--      exact same call the stock Nomad Moogles make (see
--      scripts/zones/Selbina/npcs/Nomad_Moogle.lua). That opens the client's
--      moogle service menu (Change Jobs / Delivery Box / ...).
--   2. Every action the player picks in that menu is a separate client
--      packet the map server validates against the CURRENT ZONE's misc
--      flags: job change (c2s 0x100) requires MISC_MOGMENU (0x20), and the
--      Delivery Box (c2s 0x04d) requires MISC_MOGMENU or MISC_AH. Zone 44
--      gets MISC_MOGMENU from modules/custom/sql/hub_zone_settings.sql
--      (MISC_AH is already global via ah_anywhere_zone_settings.sql).
--      Without the flag the menu opens but every selection is rejected.
--
-- Position: on the !hub landing row (landing is 571.53/-3.36/508.86), a few
-- steps west so it's the first NPC arrivals see. The 514/520 grid rows are
-- fully occupied; 508 row was free. Verify with !pos after restart.
--
-- Lua module override -- needs one map restart. The zone misc SQL also
-- needs a restart (zone_settings is read once at map boot).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
-----------------------------------
local m = Module:new('nomad_moogle')

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Nomad_Moogle',
        packetName = string.format('%sNomad Moogle', xi.icon.STAR_LARGE),
        look       = 2419,  -- moogle (same confirmed-visible look as the Cosmetic Boutique / Gil Exchange moogles)
        x          = 529.000,
        y          =  -3.038,
        z          = 541.000,
        rotation   = 192,
        widescan   =  1,

        onTrigger = function(player, npc)
            player:printToPlayer('Job changes, Delivery Box -- all your mog services right here at the hub, kupo!', xi.msg.channel.NS_SAY)
            player:sendMenu(xi.menuType.MOOGLE)
        end,
    })
end)

return m
