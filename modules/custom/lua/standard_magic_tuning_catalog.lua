-----------------------------------
-- Level-scaled baseline tuning for direct player-cast magical damage.
--
-- Reuses the ordinary WS leveling curve, then assigns fresh-99/mastered multipliers
-- by spell family and tier. Direct elemental/divine/ninjutsu casts, damaging
-- Blue Magic (physical, magical, and breath), and player-automaton nukes are
-- eligible. Helix nukes and Kaustra are included so SCH DoT/2hr keep pace with
-- endgame elemental. Drains stay untouched. Dia / Diaga / Bio keep their DoT
-- and defense / attack down; the opening hit is a token (no gear Magic
-- Damage) and still respects the 33% leveling HP clamp so they cannot
-- one-shot while leveling.
--
-- Outgoing elemental / BLU / ninjutsu / divine damage also uses the ordinary
-- weaponskill rules: 33% of mob HP while below 99, the 40k / 79,999 / 99,999 /
-- 999,999 ceiling, pre-119 III REMA matching Ambuscade at 99,999, and the AoE
-- WS cap on splash hits of -ga / other multi-target casts. The mob the spell
-- was aimed at uses the single-target ceiling so an AoE nuke is still a
-- full single-target spell. Main-job BLU splash skips the weapon
-- multiplier and uses the same iLvl AoE ladder as WS / -ga
-- (40k / 79,999 / 99,999 / 149,999 / 199,999).
-- Main BLM is the nuke identity. SCH native nukes are 0.90 of that. RDM,
-- /BLM, and /SCH are much weaker so people cannot level every job by
-- subbing a nuker and spamming Stone / Stonega / Helix.
-----------------------------------

local progression = require('modules/custom/lua/standard_ws_tuning_catalog')
local remaCatalog = require('modules/custom/lua/rema_ws_tier_catalog')
local primeCatalog = require('modules/custom/lua/prime_ws_tuning_catalog')
local ambuCatalog = require('modules/custom/lua/ambuscade_ws_tuning_catalog')
local blueWeaponCatalog = require('modules/custom/lua/blu_weapon_amplification_catalog')
local levelingHpCap = require('modules/custom/lua/leveling_hp_cap')

-- FileWatcher dofile's this module and discards the return value, so a
-- `local catalog = {}` would leave package.loaded on the map-start table
-- (no applyPlayerOutgoingLimits) while damage_spell.lua already calls it
-- -> every nuke errors and lands 0. Mutate the cached table in place.
local CATALOG_KEY = 'modules/custom/lua/standard_magic_tuning_catalog'
local catalog = package.loaded[CATALOG_KEY]
if type(catalog) ~= 'table' then
    catalog = {}
end
package.loaded[CATALOG_KEY] = catalog

-- Same ladder as ordinary weaponskills: no-119 / 119 / Ambu / REMA-Prime.
catalog.NON_ITEM_LEVEL_119_CAP = 40000
catalog.DAMAGE_CAP             = 79999
catalog.AMBU_DAMAGE_CAP        = 99999
catalog.REMA_DAMAGE_CAP        = 999999
catalog.PRIME_DAMAGE_CAP       = 999999
catalog.FULL_POWER_LEVEL_RATIO = 0.70
catalog.MIN_SPELL_FACTOR       = 0.15

-- Matches the AoE weaponskill ceiling (charentity.cpp + StandardWeaponskillTuning).
catalog.AOE_PRE_119_CAP = 40000
catalog.AOE_ITEM_119_CAP = 79999

-- Main-job identity. A spell that is not native on the current main job
-- (learned only from /BLM or /SCH, or a BLM-only nuke on SCH/BLM) uses
-- SUBJOB_POWER. That is the leveling-cheese gate: WAR/BLM Stonega and
-- WAR/SCH Stone / Helix are both 0.20, not the main-job factor.
catalog.SUBJOB_POWER = 0.20
catalog.MAIN_JOB_POWER =
{
    [xi.job.BLM] = 1.00,
    [xi.job.SCH] = 0.90,
    [xi.job.GEO] = 0.65,
    [xi.job.RDM] = 0.35,
    [xi.job.WHM] = 1.00,
    [xi.job.NIN] = 1.00,
    [xi.job.PLD] = 0.55,
}

