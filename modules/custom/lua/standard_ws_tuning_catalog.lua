-----------------------------------
-- Baseline weaponskill progression tuning.
--
-- Ordinary player weaponskills receive a target-HP floor while leveling. At
-- 99, weapon level and Job Point mastery set the floor; the equipped weapon's
-- stock base damage remains in the normal WS formula. Naturally stronger WSs
-- keep their stock result up to the weapon-appropriate ceiling.
-----------------------------------

local catalog = {}

catalog.DAMAGE_BONUS_LOCAL_VAR = 'StandardWsDamageBonus'
catalog.DAMAGE_CAP_LOCAL_VAR   = 'StandardWsDamageCap'
catalog.DAMAGE_CAP             = 99999
catalog.NON_ITEM_LEVEL_119_CAP = 40000
catalog.TARGET_HP_FRACTION     = 0.30
catalog.ENDGAME_PLAYER_LEVEL   = 99
catalog.MASTER_JOB_POINTS       = 2100
catalog.FRESH_99_FLOOR          = 32000
catalog.MASTERED_99_FLOOR       = 45000
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

local function getEndgameFloor(player, freshFloor, masteredFloor)
    local mastery = catalog.getMasteryProgress(player)
    return math.floor(freshFloor + (masteredFloor - freshFloor) * mastery + 0.5)
end

-- Stock WS formulas already include the equipped weapon's base damage. Scale
-- only the custom floor by required level so that it cannot erase that weapon
-- progression (for example, an Onion Sword must not inherit a full Lv99 floor).
-- Item-level 119 weapons unlock the full floor and normal 99,999 ceiling.
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

-- Standard tuning is a floor, not a blanket additive multiplier. Weak WSs are
-- lifted into the progression band while naturally strong WSs and augmented
-- builds keep their stock result and progress toward the unchanged 99,999 cap.
function catalog.getWeaponskillFloor(player, target, slot)
    if player:getMainLvl() < catalog.ENDGAME_PLAYER_LEVEL then
        return catalog.getDamageBonus(
            player:getMainLvl(), target:getMainLvl(), target:getMaxHP())
    end

    local endgameFloor = getEndgameFloor(
        player, catalog.FRESH_99_FLOOR, catalog.MASTERED_99_FLOOR)

    return math.floor(
        endgameFloor * catalog.getWeaponProgression(player, slot or xi.slot.MAIN) + 0.5)
end

function catalog.getPetDamageFloor(player, target)
    if player:getMainLvl() < catalog.ENDGAME_PLAYER_LEVEL then
        return math.floor(catalog.getDamageBonus(
            player:getMainLvl(), target:getMainLvl(), target:getMaxHP()) * 0.65 + 0.5)
    end

    return getEndgameFloor(
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
