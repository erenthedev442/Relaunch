-----------------------------------
-- Trust: Maximilian
-- THF/NIN. Dual wields swords.
-- WS: Fast Blade / Vorpal Blade / Swift Blade (random opener).
-- Traits: Treasure Hunter 3, Dual Wield, Triple Attack.
-- Opens for the player only when master TP >= 1500 (not other trusts).
-- Closes SCs with players/trusts; otherwise dumps at 2500 TP.
-- A-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local WS_POOL =
{
    32, -- Fast Blade
    40, -- Vorpal Blade
    41, -- Swift Blade
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- THF/NIN flavor (skirmisher package already carries haste/TA floors).
    mob:addMod(xi.mod.TREASURE_HUNTER, 3)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 8)
    mob:setMobMod(xi.mobMod.DUAL_WIELD, 1)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Block built-in opener (OPENER treats other trusts as party TP).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    mob:setLocalVar('maxWsLock', 0)

    mob:addListener('COMBAT_TICK', 'MAXIMILIAN_TP', function(mobArg)
        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('maxWsLock', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Close SCs opened by player or other trusts.
        if battleTarget:getStatusEffect(xi.effect.SKILLCHAIN) then
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
            return
        end

        -- Hold auto-WS. Open only for the summoner @1500, else dump @2500.
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)

        if mobArg:getLocalVar('maxWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        local master = mobArg:getMaster()
        local openForPlayer = master and master:getTP() >= 1500
        if not openForPlayer and tp < 2500 then
            return
        end

        mobArg:setLocalVar('maxWsLock', 1)
        mobArg:useMobAbility(WS_POOL[math.random(#WS_POOL)], battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'MAXIMILIAN_WS_UNLOCK', function(mobArg)
        mobArg:setLocalVar('maxWsLock', 0)
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
