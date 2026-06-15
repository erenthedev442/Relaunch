-----------------------------------
-- Merciless Strike  (retail name: Ruthless Stroke)
-- Dagger weapon skill (Prime: Mpu Gandring, item 21589)
-- Skill Level: N/A -- granted by equipping Mpu Gandring.
-- Description: Delivers a fourfold attack. Damage varies with TP.
-- Element: None   Skillchain: Liquefaction / Impaction / Fragmentation
-- Modifiers: DEX 25% / AGI 25%
-- 100%TP   200%TP   300%TP
-- 5.375    14.0     23.0
-- (The weapon_skills row keeps LSB's internal name "merciless_strike"; the
-- client shows whatever name it has for WS id 232.)
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 4
    params.ftpMod  = { 5.375, 14.0, 23.0 }
    params.dex_wsc = 0.25
    params.agi_wsc = 0.25

    -- Prime Aftermath (TP-tiered Lv.1/2/3), applied from the weapon's own WS.
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.PRIME)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
