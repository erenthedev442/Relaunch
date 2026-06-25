local commandObj = {}
commandObj.cmdprops = { permission = 0, parameters = '' }
commandObj.onTrigger = function(player)
    player:setPos(-114.0, -2.15, -88.0, 0, xi.zone.CELENNIA_MEMORIAL_LIBRARY)
end
return commandObj
