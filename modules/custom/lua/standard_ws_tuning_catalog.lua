-----------------------------------
-- Baseline weaponskill progression tuning.
--
-- Ordinary player weaponskills receive a multiplicative progression boost.
-- The normal WS formula resolves first, so weapon damage, attributes, attack,
-- TP, WSD and multi-attacks all retain their full proportional value.
-----------------------------------

-- FileWatcher dofile's this module and discards the return, so mutate the
-- cached table in place (same pitfall as standard_magic_tuning_catalog).
local KEY = 'modules/custom/lua/standard_ws_tuning_catalog'
local catalog = package.loaded[KEY]
if type(catalog) ~= 'table' then
    catalog = {}
end
package.loaded[KEY] = catalog

catalog.DAMAGE_MULTIPLIER_LOCAL_VAR = 'StandardWsDamageMultiplier'
catalog.DAMAGE_CAP_LOCAL_VAR        = 'StandardWsDamageCap'
catalog.DAMAGE_CAP                  = 79999
catalog.NON_ITEM_LEVEL_119_CAP      = 40000
-- Pre-119 III REMA (99 / 119 I / 119 II) must never sit below Ambuscade.
catalog.REMA_PRE_III_DAMAGE_CAP     = 99999
catalog.REMA_PRE_III_NATIVE_WS_CAP  = 149999
catalog.TARGET_HP_FRACTION          = 0.30 -- retained for Fellow progression caps
catalog.ENDGAME_PLAYER_LEVEL        = 99
catalog.MASTER_JOB_POINTS           = 2100
catalog.FRESH_99_MULTIPLIER         = 8.00
catalog.MASTERED_99_MULTIPLIER      = 13.00
catalog.PET_FRESH_99_MULTIPLIER     = 7.00
catalog.PET_MASTERED_99_MULTIPLIER  = 11.00
-- BST/DRG/PUP/SMN companion caps by master mainhand tier (pets never use
-- player Prime WS ceilings).
catalog.PET_AMBU_DAMAGE_CAP         = 99999
catalog.PET_REMA_DAMAGE_CAP         = 999999
catalog.PET_PRIME_DAMAGE_CAP        = 1499999
catalog.COMPANION_PLAYER_REMA_CAP   = 249999
catalog.COMPANION_PLAYER_PRIME_CAP  = 499999
catalog.PET_DAMAGE_CAP_LOCAL_VAR    = 'CompanionDamageCap'
-- Extra multipliers on top of the JP curve. Prime is the pinnacle companion
-- tier; it raises potential without changing any pet's baseline formula.
catalog.PET_AMBU_MULTIPLIER_BONUS   = 1.25
catalog.PET_REMA_MULTIPLIER_BONUS   = 2.85
catalog.PET_PRIME_MULTIPLIER_BONUS  = 4.25

local companionMainJobs =
{
    [xi.job.BST] = true,
    [xi.job.PUP] = true,
    [xi.job.SMN] = true,
}

local companionPrimeItemByJob =
{
    [xi.job.BST] = 21730, -- Spalirisos
    [xi.job.PUP] = 21535, -- Varga Purnikawa
    [xi.job.SMN] = 22106, -- Opashoro
}

local function isCompanionMainJob(player)
    return
        player ~= nil and
        player:isPC() and
        companionMainJobs[player:getMainJob()] == true
end

function catalog.getPlayerRemaDamageCap(player, defaultCap)
    if isCompanionMainJob(player) then
        return math.min(defaultCap, catalog.COMPANION_PLAYER_REMA_CAP)
    end

    return defaultCap
end

function catalog.getPlayerPrimeDamageCap(player, defaultCap)
    if isCompanionMainJob(player) then
        return math.min(defaultCap, catalog.COMPANION_PLAYER_PRIME_CAP)
    end

    return defaultCap
end

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

local remaPathByItem = {}

local function registerRemaPath(itemId, info)
    if itemId and itemId > 0 then
        remaPathByItem[itemId] = info
    end
end

