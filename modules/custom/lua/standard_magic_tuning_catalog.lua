-----------------------------------
-- Level-scaled baseline tuning for direct player-cast magical damage.
--
-- Reuses the ordinary WS progression curve so physical and magical damage
-- target the same share of enemy HP. Only direct elemental/divine/ninjutsu
-- casts and magical Blue Magic are eligible; weaponskills, abilities, pets,
-- drains, enfeebles and Helix damage-over-time spells remain untouched.
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
    return
        caster ~= nil and
        target ~= nil and
        caster:isPC() and
        target:isMob()
end

local function isNativeMainJobSpell(caster, spell)
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

function catalog.isMagicalBlueEligible(caster, target, spell, params)
    return
        validCasterAndTarget(caster, target) and
        isNativeMainJobSpell(caster, spell) and
        params ~= nil and
        params.attackType == xi.attackType.MAGICAL
end

function catalog.getDamageCap(caster)
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
    local playerLevel = math.max(1, caster:getMainLvl())
    local spellLevel  = spell:getLevel(caster:getMainJob())
    if not spellLevel or spellLevel <= 0 then
        return 0
    end

    return utils.clamp(
        spellLevel / (playerLevel * catalog.FULL_POWER_LEVEL_RATIO),
        catalog.MIN_SPELL_FACTOR,
        1.00)
end

function catalog.getDamageBonus(caster, target, spell)
    local levelScaledBonus = progression.getDamageBonus(
        caster:getMainLvl(), target:getMainLvl(), target:getMaxHP())

    return math.floor(
        levelScaledBonus * catalog.getSpellProgressionFactor(caster, spell) + 0.5)
end

function catalog.getMagicAccuracyPenalty(caster, target)
    return progression.getAccuracyPenalty(
        caster:getMainLvl(), target:getMainLvl())
end

return catalog
