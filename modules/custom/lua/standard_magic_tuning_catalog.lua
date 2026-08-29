-----------------------------------
-- Level-scaled baseline tuning for direct player-cast magical damage.
--
-- Reuses the ordinary WS leveling curve, then assigns fresh-99/mastered multipliers
-- by spell family and tier. Direct elemental/divine/ninjutsu casts, damaging
-- Blue Magic (physical, magical, and breath), and player-automaton nukes are
-- eligible. Helix nukes and Kaustra are included so SCH DoT/2hr keep pace with
-- endgame elemental. Drains and enfeebles remain untouched.
-----------------------------------

local progression = require('modules/custom/lua/standard_ws_tuning_catalog')
local remaCatalog = require('modules/custom/lua/rema_ws_tier_catalog')
local primeCatalog = require('modules/custom/lua/prime_ws_tuning_catalog')
local blueWeaponCatalog = require('modules/custom/lua/blu_weapon_amplification_catalog')
local catalog = {}

catalog.DAMAGE_CAP             = 99999
catalog.REMA_DAMAGE_CAP        = 999999
catalog.PRIME_DAMAGE_CAP       = 1999999
catalog.FULL_POWER_LEVEL_RATIO = 0.70
catalog.MIN_SPELL_FACTOR       = 0.15

catalog.MULTIPLIERS =
{
    -- base* raises spell base damage before normal modifiers and the progression
    -- multiplier. It is deliberately small so MAB, INT, affinity, MACC/resists,
    -- weather and burst still determine whether a cast reaches the 50-99k range.
    elementalHigh = { fresh = 8.00, mastered = 13.00, baseFresh = 600, baseMastered = 1050 },
    elementalMid  = { fresh = 6.00, mastered = 10.00, baseFresh = 400, baseMastered =  700 },
    elementalLow  = { fresh = 4.00, mastered =  7.00, baseFresh = 200, baseMastered =  350 },
    ninjutsu      = { fresh = 5.00, mastered =  8.00, baseFresh = 250, baseMastered =  450 },
    divine        = { fresh = 5.00, mastered =  9.00, baseFresh = 300, baseMastered =  550 },
    -- Native BLU uses blueWeaponCatalog instead of this generic progression.
    blue          = { fresh = 1.00, mastered =  1.00, baseFresh =   0, baseMastered =    0 },
}

local remaWeaponIds = {}
for _, entry in ipairs(remaCatalog.WEAPONS) do
    remaWeaponIds[entry.itemId] = true
end

local primeWeaponIds = {}
for _, entry in pairs(primeCatalog.PRIME_WS_TUNING) do
    primeWeaponIds[entry.itemId] = true
end

local directSkills =
{
    [xi.skill.DIVINE_MAGIC]    = true,
    [xi.skill.ELEMENTAL_MAGIC] = true,
    [xi.skill.NINJUTSU]        = true,
}

local function isHelix(spellId)
    return
        (spellId >= xi.magic.spell.GEOHELIX and
        spellId <= xi.magic.spell.LUMINOHELIX) or
        (spellId >= xi.magic.spell.GEOHELIX_II and
        spellId <= xi.magic.spell.LUMINOHELIX_II)
end

local function validCasterAndTarget(caster, target)
    local isPlayerAutomaton =
        caster ~= nil and
        caster:isAutomaton() and
        caster:getMaster() ~= nil and
        caster:getMaster():isPC()

    return
        caster ~= nil and
        target ~= nil and
        (caster:isPC() or isPlayerAutomaton) and
        target:isMob()
end

local function isNativeMainJobSpell(caster, spell)
    if caster:isAutomaton() then
        return true
    end

    local spellLevel = spell:getLevel(caster:getMainJob())
    return
        spellLevel ~= nil and
        spellLevel > 0 and
        spellLevel <= caster:getMainLvl()
end

function catalog.isDirectSpellEligible(caster, target, spell)
    if not validCasterAndTarget(caster, target) then
        return false
    end

    if not isNativeMainJobSpell(caster, spell) then
        return false
    end

    local spellId = spell:getID()
    -- Kaustra is Dark Magic (not in directSkills); Helix is Elemental but was
    -- previously excluded so DoTs never reached endgame tick values.
    if spellId == xi.magic.spell.KAUSTRA or isHelix(spellId) then
        return true
    end

    return directSkills[spell:getSkillType()] == true
end

function catalog.isBlueDamageEligible(caster, target, spell, params)
    return
        validCasterAndTarget(caster, target) and
        caster:isPC() and
        caster:getMainJob() == xi.job.BLU and
        isNativeMainJobSpell(caster, spell) and
        params ~= nil and
        params.attackType ~= nil and
        params.attackType ~= xi.attackType.NONE and
        params.blueDamageExempt ~= true
end

