-----------------------------------
-- Baseline weaponskill progression tuning.
--
-- Ordinary player weaponskills receive a multiplicative progression boost.
-- The normal WS formula resolves first, so weapon damage, attributes, attack,
-- TP, WSD and multi-attacks all retain their full proportional value.
-----------------------------------

local catalog = {}

catalog.DAMAGE_MULTIPLIER_LOCAL_VAR = 'StandardWsDamageMultiplier'
catalog.DAMAGE_CAP_LOCAL_VAR        = 'StandardWsDamageCap'
catalog.DAMAGE_CAP                  = 79999
catalog.NON_ITEM_LEVEL_119_CAP      = 40000
catalog.TARGET_HP_FRACTION          = 0.30 -- retained for Fellow progression caps
catalog.ENDGAME_PLAYER_LEVEL        = 99
catalog.MASTER_JOB_POINTS           = 2100
catalog.FRESH_99_MULTIPLIER         = 8.00
catalog.MASTERED_99_MULTIPLIER      = 13.00
catalog.PET_FRESH_99_MULTIPLIER     = 7.00
catalog.PET_MASTERED_99_MULTIPLIER  = 11.00
-- BST/DRG/PUP companion caps by master mainhand tier (pets never use Prime WS ceilings).
catalog.PET_AMBU_DAMAGE_CAP         = 99999
catalog.PET_REMA_DAMAGE_CAP         = 999999
-- Extra mult on top of the JP curve so REMA pets land ~200-300k Ready hits.
catalog.PET_AMBU_MULTIPLIER_BONUS   = 1.25
catalog.PET_REMA_MULTIPLIER_BONUS   = 2.85

-- Spalirisos (Prime BST axe) — hard-capped like REMA pets, never Prime-WS tier.
local PET_PRIME_ITEM_IDS =
{
    [21730] = true, -- Spalirisos
}

local function getMasterMainItemId(player)
    if not player then
        return 0
    end

    return player:getEquipID(xi.slot.MAIN) or 0
end

local function isAmbuFinalWeapon(itemId)
    if itemId == 0 then
        return false
    end

    local ok, ambu = pcall(require, 'modules/custom/lua/ambuscade_weapons_catalog')
    if not ok or not ambu or not ambu.BY_ITEM then
        return false
    end

    local info = ambu.BY_ITEM[itemId]
    return info ~= nil and info.stage == 5
end

local function isRemaFinalWeapon(itemId)
    if itemId == 0 then
        return false
    end

    local ok, rema = pcall(require, 'modules/custom/lua/rema_ws_tier_catalog')
    if not ok or not rema or not rema.BY_ITEM_ID then
        return false
    end

    return rema.BY_ITEM_ID[itemId] ~= nil
end

function catalog.getPetDamageCap(player)
    local itemId = getMasterMainItemId(player)
    if isRemaFinalWeapon(itemId) or PET_PRIME_ITEM_IDS[itemId] then
        return catalog.PET_REMA_DAMAGE_CAP
    end

    if isAmbuFinalWeapon(itemId) then
        return catalog.PET_AMBU_DAMAGE_CAP
    end

    return catalog.DAMAGE_CAP
end

-- A three-level grace band keeps ordinary Even Match / Tough combat unchanged.
-- Beyond that band, progression scaling and WS accuracy fall progressively.
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

-- Fellow progression still uses an encounter-HP budget rather than the player
-- WS multiplier. Keep this helper isolated from player and pet damage paths.
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
    return freshValue + (masteredValue - freshValue) * mastery
end

-- Scale only the custom bonus by required level. Stock formulas already include
-- weapon base damage, so an Onion Sword remains far behind a level-115 weapon.
-- Item-level 119 weapons unlock the full bonus and normal 79,999 ceiling.
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

function catalog.getWeaponskillMultiplier(player, target, slot)
    local levelRatio = utils.clamp(
        player:getMainLvl() / catalog.ENDGAME_PLAYER_LEVEL, 0.01, 1.00)
    local endgameMultiplier = getMasteryScaledValue(
        player, catalog.FRESH_99_MULTIPLIER, catalog.MASTERED_99_MULTIPLIER)
    local progressionFactor =
        catalog.getWeaponProgression(player, slot or xi.slot.MAIN) *
        catalog.getLevelGapFactor(player:getMainLvl(), target:getMainLvl()) *
        levelRatio

    return 1 + (endgameMultiplier - 1) * progressionFactor
end

function catalog.getPetDamageMultiplier(player, target)
    local levelRatio = utils.clamp(
        player:getMainLvl() / catalog.ENDGAME_PLAYER_LEVEL, 0.01, 1.00)
    local endgameMultiplier =
        getMasteryScaledValue(
            player,
            catalog.PET_FRESH_99_MULTIPLIER,
            catalog.PET_MASTERED_99_MULTIPLIER)
    local progressionFactor =
        catalog.getLevelGapFactor(player:getMainLvl(), target:getMainLvl()) *
        levelRatio

    local mult = 1 + (endgameMultiplier - 1) * progressionFactor
    local itemId = getMasterMainItemId(player)
    if isRemaFinalWeapon(itemId) or PET_PRIME_ITEM_IDS[itemId] then
        mult = mult * catalog.PET_REMA_MULTIPLIER_BONUS
    elseif isAmbuFinalWeapon(itemId) then
        mult = mult * catalog.PET_AMBU_MULTIPLIER_BONUS
    end

    return mult
end

function catalog.applyMultiplier(damage, multiplier, cap)
    return math.min(math.floor(damage * multiplier), cap)
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
