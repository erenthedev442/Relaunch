-----------------------------------
-- Nyzul objective reliability
--
-- Objective deaths must credit party-controlled kills (Trusts, Fellows and
-- pets), not only direct player killing blows. Spawn generation marks each
-- objective mob with a role; this global death hook supplies a single,
-- deduplicated fallback when the individual mob script did not credit it.
-----------------------------------
require('modules/module_utils')

local m = Module:new('nyzul_reliability')

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if not mob or mob:getZoneID() ~= xi.zone.NYZUL_ISLE or not mob:getInstance() then
        return
    end

    local role = mob:getLocalVar('NyzulObjectiveRole')
    if role == 1 then
        xi.nyzul.enemyLeaderKill(mob)
    elseif role == 2 then
        xi.nyzul.specifiedGroupKill(mob)
    elseif role == 3 then
        xi.nyzul.specifiedEnemyKill(mob)
    elseif role == 4 then
        xi.nyzul.eliminateAllKill(mob)
    end
end)

return m
