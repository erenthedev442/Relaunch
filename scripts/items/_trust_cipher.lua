-----------------------------------
-- Shared handler for Trust Cipher items (10112-10193).
-- Registered on xi.items.* at server start by trust_cipher_usable.lua.
-- Use item -> learn trust spell, consume cipher (scroll-like).
-----------------------------------
---@type TItem
local itemObject = {}

itemObject.onItemCheck = function(target, item, param, caster)
    return xi.trust.onItemCheckCipher(target, item)
end

itemObject.onItemUse = function(target, user, item, action)
    xi.trust.onItemUseCipher(target, item)
end

return itemObject
