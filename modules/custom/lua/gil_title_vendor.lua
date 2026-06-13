-----------------------------------
-- gil_title_vendor.lua
-- Title Broker: pay gil to display a title over your character. Pure
-- vanity sink -- doesn't unlock the title officially (player:setTitle
-- just sets the active title), but on a fast-progression server that's
-- exactly what players want.
--
-- Edit the title catalog in gil_title_vendor_catalog.lua. Browse
-- scripts/enum/title.lua for available xi.title.* constants.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog = require('modules/custom/lua/gil_title_vendor_catalog')

local m = Module:new('gil_title_vendor')

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    local buildTierMenu  -- forward declare
    local function buildMainMenu(player)
        local options = {}
        for _, tier in ipairs(catalog.tiers) do
            local t = tier
            table.insert(options, {
                t.label,
                function(p) buildTierMenu(p, t) end,
            })
        end
        table.insert(options, {
            'Close',
            function(p) p:printToPlayer('Look your best!', xi.msg.channel.SYSTEM_3) end,
        })

        menu.title   = string.format('Title Broker  (Your gil: %d)', player:getGil())
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    buildTierMenu = function(player, tier)
        local options = {}
        for _, t in ipairs(tier.titles) do
            local tt = t
            table.insert(options, {
                tt.label,
                function(playerArg)
                    if playerArg:getGil() < tier.cost then
                        playerArg:printToPlayer(
                            string.format('Not enough gil! Need %d, have %d.',
                                tier.cost, playerArg:getGil()),
                            xi.msg.channel.SYSTEM_3
                        )
                        return
                    end
                    playerArg:delGil(tier.cost)
                    -- The engine only displays titles the player OWNS, so
                    -- grant ownership first via addTitle (idempotent --
                    -- a no-op if they already have it), then set it as the
                    -- currently-displayed title. setTitle alone silently
                    -- fails if the player hasn't earned the title.
                    playerArg:addTitle(tt.titleId)
                    playerArg:setTitle(tt.titleId)
                    playerArg:printToPlayer(
                        string.format('Title set: "%s"  (-%d gil)', tt.label, tier.cost),
                        xi.msg.channel.SYSTEM_3
                    )
                end,
            })
        end
        table.insert(options, {
            '<< Back',
            function(p) buildMainMenu(p) end,
        })

        -- Sub-menu title carries the full per-pick cost since the main
        -- menu's tier labels had to stay short. Format is also compact
        -- because the Endgame tier has 6 long title labels and we need
        -- to leave room for them in the same 150-byte packet budget.
        menu.title   = string.format('%s tier (%d g)', tier.label, tier.cost)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local TitleBroker = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Title_Broker',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, catalog.npcName),
        look       = catalog.npcLook,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Browse the menu!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            buildMainMenu(player)
        end,
    })
    utils.unused(TitleBroker)
end)

return m
