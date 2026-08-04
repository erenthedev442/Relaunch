-----------------------------------
-- trust_cipher_usable.lua
-- Trust Ciphers are RETIRED. Content unlocks teach the spell directly
-- (trust_cipher_drops → xi.trustGrant.grantSpell). Leftover inventory
-- ciphers are converted on login by trust_grant_gate.
--
-- Item scripts under scripts/items/cipher_of_*.lua are kept only so any
-- straggler Use still routes through _trust_cipher → grantSpell.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('trust_cipher_usable')

m:addOverride('xi.server.onServerStart', function()
    super()
    print('[trust_cipher_usable] Ciphers retired — content drops teach Alter Egos directly.')
end)

return m
