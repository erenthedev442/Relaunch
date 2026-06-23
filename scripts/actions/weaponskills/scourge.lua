    -----------------------------------
-- Scourge
-- Great Sword weapon skill
-- Skill level: N/A
-- Additional effect: temporarily improves params.critical hit rate.
-- params.critical hit rate boost duration is based on TP when the weapon skill is used. 100% TP will give 20 seconds of params.critical hit rate boost this scales linearly to 60 seconds of params.critical hit rate boost at 300% TP. 5 TP = 1 Second of Aftermath.
-- Parses show the params.critical hit rate increase from the Scourge Aftermath is between 10% and 15%.
-- This weapon skill is only available with the stage 5 relic Great Sword Ragnarok or within Dynamis with the stage 4 Valhalla.
-- Aligned with the Light Gorget & Flame Gorget.
-- Aligned with the Light Belt & Flame Belt.
-- Element: None
-- Modifiers: STR:40%  VIT:40%
-- 100%TP    200%TP    300%TP
-- 3.00      3.00      3.00
--
-- LEGENDARY (2026-06-23): Scourge is now a TRUE crit WS -- params.critVaries gives
-- its hit +25%/+50%/+100% crit rate by TP (guaranteed crit at 300% TP). Ragnarok's
-- aftermath was also buffed from retail +5/+10% crit to a real crit-rate +
-- crit-damage cooldown (see aftermath.lua [4]/[18]).
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits = 1
    params.ftpMod = { 3.0, 3.0, 3.0 }
    params.mnd_wsc = 0.4 params.chr_wsc = 0.4

    -- LEGENDARY: Scourge is now a TRUE crit WS -- its hit crit-scales with TP
    -- (+25% crit @100% TP -> guaranteed crit @300% TP), like Evisceration. The
    -- aftermath (applied below, BEFORE the hit) layers its crit-rate + crit-damage
    -- on top, so a high-TP Scourge lands a hard crit and leaves the buff running.
    params.critVaries = { 0.25, 0.50, 1.00 }

    if xi.settings.main.USE_ADOULIN_WEAPON_SKILL_CHANGES then
        params.str_wsc = 0.4 params.vit_wsc = 0.4 params.mnd_wsc = 0.0 params.chr_wsc = 0.0
    end

    -- Apply aftermath
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.RELIC)

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)

    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
