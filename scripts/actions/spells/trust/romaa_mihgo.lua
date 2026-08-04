-----------------------------------
-- Trust: Romaa Mihgo
-- THF/WAR. Sword. Fast Blade / Vorpal / Savage / Cobra Clamp (conal Stun+Para).
-- Feint, Aura Steal (via Steal), SA / TA only when positioned (not WS-combined).
-- ASAP@1000. C-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_COBRA_CLAMP = 3297
local RECAST_SA      = 64
local RECAST_TA      = 66

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

-- Retail: TA only when positioned correctly with the player.
local function canTrickAttack(mobArg)
    local master = mobArg:getMaster()
    if not master or not master:isAlive() then
        return false
    end

    return mobArg:checkDistance(master) <= 3.0 and mobArg:isBehind(master)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NANAA_MIHGO] = xi.trust.messageOffset.TEAMWORK_1,
    })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FEINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FEINT })

    -- ASAP WS — do not hold for SA/TA (retail: SA/TA not combined with WS).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Aura Steal: pull a buff; Steal items go to the master's inventory.
    mob:setLocalVar('romaaStealReady', 0)
    mob:addListener('COMBAT_TICK', 'ROMAA_AURA_STEAL', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local now = os.time()
        if now < mobArg:getLocalVar('romaaStealReady') then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() or not battleTarget:isMob() then
            return
        end

        local hasBuff = battleTarget:countEffectWithFlag(xi.effectFlag.DISPELABLE) > 0
        local stealItem = battleTarget:getStealItem() or 0
        if not hasBuff and stealItem == 0 then
            return
        end

        mobArg:setLocalVar('romaaStealReady', now + 60)
        mobArg:useJobAbility(xi.ja.STEAL, battleTarget)

        if hasBuff then
            mobArg:stealStatusEffect(battleTarget, xi.effectFlag.DISPELABLE)
        end

        if stealItem ~= 0 then
            local master = mobArg:getMaster()
            if master and master:getFreeSlotsCount() > 0 and master:addItem(stealItem) then
                battleTarget:itemStolen()
            end
        end
    end)

    -- SA behind enemy / TA behind player — AA only, never gate WS on these.
    mob:addListener('COMBAT_TICK', 'ROMAA_SA_TA', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        if
            mobArg:isBehind(battleTarget) and
            not mobArg:hasStatusEffect(xi.effect.SNEAK_ATTACK) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_SA)
        then
            mobArg:useJobAbility(xi.ja.SNEAK_ATTACK, mobArg)
            return
        end

        if
            canTrickAttack(mobArg) and
            not mobArg:hasStatusEffect(xi.effect.TRICK_ATTACK) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_TA)
        then
            mobArg:useJobAbility(xi.ja.TRICK_ATTACK, mobArg)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'ROMAA_WS', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_COBRA_CLAMP then
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
