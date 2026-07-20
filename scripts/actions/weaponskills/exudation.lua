-----------------------------------
-- Exudation
-- Club weapon skill
-- Delivers a single attack. Attack varies with TP.
-- Modifiers: INT 50%, MND 50%
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits   = 1
    params.ftpMod    = { 2.8, 2.8, 2.8 }
    params.atkVaries = { 1.5, 3.625, 4.75 }
    params.int_wsc   = 0.5
    params.mnd_wsc   = 0.5

    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.MYTHIC)

    local damage, criticalHit, tpHits, extraHits =
        xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)

    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
