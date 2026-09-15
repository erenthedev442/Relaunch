-----------------------------------
-- Apex Arrow
-- Archery weapon skill
-- Skill level: 357
-- Merit
-- RNG or SAM
-- Aligned with the Thunder & Light Gorget.
-- Aligned with the Thunder Belt & Light Belt.
-- Element: None
-- Modifiers: AGI:73~85%
-- 100%TP    200%TP    300%TP
-- 3.00      3.00      3.00
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod = { 4.5, 4.5, 4.5 }
    params.agi_wsc = xi.weaponskills.getMeritWeaponSkillWSC(player, xi.merit.APEX_ARROW)
    params.ignoredDefense = { 0.15, 0.35, 0.5 }

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doRangedWeaponskill(player, target, wsID, params, tp, action, primary)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
