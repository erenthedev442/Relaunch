-----------------------------------
-- Trust: Mumor II
-- BLM/DNC Club. ST nukes I–V + Stun + -ja (MB only).
-- WS: Shining Summer Samba / Lovely Miracle Waltz /
--   Neo Crystal Jig → Super Crusher Jig → Eternal Vana Illusion → Final Eternal Heart (fever).
-- Firesday Night Fever @<50% HP: full HP/MP, all-stat aura (~4 min / 5 min CD).
-- Ends on Final Eternal Heart. Melees with wands. Stun interrupts.
-- A-tier nuker (burst) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SAMBA   = 3637
local MS_WALTZ   = 3638
local MS_NEO     = 3639
local MS_SUPER   = 3640
local MS_ETERNAL = 3641
local MS_FINAL   = 3642
local MS_FEVER   = 3643

local FEVER_SEQ = { MS_NEO, MS_SUPER, MS_ETERNAL, MS_FINAL }
local FEVER_CD  = 300 -- 5 min after finale
local IDLE_POOL = { MS_SAMBA, MS_WALTZ }

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function clearFeverBuffs(mobArg)
    if mobArg:getLocalVar('mumorFeverBuff') ~= 1 then
        return
    end

    local statBoost = mobArg:getLocalVar('mumorFeverStat')
    mobArg:delMod(xi.mod.STR, statBoost)
    mobArg:delMod(xi.mod.DEX, statBoost)
    mobArg:delMod(xi.mod.VIT, statBoost)
    mobArg:delMod(xi.mod.AGI, statBoost)
    mobArg:delMod(xi.mod.INT, statBoost)
    mobArg:delMod(xi.mod.MND, statBoost)
    mobArg:delMod(xi.mod.CHR, statBoost)
    mobArg:delMod(xi.mod.ATT, math.floor(statBoost * 2))
    mobArg:delMod(xi.mod.ACC, math.floor(statBoost * 2))
    mobArg:delMod(xi.mod.MATT, math.floor(statBoost * 1.5))
    mobArg:delMod(xi.mod.MACC, math.floor(statBoost * 1.5))
    mobArg:setLocalVar('mumorFeverBuff', 0)
    mobArg:setLocalVar('mumorFeverStat', 0)
end

local function endFever(mobArg)
    clearFeverBuffs(mobArg)
    mobArg:setAnimationSub(0)
    mobArg:setLocalVar('mumorFever', 0)
    mobArg:setLocalVar('mumorFeverStep', 0)
    mobArg:setLocalVar('mumorFeverEnd', 0)
    mobArg:setLocalVar('mumorFeverCD', GetSystemTime() + FEVER_CD)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.MUMOR)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MUMOR] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ULLEGORE] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:addMod(xi.mod.HPP, 15)
    mob:addMod(xi.mod.FASTCAST, 40)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 35)
    mob:addMod(xi.mod.MACC, 50)
    -- Wand AA (nuker package has no melee axes). Low haste feel (retail).
    mob:addMod(xi.mod.ACC, 45)
    mob:addMod(xi.mod.ATT, 40)
    mob:addMod(xi.mod.MAIN_DMG_RATING, 25)
    mob:addMod(xi.mod.OCCULT_ACUMEN, 40)

    -- Stun interrupts.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- MB only (-ja preferred via highest IDs on trimmed spell list).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Hold built-in WS (RANDOM@3001 rarely auto-fires); COMBAT_TICK drives dances.
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 3001)
    mob:setAnimationSub(0)
    mob:setLocalVar('mumorFever', 0)
    mob:setLocalVar('mumorFeverCD', 0)
    mob:setLocalVar('mumorWsLock', 0)

    mob:addListener('COMBAT_TICK', 'MUMOR_II_AI', function(mobArg)
        local now = GetSystemTime()

        -- Fever timeout (~4 min).
        if
            mobArg:getLocalVar('mumorFever') == 1 and
            mobArg:getLocalVar('mumorFeverEnd') > 0 and
            now >= mobArg:getLocalVar('mumorFeverEnd')
        then
            endFever(mobArg)
        end

        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Activate Firesday Night Fever under 50% HP.
        if
            mobArg:getLocalVar('mumorFever') == 0 and
            mobArg:getHPP() < 50 and
            now >= mobArg:getLocalVar('mumorFeverCD')
        then
            mobArg:setLocalVar('mumorWsLock', now + 3)
            mobArg:useMobAbility(MS_FEVER, mobArg)
            return
        end

        if mobArg:getLocalVar('mumorWsLock') > now then
            return
        end

        local tp = mobArg:getTP()
        if tp < 1000 then
            return
        end

        if mobArg:getLocalVar('mumorFever') == 1 then
            local step = mobArg:getLocalVar('mumorFeverStep')
            if step < 1 then
                step = 1
            end

            local skillId = FEVER_SEQ[step]
            if not skillId then
                endFever(mobArg)
                return
            end

            mobArg:setLocalVar('mumorWsLock', now + 4)
            mobArg:useMobAbility(skillId, battleTarget)
            return
        end

        -- Outside fever: Samba / Waltz dump.
        mobArg:setLocalVar('mumorWsLock', now + 4)
        mobArg:useMobAbility(IDLE_POOL[math.random(#IDLE_POOL)], battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'MUMOR_II_WS', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('mumorWsLock', 0)

        local skillId = skill:getID()
        if skillId == MS_FEVER then
            return
        end

        if mobArg:getLocalVar('mumorFever') ~= 1 then
            return
        end

        local step = mobArg:getLocalVar('mumorFeverStep')
        if skillId ~= FEVER_SEQ[step] then
            return
        end

        if skillId == MS_FINAL then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            endFever(mobArg)
            return
        end

        mobArg:setLocalVar('mumorFeverStep', step + 1)
    end)
end

spellObject.onMobDespawn = function(mob)
    clearFeverBuffs(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    clearFeverBuffs(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
