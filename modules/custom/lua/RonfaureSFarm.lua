-----------------------------------
-- RonfaureSFarm.lua
-- Capacity Point farm in East Ronfaure [S] (zone 81).
-- 80 always-up Capacity Phantoms (sheep / goblin / rabbit / beetle).
-- Access via !capacity3 or !capacity ronfaure.
--
-- Logic: capacity_farm_engine.lua  |  Tuning: ronfaure_s_farm_catalog.lua
-----------------------------------
local makeFarm = require('modules/custom/lua/capacity_farm_engine')
local catalog  = require('modules/custom/lua/ronfaure_s_farm_catalog')
return makeFarm(catalog)
