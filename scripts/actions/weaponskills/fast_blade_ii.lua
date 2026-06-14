-----------------------------------
-- Fast Blade II  (Prime weapon skill, WS id 229)
-- Sword weapon skill (Prime: Naegling, item 21621)
-- Skill Level: N/A -- granted by equipping Naegling.
-- Description: Delivers a twofold attack. Damage varies with TP.
-- Element: None   Skillchain: Scission / Transfixion
-- Modifiers: DEX 80%
-- 100%TP   200%TP   300%TP
-- 2.75     5.5      8.0
-- NOTE: 229 is a Prime-tier stub in LSB with no real captured retail values
-- (the mob capture reuses basic Fast Blade numbers). fTP and skillchain here
-- are best-effort, tuned to fit alongside the other Prime weapon skills.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 2
    params.ftpMod  = { 2.75, 5.5, 8.0 }
    params.dex_wsc = 0.8

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
