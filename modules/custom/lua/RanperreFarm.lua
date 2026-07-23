-----------------------------------
-- RanperreFarm.lua
-- Capacity Point farm in King Ranperre's Tomb (zone 190).
--
-- 100 always-up Lv150-160 Capacity Phantoms with 120k HP.
-- Automatic respawn, shared claim, no loot or EXP. Access via !ranperre.
--
-- Logic: capacity_farm_engine.lua  |  Tuning: ranperre_farm_catalog.lua
-----------------------------------
local makeFarm = require('modules/custom/lua/capacity_farm_engine')
local catalog  = require('modules/custom/lua/ranperre_farm_catalog')
return makeFarm(catalog)
