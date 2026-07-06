-----------------------------------
-- gil_exchange_npc.lua
-- Gil Exchange: converts gil to Hunt Marks at TERRIBLE rates. Release
-- valve for whales who've hit a gil wall but still want progression.
-- Bad ratio (100k gil = 1 Hunt Mark) keeps Hunt Mark farming as the
-- primary path -- this is just a last-resort sink for rich players.
--
-- Trade-sizes are bundles (100k / 1M / 10M) so a single click can move
-- a lot of gil without spamming the menu. Inventory operations need
-- no item slot (gil + charvar only).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Celennia_Memorial_Library/Zone')

local m = Module:new('gil_exchange_npc')

-- Inline config -- this one's small enough not to warrant a separate
-- catalog file.
--
-- Label budget note: FFXI's customMenu packet caps title + all option
-- labels at ~150 bytes total. Worst-case title with a 9-digit gil
-- balance is ~30 bytes, leaving ~120 bytes for the three bundle labels
-- + Close. The previous verbose labels ("(small bonus)" / "(best
-- ratio)") plus a longer title ran 153 bytes, truncating the third
-- option so clicks on it couldn't be matched server-side. Keep labels
-- terse here.
local config = {
    npcName  = 'Gil Exchange',
    npcLook  = 2419,    -- moogle (same as ExpCamp)
    npcPos   = { x = -106.000, y = -2.150, z = -100.000, rot = 190 },
    huntCv   = 'HL_Points',   -- matches CV_POINTS in HuntingLeague.lua
    -- conversion bundles: { gil, hunt_marks }
    bundles  =
    {
        { gil =    100000, marks =   1, label = '100k  ->  1 mark' },
        { gil =   1000000, marks =  12, label =   '1M  ->  12 marks' },
        { gil =  10000000, marks = 150, label =  '10M  ->  150 marks  (best deal)' },
    },
}

m:addOverride('xi.zones.Celennia_Memorial_Library.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    local function buildMenu(player)
        local options = {}
        local gil    = player:getGil()
        local marks  = player:getCharVar(config.huntCv)

        for _, b in ipairs(config.bundles) do
            local bundle = b
            table.insert(options, {
                bundle.label,
                function(playerArg)
                    if playerArg:getGil() < bundle.gil then
                        playerArg:printToPlayer(
                            string.format('Not enough gil! Need %d, have %d.',
                                bundle.gil, playerArg:getGil()),
                            xi.msg.channel.SYSTEM_3
                        )
                        return
                    end
                    playerArg:delGil(bundle.gil)
                    playerArg:setCharVar(config.huntCv,
                        playerArg:getCharVar(config.huntCv) + bundle.marks)
                    playerArg:printToPlayer(
                        string.format('Exchanged %d gil for %d Hunt Marks. (Total: %d marks)',
                            bundle.gil, bundle.marks,
                            playerArg:getCharVar(config.huntCv)),
                        xi.msg.channel.SYSTEM_3
                    )
                end,
            })
        end

        table.insert(options, {
            'Close',
            function(p) p:printToPlayer('Trade well.', xi.msg.channel.SYSTEM_3) end,
        })

        -- Title is intentionally short (just gil) -- the Marks balance
        -- shows in the per-bundle confirmation message instead. See the
        -- budget-note comment in `config` for why this matters.
        menu.title   = string.format('Gil Exchange  (Gil: %d)', gil)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local GilExchange = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Gil_Exchange',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, config.npcName),
        look       = 172,
        x          = config.npcPos.x,
        y          = config.npcPos.y,
        z          = config.npcPos.z,
        rotation   = config.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Use the menu.', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            buildMenu(player)
        end,
    })
    utils.unused(GilExchange)
end)

return m
