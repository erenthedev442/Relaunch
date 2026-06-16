-----------------------------------
-- !abyssea
-- Warp to any Abyssea zone via a two-tier menu.
-- Root picks the expansion; sub-menu picks the zone.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops = 
{
    permission = 0,
    parameters = '',
}

local showRoot  -- forward declaration for Back buttons

local function showVisions(p)
    p:timer(30, function(pl)
        pl:customMenu({
            title   = 'Visions',
            options = {
                { 'Konschtat', function(q) q:setPos( 153,    -72,    -840,   140, xi.zone.ABYSSEA_KONSCHTAT) end },
                { 'Tahrongi',  function(q) q:setPos( -24,     44,    -678,   240, xi.zone.ABYSSEA_TAHRONGI)  end },
                { 'La Theine', function(q) q:setPos(-480.5,   -0.5,   794,    62, xi.zone.ABYSSEA_LA_THEINE) end },
                { 'Back',      function(q) showRoot(q) end },
            },
        })
    end)
end

local function showScars(p)
    p:timer(30, function(pl)
        pl:customMenu({
            title   = 'Scars',
            options = {
                { 'Attohwa',   function(q) q:setPos(-134,    -20,    -182,   108, xi.zone.ABYSSEA_ATTOHWA)   end },
                { 'Misareaux', function(q) q:setPos( 670,    -15,     318,   119, xi.zone.ABYSSEA_MISAREAUX) end },
                { 'Vunkerl',   function(q) q:setPos(-351,    -46.75,  699.5,  10, xi.zone.ABYSSEA_VUNKERL)   end },
                { 'Back',      function(q) showRoot(q) end },
            },
        })
    end)
end

local function showHeroes(p)
    p:timer(30, function(pl)
        pl:customMenu({
            title   = 'Heroes',
            options = {
                { 'Altepa',     function(q) q:setPos( 435,     0,     320,   136, xi.zone.ABYSSEA_ALTEPA)     end },
                { 'Uleguerand', function(q) q:setPos(-238,   -40,    -520.5,   0, xi.zone.ABYSSEA_ULEGUERAND) end },
                { 'Grauberg',   function(q) q:setPos(-555,    31,    -760,     0, xi.zone.ABYSSEA_GRAUBERG)   end },
                { 'Back',       function(q) showRoot(q) end },
            },
        })
    end)
end

showRoot = function(p)
    p:timer(30, function(pl)
        pl:customMenu({
            title   = 'Abyssea Warp',
            options = {
                { 'Visions', function(q) showVisions(q) end },
                { 'Scars',   function(q) showScars(q)   end },
                { 'Heroes',  function(q) showHeroes(q)  end },
                { 'Close',   nil },
            },
        })
    end)
end

commandObj.onTrigger = function(player)
    showRoot(player)
end

return commandObj
