-----------------------------------
-- Imperator
-- Sword weapon skill (Prime: Caliburnus / "Prime Sword", item 21642)
-- Skill Level: N/A -- granted by equipping the Prime Sword.
-- Description: Single-hit attack. Damage varies with TP.
-- Element: None   Skillchain: Detonation / Compression / Distortion
-- Modifiers: DEX 70% / MND 70%
-- 100%TP   200%TP   300%TP
-- 3.75     7.5      11.75
-- Values from LSB mob capture scripts/actions/mobskills/imperator.lua.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 3.75, 7.5, 11.75 }
    params.dex_wsc = 0.7
    params.mnd_wsc = 0.7

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
