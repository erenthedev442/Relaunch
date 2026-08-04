-----------------------------------
-- Trust: Jakoh Wahcondalo UC
-- Spell ID: 956 | Pool ID: 5956
-- THF/WAR knife. Feint on CD, Conspirator, SA/TA into WS.
-- WS @>2000 with SA and/or TA; hold to 3000 waiting for position.
-- Random WS (no skillchain): Dancing Edge (5) / Evisceration (25) /
-- Sarva's Storm (50, Rudra-like). ~55 TP/hit (knife delay).
-- A-tier melee_dd (skirmisher) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_DANCING = 23
local MS_EVISC   = 25
local MS_SARVA   = 3497

local RECAST_SA    = 64 -- sneak_attack
local RECAST_TA    = 66 -- trick_attack
local RECAST_FEINT = 68 -- feint

local function isWearingJakohShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.JAKOH_WAHCONDALO_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

-- Retail: TA only when positioned correctly with the player.
local function canTrickAttack(mobArg)
    local master = mobArg:getMaster()
    if not master or not master:isAlive() then
        return false
    end

    return mobArg:checkDistance(master) <= 3.0 and mobArg:isBehind(master)
end

local function pickWS(mobArg)
    local lvl = mobArg:getMainLvl()
    local pool = {}

    if lvl >= 5 then
        pool[#pool + 1] = MS_DANCING
    end

    if lvl >= 25 then
        pool[#pool + 1] = MS_EVISC
    end

    if lvl >= 50 then
        pool[#pool + 1] = MS_SARVA
    end

    if #pool == 0 then
        return nil
    end

    return pool[math.random(#pool)]
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingJakohShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Knife delay (~55 base TP/hit). Shared A-tier Store TP package still applies.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Conspirator uptime (Accuracy when not top hate).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.CONSPIRATOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CONSPIRATOR })

    -- WS are listener-driven (pool skill_list_id = 0) so he never auto-closes SCs.
    mob:addListener('COMBAT_TICK', 'JAKOH_UC_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Feint: open and reuse on cooldown.
        if
            mobArg:getMainLvl() >= 75 and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FEINT)
        then
            mobArg:useJobAbility(xi.ja.FEINT, mobArg)
            return
        end

        local tp = mobArg:getTP()
        if tp < 2000 then
            return
        end

        -- Prefer SA behind the enemy, else TA behind the master.
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
            return
        end

        local hasSATA =
            mobArg:hasStatusEffect(xi.effect.SNEAK_ATTACK) or
            mobArg:hasStatusEffect(xi.effect.TRICK_ATTACK)

        -- Dump at 3000 even if positioning never lined up.
        if not hasSATA and tp < 3000 then
            return
        end

        local wsId = pickWS(mobArg)
        if wsId then
            mobArg:useMobAbility(wsId, battleTarget)
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
