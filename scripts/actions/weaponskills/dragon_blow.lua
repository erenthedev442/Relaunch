-----------------------------------
-- Dragon Blow  (Prime weapon skill, WS id 230)
-- Hand-to-Hand weapon skill (Prime: "Prime Fists", item 21531)
-- Skill Level: N/A -- granted by equipping the Prime Fists.
-- Description: Delivers a twofold attack. Damage varies with TP.
-- Element: None   Skillchain: Liquefaction / Impaction
-- Modifiers: DEX 85%
-- 100%TP   200%TP   300%TP
-- 3.675    7.0      10.4375
-- Values from LSB mob capture scripts/actions/mobskills/dragon_blow.lua.
-- (Skillchain is best-effort -- not documented for this id.)
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 2
    params.ftpMod  = { 3.675, 7.0, 10.4375 }
    params.dex_wsc = 0.85

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
