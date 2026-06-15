-----------------------------------
-- Dagda
-- Club weapon skill (Prime: Lorg Mor / "Prime Maul", item 21999)
-- Skill Level: N/A -- granted by equipping the Prime Maul.
-- Description: Delivers a twofold attack. Damage varies with TP.
-- Element: None   Skillchain: Transfixion / Scission / Gravitation
-- Modifiers: STR 40% / MND 40%  (community consensus per FFXIAH topic 57318,
--   reverse-engineered by Bolmster + SimonSes, 2026-01-26)
-- 100%TP   200%TP   300%TP
-- 4.3      8.87*    13.5
-- (* 2k fTP interpolated; SimonSes warned linearity not confirmed for Dagda)
-- NOTE: WSC changed from INT/MND to STR/MND in the March 2024 retail update.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits     = 2
    params.ftpMod      = { 4.3, 8.87, 13.5 }
    params.multiHitfTP = true
    params.str_wsc     = 0.4
    params.mnd_wsc     = 0.4

    -- Prime Aftermath (TP-tiered Lv.1/2/3), applied from the weapon's own WS.
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.PRIME)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
