-----------------------------------
-- ID: 6500
-- Item: Abdhaljs Seal
-- Hold into a party Ambuscade clear to triple that run's Gallantry.
-- Using the item does nothing and must not consume it.
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    if target and target.printToPlayer then
        target:printToPlayer(
            '[Ambuscade] Keep the Seal in your inventory. A party clear consumes one and triples Gallantry. Using it does nothing.',
            xi.msg.channel.SYSTEM_3)
    end
    return xi.msg.basic.ITEM_UNABLE_TO_USE
end

itemObject.onItemUse = function(target, user)
end

return itemObject
