-----------------------------------
-- RonfaureSFarm4.lua
-- Second East Ronfaure [S] Capacity camp (south/water square).
-- 80 Capacity Phantoms: colibri / ladybug / pugil / crab.
-- Access via !capacity4 or !capacity 4.
--
-- Logic: capacity_farm_engine.lua  |  Tuning: ronfaure_s_farm4_catalog.lua
-----------------------------------
local makeFarm = require('modules/custom/lua/capacity_farm_engine')
local catalog  = require('modules/custom/lua/ronfaure_s_farm4_catalog')
return makeFarm(catalog)
