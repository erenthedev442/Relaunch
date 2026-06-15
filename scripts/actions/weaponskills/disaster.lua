-----------------------------------
-- Disaster
-- Great Axe weapon skill (Prime: "Prime Great Axe", item 21781)
-- Skill Level: N/A -- granted by equipping the Prime Great Axe.
-- Description: Single-hit attack. Damage varies with TP.
-- Element: None   Skillchain: Gravitation / Scission / Transfixion
-- Modifiers: STR 60% / VIT 60%
-- 100%TP   200%TP   300%TP
-- 3.05     6.1      9.15
-- Values from LSB mob capture scripts/actions/mobskills/disaster.lua.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 3.05, 6.1, 9.15 }
    params.str_wsc = 0.6
    params.vit_wsc = 0.6

    -- Prime Aftermath (TP-tiered Lv.1/2/3), applied from the weapon's own WS.
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.PRIME)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
