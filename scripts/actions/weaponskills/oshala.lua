-----------------------------------
-- Oshala
-- Staff weapon skill (Prime: Opashoro / "Prime Staff", item 22102)
-- Skill Level: N/A -- granted by equipping the Prime Staff.
-- Description: Single-hit attack. Damage varies with TP.
-- Element: None   Skillchain: Induration / Reverberation / Fusion
-- Modifiers: MND 45% / INT 45%
-- 100%TP   200%TP   300%TP
-- 3.95     7.89     11.84
-- NOTE: Oshala scales off mental stats but is mechanically a PHYSICAL weapon
-- skill (pDIF, attack, physical damage limit) -- NOT a magic-damage WS.
-- Values from LSB mob capture scripts/actions/mobskills/oshala.lua.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 3.95, 7.89, 11.84 }
    params.mnd_wsc = 0.45
    params.int_wsc = 0.45

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
