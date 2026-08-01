-----------------------------------
-- trust_cipher_usable.lua
-- Register Trust Cipher items (10112-10193) as scroll-like usables:
-- use item -> learn trust -> consume cipher.
--
-- Requires modules/custom/sql/trust_cipher_usable.sql (item type + item_usable rows).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
-----------------------------------
local m = Module:new('trust_cipher_usable')

local catalog    = require('modules/custom/lua/trust_cipher_catalog')
local cipherItem = require('scripts/items/_trust_cipher')

local function registerCipherHandlers()
    xi.items = xi.items or {}

    for _, itemName in ipairs(catalog.itemNames) do
        xi.items[itemName] = xi.items[itemName] or {}
        xi.items[itemName].onItemCheck = cipherItem.onItemCheck
        xi.items[itemName].onItemUse   = cipherItem.onItemUse
    end
end

m:addOverride('xi.server.onServerStart', function()
    super()
    registerCipherHandlers()
end)

return m
