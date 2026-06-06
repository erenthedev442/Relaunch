-----------------------------------
-- gil_warp_npc.lua
-- Warpman: pay gil to insta-warp to popular zones. The first gil sink
-- in the GIL SERVICES row at GM Home (z=-35).
--
-- Menu is TWO LEVELS to stay under FFXI's ~150-byte customMenu packet
-- cap (a flat 15-row list truncated client-side):
--   1. Pick a tier (Cities / Expansions / Remote / Endgame)
--   2. Pick a destination within that tier; all share the tier's cost
--
-- Edit destinations + prices in gil_warp_npc_catalog.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog = require('modules/custom/lua/gil_warp_npc_catalog')

local m = Module:new('gil_warp_npc')

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    local buildTierMenu  -- forward declare (buildDestMenu's Back calls it)
    local function buildDestMenu(player, tier)
        local options = {}

        for _, dest in ipairs(tier.destinations) do
            local d = dest
            local cost = tier.cost
            table.insert(options, {
                d.label,
                function(playerArg)
                    if playerArg:getGil() < cost then
                        playerArg:printToPlayer(
                            string.format('Not enough gil! Need %d, have %d.',
                                cost, playerArg:getGil()),
                            xi.msg.channel.SYSTEM_3
                        )
                        return
                    end
                    playerArg:delGil(cost)
                    playerArg:printToPlayer(
                        string.format('Warped to %s (-%d gil). Safe travels!',
                            d.label, cost),
                        xi.msg.channel.SYSTEM_3
                    )
                    playerArg:setPos(d.x, d.y, d.z, d.r, d.zone)
                end,
            })
        end

        table.insert(options, {
            '<< Back',
            function(p) buildTierMenu(p) end,
        })

        -- Sub-menu title carries the full per-warp cost since destination
        -- labels are bare.
        menu.title   = string.format('%s tier (%d g)', tier.label, tier.cost)
        menu.options = options
        player:timer(50, function(p) p:customMenu(menu) end)
    end

    buildTierMenu = function(player)
        local options = {}
        for _, tier in ipairs(catalog.tiers) do
            local t = tier
            table.insert(options, {
                t.label,
                function(p) buildDestMenu(p, t) end,
            })
        end
        table.insert(options, {
            'Close',
            function(p) p:printToPlayer('Travel safe!', xi.msg.channel.SYSTEM_3) end,
        })

        menu.title   = string.format('Warpman  (Your gil: %d)', player:getGil())
        menu.options = options
        player:timer(50, function(p) p:customMenu(menu) end)
    end

    local Warpman = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = catalog.npcName,
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, catalog.npcName),
        look       = catalog.npcLook,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Use the menu, friend!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            buildTierMenu(player)
        end,
    })
    utils.unused(Warpman)
end)

return m
