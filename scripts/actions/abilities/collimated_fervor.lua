-----------------------------------
-- Ability: Collimated Fervor  (repurposed: Bouncer "Bodyguard")
--
-- Stock LSB ships NO player action file for collimated_fervor (ability 348) --
-- it only exists as an empty effect + an unused job_utils handler -- so this
-- additive file completes that gap.  For the custom "Bouncer" tank job (the
-- repurposed GEO/job 21 slot) it grants a brief full-invulnerability window to
-- a targeted party member ("Bodyguard").
--
-- The behaviour itself lives in modules/custom/lua/bouncer_abilities.lua, which
-- overrides xi.job_utils.geomancer.collimatedFervor.  The check is intentionally
-- open: the Bouncer kit drops GEO's "requires luopan" gate (the Bouncer has no
-- luopan).  Safe to ship because GEO == Bouncer on this server.
-----------------------------------
---@type TAbility
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0, 0
end

abilityObject.onUseAbility = function(player, target, ability, action)
    return xi.job_utils.geomancer.collimatedFervor(player, target, ability)
end

return abilityObject
