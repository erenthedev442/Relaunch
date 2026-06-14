-----------------------------------
-- Dagda
-- Club weapon skill (Prime: Lorg Mor / "Prime Maul", item 21999)
-- Skill Level: N/A -- granted by equipping the Prime Maul.
-- Description: Delivers a twofold attack. Damage varies with TP.
-- Element: None   Skillchain: Transfixion / Scission / Gravitation
-- Modifiers: STR 50% / MND 50%
-- 100%TP   200%TP   300%TP
-- 3.0      6.5      10.0
-- NOTE: retail fTP for Dagda is undocumented (LSB mob capture is a {1,1,1}
-- placeholder); the fTP below is an estimate tuned to sit between the other
-- 2-hit Prime weapon skills. Adjust in this file if you want it stronger/weaker.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 2
    params.ftpMod  = { 3.0, 6.5, 10.0 }
    params.str_wsc = 0.5
    params.mnd_wsc = 0.5

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
