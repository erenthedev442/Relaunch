-----------------------------------
-- Trust: Zeid II
-- DRK/WAR Great Sword. Stun, Absorb-Attri. Last Resort, Souleater.
-- Exclusive Ground Strike (available from level 50; holds 3000 TP below that).
-- CLOSER@3000 (SC with others; dump at 3000). Stun interrupts. Souleater only
-- with a healer present (Automaton ignored). Desperate Blows via DRK traits + LR.
-- S-tier melee_dd (weaponskill) CORE — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_GROUND_STRIKE = 56
local RECAST_SOULEATER = 85

local HEALER_JOBS =
{
    [xi.job.WHM] = true,
    [xi.job.RDM] = true,
    [xi.job.PLD] = true,
    [xi.job.SCH] = true,
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

-- Retail: Souleater only with a healer present. Automaton / pets do not count.
local function partyHasHealer(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getObjType() ~= xi.objType.PET and
            HEALER_JOBS[member:getMainJob()]
        then
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ZEID)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.LION_II] = xi.trust.messageOffset.TEAMWORK_1,
    })

    mob:addListener('WEAPONSKILL_USE', 'ZEID_II_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_GROUND_STRIKE then
            -- Never again will I lose sight of who I am
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    -- Stun interrupt.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.LAST_RESORT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.LAST_RESORT })

    -- Steal enhancements (Chacharoon Tripe Gripe synergy path).
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_ATTRI }, 60)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Close SC when possible; otherwise hold to 3000 then Ground Strike.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 3000)

    mob:addListener('COMBAT_TICK', 'ZEID_II_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        if
            partyHasHealer(mobArg) and
            not mobArg:hasStatusEffect(xi.effect.SOULEATER) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_SOULEATER)
        then
            mobArg:useJobAbility(xi.ja.SOULEATER, mobArg)
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
