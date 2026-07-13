-----------------------------------
-- Tachi: Mumei
-- Great Katana weapon skill (Prime / Kusanagi-no-Tsurugi)
-- Skill Level: N/A -- granted by equipping the Kusanagi-no-Tsurugi.
-- Description: Single-hit attack. Damage varies with TP.
-- Element: None   Skillchain: Detonation / Compression / Distortion
-- Modifiers: STR 50% / DEX 50%
--                   100%TP   200%TP   300%TP
-- Retail ftpMod     3.66     7.33     11.0
-- Relaunch ftpMod   4.5      9.0      13.5    (matches Legendary damage output)
-- Single-hit WS, so multiHitfTP is moot.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 4.5, 9.0, 13.5 }
    params.str_wsc = 0.5
    params.dex_wsc = 0.5

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