local function buildRemaPathLookup()
    remaPathByItem = {}
    local okRema, rema = pcall(require, 'modules/custom/lua/rema_ws_tier_catalog')
    local okForge, forge = pcall(require, 'modules/custom/lua/weapon_forge_catalog')
    if not okRema or not rema or not rema.BY_ITEM_ID or not okForge or not forge then
        catalog.REMA_PATH = remaPathByItem
        return
    end

    local function addChain(chain)
        local final = rema.BY_ITEM_ID[chain.s3]
        if not final then
            return
        end

        local info =
        {
            wsId  = final.wsId,
            slot  = final.slot,
            final = false,
        }
        registerRemaPath(chain.base, info)
        registerRemaPath(chain.s1, info)
        registerRemaPath(chain.s2, info)
        registerRemaPath(chain.s3,
        {
            wsId  = final.wsId,
            slot  = final.slot,
            final = true,
        })
    end

    for _, chain in ipairs(forge.relicChains or {}) do
        addChain(chain)
    end
    for _, chain in ipairs(forge.empyreanChains or {}) do
        addChain(chain)
    end
    for _, chain in ipairs(forge.mythicChains or {}) do
        addChain(chain)
    end
    for itemId, entry in pairs(rema.BY_ITEM_ID) do
        if remaPathByItem[itemId] == nil then
            registerRemaPath(itemId,
            {
                wsId  = entry.wsId,
                slot  = entry.slot,
                final = true,
            })
        end
    end

    catalog.REMA_PATH = remaPathByItem
end

buildRemaPathLookup()

function catalog.getRemaPathInfo(itemId)
    if not itemId or itemId == 0 then
        return nil
    end

    return remaPathByItem[itemId]
end

function catalog.isRemaPathWeapon(itemId)
    return catalog.getRemaPathInfo(itemId) ~= nil
end

local function isRemaFinalWeapon(itemId)
    local info = catalog.getRemaPathInfo(itemId)
    return info ~= nil and info.final == true
end

local function isPrimeFinalWeapon(itemId)
    if itemId == 0 then
        return false
    end

    local ok, prime = pcall(require, 'modules/custom/lua/prime_ws_tuning_catalog')
    if not ok or not prime or not prime.PRIME_WS_TUNING then
        return false
    end

    for _, entry in pairs(prime.PRIME_WS_TUNING) do
        if entry.itemId == itemId then
            return true
        end
    end

    return false
end

function catalog.getPetDamageCap(player)
    local itemId = getMasterMainItemId(player)
    if isPrimeFinalWeapon(itemId) then
        local mainJob = player:getMainJob()
        if companionPrimeItemByJob[mainJob] == itemId then
            return catalog.PET_PRIME_DAMAGE_CAP
        end

        if companionMainJobs[mainJob] then
            return catalog.DAMAGE_CAP
        end

        -- Jobs outside this identity change keep their previous
        -- REMA-equivalent Prime pet tier.
        return catalog.PET_REMA_DAMAGE_CAP
    end

    if isRemaFinalWeapon(itemId) then
        return catalog.PET_REMA_DAMAGE_CAP
    end

    if catalog.isRemaPathWeapon(itemId) then
        return catalog.PET_AMBU_DAMAGE_CAP
    end

    if isAmbuFinalWeapon(itemId) then
        return catalog.PET_AMBU_DAMAGE_CAP
    end

    return catalog.DAMAGE_CAP
end

function catalog.setPetDamageCap(pet, player)
    local cap = catalog.getPetDamageCap(player)
    pet:setLocalVar(catalog.PET_DAMAGE_CAP_LOCAL_VAR, cap)

    return cap
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
    if isPrimeFinalWeapon(itemId) then
        local mainJob = player:getMainJob()
        if companionPrimeItemByJob[mainJob] == itemId then
            mult = mult * catalog.PET_PRIME_MULTIPLIER_BONUS
        elseif not companionMainJobs[mainJob] then
            mult = mult * catalog.PET_REMA_MULTIPLIER_BONUS
        end
    elseif isRemaFinalWeapon(itemId) then
        mult = mult * catalog.PET_REMA_MULTIPLIER_BONUS
    elseif catalog.isRemaPathWeapon(itemId) or isAmbuFinalWeapon(itemId) then
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
