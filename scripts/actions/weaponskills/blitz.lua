-----------------------------------
-- Blitz
-- Axe weapon skill (Prime / Spalirisos)
-- Skill Level: N/A -- granted by equipping the Spalirisos.
-- Description: Delivers a fivefold attack. Damage varies with TP.
-- Element: None   Skillchain: Liquefaction / Impaction / Fragmentation
-- Modifiers: STR 32% / DEX 32%
-- 100%TP   200%TP   300%TP
-- 1.5      7.0      12.5
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits     = 5
    params.ftpMod      = { 1.5, 7.0, 12.5 }
    params.multiHitfTP = true
    params.str_wsc     = 0.32
    params.dex_wsc     = 0.32

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
