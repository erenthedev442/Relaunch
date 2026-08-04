-----------------------------------
-- Trust: Ark Angel TT (AATT)
-- BLM/DRK Scythe. Guillotine / Amon Drive (AoE Para+Petrify).
-- Elemental Seal, Last Resort, Souleater. Nukes I–V (MB only),
-- Sleepga/II (+ ES), Sleep/II, Bio/II, Poison/II, Aspir, Stun.
-- HP+20%, MP+50%. WS ASAP@2000 (no SC). Poison/Bio uptime.
-- Sleepga at engage + after every Amon Drive. Aspir @MP<50% vs MP mobs.
-- A-tier nuker (burst) — no kit inject (kit would free-nuke + disable AA).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_AMON = 935
local RECAST_ES = 75 -- xi.ja.ELEMENTAL_SEAL

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function targetHasMp(battleTarget)
    return battleTarget and battleTarget:getMaxMP() > 0
end

local function trySleepgaPackage(mobArg)
    if mobArg:getLocalVar('aattSleepga') ~= 1 then
        return
    end

    if not canAct(mobArg) then
        return
    end

    local battleTarget = mobArg:getTarget()
    if not battleTarget or not battleTarget:isAlive() then
        return
    end

    -- Elemental Seal first when available (augments Sleepga).
    if
        not mobArg:hasStatusEffect(xi.effect.ELEMENTAL_SEAL) and
        not mobArg:hasRecast(xi.recast.ABILITY, RECAST_ES)
    then
        mobArg:useJobAbility(xi.ja.ELEMENTAL_SEAL, mobArg)
        return
    end

    local lvl = mobArg:getMainLvl()
    local spellId = (lvl >= 56) and xi.magic.spell.SLEEPGA_II or xi.magic.spell.SLEEPGA
    if lvl < 31 then
        -- Below Sleepga: single-target Sleep line.
        spellId = (lvl >= 41) and xi.magic.spell.SLEEP_II or xi.magic.spell.SLEEP
    end

    mobArg:setLocalVar('aattSleepga', 0)
    mobArg:castSpell(spellId, battleTarget)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, 20)
    mob:addMod(xi.mod.MPP, 50)
    mob:addMod(xi.mod.FASTCAST, 40)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 35)
    mob:addMod(xi.mod.MACC, 60)

    -- DRK JAs whenever ready.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.LAST_RESORT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.LAST_RESORT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SOULEATER }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SOULEATER })

    -- Stun interrupts.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Keep Bio / Poison up.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.BIO }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BIO }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.POISON }, 30)

    -- Single-target Sleep when not already slept (Sleepga handled in COMBAT_TICK).
    mob:addGambit(ai.t.TARGET, {
        { ai.c.NOT_STATUS, xi.effect.SLEEP_I },
        { ai.c.NOT_STATUS, xi.effect.SLEEP_II },
    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLEEP }, 90)

    -- Magic burst only (no free nukes). Weakness element avoids sure resists.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    -- Second cast attempt on same SC window (retail often tries two; cast time usually fails the 2nd).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 2)

    -- Aspir: Compression MB via MB_ELEMENT; free cast when MP low vs MP-bearing foes (COMBAT_TICK).

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Dump at 2000; do not try to skillchain.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 2000)

    mob:setLocalVar('aattSleepga', 1)

    mob:addListener('ENGAGE', 'AATT_ENGAGE_SLEEPGA', function(mobArg)
        mobArg:setLocalVar('aattSleepga', 1)
    end)

    mob:addListener('WEAPONSKILL_USE', 'AATT_AMON_SLEEPGA', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_AMON then
            mobArg:setLocalVar('aattSleepga', 1)
        end
    end)

    mob:addListener('COMBAT_TICK', 'AATT_COMBAT', function(mobArg)
        trySleepgaPackage(mobArg)

        if mobArg:getLocalVar('aattSleepga') == 1 then
            return
        end

        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Free Aspir when under 50% MP against enemies that have MP.
        if mobArg:getMPP() < 50 and targetHasMp(battleTarget) then
            mobArg:castSpell(xi.magic.spell.ASPIR, battleTarget)
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
