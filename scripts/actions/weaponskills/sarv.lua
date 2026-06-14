-----------------------------------
-- Sarv
-- Archery (Bow) weapon skill (Prime: "Prime Bow", item 22155)
-- Skill Level: N/A -- granted by equipping the Prime Bow.
-- Description: Single ranged attack. Damage varies with TP. Requires arrows.
-- Element: None   Skillchain: Gravitation / Scission / Transfixion
-- Modifiers: STR 65% / AGI 65%
-- 100%TP   200%TP   300%TP
-- 2.75     5.5      8.25
-- Ranged WS -> doRangedWeaponskill (no taChar). Values from LSB mob capture
-- scripts/actions/mobskills/sarv.lua.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 2.75, 5.5, 8.25 }
    params.str_wsc = 0.65
    params.agi_wsc = 0.65

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doRangedWeaponskill(player, target, wsID, params, tp, action, primary)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
