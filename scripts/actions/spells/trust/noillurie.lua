-----------------------------------
-- Trust: Noillurie
-- SAM/PLD. Great Katana. Cure I–IV.
-- Hasso, Third Eye, Meditate, Sekkanoki.
-- WS: Jinpu / Yukikaze / Gekko / Kasha / Kaiten (early unlocks).
-- MP+65%. Favors Kaiten @1000 TP; closes SCs; Kaiten on Light → LightLight.
-- Sekkanoki + Meditate ready @2000: Yukikaze > Gekko > Kasha > Kaiten (double Light).
-- B-tier melee_dd (weaponskill) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local WS_JINPU     = 148
local WS_YUKIKAZE  = 150
local WS_GEKKO     = 151
local WS_KASHA     = 152
local WS_KAITEN    = 153

-- abilities.sql recastIds
local RECAST_MEDITATE  = 134
local RECAST_SEKKANOKI = 140

local SOLO_SEQ =
{
    WS_YUKIKAZE,
    WS_GEKKO,
    WS_KASHA,
    WS_KAITEN,
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function soloPackageReady(mob)
    return not mob:hasRecast(xi.recast.ABILITY, RECAST_SEKKANOKI) and
        not mob:hasRecast(xi.recast.ABILITY, RECAST_MEDITATE) and
        mob:getMainLvl() >= 50
end

local function scPower(target)
    local sc = target:getStatusEffect(xi.effect.SKILLCHAIN)
    return sc and sc:getPower() or 0
end

local function isLightSC(power)
    return power == xi.skillchainType.LIGHT or power == xi.skillchainType.LIGHT_II
end

-- Favor Kaiten once available; earlier unlocks track retail low-level learning.
local function preferredOpenWS(mob)
    local lvl = mob:getMainLvl()
    if lvl >= 50 then
        return WS_KAITEN
    elseif lvl >= 40 then
        return WS_KASHA
    elseif lvl >= 30 then
        return WS_JINPU
    end

    return WS_JINPU
end

local function queueSoloWS(mob, step)
    mob:timer(1800, function(mobArg)
        if mobArg:getLocalVar('noilSoloStep') ~= step then
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            mobArg:setLocalVar('noilSoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
            return
        end

        -- Keep the 4-step window alive (high STP + Sekkanoki first hit).
        mobArg:setTP(math.max(mobArg:getTP(), 1000))
        mobArg:useMobAbility(SOLO_SEQ[step], target)
    end)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.MPP, 65)
    -- Retail: high TP gain so she can reopen / double-Light off her own opens.
    mob:addMod(xi.mod.STORETP, 80)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Cure party <50% or asleep.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:setLocalVar('noilSoloStep', 0)
    mob:setLocalVar('noilWsLock', 0)

    -- Sekkanoki on CD: WS at 1000 (script picks Kaiten / close).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)

    mob:addListener('COMBAT_TICK', 'NOILLURIE_SOLO_SC', function(mobArg)
        if mobArg:getLocalVar('noilSoloStep') > 0 then
            return
        end

        if not soloPackageReady(mobArg) then
            return
        end

        -- Package ready: hold auto-WS for the self-SC @2000.
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)

        if mobArg:getTP() < 2000 then
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() or not canAct(mobArg) then
            return
        end

        mobArg:useJobAbility(xi.ja.SEKKANOKI, mobArg)
        mobArg:useJobAbility(xi.ja.MEDITATE, mobArg)
        mobArg:setLocalVar('noilSoloStep', 1)
        mobArg:useMobAbility(WS_YUKIKAZE, target)
    end)

    mob:addListener('COMBAT_TICK', 'NOILLURIE_TP', function(mobArg)
        if mobArg:getLocalVar('noilSoloStep') > 0 then
            return
        end

        -- While solo package is ready, that listener owns TP.
        if soloPackageReady(mobArg) then
            return
        end

        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('noilWsLock', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local power = scPower(battleTarget)

        -- Light window → Kaiten for LightLight (even if she opened it).
        if isLightSC(power) then
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
            if mobArg:getLocalVar('noilWsLock') == 0 and canAct(mobArg) and mobArg:getMainLvl() >= 50 then
                mobArg:setLocalVar('noilWsLock', 1)
                mobArg:useMobAbility(WS_KAITEN, battleTarget)
            end

            return
        end

        -- Other SC windows: let controller close with best link.
        if power > 0 then
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1000)
            return
        end

        -- No SC: dump preferred open @1000 (Kaiten when available).
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
        if mobArg:getLocalVar('noilWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        mobArg:setLocalVar('noilWsLock', 1)
        mobArg:useMobAbility(preferredOpenWS(mobArg), battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'NOILLURIE_WS', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('noilWsLock', 0)

        local step = mobArg:getLocalVar('noilSoloStep')
        if step > 0 then
            if skill:getID() ~= SOLO_SEQ[step] then
                return
            end

            if step >= #SOLO_SEQ then
                mobArg:setLocalVar('noilSoloStep', 0)
                mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
                return
            end

            local nextStep = step + 1
            mobArg:setLocalVar('noilSoloStep', nextStep)
            queueSoloWS(mobArg, nextStep)
            return
        end

        if skill:getID() == WS_KAITEN then
            -- En garde!
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
