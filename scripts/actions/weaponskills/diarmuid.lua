-----------------------------------
-- Diarmuid
-- Polearm weapon skill (Prime: "Prime Lance", item 21887)
-- Skill Level: N/A -- granted by equipping the Prime Lance.
-- Description: Delivers a twofold attack. Damage varies with TP.
-- Element: None   Skillchain: Distortion / Scission / Transfixion
-- Modifiers: STR 55% / VIT 55%
-- 100%TP   200%TP   300%TP
-- 2.17     5.36     8.55
-- Values from LSB mob capture scripts/actions/mobskills/diarmuid.lua.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits     = 2
    params.ftpMod      = { 2.17, 5.36, 8.55 }
    params.multiHitfTP = true
    params.str_wsc     = 0.55
    params.vit_wsc     = 0.55

    -- Prime Aftermath (TP-tiered Lv.1/2/3), applied from the weapon's own WS.
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.PRIME)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