catalog.MULTIPLIERS =
{
    -- No free flat base. Stock INT, Magic Damage, MAB, affinity, weather and
    -- burst stay on the normal path; the multiplier only scales that result.
    elementalHigh = { fresh = 8.00, mastered = 13.00, baseFresh = 0, baseMastered = 0 },
    elementalMid  = { fresh = 6.00, mastered = 10.00, baseFresh = 0, baseMastered = 0 },
    elementalLow  = { fresh = 4.00, mastered =  7.00, baseFresh = 0, baseMastered = 0 },
    ninjutsu      = { fresh = 5.00, mastered =  8.00, baseFresh = 0, baseMastered = 0 },
    divine        = { fresh = 5.00, mastered =  9.00, baseFresh = 0, baseMastered = 0 },
    -- Native BLU uses blueWeaponCatalog instead of this generic progression.
    blue          = { fresh = 1.00, mastered =  1.00, baseFresh = 0, baseMastered = 0 },
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

-- Dia / Diaga / Bio go through useDamageSpell for a token opening hit.
-- Gear Magic Damage is for nukes; these spells must not inherit it.
local tokenInitialSpellIds =
{
    [xi.magic.spell.DIA]       = true,
    [xi.magic.spell.DIA_II]    = true,
    [xi.magic.spell.DIA_III]   = true,
    [xi.magic.spell.DIA_IV]    = true,
    [xi.magic.spell.DIA_V]     = true,
    [xi.magic.spell.DIAGA]     = true,
    [xi.magic.spell.DIAGA_II]  = true,
    [xi.magic.spell.DIAGA_III] = true,
    [xi.magic.spell.DIAGA_IV]  = true,
    [xi.magic.spell.DIAGA_V]   = true,
    [xi.magic.spell.BIO]       = true,
    [xi.magic.spell.BIO_II]    = true,
    [xi.magic.spell.BIO_III]   = true,
    [xi.magic.spell.BIO_IV]    = true,
    [xi.magic.spell.BIO_V]     = true,
}

function catalog.isTokenInitialSpellId(spellId)
    return tokenInitialSpellIds[spellId] == true
end

function catalog.isTokenInitialSpell(spell)
    if not spell then
        return false
    end

    local spellId = spell.getID and spell:getID() or spell
    return catalog.isTokenInitialSpellId(spellId)
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

-- LSB maps "job cannot use this spell" to 255. Treat that as missing, not
-- as a real learn level, so a 99+ main can never look "native" on /BLM or /SCH.
local function isNativeMainJobSpell(caster, spell)
    if caster:isAutomaton() then
        return true
    end

    local spellLevel = spell:getLevel(caster:getMainJob())
    return
        spellLevel ~= nil and
        spellLevel > 0 and
        spellLevel < 255 and
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

local function getMainHandILvl(caster)
    if not caster.getEquippedItem then
        return 0
    end

    local weapon = caster:getEquippedItem(xi.slot.MAIN)
    if weapon == nil or not weapon.getILvl then
        return 0
    end

    return weapon:getILvl() or 0
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

    if
        progression.isRemaPathWeapon(mainWeapon) or
        progression.isRemaPathWeapon(rangedWeapon)
    then
        return catalog.AMBU_DAMAGE_CAP
    end

    if
        ambuCatalog.isFinalWeapon(mainWeapon, xi.slot.MAIN) or
        ambuCatalog.isFinalWeapon(rangedWeapon, xi.slot.RANGED)
    then
        return catalog.AMBU_DAMAGE_CAP
    end

    if getMainHandILvl(caster) >= 119 then
        return catalog.DAMAGE_CAP
    end

    return catalog.NON_ITEM_LEVEL_119_CAP
end

function catalog.getAoEDamageCap(caster, spell)
    if not spell or not spell.isAoE or spell:isAoE() == 0 then
        return nil
    end

    if caster.isAutomaton and caster:isAutomaton() then
        -- Splash uses the shared player AoE ladder. Aimed-at automaton
        -- nukes keep the companion single-target cap via getOutgoingDamageCap.
        local master = caster.getMaster and caster:getMaster()
        return progression.getPetAoEDamageCap(master)
    end

    if not caster:isPC() then
        return catalog.AOE_PRE_119_CAP
    end

    local mainWeapon = caster:getEquipID(xi.slot.MAIN)
    if primeWeaponIds[mainWeapon] then
        return primeCatalog.AOE_DAMAGE_CAP
    end

    if remaWeaponIds[mainWeapon] then
        return remaCatalog.AOE_DAMAGE_CAP
    end

    if progression.isRemaPathWeapon(mainWeapon) then
        return catalog.AMBU_DAMAGE_CAP
    end

    if ambuCatalog.isFinalWeapon(mainWeapon, xi.slot.MAIN) then
        return ambuCatalog.AOE_DAMAGE_CAP
    end

    if getMainHandILvl(caster) >= 119 then
        return catalog.AOE_ITEM_119_CAP
    end

    return catalog.AOE_PRE_119_CAP
end

-- True for every extra mob an AoE spell tags. The aimed-at target is false
-- so it keeps the single-target ceiling. Missing primary-id data fails closed
-- (treat as splash) so old callers still see the AoE cap.
function catalog.isAoESplashTarget(spell, target)
    if not spell or not spell.isAoE or spell:isAoE() == 0 then
        return false
    end

    if
        target and
        target.getID and
        spell.getPrimaryTargetID
    then
        local primaryId = spell:getPrimaryTargetID()
        if type(primaryId) == 'number' and primaryId > 0 then
            return target:getID() ~= primaryId
        end
    end

    return true
end

function catalog.getOutgoingDamageCap(caster, spell, target)
    local single = catalog.getDamageCap(caster)
    if catalog.isAoESplashTarget(spell, target) then
        local aoe = catalog.getAoEDamageCap(caster, spell)
        if aoe and aoe > 0 then
            return math.min(single, aoe)
        end
    end

    return single
end

function catalog.getCasterPowerFactor(caster, spell)
    if
        not caster or
        not spell or
        (caster.isAutomaton and caster:isAutomaton()) or
        not caster.isPC or
        not caster:isPC()
    then
        return 1.00
    end

    local skill = spell:getSkillType()
    if skill == xi.skill.BLUE_MAGIC then
        return 1.00
    end

    local mainJob = caster:getMainJob()
    if not isNativeMainJobSpell(caster, spell) then
        return catalog.SUBJOB_POWER
    end

    if skill == xi.skill.NINJUTSU then
        return mainJob == xi.job.NIN and 1.00 or catalog.SUBJOB_POWER
    end

    if skill == xi.skill.DIVINE_MAGIC then
        return catalog.MAIN_JOB_POWER[mainJob] or 0.40
    end

    return catalog.MAIN_JOB_POWER[mainJob] or 0.40
end

local function isOutgoingLimitedSpell(spell)
    if not spell or not spell.getSkillType then
        return false
    end

    local skill = spell:getSkillType()
    if
        skill == xi.skill.ELEMENTAL_MAGIC or
        skill == xi.skill.DIVINE_MAGIC or
        skill == xi.skill.NINJUTSU or
        skill == xi.skill.BLUE_MAGIC
    then
        return true
    end

    local spellId = spell.getID and spell:getID() or 0
    return spellId == xi.magic.spell.KAUSTRA or isHelix(spellId)
end

function catalog.applyPlayerOutgoingLimits(caster, target, spell, damage)
    if type(damage) ~= 'number' or damage <= 0 then
        return damage
    end

    if
        not caster or
        not target or
        (not (caster.isPC and caster:isPC()) and
            not (caster.isAutomaton and caster:isAutomaton()))
    then
        return damage
    end

    -- Token Dia / Diaga / Bio: leveling clamp only. No job-nuke factor and
    -- no REMA ceiling — those are for real damage spells.
    if catalog.isTokenInitialSpell(spell) then
        local source = caster:isPC() and caster or caster:getMaster()
        local sourceLevel = source and source.getMainLvl and source:getMainLvl() or 0
        return levelingHpCap.apply(sourceLevel, target, damage)
    end

    if not isOutgoingLimitedSpell(spell) then
        return damage
    end

    if caster:isPC() then
        damage = math.floor(damage * catalog.getCasterPowerFactor(caster, spell) + 1e-6)
    end

    local source = caster:isPC() and caster or caster:getMaster()
    local sourceLevel = source and source.getMainLvl and source:getMainLvl() or 0
    damage = levelingHpCap.apply(sourceLevel, target, damage)

    local cap = catalog.getOutgoingDamageCap(caster, spell, target)
    if cap and cap > 0 then
        damage = math.min(damage, cap)
    end

    return damage
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
        -- Splash extras do not inherit the 9x-105x main-hand table.
        if catalog.isAoESplashTarget(spell, target) then
            return 1
        end

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
