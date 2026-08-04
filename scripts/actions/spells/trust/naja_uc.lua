-----------------------------------
-- Trust: Naja Salaheem UC
-- Spell ID: 1008 | Pool ID: 6008
-- MNK/WAR club. No JAs. High QA/TA + Store TP (~200 TP/hit) + Gilfinder.
-- On summon: picks one club WS exclusively (re-summon to re-roll):
--   Peacebreaker (5) / Hexa Strike (25) / Nott (50) /
--   Black Halo (60) / Justicebreaker (70).
-- OPENER: WS only when another party member (player/trust) has >=1000 TP;
-- otherwise holds TP indefinitely (no 3000 dump).
-- No MP (Nott = HP restore). Low per-hit damage, high multi-attack.
-- A-tier melee_dd (skirmisher) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_PEACEBREAKER   = 3215
local MS_HEXA_STRIKE    = 168
local MS_NOTT           = 3502
local MS_BLACK_HALO     = 169
local MS_JUSTICEBREAKER = 3503

local function isWearingNajaShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.NAJA_SALAHEEM_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function buildWSPool(lvl)
    local pool = {}

    if lvl >= 5 then
        pool[#pool + 1] = MS_PEACEBREAKER
    end

    if lvl >= 25 then
        pool[#pool + 1] = MS_HEXA_STRIKE
    end

    if lvl >= 50 then
        pool[#pool + 1] = MS_NOTT
    end

    if lvl >= 60 then
        pool[#pool + 1] = MS_BLACK_HALO
    end

    if lvl >= 70 then
        pool[#pool + 1] = MS_JUSTICEBREAKER
    end

    return pool
end

-- Retail OPENER: any other party member (player or trust) at >=1000 TP.
local function partyMemberHasTP(mobArg, threshold)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:getID() ~= mobArg:getID() and
            member:isAlive() and
            member:getTP() >= threshold
        then
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.NAJA_SALAHEEM)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingNajaShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- No MP — Nott is HP-only for this alter ego.
    mob:setMod(xi.mod.MPP, -100)

    -- Retail: ~200 TP/hit, Gilfinder, very high multi-attack, lower per-hit punch.
    mob:addMod(xi.mod.STORETP, 125)
    mob:addMod(xi.mod.GILFINDER, 50)
    mob:addMod(xi.mod.QUAD_ATTACK, 20)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 25)
    mob:addMod(xi.mod.DOUBLE_ATTACK, 30)
    -- Soften AA/WS so multi-attack volume doesn't outpace A-tier soft bands.
    mob:addMod(xi.mod.MAIN_DMG_RATING, -25)
    mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, -10)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Pick one exclusive WS for this summon (empty pool below lvl 5 = idle TP).
    local pool = buildWSPool(mob:getMainLvl())
    local chosen = (#pool > 0) and pool[math.random(#pool)] or 0
    mob:setLocalVar('najaUcWS', chosen)
    mob:setLocalVar('najaUcWsLock', 0)

    -- Listener-driven OPENER (no 3000 dump — hold until a partner has TP).
    mob:addListener('COMBAT_TICK', 'NAJA_UC_AI', function(mobArg)
        local chosenWS = mobArg:getLocalVar('najaUcWS')
        if chosenWS == 0 then
            return
        end

        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('najaUcWsLock', 0)
            return
        end

        if
            mobArg:getLocalVar('najaUcWsLock') ~= 0 or
            not canAct(mobArg) or
            not partyMemberHasTP(mobArg, 1000)
        then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Nott is self-target heal.
        mobArg:setLocalVar('najaUcWsLock', 1)
        if chosenWS == MS_NOTT then
            mobArg:useMobAbility(chosenWS, mobArg)
        else
            mobArg:useMobAbility(chosenWS, battleTarget)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'NAJA_UC_WS_UNLOCK', function(mobArg, target, skill)
        mobArg:setLocalVar('najaUcWsLock', 0)
        if skill:getID() == MS_PEACEBREAKER then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:addListener('WEAPONSKILL_STATE_EXIT', 'NAJA_UC_WS_EXIT', function(mobArg)
        mobArg:setLocalVar('najaUcWsLock', 0)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
