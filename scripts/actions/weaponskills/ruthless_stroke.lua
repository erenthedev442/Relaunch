-----------------------------------
-- Ruthless Stroke
-- Dagger weapon skill (Prime / Mpu Gandring)
-- Skill Level: N/A -- granted by equipping the Mpu Gandring.
-- Description: Delivers a fourfold attack. Damage varies with TP.
-- Element: None   Skillchain: Liquefaction / Impaction / Fragmentation
-- Modifiers: DEX 25% / AGI 25%  (changed from DEX/VIT in the March 2024 retail update)
-- 100%TP   200%TP   300%TP
-- 5.375    14.0     23.0
-- NOTE: In-game first SC prop is erroneously labelled "Dissolution"; real value is Liquefaction.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits     = 4
    params.ftpMod      = { 5.375, 14.0, 23.0 }
    params.multiHitfTP = true
    params.dex_wsc     = 0.25
    params.agi_wsc     = 0.25

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
