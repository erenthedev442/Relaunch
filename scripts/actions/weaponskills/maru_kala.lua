-----------------------------------
-- Maru Kala
-- Hand-to-Hand weapon skill
-- Skill Level: N/A -- unlocked by equipping Varga Purnikawa (item 21534/21535),
--              whose ADDS_WEAPONSKILL mod grants weapon skill 231.
-- Description: Delivers a twofold attack. Damage varies with TP.
-- Element: None
-- Skillchain Properties: Detonation / Compression / Distortion
-- Modifiers: STR:41.75% DEX:41.75%
-- 100%TP    200%TP    300%TP
-- 3.128     7.273     11.414
--
-- Note: Maru Kala is the Prime weapon skill for Varga Purnikawa. The Prime
-- "Aftermath: varies with TP" is intentionally NOT applied here -- LSB has no
-- PRIME aftermath type (only RELIC/MYTHIC/EMPYREAN), so there is nothing to
-- hook into. The core twofold physical hit + skillchain works as retail.
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 2
    params.ftpMod  = { 3.128, 7.273, 11.414 }
    params.str_wsc = 0.4175
    params.dex_wsc = 0.4175

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)

    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
