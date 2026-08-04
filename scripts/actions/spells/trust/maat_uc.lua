-----------------------------------
-- Trust: Maat UC
-- Spell ID: 1006 | Pool ID: 6006
-- MNK/WAR H2H. Chakra / Counterstance / Impetus. Increased Kick Attacks.
-- Exclusive WS: Hollow Smite (50+, Victory Smite-like, no Aftermath).
-- Below 50: no TP spend. Hollow Smite when:
--   - opening for the player (master TP >= 1000),
--   - closing a skillchain / Chainbound if present,
--   - or dumping at 3000 TP.
-- B-tier melee_dd (bruiser) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_HOLLOW_SMITE = 3496

local function isWearingMaatShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.MAAT_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function canCloseSkillchain(target)
    if not target then
        return false
    end

    return target:getStatusEffect(xi.effect.SKILLCHAIN) ~= nil or
        target:getStatusEffect(xi.effect.CHAINBOUND) ~= nil
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.MAAT)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingMaatShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Retail: increased Kick Attacks rate (on top of MNK Kick Attacks trait).
    mob:addMod(xi.mod.KICK_ATTACK_RATE, 25)

    mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CHAKRA })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.COUNTERSTANCE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.IMPETUS }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.IMPETUS })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- WS are listener-driven (pool skill_list_id = 0).
    mob:setLocalVar('maatUcWsLock', 0)

    mob:addListener('COMBAT_TICK', 'MAAT_UC_AI', function(mobArg)
        if mobArg:getMainLvl() < 50 then
            return
        end

        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('maatUcWsLock', 0)
            return
        end

        if mobArg:getLocalVar('maatUcWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local masterArg = mobArg:getMaster()
        local openForPlayer = masterArg and masterArg:getTP() >= 1000
        local closeSC = canCloseSkillchain(battleTarget)
        local dump = tp >= 3000

        if not closeSC and not openForPlayer and not dump then
            return
        end

        mobArg:setLocalVar('maatUcWsLock', 1)
        mobArg:useMobAbility(MS_HOLLOW_SMITE, battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'MAAT_UC_WS_UNLOCK', function(mobArg)
        mobArg:setLocalVar('maatUcWsLock', 0)
    end)

    -- Mobskills don't always fire WEAPONSKILL_USE; clear lock on ability finish too.
    mob:addListener('WEAPONSKILL_STATE_EXIT', 'MAAT_UC_WS_EXIT', function(mobArg)
        mobArg:setLocalVar('maatUcWsLock', 0)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
