-----------------------------------
-- Baseline weaponskill progression tuning.
--
-- Ordinary player weaponskills receive an additive progression bonus. At 99,
-- weapon level and Job Point mastery set that bonus; the normal WS formula
-- retains weapon damage, attributes, attack, TP and gear before the final
-- weapon-appropriate ceiling is applied.
-----------------------------------

local catalog = {}

catalog.DAMAGE_BONUS_LOCAL_VAR = 'StandardWsDamageBonus'
catalog.DAMAGE_CAP_LOCAL_VAR   = 'StandardWsDamageCap'
catalog.DAMAGE_CAP             = 99999
catalog.NON_ITEM_LEVEL_119_CAP = 40000
catalog.TARGET_HP_FRACTION     = 0.30
catalog.ENDGAME_PLAYER_LEVEL   = 99
catalog.MASTER_JOB_POINTS       = 2100
catalog.FRESH_99_BONUS          = 20000
catalog.MASTERED_99_BONUS       = 30000
catalog.PET_FRESH_99_FLOOR      = 18000
catalog.PET_MASTERED_99_FLOOR   = 28000

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

function catalog.getMasteryProgress(player)
    if not player or player:getMainLvl() < catalog.ENDGAME_PLAYER_LEVEL then
        return 0
    end

    return utils.clamp(
        (player:getSpentJobPoints() or 0) / catalog.MASTER_JOB_POINTS, 0, 1)
end

local function getMasteryScaledValue(player, freshValue, masteredValue)
    local mastery = catalog.getMasteryProgress(player)
    return math.floor(freshValue + (masteredValue - freshValue) * mastery + 0.5)
end

-- Scale only the custom bonus by required level. Stock formulas already include
-- weapon base damage, so an Onion Sword remains far behind a level-115 weapon.
-- Item-level 119 weapons unlock the full bonus and normal 99,999 ceiling.
function catalog.getWeaponProgression(player, slot)
    local weapon = player:getEquippedItem(slot)
    if weapon == nil then
        return 0.01
    end

    if (weapon:getILvl() or 0) >= 119 then
        return 1.00
    end

    return utils.clamp((weapon:getReqLvl() or 0) / 99, 0.01, 1.00)
end

function catalog.getWeaponskillCap(player, slot)
    local weapon = player:getEquippedItem(slot)
    if weapon ~= nil and (weapon:getILvl() or 0) >= 119 then
        return catalog.DAMAGE_CAP
    end

    return catalog.NON_ITEM_LEVEL_119_CAP
end

function catalog.getWeaponskillBonus(player, target, slot)
    if player:getMainLvl() < catalog.ENDGAME_PLAYER_LEVEL then
        return catalog.getDamageBonus(
            player:getMainLvl(), target:getMainLvl(), target:getMaxHP())
    end

    local endgameBonus = getMasteryScaledValue(
        player, catalog.FRESH_99_BONUS, catalog.MASTERED_99_BONUS)

    return math.floor(
        endgameBonus * catalog.getWeaponProgression(player, slot or xi.slot.MAIN) + 0.5)
end

function catalog.getPetDamageFloor(player, target)
    if player:getMainLvl() < catalog.ENDGAME_PLAYER_LEVEL then
        return math.floor(catalog.getDamageBonus(
            player:getMainLvl(), target:getMainLvl(), target:getMaxHP()) * 0.65 + 0.5)
    end

    return getMasteryScaledValue(
        player, catalog.PET_FRESH_99_FLOOR, catalog.PET_MASTERED_99_FLOOR)
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
