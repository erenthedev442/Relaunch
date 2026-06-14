-----------------------------------
-- Terminus
-- Marksmanship (Gun) weapon skill (Prime: "Prime Gun", item 22159)
-- Skill Level: N/A -- granted by equipping the Prime Gun.
-- Description: Single ranged attack. Damage varies with TP. Requires bullets.
-- Element: None   Skillchain: Fusion / Induration / Reverberation
-- Modifiers: DEX 70% / AGI 70%
-- 100%TP   200%TP   300%TP
-- 2.5      5.0      7.5
-- Ranged WS -> doRangedWeaponskill (no taChar). Values from LSB mob capture
-- scripts/actions/mobskills/terminus.lua.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 2.5, 5.0, 7.5 }
    params.dex_wsc = 0.7
    params.agi_wsc = 0.7

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doRangedWeaponskill(player, target, wsID, params, tp, action, primary)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
