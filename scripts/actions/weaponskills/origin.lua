-----------------------------------
-- Origin
-- Scythe weapon skill (Prime: "Prime Scythe", item 21833)
-- Skill Level: N/A -- granted by equipping the Prime Scythe.
-- Description: Single-hit attack that absorbs HP and MP. Damage varies with TP.
-- Element: None   Skillchain: Fusion / Induration / Reverberation
-- Modifiers: STR 60% / INT 60%
-- 100%TP   200%TP   300%TP
-- 3.0      6.0      9.0
-- Values from LSB mob capture scripts/actions/mobskills/origin.lua, including
-- its HP/MP drain (absorb is clamped to the target's HP/MP; undead give no HP).
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    local targetHP = target:getHP()
    local targetMP = target:getMP()

    local params = {}
    params.numHits = 1
    params.ftpMod  = { 3.0, 6.0, 9.0 }
    params.str_wsc = 0.6
    params.int_wsc = 0.6

    local damage, criticalHit, tpHits, extraHits = xi.weaponskills.doPhysicalWeaponskill(player, target, wsID, params, tp, action, primary, taChar)

    -- HP absorb: skipped on Undead per BG-Wiki. MP absorb ~50% of damage per retail testing.
    if damage and damage > 0 then
        if target:getSystem() ~= xi.ecosystem.UNDEAD then
            player:addHP(math.min(damage, targetHP))
        end
        local mpAbsorbed = math.min(targetMP, math.floor(damage / 2))
        if mpAbsorbed > 0 then
            target:delMP(mpAbsorbed)
            player:addMP(mpAbsorbed)
        end
    end

    return tpHits, extraHits, criticalHit, damage
end

return weaponskillObject
