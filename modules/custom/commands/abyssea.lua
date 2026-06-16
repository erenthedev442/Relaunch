-----------------------------------
-- !abyssea
-- Warp to any Abyssea zone.
-- Drops you at the standard Cavernous Maw entry position.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:customMenu({
        title = 'Abyssea Warp',
        options = {
            { 'Konschtat',        function(p) p:setPos(153,    -72,    -840,   140, xi.zone.ABYSSEA_KONSCHTAT)        end },
            { 'Tahrongi',         function(p) p:setPos(-24,     44,    -678,   240, xi.zone.ABYSSEA_TAHRONGI)         end },
            { 'La Theine',        function(p) p:setPos(-480.5,  -0.5,   794,    62, xi.zone.ABYSSEA_LA_THEINE)        end },
            { 'Attohwa',          function(p) p:setPos(-134,   -20,    -182,   108, xi.zone.ABYSSEA_ATTOHWA)          end },
            { 'Misareaux',        function(p) p:setPos(670,    -15,     318,   119, xi.zone.ABYSSEA_MISAREAUX)        end },
            { 'Vunkerl',          function(p) p:setPos(-351,   -46.75,  699.5,  10, xi.zone.ABYSSEA_VUNKERL)         end },
            { 'Altepa',           function(p) p:setPos(435,      0,     320,   136, xi.zone.ABYSSEA_ALTEPA)           end },
            { 'Uleguerand',       function(p) p:setPos(-238,   -40,    -520.5,   0, xi.zone.ABYSSEA_ULEGUERAND)       end },
            { 'Grauberg',         function(p) p:setPos(-555,    31,    -760,     0, xi.zone.ABYSSEA_GRAUBERG)         end },
            { 'Empyreal Paradox', function(p) p:setPos(540,   -500,    -571,    64, xi.zone.ABYSSEA_EMPYREAL_PARADOX) end },
            { 'Close', nil },
        },
    })
end

return commandObj
