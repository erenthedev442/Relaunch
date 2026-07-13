-----------------------------------
--  MOB: Stealth Bomber Gagaroo
-- Area: Nyzul Isle
-- Info: Enemy Leader (Qiqirn). Script was MISSING on relaunch, so when this mob
--       was the randomly-picked "Eliminate the enemy leader" target -- directly,
--       or via the +18(Qiqirn_Mine)->+19 redirect in floor_generation -- killing
--       it never fired enemyLeaderKill, so the objective could not complete
--       ("Enemy Leader, no leader" report 2026-07-13). Mirrors its sibling
--       Quick_Draw_Sasaroon.
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobDeath = function(mob, player, optParams)
    if optParams.isKiller or optParams.noKiller then
        xi.nyzul.spawnChest(mob, player)
        xi.nyzul.enemyLeaderKill(mob)
    end
end

return entity
