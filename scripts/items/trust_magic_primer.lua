-----------------------------------
-- ID: 6716
-- Item: Trust Magic Primer
-- Use: Grants 20 alter ego points.
-- Source: Records of Eminence monthly objectives. Added March 2026 retail update.
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return 0
end

itemObject.onItemUse = function(target, user, item, action)
    user:addCurrency('alter_ego_points', 20, 65535)
    -- TODO: NOT CAPTURE-VERIFIED — retail "<player> receives # alter ego points."
    -- line uses a MsgBasic ID we can't pin down without a no-filter PacketLogger
    -- capture. Tested 829 (silent — bare SystemMessage header). Until the real
    -- ID is captured, printToPlayer keeps the user informed.
    user:printToPlayer(string.format('You obtain 20 alter ego points. Total: %d.',
        user:getCurrency('alter_ego_points')))
end

return itemObject
