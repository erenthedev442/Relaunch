-----------------------------------
-- trust_cipher_usable.lua
-- Trust Cipher items (10112-10193) are used like scrolls:
-- use item -> learn trust -> consume cipher.
--
-- Engine path: OnItemCheck/OnItemUse load ./scripts/items/<item_basic.name>.lua
-- Those stubs return scripts/items/_trust_cipher.lua.
--
-- Also requires modules/custom/sql/trust_cipher_usable.sql
-- (item type=usable + item_usable rows). Apply via dbtool / deploy SQL.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('trust_cipher_usable')

-- No runtime registration needed — C++ loads scripts/items/*.lua by filename.
-- Module kept so the feature is discoverable in modules/custom/lua and so
-- onServerStart can warn if a stub is missing after a catalog change.
local catalog = require('modules/custom/lua/trust_cipher_catalog')

m:addOverride('xi.server.onServerStart', function()
    super()

    local missing = 0
    for _, itemName in ipairs(catalog.itemNames) do
        local path = string.format('scripts/items/%s.lua', itemName)
        local f = io.open(path, 'r')
        if f then
            f:close()
        else
            missing = missing + 1
            print(string.format('[trust_cipher_usable] MISSING item script: %s', path))
        end
    end

    if missing == 0 then
        print(string.format('[trust_cipher_usable] %d cipher item scripts present.', #catalog.itemNames))
    else
        print(string.format('[trust_cipher_usable] WARNING: %d cipher item script(s) missing.', missing))
    end
end)

return m
