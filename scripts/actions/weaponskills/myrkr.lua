-----------------------------------
-- Myrkr
-----------------------------------
---@type TWeaponSkill
local weaponskillObject = {}

weaponskillObject.onUseWeaponSkill = function(player, target, wsID, tp, primary, action, taChar)
    -- Apply aftermath
    xi.aftermath.addStatusEffect(player, tp, xi.slot.MAIN, xi.aftermath.type.EMPYREAN)

    local ftpmp = xi.weaponskills.fTP(tp, { 0.2, 0.4, 0.6 })
    local mpBefore = player:getMP()
    local mpRestore = math.min(
        player:getMaxMP() - mpBefore,
        math.floor(ftpmp * player:getMaxMP()))

    if xi.legendaryPilgrimage and xi.legendaryPilgrimage.onSupportWs then
        pcall(function()
            xi.legendaryPilgrimage.onSupportWs(player, target, wsID, {
                hpBeforePct = player:getHPP(),
                mpBeforePct = mpBefore * 100 / math.max(1, player:getMaxMP()),
                hpRestored   = 0,
                mpRestored   = math.max(0, mpRestore),
            })
        end)
    end

    return 1, 0, false, ftpmp * player:getMaxMP()
end

return weaponskillObject
