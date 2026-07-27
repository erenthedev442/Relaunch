-----------------------------------
-- Level-scaled baseline tuning for direct player-cast magical damage.
--
-- Reuses the ordinary WS leveling curve, then assigns fresh-99/mastered bonuses
-- by spell family and tier. Direct elemental/divine/ninjutsu casts, damaging
-- Blue Magic (physical, magical, and breath), and player-automaton nukes are
-- eligible. Drains, enfeebles and Helix damage-over-time spells remain untouched.
-----------------------------------

local progression = require('modules/custom/lua/standard_ws_tuning_catalog')
local remaCatalog = require('modules/custom/lua/rema_ws_tier_catalog')
local primeCatalog = require('modules/custom/lua/prime_ws_tuning_catalog')
local catalog = {}

catalog.DAMAGE_CAP             = 99999
catalog.REMA_DAMAGE_CAP        = 999999
catalog.PRIME_DAMAGE_CAP       = 1999999
catalog.FULL_POWER_LEVEL_RATIO = 0.70
catalog.MIN_SPELL_FACTOR       = 0.15

catalog.BONUSES =
{
    elementalHigh = { fresh = 25000, mastered = 35000 },
    elementalMid  = { fresh = 18000, mastered = 27000 },
    elementalLow  = { fresh = 12000, mastered = 18000 },
    ninjutsu      = { fresh =  8000, mastered = 12000 },
    divine        = { fresh = 12000, mastered = 20000 },
    blue          = { fresh = 16000, mastered = 25000 },
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

    return
        directSkills[spell:getSkillType()] == true and
        isNativeMainJobSpell(caster, spell) and
        not isHelix(spell:getID())
end

function catalog.isBlueDamageEligible(caster, target, spell, params)
    return
        validCasterAndTarget(caster, target) and
        isNativeMainJobSpell(caster, spell) and
        params ~= nil and
        params.attackType ~= nil and
        params.attackType ~= xi.attackType.NONE
end

function catalog.getDamageCap(caster)
    if not caster:isPC() then
        return catalog.DAMAGE_CAP
    end

    local mainWeapon   = caster:getEquipID(xi.slot.MAIN)
    local rangedWeapon = caster:getEquipID(xi.slot.RANGED)

    if primeWeaponIds[mainWeapon] or primeWeaponIds[rangedWeapon] then
        return catalog.PRIME_DAMAGE_CAP
    end

    if remaWeaponIds[mainWeapon] or remaWeaponIds[rangedWeapon] then
        return catalog.REMA_DAMAGE_CAP
    end

    return catalog.DAMAGE_CAP
end

function catalog.getSpellProgressionFactor(caster, spell)
    local player = caster:isPC() and caster or caster:getMaster()
    local playerLevel = math.max(1, player:getMainLvl())
    local spellLevel  = spell:getLevel(player:getMainJob())
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

local function getBonusBand(caster, spell)
    local skill = spell:getSkillType()
    if skill == xi.skill.NINJUTSU then
        return catalog.BONUSES.ninjutsu
    elseif skill == xi.skill.DIVINE_MAGIC then
        return catalog.BONUSES.divine
    elseif skill == xi.skill.BLUE_MAGIC then
        return catalog.BONUSES.blue
    end

    local player = getProgressionPlayer(caster)
    local spellLevel = spell:getLevel(player:getMainJob()) or 1
    if spellLevel >= 75 or isAncientMagic(spell:getID()) then
        return catalog.BONUSES.elementalHigh
    elseif spellLevel >= 50 then
        return catalog.BONUSES.elementalMid
    end

    return catalog.BONUSES.elementalLow
end

function catalog.getDamageBonus(caster, target, spell)
    local player = getProgressionPlayer(caster)
    if caster:isAutomaton() then
        return progression.getPetDamageFloor(player, target)
    end

    if player:getMainLvl() < progression.ENDGAME_PLAYER_LEVEL then
        local levelScaledBonus = progression.getDamageBonus(
            player:getMainLvl(), target:getMainLvl(), target:getMaxHP())
        return math.floor(
            levelScaledBonus * catalog.getSpellProgressionFactor(caster, spell) + 0.5)
    end

    local band = getBonusBand(caster, spell)
    local mastery = progression.getMasteryProgress(player)
    local masteryBonus = math.floor(
        band.fresh + (band.mastered - band.fresh) * mastery + 0.5)

    -- Add rather than replace stock spell damage so INT, MAB, Magic Damage,
    -- affinity, skill, burst bonuses and equipment remain effective.
    return masteryBonus
end

function catalog.getMagicAccuracyPenalty(caster, target)
    local player = getProgressionPlayer(caster)
    return progression.getAccuracyPenalty(
        player:getMainLvl(), target:getMainLvl())
end

return catalog
