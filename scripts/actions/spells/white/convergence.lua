-----------------------------------
-- Spell: Convergence (ID 1021)
--
-- Custom spell — Legendary server only.
-- RDM only, level 50. Enfeebling Magic.
--
-- Mechanic:
--   Single-target enemy spell that randomly binds one of six element/enfeeble
--   pairs together, delivering both damage and a status effect simultaneously.
--
--   Each cast randomly picks one of:
--     Slow      + Fire element
--     Blind     + Light element
--     Paralysis + Water element
--     Silence   + Earth element
--     Gravity   + Wind element
--     Bind      + Thunder element
--
--   Damage  = floor( (INT*2.5 + MND*2.0 + 80) * resistRate )
--   Enfeeble applied at standard potency, duration reduced by resistRate.
--   Full resist → MAGIC_RESIST message, no damage, no enfeeble.
-----------------------------------
require('scripts/globals/combat/magic_hit_rate')
---@type TSpell
local spellObject = {}

-- Element/enfeeble pairs.  Fields: effect, element, dmgType, power, duration.
-- 'power' is the base enfeeble potency; for BIND it is overridden by target speed.
local PAIRS =
{
    { effect = xi.effect.SLOW,      element = xi.element.FIRE,    dmgType = xi.damageType.FIRE,    power = 1500, duration = 90 },
    { effect = xi.effect.BLINDNESS, element = xi.element.LIGHT,   dmgType = xi.damageType.LIGHT,   power = 25,   duration = 90 },
    { effect = xi.effect.PARALYSIS, element = xi.element.WATER,   dmgType = xi.damageType.WATER,   power = 15,   duration = 90 },
    { effect = xi.effect.SILENCE,   element = xi.element.EARTH,   dmgType = xi.damageType.EARTH,   power = 1,    duration = 90 },
    { effect = xi.effect.WEIGHT,    element = xi.element.WIND,    dmgType = xi.damageType.WIND,    power = 26,   duration = 90 },
    { effect = xi.effect.BIND,      element = xi.element.THUNDER, dmgType = xi.damageType.THUNDER, power = 0,    duration = 30 },
}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Choose a random pair for this cast.
    local choice = PAIRS[math.random(#PAIRS)]

    -- Resist check using the chosen element and status effect.
    local resistRate = xi.combat.magicHitRate.calculateResistRate(
        caster, target,
        spell:getSpellGroup(),
        xi.skill.ENFEEBLING_MAGIC,
        0,                   -- skillRank (unused when skillType is set)
        choice.element,
        xi.mod.MND,          -- primary stat for enfeebling
        choice.effect,       -- effectId
        0                    -- bonusMacc
    )

    -- Full resist: bail out.
    if resistRate == 0 then
        spell:setMsg(xi.msg.basic.MAGIC_RESIST)
        return 0
    end

    -- Apply the status effect.
    local power    = choice.power
    local duration = math.floor(choice.duration * resistRate)

    -- BIND uses target movement speed as its potency.
    if choice.effect == xi.effect.BIND then
        power = target:getSpeed()
    elseif resistRate < 1 then
        power = math.floor(power * resistRate)
    end

    target:addStatusEffect(choice.effect, {
        power    = power,
        duration = duration,
        origin   = caster,
        tick     = 0,
    })

    -- Calculate elemental damage.
    local int      = caster:getStat(xi.mod.INT)
    local mnd      = caster:getStat(xi.mod.MND)
    local baseDmg  = math.floor(int * 2.5 + mnd * 2.0 + 80)
    local finalDmg = math.max(1, math.floor(baseDmg * resistRate))

    -- Clamp to target's remaining HP to avoid overkill artefacts.
    finalDmg = math.min(finalDmg, target:getHP())

    -- Apply damage (handles enmity tracking internally).
    target:takeSpellDamage(caster, spell, finalDmg, xi.attackType.MAGICAL, choice.dmgType)
    target:updateEnmityFromDamage(caster, finalDmg)

    return finalDmg
end

return spellObject
