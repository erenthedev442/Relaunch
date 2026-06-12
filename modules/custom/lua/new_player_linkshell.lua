-----------------------------------
-- new_player_linkshell.lua  (RETIRED 2026-06-12)
-- Used to hand every new character a linkpearl on creation, but the
-- linkshell name was never chosen (shipped as the literal placeholder
-- 'InsertLsNameHere') and the owner decided against an auto-granted
-- linkshell altogether. Kept as a no-op stub instead of being deleted so
-- "Deploy to Server.bat" (which overwrites but does not delete) pushes the
-- disable to the live box. Safe to delete once removed server-side too.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('new_player_linkshell')

return m
