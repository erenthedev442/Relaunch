-----------------------------------
-- trust_meat_vendor.lua  --  RETIRED 2026-06-06
--
-- The Meat trust (spell 899) is now sold by the Void Keeper (trust_skoll.lua),
-- the single GM Home vendor for ALL custom trusts. This standalone "Bulwark
-- Keeper" NPC was folded in to avoid a second, easy-to-miss vendor (it was a
-- plain Moogle a few units from the Void Keeper, simple to walk past).
--
-- Kept as a loaded no-op rather than deleted: a tar-extract deploy overwrites
-- the old spawning version on the box, and on the next map restart the Bulwark
-- Keeper simply stops appearing. Meat's spell/pool registration is unaffected
-- (modules/custom/sql/trust_meat.sql); only the duplicate NPC is removed.
--
-- To bring a standalone Meat vendor back, restore from git history.
-----------------------------------
require('modules/module_utils')

local m = Module:new('meat_vendor')

return m
