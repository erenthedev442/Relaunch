-----------------------------------
-- Trust: Selh'teus
-- PLD/SAM. Unique WS: Luminous Lance (ranged) / Rejuvenation / Revelation.
-- Regain 50, MP+100%. Holds to 3000 to close SCs.
-- Rejuvenation on master yellow/sleep, 30s CD (party HP/MP/TP).
-- NO_MOVE (summon early so he starts in range). A-tier hybrid — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_LANCE      = 3621
local MS_REJUV      = 3622
local MS_REVELATION = 3623

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function masterNeedsRejuv(master)
    if not master or not master:isAlive() then
        return false
    end

    if master:getHPP() < 75 then
        return true
    end

    return master:hasStatusEffect(xi.effect.SLEEP_I) or
        master:hasStatusEffect(xi.effect.SLEEP_II) or
        master:hasStatusEffect(xi.effect.LULLABY)
end

local function tryRejuvenation(mobArg)
    if mobArg:getLocalVar('selhRejuvReady') > os.time() then
        return
    end

    if mobArg:getTP() < 1000 or not canAct(mobArg) then
        return
    end

    local master = mobArg:getMaster()
    if not masterNeedsRejuv(master) then
        return
    end

    mobArg:setLocalVar('selhRejuvReady', os.time() + 30)
    mobArg:setLocalVar('selhRejuv', 1)
    mobArg:useMobAbility(MS_REJUV, mobArg)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.REGAIN, 50)
    mob:addMod(xi.mod.MPP, 100)
    -- A hybrid / pressure package owns AA, Lance, and Revelation scaling.

    -- Retail: does not path into melee on his own — summon early for range.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    -- Hold to close; dump by 3000 (Lance / Revelation only via skill check gate).
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 3000)

    mob:setLocalVar('selhRejuvReady', 0)
    mob:setLocalVar('selhRejuv', 0)

    local master = mob:getMaster()
    local listenerName = 'SELHTEUS_REJUV_' .. mob:getID()

    if master then
        master:addListener('TAKE_DAMAGE', listenerName, function(playerArg, amount, attacker, attackType, damageType)
            local trust = nil
            for _, member in pairs(playerArg:getPartyWithTrusts() or {}) do
                if
                    member:getObjType() == xi.objType.TRUST and
                    member:getTrustID() == xi.magic.spell.SELHTEUS
                then
                    trust = member
                    break
                end
            end

            if not trust then
                return
            end

            local hpAfter = playerArg:getHP() - amount
            local maxHp = playerArg:getMaxHP()
            if maxHp > 0 and hpAfter <= maxHp * 0.75 then
                tryRejuvenation(trust)
            end
        end)
    end

    mob:addListener('COMBAT_TICK', 'SELHTEUS_REJUV_TICK', function(mobArg)
        local masterArg = mobArg:getMaster()
        if masterNeedsRejuv(masterArg) then
            tryRejuvenation(mobArg)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'SELHTEUS_WS', function(mobArg, target, skill, tp, action, damage)
        local id = skill:getID()
        if id == MS_LANCE or id == MS_REVELATION then
            if math.random(1, 100) <= 25 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
        end
    end)
end

local function cleanup(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('SELHTEUS_REJUV_' .. mob:getID())
    end
end

spellObject.onMobDespawn = function(mob)
    cleanup(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    cleanup(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