function catalog.getDamageCap(caster)
    if caster:isAutomaton() then
        -- Automata inherit the master's companion tier, not player REMA/Prime
        -- spell ceilings. This matches their physical WS and ability contract.
        return progression.setPetDamageCap(caster, caster:getMaster())
    end

    if not caster:isPC() then
        return catalog.DAMAGE_CAP
    end

    if caster:getMainJob() == xi.job.BLU then
        return blueWeaponCatalog.getDamageCap(caster)
    end

    local mainWeapon   = caster:getEquipID(xi.slot.MAIN)
    local rangedWeapon = caster:getEquipID(xi.slot.RANGED)

    if primeWeaponIds[mainWeapon] or primeWeaponIds[rangedWeapon] then
        return progression.getPlayerPrimeDamageCap(caster, catalog.PRIME_DAMAGE_CAP)
    end

    if remaWeaponIds[mainWeapon] or remaWeaponIds[rangedWeapon] then
        return progression.getPlayerRemaDamageCap(caster, catalog.REMA_DAMAGE_CAP)
    end

    return catalog.DAMAGE_CAP
end

function catalog.getSpellProgressionFactor(caster, spell)
    local player = caster:isPC() and caster or caster:getMaster()
    local playerLevel = math.max(1, player:getMainLvl())
    local spellId = spell:getID()

    -- Kaustra's jobs blob lists SCH at lv5 (Tabula-gated); treat as full-power 2hr.
    if spellId == xi.magic.spell.KAUSTRA then
        return 1.00
    end

    local spellLevel = spell:getLevel(player:getMainJob())
    if not spellLevel or spellLevel <= 0 then
        return 0
    end

    return utils.clamp(
        spellLevel / (playerLevel * catalog.FULL_POWER_LEVEL_RATIO),
        catalog.MIN_SPELL_FACTOR,
        1.00)
end

local function getProgressionPlayer(caster)
    return caster:isPC() and caster or caster:getMaster()
end

local function isAncientMagic(spellId)
    return spellId >= xi.magic.spell.FLARE and spellId <= xi.magic.spell.FLOOD_II
end

local function getMultiplierBand(caster, spell)
    local skill = spell:getSkillType()
    if skill == xi.skill.NINJUTSU then
        return catalog.MULTIPLIERS.ninjutsu
    elseif skill == xi.skill.DIVINE_MAGIC then
        return catalog.MULTIPLIERS.divine
    elseif skill == xi.skill.BLUE_MAGIC then
        return catalog.MULTIPLIERS.blue
    end

    local spellId = spell:getID()
    if spellId == xi.magic.spell.KAUSTRA or isHelix(spellId) then
        return catalog.MULTIPLIERS.elementalHigh
    end

    local player = getProgressionPlayer(caster)
    local spellLevel = spell:getLevel(player:getMainJob()) or 1
    if spellLevel >= 75 or isAncientMagic(spellId) then
        return catalog.MULTIPLIERS.elementalHigh
    elseif spellLevel >= 50 then
        return catalog.MULTIPLIERS.elementalMid
    end

    return catalog.MULTIPLIERS.elementalLow
end

function catalog.getDamageMultiplier(caster, target, spell)
    if
        caster:isPC() and
        caster:getMainJob() == xi.job.BLU and
        spell:getSkillType() == xi.skill.BLUE_MAGIC
    then
        return blueWeaponCatalog.getDamageMultiplier(caster)
    end

    local player = getProgressionPlayer(caster)
    local band = getMultiplierBand(caster, spell)
    local mastery = progression.getMasteryProgress(player)
    local endgameMultiplier =
        band.fresh + (band.mastered - band.fresh) * mastery
    local levelRatio = utils.clamp(
        player:getMainLvl() / progression.ENDGAME_PLAYER_LEVEL, 0.01, 1.00)
    local progressionFactor =
        catalog.getSpellProgressionFactor(caster, spell) *
        progression.getLevelGapFactor(player:getMainLvl(), target:getMainLvl()) *
        levelRatio

    -- Stock already contains INT/MND, Magic Damage, MAB, affinity, weather,
    -- magic burst and resists. Scaling it preserves all of those relationships.
    return 1 + (endgameMultiplier - 1) * progressionFactor
end

function catalog.getBaseStockBonus(caster, target, spell)
    local player = getProgressionPlayer(caster)
    local band = getMultiplierBand(caster, spell)
    local mastery = progression.getMasteryProgress(player)
    local endgameBase =
        band.baseFresh + (band.baseMastered - band.baseFresh) * mastery
    local levelRatio = utils.clamp(
        player:getMainLvl() / progression.ENDGAME_PLAYER_LEVEL, 0.01, 1.00)
    local progressionFactor =
        catalog.getSpellProgressionFactor(caster, spell) *
        progression.getLevelGapFactor(player:getMainLvl(), target:getMainLvl()) *
        levelRatio

    return math.floor(endgameBase * progressionFactor + 0.5)
end

function catalog.getMagicAccuracyPenalty(caster, target)
    local player = getProgressionPlayer(caster)
    return progression.getAccuracyPenalty(
        player:getMainLvl(), target:getMainLvl())
end

return catalog
