-----------------------------------
-- Ruthless Stroke
-- Dagger weapon skill (Prime / Mpu Gandring)
-- Skill Level: N/A -- granted by equipping the Mpu Gandring.
-- Description: Delivers a fourfold attack. Damage varies with TP.
-- Element: None   Skillchain: Liquefaction / Impaction / Fragmentation
-- Modifiers: DEX 32% / AGI 32%  (retail 25%; Prime tier lifts wsc for endgame scaling.
--                                Retail also changed from DEX/VIT to DEX/AGI in the March 2024 update.)
--                   100%TP   200%TP   300%TP
-- Retail ftpMod     5.375    14.0     23.0
-- Relaunch ftpMod   6.5      16.5     27.0    (matches Legendary damage output)
-- fTP is single-hit only (no multiHitfTP): matches Legendary's damage model.
-- NOTE: In-game first SC prop is erroneously labelled "Dissolution"; real value is Liquefaction.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 4
    params.ftpMod  = { 6.5, 16.5, 27.0 }
    params.dex_wsc = 0.32
    params.agi_wsc = 0.32

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
