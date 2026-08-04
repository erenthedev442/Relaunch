-----------------------------------
-- Trust: Tenzen II
-- SAM/RNG Archery. Oisoya only (Namas enmity; Light/Distortion).
-- Store TP+10 + Ranged Attacks TP+100% + SAM Store TP traits (~252 TP/hit @90+).
-- Stays out of melee. Pure opener: WS only when another party member has 1000+ TP;
-- holds through 3000 TP if nobody is ready (blocks C++ ASAP-at-3000 dump).
-- B-tier ranged_dd (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_OISOYA = 3542

local function canAct(mob)
    -- AA off; RA gambit leaves him on NONE between shots (not BASIC_ATTACK).
    if not mob:isEngaged() or mob:hasPreventActionEffect() then
        return false
    end

    local act = mob:getCurrentAction()
    return act == xi.action.category.NONE or act == xi.action.category.BASIC_ATTACK
end

local function allyHasTp(mob, threshold)
    local master = mob:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member ~= mob and
            member:isAlive() and
            member:getTP() >= threshold
        then
            return true
        end
    end

    return false
end

-- SAM Store TP trait ladder (retail Trust TP curve is trait-based).
local function samStoreTp(level)
    if level >= 90 then
        return 30
    elseif level >= 70 then
        return 25
    elseif level >= 50 then
        return 20
    elseif level >= 30 then
        return 15
    elseif level >= 10 then
        return 10
    end

    return 0
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.TENZEN)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.PRISHE] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- Store TP+10 + Ranged Attacks TP+100% + SAM traits.
    mob:addMod(xi.mod.STORETP, 10)
    mob:addMod(xi.mod.STORETP, 100)
    mob:addMod(xi.mod.STORETP, samStoreTp(mob:getMainLvl()))
    mob:addMod(xi.mod.RACC, 50)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })
    mob:setAutoAttackEnabled(false)
    -- Out of melee (~10'); LONG_RANGE 12' historically stuck m_InTransit.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 10)

    -- Block built-in 3000-TP dump; we fire Oisoya only as an opener.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
    mob:setMobAbilityEnabled(false)
    mob:setLocalVar('tenzenIIWsLock', 0)

    mob:addListener('COMBAT_TICK', 'TENZEN_II_OPENER', function(mobArg)
        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('tenzenIIWsLock', 0)
            return
        end

        if mobArg:getLocalVar('tenzenIIWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        -- Wait indefinitely (including at 3000) until an ally is ready to close.
        if not allyHasTp(mobArg, 1000) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        mobArg:setLocalVar('tenzenIIWsLock', 1)
        mobArg:useMobAbility(MS_OISOYA, battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'TENZEN_II_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('tenzenIIWsLock', 0)
        if skill:getID() == MS_OISOYA then
            -- Ephemeral, fleeting, fading. You are but a memory!
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
