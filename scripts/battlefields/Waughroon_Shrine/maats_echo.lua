-----------------------------------
-- Area: Waughroon Shrine
-- Name: Maat's Echo (Relaunch Infamy challenge)
--
-- Thin Battlefield:new() wrapper. Dialogue, KI, Palborough warp, scaling,
-- rewards, and the 2-companion cap live in modules/custom/lua/maat_infamy_fight.lua.
-- Loaded with the other BCNMs so the Battlefield class is available.
-----------------------------------
return require('modules/custom/lua/maat_infamy_fight').registerBattlefield()
