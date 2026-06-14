-----------------------------------
-- Fimbulvetr
-- Great Sword weapon skill (Prime / Helheim)
-- Skill Level: N/A -- granted by equipping the Helheim.
-- Description: Single-hit attack. Damage varies with TP.
-- Element: None   Skillchain: Detonation / Compression / Distortion
-- Modifiers: STR 60% / VIT 60%
-- 100%TP   200%TP   300%TP
-- 3.3      6.6      9.9
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 3.3, 6.6, 9.9 }
    params.str_wsc = 0.6
    params.vit_wsc = 0.6

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
