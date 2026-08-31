-----------------------------------
-- Legendary-style leveling HP clamp.
-- While the acting player (or pet master) is below 99, a single outgoing hit
-- against a mob cannot exceed FRACTION of that mob's max HP. At 99+ this is
-- a no-op so existing BLU / companion progression deals full damage.
-----------------------------------
local cap = {}

cap.FRACTION       = 0.33
cap.ENDGAME_LEVEL  = 99

function cap.apply(sourceLevel, target, damage)
    if type(damage) ~= 'number' or damage <= 0 or target == nil then
        return damage
    end

    if (sourceLevel or 0) >= cap.ENDGAME_LEVEL then
        return damage
    end

    if target.isMob and not target:isMob() then
        return damage
    end

    local maxHp = target.getMaxHP and target:getMaxHP() or 0
    if maxHp <= 0 then
        return damage
    end

    return math.min(damage, math.max(1, math.floor(maxHp * cap.FRACTION)))
end

return cap
