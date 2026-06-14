-----------------------------------
-- ID: 6717
-- Item: Trust Magic Tome
-- Use: Grants 100 alter ego points.
-- Source: Event rewards; one given on system unlock by Syndella in Ru'Lude Gardens. Added March 2026.
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return 0
end

itemObject.onItemUse = function(target, user, item, action)
    user:addCurrency('alter_ego_points', 100, 65535)
    -- See trust_magic_primer.lua note. Real MsgBasic ID still pending.
    user:printToPlayer(string.format('You obtain 100 alter ego points. Total: %d.',
        user:getCurrency('alter_ego_points')))
end

return itemObject
