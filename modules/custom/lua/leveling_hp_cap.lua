-----------------------------------
-- Legendary-style leveling HP clamp.
-- While the acting player (or pet master) is below 99, a single outgoing hit
-- against a mob cannot exceed one third of that mob's max HP. At 99+ this is
-- a no-op so existing BLU / companion progression deals full damage.
--
-- Three floored 33% hits leave 1–2 HP (the bar still paints that as 1%).
-- That leftover is not a crash workaround — finish the mob instead of
-- forcing a 5-damage tap. The combat log keeps the hit that landed.
-----------------------------------
local cap = {}

cap.FRACTION       = 1 / 3
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

    local portion = math.max(1, math.floor(maxHp * cap.FRACTION))
    local current = target.getHP and target:getHP() or 0

    -- Already inside one portion of death: do not shrink the hit to leftover HP.
    if current > 0 and current <= portion then
        return damage
    end

    local capped = math.min(damage, portion)
    if current > 0 then
        local leftover = current - capped
        -- floor(max/3)*3 remainder still shows as 1% on the HP bar.
        if leftover > 0 and leftover * 100 < maxHp then
            return math.max(capped, current)
        end
    end

    return capped
end

return cap
