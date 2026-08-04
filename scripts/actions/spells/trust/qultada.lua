-----------------------------------
-- Trust: Qultada
-- COR/RNG. Phantom Rolls (Chaos/Hunter + Fighter/Evoker/Corsair),
-- Double-Up / Snake Eye, Light Shot (Dia) / Dark Shot (Dispel),
-- Triple Shot. WS @1000 after rolls settle; hold during bust.
-- A-tier ranged_dd (skirmisher) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_LIGHT_SHOT = 2015
local MS_DARK_SHOT  = 2016

local RECAST_PHANTOM = 193
local RECAST_DOUBLE  = 194
local RECAST_SNAKE   = 197

local LUCKY =
{
    [xi.ja.CHAOS_ROLL]    = 4,
    [xi.ja.HUNTERS_ROLL]  = 4,
    [xi.ja.FIGHTERS_ROLL] = 5,
    [xi.ja.EVOKERS_ROLL]  = 5,
    [xi.ja.CORSAIRS_ROLL] = 5,
}

local function canAct(mobArg)
    local action = mobArg:getCurrentAction()
    return mobArg:isEngaged() and
        (action == xi.action.category.NONE or
            action == xi.action.category.BASIC_ATTACK or
            action == xi.action.category.MOBABILITY_FINISH)
end

-- Real Dedication/Commitment only (ignore Kupofried icon placeholders).
local function hasExpBoost(master)
    if not master then
        return false
    end

    if
        master:hasStatusEffect(xi.effect.DEDICATION) and
        master:getLocalVar('KupofriedDedicationIcon') ~= 1
    then
        return true
    end

    if
        master:hasStatusEffect(xi.effect.COMMITMENT) and
        master:getLocalVar('KupofriedCommitmentIcon') ~= 1
    then
        return true
    end

    return false
end

local function partyHasLowMp(master)
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and member:getMPP() < 66 then
            return true
        end
    end

    return false
end

-- Low ACC vs current foe → Hunter's instead of Chaos.
local function needsHunterRoll(master, target)
    if not master or not target then
        return false
    end

    return master:getACC() < target:getEVA()
end

local function pickRollPair(master, target)
    local rollA = needsHunterRoll(master, target) and xi.ja.HUNTERS_ROLL or xi.ja.CHAOS_ROLL
    local effA  = needsHunterRoll(master, target) and xi.effect.HUNTERS_ROLL or xi.effect.CHAOS_ROLL

    local rollB = xi.ja.FIGHTERS_ROLL
    local effB  = xi.effect.FIGHTERS_ROLL

    if hasExpBoost(master) then
        rollB = xi.ja.CORSAIRS_ROLL
        effB  = xi.effect.CORSAIRS_ROLL
    elseif partyHasLowMp(master) then
        rollB = xi.ja.EVOKERS_ROLL
        effB  = xi.effect.EVOKERS_ROLL
    end

    return rollA, effA, rollB, effB
end

local function getActiveRollTotal(mobArg)
    local du = mobArg:getStatusEffect(xi.effect.DOUBLE_UP_CHANCE)
    if not du then
        return nil, nil, nil
    end

    local effectId = du:getSubPower()
    local rollEffect = mobArg:getStatusEffect(effectId)
    if not rollEffect then
        return nil, nil, nil
    end

    local abilityId = mobArg:getLocalVar('corsairActiveRoll')
    if abilityId == 0 then
        abilityId = du:getSourceTypeParam()
    end

    return rollEffect:getSubPower(), LUCKY[abilityId], abilityId
end

local function rollsSettled(mobArg, master, target)
    if mobArg:hasStatusEffect(xi.effect.DOUBLE_UP_CHANCE) then
        return false
    end

    if mobArg:numBustEffects() > 0 then
        return false
    end

    local _, effA, _, effB = pickRollPair(master, target)
    if not mobArg:hasStatusEffect(effA) or not mobArg:hasStatusEffect(effB) then
        return false
    end

    return true
end

local function setWsGate(mobArg, allow)
    if allow then
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    else
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Winning Streak (75): +100s Phantom Roll duration.
    if mob:getMainLvl() >= 75 then
        mob:addMod(xi.mod.PHANTOM_DURATION, 100)
    end

    -- Enhanced Magic Accuracy (Dec 2015 note).
    mob:addMod(xi.mod.MACC, math.floor(mob:getMainLvl() / 5))

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.TRIPLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TRIPLE_SHOT })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 10)

    setWsGate(mob, false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addListener('COMBAT_TICK', 'QULTADA_AI', function(mobArg)
        local master = mobArg:getMaster()
        local target = mobArg:getTarget()
        if not master or not target or not target:isAlive() then
            return
        end

        local settled = rollsSettled(mobArg, master, target)
        setWsGate(mobArg, settled)

        if not canAct(mobArg) then
            return
        end

        ----------------------------------------------------------
        -- Double-Up / Snake Eye window
        ----------------------------------------------------------
        if mobArg:hasStatusEffect(xi.effect.DOUBLE_UP_CHANCE) then
            local total, lucky = getActiveRollTotal(mobArg)
            if not total or not lucky then
                return
            end

            -- Snake Eye when one away from lucky or 11.
            if total == lucky - 1 or total == 10 then
                if
                    not mobArg:hasStatusEffect(xi.effect.SNAKE_EYE) and
                    not mobArg:hasRecast(xi.recast.ABILITY, RECAST_SNAKE)
                then
                    mobArg:useJobAbility(xi.ja.SNAKE_EYE, mobArg)
                    return
                end

                if not mobArg:hasRecast(xi.recast.ABILITY, RECAST_DOUBLE) then
                    mobArg:useJobAbility(xi.ja.DOUBLE_UP, mobArg)
                end

                return
            end

            -- Double-Up any non-lucky 1–6 (can bust).
            if
                total >= 1 and
                total <= 6 and
                total ~= lucky and
                not mobArg:hasRecast(xi.recast.ABILITY, RECAST_DOUBLE)
            then
                mobArg:useJobAbility(xi.ja.DOUBLE_UP, mobArg)
            end

            return
        end

        ----------------------------------------------------------
        -- Apply / refresh Phantom Rolls
        ----------------------------------------------------------
        if not mobArg:hasRecast(xi.recast.ABILITY, RECAST_PHANTOM) then
            local rollA, effA, rollB, effB = pickRollPair(master, target)

            if not mobArg:hasStatusEffect(effA) then
                mobArg:useJobAbility(rollA, mobArg)
                return
            end

            if not mobArg:hasStatusEffect(effB) then
                mobArg:useJobAbility(rollB, mobArg)
                return
            end
        end

        ----------------------------------------------------------
        -- Quick Draw utility only (no damage QD)
        ----------------------------------------------------------
        local now = os.time()
        if now < mobArg:getLocalVar('qultadaQdReady') then
            return
        end

        if target:hasStatusEffect(xi.effect.DIA) then
            mobArg:setLocalVar('qultadaQdReady', now + 12)
            mobArg:useMobAbility(MS_LIGHT_SHOT, target)
            return
        end

        if target:hasStatusEffectByFlag(xi.effectFlag.DISPELABLE) then
            mobArg:setLocalVar('qultadaQdReady', now + 12)
            mobArg:useMobAbility(MS_DARK_SHOT, target)
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
