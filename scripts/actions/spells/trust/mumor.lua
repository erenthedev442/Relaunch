-----------------------------------
-- Trust: Mumor
-- DNC/WAR. Club. Skullbreaker @1000 TP.
-- Abilities: Saber Dance (always), Stutter Step, Haste/Drain Samba,
--   Violent Flourish (stun TP moves). No waltzes.
-- Stutter Step to daze 5; refresh only when <10s remaining.
-- Haste Samba if any party main can Cure (WHM/RDM/SCH/PLD) or target undead;
-- else Drain Samba I–III.
-- B-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_STUTTER = 203 -- xi.ja.STUTTER_STEP

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

local function getWeakenedDaze(target)
    local eff = target:getStatusEffect(xi.effect.WEAKENED_DAZE_1)
    if not eff then
        return 0, 0
    end

    return eff:getPower() or 0, eff:getTimeRemaining() or 0
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
    return xi.trust.canCast(caster, spell, xi.magic.spell.MUMOR_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.UKA_TOTLIHN] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ULLEGORE] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Always Saber Dance; no waltzes.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SABER_DANCE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SABER_DANCE })

    -- Violent Flourish to interrupt TP moves.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })

    -- Skullbreaker ASAP at 1000 TP.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)

    -- Uka synergy: +Samba duration while she is out.
    mob:addListener('COMBAT_TICK', 'MUMOR_UKA_SAMBA', function(mobArg)
        local boost = 0
        local master = mobArg:getMaster()
        if master then
            for _, member in pairs(master:getPartyWithTrusts() or {}) do
                if
                    member:getObjType() == xi.objType.TRUST and
                    member:getTrustID() == xi.magic.spell.UKA_TOTLIHN
                then
                    boost = 10
                    break
                end
            end
        end

        mobArg:setMod(xi.mod.SAMBA_DURATION, boost)
    end)

    mob:addListener('COMBAT_TICK', 'MUMOR_AI', function(mobArg)
        if not mobArg:isEngaged() then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Samba: Haste if any party main can Cure or target is Undead; else Drain line.
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

        -- Stutter Step: build to daze 5; at 5 only refresh when <10s remaining.
        local dazePower, timeRemaining = getWeakenedDaze(battleTarget)
        local needsStep =
            dazePower < 5 or
            (dazePower >= 5 and timeRemaining > 0 and timeRemaining < 10000)

        if
            needsStep and
            mobArg:getTP() >= 100 and
            canAct(mobArg) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_STUTTER)
        then
            mobArg:useJobAbility(xi.ja.STUTTER_STEP, battleTarget)
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
