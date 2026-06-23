-----------------------------------
-- Asuran Fists
-- Hand-to-Hand weapon skill
-- Skill Level: 250
-- Delivers an eightfold attack. Accuracy varies with TP.
-- Physical hits + Light-elemental magic finisher that scales with MND.
-- Element: Light
-- Modifiers: STR:10%  MND:20%
-- Physical fTP   100%TP    200%TP    300%TP
--                 4.0       4.25      4.5
-- Magic fTP      100%TP    200%TP    300%TP
--                 0.30      0.40      0.50  (× total physical dmg, boosted by MAB)
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local params = {}
    params.numHits        = 8
    params.ftpMod         = { 4.0, 4.25, 4.5 }
    params.str_wsc        = 0.1
    params.mnd_wsc        = 0.2
    params.accVaries      = { 0, 30, 60 }
    params.critVaries     = { 0.10, 0.20, 0.30 }
    params.hybridWS       = true
    params.hybridFtpMod   = { 0.30, 0.40, 0.50 }
    params.ele            = xi.element.LIGHT
    params.skill          = xi.skill.HAND_TO_HAND
    params.includemab     = true

    if xi.settings.main.USE_ADOULIN_WEAPON_SKILL_CHANGES then
        params.multiHitfTP    = true
        params.str_wsc        = 0.15
        params.mnd_wsc        = 0.25
        params.critVaries     = { 0.15, 0.25, 0.40 }
        params.hybridFtpMod   = { 0.35, 0.50, 0.65 }
    end

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)
    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
