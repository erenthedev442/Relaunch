-----------------------------------
-- WSTracker - Weapon Skill damage leaderboard
--
-- Registers a WEAPONSKILL_USE listener on every player on zone-in.
-- When a WS hit exceeds the stored personal best, updates two charVars:
--   WSMaxDmg      -- the peak damage value
--   WSMaxDmgSkillId -- the weapon skill ID that set the record
--
-- The fixed listener key ('WS_DMG_TRACKER') makes this idempotent across
-- every zone-in; re-registering replaces the old listener safely.
-- Needs one map restart to take effect (onGameIn override).
-----------------------------------
require('modules/module_utils')

local m = Module:new('ws_damage_tracker')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    player:addListener('WEAPONSKILL_USE', 'WS_DMG_TRACKER', function(attacker, target, skill, tp, action, damage)
        if not damage or damage <= 0 then return end
        local stored = attacker:getCharVar('WSMaxDmg')
        if damage > stored then
            attacker:setCharVar('WSMaxDmg', damage)
            attacker:setCharVar('WSMaxDmgSkillId', skill:getID())
        end
    end)
end)

return m
