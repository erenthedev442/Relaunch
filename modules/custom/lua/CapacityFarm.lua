-----------------------------------
-- CapacityFarm.lua
-- Capacity Point farm in Bibiki Bay (zone 4).
--
-- All logic lives in capacity_farm_engine.lua (shared with other farm
-- zones). All tuning lives in capacity_farm_catalog.lua.
-- See those files for design notes, cap commentary, etc.
-----------------------------------
local makeFarm = require('modules/custom/lua/capacity_farm_engine')
local catalog  = require('modules/custom/lua/capacity_farm_catalog')
return makeFarm(catalog)
