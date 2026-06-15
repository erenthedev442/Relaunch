-----------------------------------
-- Imperator
-- Sword weapon skill (Prime: Caliburnus / "Prime Sword", item 21642)
-- Skill Level: N/A -- granted by equipping the Prime Sword.
-- Description: Single-hit attack. Damage varies with TP.
-- Element: None   Skillchain: Detonation / Compression / Distortion
-- Modifiers: DEX 27% / MND 27%  (community consensus: Aspens 27%/za_ibd 26%/Anillla 28%;
--   BG-Wiki's 70/70 + {3.75/7.5/11.75} are WRONG -- superseded by player testing)
-- 100%TP   200%TP   300%TP
-- 6.6      13.35    20.1
-- (za_ibd 256ths precision: 1722/256, 3444/256, 5164/256)
-- Source: FFXIAH topic 57318 + https://x.com/za_ibd/status/1881683907923603591
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod  = { 6.6, 13.35, 20.1 }
    params.dex_wsc = 0.27
    params.mnd_wsc = 0.27

    -- Prime Aftermath (TP-tiered Lv.1/2/3), applied from the weapon's own WS.
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.PRIME)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
