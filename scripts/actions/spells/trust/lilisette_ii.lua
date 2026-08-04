-----------------------------------
-- Trust: Lilisette II
-- DNC/WAR. Dagger. Fast AA / TP gain.
-- Abilities: Rousing Samba (350 TP JA — party Crit+10%, self Crit+75%).
-- WS: Whirling Edge (ST) / Dancer's Fury / Vivifying Waltz.
-- Holds to 2000 TP to close skillchains.
-- Vivifying when 3+ party members <75% HP, at >=1000 TP.
-- A-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_VIVIFYING = 3313
local MS_ROUSING   = 3298 -- NO_TP_COST; script spends 350 TP

local function countYellow(mob)
    local yellow = 0
    local master = mob:getMaster()
    if not master then
        return 0
    end

    for _, member in ipairs(master:getPartyWithTrusts()) do
        if member:isAlive() and mob:checkDistance(member) <= 20 and member:getHPP() < 75 then
            yellow = yellow + 1
        end
    end

    return yellow
end

local function canAct(mob)
    return mob:isEngaged() and mob:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LILISETTE)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Fast attack rate / TP gain (retail note), on top of A skirmisher package.
    mob:addMod(xi.mod.HASTE_GEAR, 500)
    mob:addMod(xi.mod.STORETP, 45)
    mob:addMod(xi.mod.DELAYP, -8)

    mob:setMobMod(xi.mobMod.DUAL_WIELD, 0)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- RANDOM: opener varies Whirling/Fury; closer still picks best SC.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)

    mob:addListener('COMBAT_TICK', 'LILISETTE_II_AI', function(mobArg)
        local tp     = mobArg:getTP()
        local yellow = countYellow(mobArg)
        local now    = GetSystemTime()

        -- Vivifying Waltz: 3+ yellow, >=1000 TP (priority over holding for SC).
        if yellow >= 3 and tp >= 1000 then
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)

            if
                canAct(mobArg) and
                mobArg:getLocalVar('lili2WsLock') <= now
            then
                mobArg:setLocalVar('lili2WsLock', now + 4)
                mobArg:useMobAbility(MS_VIVIFYING, mobArg)
            end

            return
        end

        -- Resume SC hold / dump @2000.
        mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)

        -- Rousing Samba JA: maintain when missing; costs 350 TP.
        if
            tp >= 350 and
            canAct(mobArg) and
            not mobArg:hasStatusEffect(xi.effect.BLOOD_RAGE) and
            mobArg:getLocalVar('lili2RouseLock') <= now
        then
            -- Don't spend if it would block an imminent Vivifying build (2 yellow, <1000 after).
            if yellow >= 2 and (tp - 350) < 1000 then
                return
            end

            mobArg:setLocalVar('lili2RouseLock', now + 4)
            mobArg:delTP(350)
            mobArg:useMobAbility(MS_ROUSING, mobArg)
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
