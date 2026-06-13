-----------------------------------
-- func: convergence
-- desc: Cast Convergence (an RDM-only custom spell) on your current target:
--       a random element + enfeeble combo that deals magic damage plus one
--       of six status effects (Slow, Blind, Paralyze, Silence, Gravity, or
--       Bind). Exposed as a command because the client cannot hard-cast
--       custom spell IDs.
--
-- Convergence is a Legendary-only custom spell (ID 1021). The stock client
-- has no data for IDs >= 1020, so it cannot hard-cast it ("a command error
-- occurred"). This command runs the server-side effect on your current
-- battle target: RDM 50 main job, 60 MP, 45s recast.
--
-- The logic mirrors scripts/actions/spells/white/convergence.lua. We REPLICATE
-- it here rather than require()-and-call it, because the spell version calls
-- spell:getSpellGroup() and target:takeSpellDamage(.., spell, ..) which both
-- need a live CSpell object the command does not have. We substitute the
-- literal spell group (6, == convergence's spell_list `group`) and
-- target:takeDamage() -- the exact same damage path divine_aegis.lua uses.
--
-- Lives in modules/custom/commands/ -> auto-registers as !convergence.
-----------------------------------
require('scripts/globals/combat/magic_hit_rate')
local gate = require('modules/custom/lua/custom_spell_command')

-- == convergence's spell_list `group`; this is what spell:getSpellGroup()
-- returns and what calculateResistRate expects as its 3rd argument.
local SPELL_GROUP = 6

-- Element/enfeeble pairs -- copied verbatim from convergence.lua, plus a
-- display `name` for the result message ('power' is base enfeeble potency;
-- BIND overrides it with target movement speed).
local PAIRS =
{
    { name = 'Slow',      effect = xi.effect.SLOW,      element = xi.element.FIRE,    dmgType = xi.damageType.FIRE,    power = 1500, duration = 90 },
    { name = 'Blind',     effect = xi.effect.BLINDNESS, element = xi.element.LIGHT,   dmgType = xi.damageType.LIGHT,   power = 25,   duration = 90 },
    { name = 'Paralysis', effect = xi.effect.PARALYSIS, element = xi.element.WATER,   dmgType = xi.damageType.WATER,   power = 15,   duration = 90 },
    { name = 'Silence',   effect = xi.effect.SILENCE,   element = xi.element.EARTH,   dmgType = xi.damageType.EARTH,   power = 1,    duration = 90 },
    { name = 'Gravity',   effect = xi.effect.WEIGHT,    element = xi.element.WIND,    dmgType = xi.damageType.WIND,    power = 26,   duration = 90 },
    { name = 'Bind',      effect = xi.effect.BIND,      element = xi.element.THUNDER, dmgType = xi.damageType.THUNDER, power = 0,    duration = 30 },
}

local cfg =
{
    name    = 'Convergence',
    spellId = 1021,
    jobs    = { [xi.job.RDM] = 50 },
    reqText = 'RDM 50',
    mp      = 60,
    recast  = 45,
    cdVar   = 'cmdspell_convergence_cd',
}

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not gate.check(player, cfg) then
        return
    end

    -- getTarget() returns the player's battle target, so they must be engaged.
    local target = player:getTarget()
    if target == nil or target:isDead() then
        player:printToPlayer('Convergence: engage an enemy first (no valid target).', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Pick a random element/enfeeble pair for this cast.
    local choice = PAIRS[math.random(#PAIRS)]

    -- Resist check using the chosen element + Enfeebling Magic skill.
    local resistRate = xi.combat.magicHitRate.calculateResistRate(
        player, target,
        SPELL_GROUP,
        xi.skill.ENFEEBLING_MAGIC,
        0,             -- skillRank (unused when skillType is set)
        choice.element,
        xi.mod.MND,    -- primary stat for enfeebling
        choice.effect, -- effectId
        0)             -- bonusMacc

    -- The cast happened: charge MP + start the recast even on a full resist.
    gate.commit(player, cfg)

    if resistRate == 0 then
        player:printToPlayer('Convergence: fully resisted.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Apply the status effect (duration scaled by resist; BIND uses speed).
    local power    = choice.power
    local duration = math.floor(choice.duration * resistRate)
    if choice.effect == xi.effect.BIND then
        power = target:getSpeed()
    elseif resistRate < 1 then
        power = math.floor(power * resistRate)
    end
    target:addStatusEffect(choice.effect, { power = power, duration = duration, origin = player, tick = 0 })

    -- Elemental damage. takeDamage() (not takeSpellDamage) needs no spell object.
    local baseDmg  = math.floor(player:getStat(xi.mod.INT) * 2.5 + player:getStat(xi.mod.MND) * 2.0 + 80)
    local finalDmg = math.max(1, math.floor(baseDmg * resistRate))
    finalDmg = math.min(finalDmg, target:getHP())
    target:takeDamage(finalDmg, player, xi.attackType.MAGICAL, choice.dmgType)
    target:updateEnmityFromDamage(player, finalDmg)

    player:printToPlayer(string.format('Convergence: %s + %d damage.', choice.name, finalDmg), xi.msg.channel.SYSTEM_3)
end

return commandObj
