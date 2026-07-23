-----------------------------------
-- Cavernous Maw: hub replacement for the former !abyssea command.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('abyssea_warp_npc')

local NPC_POS = { x = 599.3398, y = -3.0969, z = 490.0841, rot = 199 }
local MAW_LOOK = '0x0000150900000000000000000000000000000000'

local showRoot

local function showVisions(player)
    player:timer(30, function(p)
        p:customMenu({
            title   = 'Visions',
            options = {
                { 'Konschtat', function(q) q:setPos( 153,    -72,   -840, 140, xi.zone.ABYSSEA_KONSCHTAT) end },
                { 'Tahrongi',  function(q) q:setPos( -24,     44,   -678, 240, xi.zone.ABYSSEA_TAHRONGI) end },
                { 'La Theine', function(q) q:setPos(-480.5, -0.5,    794,  62, xi.zone.ABYSSEA_LA_THEINE) end },
                { 'Back',      function(q) showRoot(q) end },
            },
        })
    end)
end

local function showScars(player)
    player:timer(30, function(p)
        p:customMenu({
            title   = 'Scars',
            options = {
                { 'Attohwa',   function(q) q:setPos(-134,    -20,  -182, 108, xi.zone.ABYSSEA_ATTOHWA) end },
                { 'Misareaux', function(q) q:setPos( 670,    -15,   318, 119, xi.zone.ABYSSEA_MISAREAUX) end },
                { 'Vunkerl',   function(q) q:setPos(-351, -46.75, 699.5,  10, xi.zone.ABYSSEA_VUNKERL) end },
                { 'Back',      function(q) showRoot(q) end },
            },
        })
    end)
end

local function showHeroes(player)
    player:timer(30, function(p)
        p:customMenu({
            title   = 'Heroes',
            options = {
                { 'Altepa',     function(q) q:setPos( 435,   0,  320, 136, xi.zone.ABYSSEA_ALTEPA) end },
                { 'Grauberg',   function(q) q:setPos(-555,  31, -760,   0, xi.zone.ABYSSEA_GRAUBERG) end },
                { 'Uleguerand', function(q) q:setPos(-210, -40, -498,  32, xi.zone.ABYSSEA_ULEGUERAND) end },
                { 'Back',       function(q) showRoot(q) end },
            },
        })
    end)
end

showRoot = function(player)
    player:timer(30, function(p)
        p:customMenu({
            title   = 'Abyssea Warp',
            options = {
                { 'Visions', function(q) showVisions(q) end },
                { 'Scars',   function(q) showScars(q) end },
                { 'Heroes',  function(q) showHeroes(q) end },
                { 'Close',   function() end },
            },
        })
    end)
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local CavernousMaw = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Cavernous_Maw',
        packetName = 'Cavernous Maw',
        look       = MAW_LOOK,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,
        onTrigger  = function(player, npc)
            showRoot(player)
        end,
    })
    utils.unused(CavernousMaw)
end)

return m
