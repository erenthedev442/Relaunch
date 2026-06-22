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

-- Track peak pet WS / Blood Pact hit into the master's WSMaxDmg personal best.
-- Avatars fire WEAPONSKILL_USE on the pet entity with true uncapped BP damage.
-- Automatons and BST jug pets use the same path for their WS/Ready moves.
m:addOverride('xi.pet.spawnPet', function(caster, petID, state, target)
    super(caster, petID, state, target)
    if not caster or not caster:isPC() then return end
    local pet = caster:getPet()
    if not pet then return end
    pet:addListener('WEAPONSKILL_USE', 'WS_PET_DMG_TRACKER', function(petArg, tgt, skill, tp, action, damage)
        if not damage or damage <= 0 then return end
        local master = petArg:getMaster()
        if not master or not master:isPC() then return end
        local stored = master:getCharVar('WSMaxDmg')
        if damage > stored then
            master:setCharVar('WSMaxDmg', damage)
            master:setCharVar('WSMaxDmgSkillId', skill:getID())
        end
    end)
end)

return m
