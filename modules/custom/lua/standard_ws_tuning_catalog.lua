-----------------------------------
-- Baseline weaponskill progression tuning.
--
-- Ordinary player weaponskills receive an additive share of target max HP.
-- Target HP naturally scales the bonus from low-level enemies through capacity
-- NMs, while the level-gap table prevents underleveled players from punching
-- far above their weight. Normal WS damage is added afterward, so equipment,
-- TP and WSD augments still provide progression up to the pre-REMA cap.
-----------------------------------

local catalog = {}

catalog.DAMAGE_BONUS_LOCAL_VAR = 'StandardWsDamageBonus'
catalog.DAMAGE_CAP_LOCAL_VAR   = 'StandardWsDamageCap'
catalog.DAMAGE_CAP             = 99999
catalog.TARGET_HP_FRACTION     = 0.30
catalog.ENDGAME_PLAYER_LEVEL   = 99

-- A three-level grace band keeps ordinary Even Match / Tough combat unchanged.
-- Beyond that band, the additive HP share and WS accuracy fall progressively.
catalog.LEVEL_GAP_GRACE       = 3
catalog.ACC_PENALTY_PER_LEVEL = 8

catalog.LEVEL_GAP_FACTORS =
{
    { gap =  3, factor = 1.00 },
    { gap =  8, factor = 0.70 },
    { gap = 15, factor = 0.35 },
    { gap = 24, factor = 0.08 },
    { gap = 25, factor = 0.03 },
}

function catalog.getLevelGapFactor(playerLevel, targetLevel)
    -- Relaunch endgame mobs commonly use artificial levels 150-250 while
    -- remaining intended Lv99 content (Capacity Phantoms are Lv150-160).
    -- Their custom stats and HP provide progression; displayed level must not
    -- suppress the baseline WS tier once the player has reached the level cap.
    if playerLevel >= catalog.ENDGAME_PLAYER_LEVEL then
        return 1.00
    end

    local gap = math.max(0, targetLevel - playerLevel)
    local previous = { gap = 0, factor = 1.00 }

    for _, point in ipairs(catalog.LEVEL_GAP_FACTORS) do
        if gap <= point.gap then
            if point.gap == previous.gap then
                return point.factor
            end

            local progress = (gap - previous.gap) / (point.gap - previous.gap)
            return previous.factor + (point.factor - previous.factor) * progress
        end

        previous = point
    end

    return catalog.LEVEL_GAP_FACTORS[#catalog.LEVEL_GAP_FACTORS].factor
end

function catalog.getDamageBonus(playerLevel, targetLevel, targetMaxHp)
    if targetMaxHp <= 0 then
        return 0
    end

    return math.floor(
        targetMaxHp *
        catalog.TARGET_HP_FRACTION *
        catalog.getLevelGapFactor(playerLevel, targetLevel) + 0.5)
end

function catalog.getAccuracyPenalty(playerLevel, targetLevel)
    if playerLevel >= catalog.ENDGAME_PLAYER_LEVEL then
        return 0
    end

    local penalizedLevels = targetLevel - playerLevel - catalog.LEVEL_GAP_GRACE
    if penalizedLevels <= 0 then
        return 0
    end

    return penalizedLevels * catalog.ACC_PENALTY_PER_LEVEL
end

return catalog
