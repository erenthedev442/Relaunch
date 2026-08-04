-----------------------------------
-- Trust: Koru-Moru
-- RDM/WHM buffer. Does not engage / no WS. Convert @ very low MP.
-- Job-based Haste II / Flurry II / Refresh II (no Haste overwrite).
-- Phalanx II on top enmity (upgrade Phalanx I; never over Barrier Tusk).
-- Distract II only on /check High Evasion. B-tier buffer — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Haste II jobs (retail).
local HASTE_JOBS =
{
    [xi.job.WAR] = true, [xi.job.MNK] = true, [xi.job.THF] = true,
    [xi.job.PLD] = true, [xi.job.DRK] = true, [xi.job.BST] = true,
    [xi.job.SAM] = true, [xi.job.NIN] = true, [xi.job.DRG] = true,
    [xi.job.BLU] = true, [xi.job.PUP] = true, [xi.job.DNC] = true,
    [xi.job.RUN] = true,
}

-- Flurry II: RNG / COR.
local FLURRY_JOBS =
{
    [xi.job.RNG] = true,
    [xi.job.COR] = true,
}

-- Refresh II: WHM/BLM/RDM/PLD/SMN/GEO/RUN/SCH*, or WHM sub.
local REFRESH_JOBS =
{
    [xi.job.WHM] = true, [xi.job.BLM] = true, [xi.job.RDM] = true,
    [xi.job.PLD] = true, [xi.job.SMN] = true, [xi.job.GEO] = true,
    [xi.job.RUN] = true, [xi.job.SCH] = true,
}

local function canAct(mobArg)
    local action = mobArg:getCurrentAction()
    return mobArg:isEngaged() and
        (action == xi.action.category.NONE or
            action == xi.action.category.BASIC_ATTACK or
            action == xi.action.category.MOBABILITY_FINISH)
end

local function schBlockingRefresh(member)
    return member:getMainJob() == xi.job.SCH and
        (member:hasStatusEffect(xi.effect.SUBLIMATION_ACTIVATED) or
            member:hasStatusEffect(xi.effect.SUBLIMATION_COMPLETE))
end

local function wantsRefresh(member)
    if not member:isAlive() or member:hasStatusEffect(xi.effect.REFRESH) then
        return false
    end

    if schBlockingRefresh(member) then
        return false
    end

    if REFRESH_JOBS[member:getMainJob()] then
        return true
    end

    return member:getSubJob() == xi.job.WHM
end

-- Do not overwrite Haste with Haste II / Flurry II.
local function wantsHaste(member)
    return member:isAlive() and
        HASTE_JOBS[member:getMainJob()] and
        not member:hasStatusEffect(xi.effect.HASTE)
end

local function wantsFlurry(member)
    return member:isAlive() and
        FLURRY_JOBS[member:getMainJob()] and
        not member:hasStatusEffect(xi.effect.FLURRY) and
        not member:hasStatusEffect(xi.effect.FLURRY_II) and
        not member:hasStatusEffect(xi.effect.HASTE)
end

-- Phalanx II even over Phalanx I; never over Barrier Tusk (PHALANX power 15).
local function wantsPhalanxII(entity)
    if not entity or not entity:isAlive() then
        return false
    end

    local effect = entity:getStatusEffect(xi.effect.PHALANX)
    if not effect then
        return true
    end

    local power = effect:getPower()
    if power == 15 then
        return false -- Barrier Tusk
    end

    -- Already at Phalanx II potency (~28–35; retail ~31@99).
    if power >= 28 then
        return false
    end

    return true
end

local function getTopEnmityAlly(mobArg)
    local foe = mobArg:getTarget()
    if not foe or not foe:isMob() then
        return nil
    end

    local list = foe:getEnmityList()
    if not list then
        return nil
    end

    local bestEnt = nil
    local bestScore = -1
    for _, entry in pairs(list) do
        local ent = entry.entity
        if ent and ent:isAlive() then
            local score = (entry.ce or 0) + (entry.ve or 0)
            if score > bestScore then
                bestScore = score
                bestEnt = ent
            end
        end
    end

    return bestEnt
end

-- /check High Evasion: (mobEva - 30) > player ACC.
local function isHighEvasion(master, target)
    if not master or not target then
        return false
    end

    return (target:getEVA() - 30) > master:getACC()
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.SHANTOTTO] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.SHANTOTTO_II] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.AJIDO_MARUJIDO] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Convert only at very low MP (retail; leaves him DoT-vulnerable).
    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, 5 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CONVERT })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECT })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELL })

    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL })

    -- Lower-tier stays: do not upgrade Dia/Slow once applied.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.DIA }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.DIA }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)

    -- Single tick: job buffs → Phalanx II → Distract (avoids stacked castSpell).
    mob:addListener('COMBAT_TICK', 'KORU_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local master = mobArg:getMaster()
        if not master then
            return
        end

        local party = master:getPartyWithTrusts() or {}
        for _, member in pairs(party) do
            if wantsFlurry(member) then
                mobArg:castSpell(xi.magic.spell.FLURRY_II, member)
                return
            end
        end

        for _, member in pairs(party) do
            if wantsHaste(member) then
                mobArg:castSpell(xi.magic.spell.HASTE_II, member)
                return
            end
        end

        for _, member in pairs(party) do
            if wantsRefresh(member) then
                mobArg:castSpell(xi.magic.spell.REFRESH_II, member)
                return
            end
        end

        local ally = getTopEnmityAlly(mobArg)
        if ally and wantsPhalanxII(ally) then
            mobArg:castSpell(xi.magic.spell.PHALANX_II, ally)
            return
        end

        local target = mobArg:getTarget()
        if target and not target:hasStatusEffect(xi.effect.EVASION_DOWN) then
            if isHighEvasion(master, target) then
                mobArg:castSpell(xi.magic.spell.DISTRACT_II, target)
            else
                mobArg:castSpell(xi.magic.spell.DISTRACT, target)
            end
        end
    end)

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
