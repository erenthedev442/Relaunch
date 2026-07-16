-----------------------------------
-- Zesho Meppo
-- Katana weapon skill (Prime / Dokoku)
-- Skill Level: N/A -- granted by equipping the Dokoku.
-- Description: Delivers a fourfold attack. Damage varies with TP.
-- Element: None   Skillchain: Induration / Reverberation / Fusion
-- Modifiers: DEX 25% / AGI 25%
-- 100%TP   200%TP   300%TP
-- 4.0      11.3*    18.715
-- (* 2000 TP fTP not published on BG-Wiki; linearly interpolated -- TODO verify)
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits     = 4
    params.ftpMod      = { 4.0, 11.3, 18.715 }
    params.multiHitfTP = true
    params.dex_wsc     = 0.25
    params.agi_wsc     = 0.25

    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.PRIME)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
