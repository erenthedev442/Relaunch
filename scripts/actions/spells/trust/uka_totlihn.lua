-----------------------------------
-- Trust: Uka Totlihn
-- DNC/WAR Club. Judgment @2000 TP (no skillchains).
-- Quickstep → Reverse Flourish (5 FM, low TP). Curing Waltz @<66%.
-- Healing Waltz self-only. Haste Samba if party has Cure job or undead;
-- else Drain Samba I–III. Mumor synergy: Waltz Potency.
-- S-tier melee_dd (skirmisher) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_QUICKSTEP = 220 -- abilities.sql recastId
local RECAST_REVERSE   = 222

local healingJobs =
{
    [xi.job.WHM] = true,
    [xi.job.RDM] = true,
    [xi.job.SCH] = true,
    [xi.job.PLD] = true,
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

-- Quickstep stacks LETHARGIC_DAZE_1 power (not separate _5 effects).
local function getLethargicDaze(target)
    local eff = target:getStatusEffect(xi.effect.LETHARGIC_DAZE_1)
    if not eff then
        return 0, 0
    end

    return eff:getPower() or 0, eff:getTimeRemaining() or 0
end

local function finishingMoves(mobArg)
    local fm = mobArg:getStatusEffect(xi.effect.FINISHING_MOVE_1)
    return fm and fm:getPower() or 0
end

local function partyHasCureJob(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and healingJobs[member:getMainJob()] then
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MUMOR   ] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ULLEGORE] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Curing Waltz party <66%. Healing Waltz self only.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 66 }, { ai.r.JA, ai.s.HIGHEST_WALTZ, xi.ja.CURING_WALTZ })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.WALTZABLE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HEALING_WALTZ })

    -- Judgment when above 2000 TP; does not skillchain.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 2000)

    -- Mumor / Mumor II: +Waltz Potency while either is out.
    mob:addListener('COMBAT_TICK', 'UKA_TOTLIHN_MUMOR', function(mobArg)
        local boost = 0
        local master = mobArg:getMaster()
        if master then
            for _, member in pairs(master:getPartyWithTrusts() or {}) do
                if
                    member:getObjType() == xi.objType.TRUST and
                    (
                        member:getTrustID() == xi.magic.spell.MUMOR or
                        member:getTrustID() == xi.magic.spell.MUMOR_II
                    )
                then
                    boost = 10
                    break
                end
            end
        end

        mobArg:setMod(xi.mod.WALTZ_POTENCY, boost)
    end)

    mob:addListener('COMBAT_TICK', 'UKA_TOTLIHN_AI', function(mobArg)
        if not mobArg:isEngaged() then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Samba: Haste if any party main can Cure or target Undead; else Drain line.
        if
            not mobArg:hasStatusEffect(xi.effect.HASTE_SAMBA) and
            not mobArg:hasStatusEffect(xi.effect.DRAIN_SAMBA) and
            not mobArg:hasStatusEffect(xi.effect.ASPIR_SAMBA) and
            canAct(mobArg)
        then
            if partyHasCureJob(mobArg) or battleTarget:getEcosystem() == xi.ecosystem.UNDEAD then
                mobArg:useJobAbility(xi.ja.HASTE_SAMBA, mobArg)
            else
                local lvl = mobArg:getMainLvl()
                local drainJA = xi.ja.DRAIN_SAMBA
                if lvl >= 65 then
                    drainJA = xi.ja.DRAIN_SAMBA_III
                elseif lvl >= 45 then
                    drainJA = xi.ja.DRAIN_SAMBA_II
                end

                mobArg:useJobAbility(drainJA, mobArg)
            end

            return
        end

        -- Reverse Flourish: 5 FM and TP low (build toward Judgment @2000).
        if
            finishingMoves(mobArg) >= 5 and
            mobArg:getTP() < 1000 and
            canAct(mobArg) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_REVERSE)
        then
            mobArg:useJobAbility(xi.ja.REVERSE_FLOURISH, mobArg)
            return
        end

        -- Quickstep: build to daze 5; at 5 only refresh when <10s remaining.
        local dazePower, timeRemaining = getLethargicDaze(battleTarget)
        local needsStep =
            dazePower < 5 or
            (dazePower >= 5 and timeRemaining > 0 and timeRemaining < 10000)

        if
            needsStep and
            mobArg:getTP() >= 100 and
            canAct(mobArg) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_QUICKSTEP)
        then
            mobArg:useJobAbility(xi.ja.QUICKSTEP, battleTarget)
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
