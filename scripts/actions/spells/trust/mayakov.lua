-----------------------------------
-- Trust: Mayakov
-- DNC/WAR. Sword.
-- Abilities: Drain Samba I–III, Haste Samba (5/5 merit = 10% JA Haste),
--   Feather Step, Saber Dance, Climactic Flourish.
-- WS: Coming Up Roses / Fast Blade / Swift Blade / Vorpal Blade.
-- Feather Step to daze 10, then WS more often; Climactic before WS.
-- Holds to 2000 TP waiting for Climactic; does not skillchain.
-- C-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_COMING_UP_ROSES = 3454
local WS_ALTS            = { 32, 40, 41 } -- Fast / Vorpal / Swift
local RECAST_CLIMACTIC   = 226
local RECAST_FEATHER     = 220

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

local function getBewilderedPower(target)
    local eff = target:getStatusEffect(xi.effect.BEWILDERED_DAZE_1)
    return eff and eff:getPower() or 0
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
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Saber Dance on engage / refresh.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SABER_DANCE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SABER_DANCE })

    -- Samba: Haste when undead; otherwise COMBAT_TICK picks Haste vs Drain by party jobs.
    mob:addGambit(ai.t.TARGET, { ai.c.IS_ECOSYSTEM, xi.ecosystem.UNDEAD }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASTE_SAMBA })

    -- Block built-in WS; drive Feather Step / Climactic / hold-to-2000 ourselves.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
    mob:setLocalVar('mayaWsLock', 0)

    -- 5/5 Haste Samba Effect merits → 10% JA Haste (base 500 + merit 500).
    mob:addListener('ABILITY_USE', 'MAYAKOV_HASTE_SAMBA', function(mobArg, target, ability, action)
        if ability:getID() ~= xi.ja.HASTE_SAMBA then
            return
        end

        mobArg:delStatusEffect(xi.effect.HASTE_SAMBA)
        mobArg:addStatusEffect(xi.effect.HASTE_SAMBA, {
            power    = 1000,
            duration = 120,
            origin   = mobArg,
        })
    end)

    mob:addListener('COMBAT_TICK', 'MAYAKOV_AI', function(mobArg)
        if not mobArg:isEngaged() then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Samba choice: Haste if a party main can Cure, else Drain line.
        if not mobArg:hasStatusEffect(xi.effect.HASTE_SAMBA) and
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

        local tp = mobArg:getTP()
        local dazePower = getBewilderedPower(battleTarget)

        -- Build Feather Step to daze 10 (DNC main max). Costs 100 TP.
        if
            dazePower < 10 and
            tp >= 100 and
            canAct(mobArg) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FEATHER)
        then
            mobArg:useJobAbility(xi.ja.FEATHER_STEP, battleTarget)
            return
        end

        -- At daze 10+: only occasionally refresh to maintain.
        if
            dazePower >= 10 and
            tp >= 100 and
            tp < 1000 and
            canAct(mobArg) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FEATHER) and
            math.random(100) <= 12
        then
            mobArg:useJobAbility(xi.ja.FEATHER_STEP, battleTarget)
            return
        end

        if tp < 1000 then
            mobArg:setLocalVar('mayaWsLock', 0)
            return
        end

        if mobArg:getLocalVar('mayaWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        local climacticUp = mobArg:hasStatusEffect(xi.effect.CLIMACTIC_FLOURISH)
        local climacticReady =
            finishingMoves(mobArg) >= 1 and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_CLIMACTIC)

        -- Climactic before WS when ready.
        if climacticReady and not climacticUp then
            mobArg:useJobAbility(xi.ja.CLIMACTIC_FLOURISH, mobArg)
            return
        end

        -- Hold under 2000 while Climactic is on recast (retail: wait for it).
        if not climacticUp and not climacticReady and tp < 2000 then
            return
        end

        -- No skillchain attempts — dump random/signature WS.
        local skillId = MS_COMING_UP_ROSES
        if math.random(100) > 70 then
            skillId = WS_ALTS[math.random(#WS_ALTS)]
        end

        mobArg:setLocalVar('mayaWsLock', 1)
        mobArg:useMobAbility(skillId, battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'MAYAKOV_WS', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('mayaWsLock', 0)
        if skill:getID() == MS_COMING_UP_ROSES then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
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
