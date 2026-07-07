-----------------------------------
-- survival_guide_npc.lua
--
-- A "Survival Guide" warp book (copy of the retail Northern San d'Oria
-- guide) placed in the server's hub zone. Warps to every retail Survival
-- Guide location -- all 98 spots from
-- scripts/globals/teleports/survival_guide_map.lua -- with NO unlock
-- requirement (retail makes you register each guide by visiting it first).
--
-- The retail guide UI is a client EVENT that only exists in survival-guide
-- zones' DATs, so this uses the server's standard customMenu pattern
-- instead (same machinery as gil_warp_npc.lua / Warpman):
--   level 1: region list (paged, 5 per page -- 11 regions)
--   level 2: destinations within the region (paged, 4 per page)
-- The customMenu packet is a HARD 150-byte cap: SetCustomMenuContext sends
-- the title + every option label, each wrapped in quotes and concatenated
-- ("title""opt1""opt2"...); anything past byte 150 is silently truncated, so
-- the last option loses characters (e.g. "Close" -> "Cl"). Page sizes are set
-- so the worst-case page stays well under 150 (region page ~134 B, dest page
-- ~130 B incl. the longest "(S)" labels). Was 6/5 -> overflowed to 154 B and
-- clipped "Close" on region page 1 (fixed 2026-07-06). Labels also pre-shortened.
--
-- Destinations + placement + cost live in survival_guide_npc_catalog.lua
-- (GENERATED -- same file name on both servers, zone/pos differ: GM Home on
-- Legendary, Leafallia on relaunch).
--
-- New override module -> needs a map RESTART to register.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/survival_guide_npc_catalog')
local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))

local m   = Module:new('survival_guide_npc')
local SYS = xi.msg.channel.SYSTEM_3

local REGIONS_PER_PAGE = 5   -- 6 overflowed the 150-byte customMenu cap (clipped "Close" -> "Cl")
local DESTS_PER_PAGE   = 4   -- 5 was a razor-thin 149 B on the long "(S)" regions; 4 = safe margin

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    local buildRegionMenu  -- forward declare (dest menu's Back calls it)

    -- Deferred-snapshot send, same pattern as gil_warp_npc.lua.
    local function sendMenu(player, title, options)
        local snapshot = { title = title, options = options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local function buildDestMenu(player, region, page)
        page = page or 1
        local options = {}
        local first   = (page - 1) * DESTS_PER_PAGE + 1
        local last    = math.min(first + DESTS_PER_PAGE - 1, #region.destinations)

        for i = first, last do
            local d = region.destinations[i]
            table.insert(options, {
                d.label,
                function(p)
                    if p:getGil() < catalog.warpCost then
                        p:printToPlayer(string.format(
                            'Not enough gil! Need %d, have %d.',
                            catalog.warpCost, p:getGil()), SYS)
                        return
                    end
                    p:delGil(catalog.warpCost)
                    p:printToPlayer(string.format(
                        'The guide whisks you to %s. (-%d gil)',
                        d.label, catalog.warpCost), SYS)
                    p:setPos(d.x, d.y, d.z, d.r, d.zone)
                end,
            })
        end

        if last < #region.destinations then
            table.insert(options, {
                'More >>',
                function(p) buildDestMenu(p, region, page + 1) end,
            })
        end
        table.insert(options, {
            '<< Regions',
            function(p) buildRegionMenu(p, 1) end,
        })

        sendMenu(player, region.label, options)
    end

    buildRegionMenu = function(player, page)
        page = page or 1
        local options = {}
        local first   = (page - 1) * REGIONS_PER_PAGE + 1
        local last    = math.min(first + REGIONS_PER_PAGE - 1, #catalog.regions)

        for i = first, last do
            local r = catalog.regions[i]
            table.insert(options, {
                r.label,
                function(p) buildDestMenu(p, r, 1) end,
            })
        end

        if last < #catalog.regions then
            table.insert(options, {
                'More >>',
                function(p) buildRegionMenu(p, page + 1) end,
            })
        end
        if page > 1 then
            table.insert(options, {
                '<< Back',
                function(p) buildRegionMenu(p, page - 1) end,
            })
        else
            table.insert(options, {
                'Close',
                function(p) p:printToPlayer('Safe travels!', SYS) end,
            })
        end

        sendMenu(player,
            string.format('Survival Guide (%dg/warp)', catalog.warpCost),
            options)
    end

    local guide = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = catalog.npcName,
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, catalog.packet),
        look       = 228,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('The pages flutter. Just read it -- no offerings needed.', SYS)
        end,

        onTrigger = function(player, npc)
            buildRegionMenu(player, 1)
        end,
    })
    utils.unused(guide)
end)

return m
