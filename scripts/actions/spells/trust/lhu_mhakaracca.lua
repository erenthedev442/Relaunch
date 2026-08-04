-----------------------------------
-- Trust: Lhu Mhakaracca
-- BST/WAR. Axe.
-- Abilities: Feral Howl (target <20% HP), Berserk, Aggressor.
-- WS: Spinning Axe (favored) / Rampage / Onslaught / Decimation.
-- Uses TP ASAP @1000.
-- Retail ~91 TP/hit: C bruiser Store TP package lands near that at 99.
-- C-tier melee_dd (bruiser) power path — no kit inject (custom WS preference).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local WS_SPINNING_AXE = 68
local WS_ALTS         = { 69, 72, 73 } -- Rampage, Decimation, Onslaught

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    -- Retail: Feral Howl when target is under ~20% HP (terror / interrupt low-HP JAs).
    mob:addGambit(ai.t.TARGET, { ai.c.HPP_LT, 20 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FERAL_HOWL })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Built-in HIGHEST always picks Onslaught (highest skill id). Hold auto-WS and
    -- drive a Spinning Axe-weighted pick instead.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)

    mob:addListener('COMBAT_TICK', 'LHU_WS_PREF', function(mobArg)
        if mobArg:getTP() < 1000 then
            mobArg:setLocalVar('lhuWsLock', 0)
            return
        end

        if mobArg:getLocalVar('lhuWsLock') ~= 0 then
            return
        end

        if not mobArg:isEngaged() then
            return
        end

        if mobArg:getCurrentAction() ~= xi.action.category.BASIC_ATTACK then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- ~75% Spinning Axe; otherwise Rampage / Decimation / Onslaught.
        local skillId = WS_SPINNING_AXE
        if math.random(100) > 75 then
            skillId = WS_ALTS[math.random(#WS_ALTS)]
        end

        mobArg:setLocalVar('lhuWsLock', 1)
        mobArg:useMobAbility(skillId, battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'LHU_WS_UNLOCK', function(mobArg)
        mobArg:setLocalVar('lhuWsLock', 0)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
