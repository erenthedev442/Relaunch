-----------------------------------
-- Trust: Domina Shantotto (D. Shantotto)
-- BLM/DRK Scythe. Guillotine / Cross Reaper / Shadow of Death / Salvation Scythe.
-- Darkness nukes only (Stone / Blizzard / Water I–V). No magic burst.
-- Opens with T5 (highest available) volley, then melees. Occasional nukes
-- when not top enmity (more often vs Elementals / slashing-resistant).
-- ASAP@1000. B-tier hybrid (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Highest-to-lowest; min levels from spell list.
local STONE_LINE    = { { 163, 77 }, { 162, 68 }, { 161, 51 }, { 160, 26 }, { 159, 1 } }
local BLIZZARD_LINE = { { 153, 89 }, { 152, 74 }, { 151, 64 }, { 150, 42 }, { 149, 17 } }
local WATER_LINE    = { { 173, 80 }, { 172, 70 }, { 171, 55 }, { 170, 30 }, { 169, 5 } }

local function bestInLine(mob, line)
    local lvl = mob:getMainLvl()
    for _, entry in ipairs(line) do
        if lvl >= entry[2] then
            return entry[1]
        end
    end

    return nil
end

local function canAct(mobArg)
    return mobArg:isEngaged() and
        (mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK or
            mobArg:getCurrentAction() == xi.action.category.NONE)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.FASTCAST, 35)
    mob:addMod(xi.mod.MACC, 50)

    -- Occasional darkness nukes (spell list is Earth/Ice/Water only). No MB.
    -- More often vs Elementals (slashing-resistant). Never while top enmity.
    mob:addGambit(ai.t.TARGET, {
        { ai.c.NOT_HAS_TOP_ENMITY, 0 },
        { ai.c.IS_ECOSYSTEM, xi.ecosystem.ELEMENTAL },
    }, { ai.r.MA, ai.s.RANDOM, xi.magic.spellFamily.NONE }, 18)
    mob:addGambit(ai.t.TARGET, {
        { ai.c.NOT_HAS_TOP_ENMITY, 0 },
    }, { ai.r.MA, ai.s.RANDOM, xi.magic.spellFamily.NONE }, 50)

    mob:setAutoAttackEnabled(false)
    mob:setMobAbilityEnabled(false)
    mob:setLocalVar('dominaOpenStep', 1)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    mob:addListener('ENGAGE', 'DOMINA_OPEN_VOLLEY', function(mobArg)
        mobArg:setLocalVar('dominaOpenStep', 1)
        mobArg:setAutoAttackEnabled(false)
        mobArg:setMobAbilityEnabled(false)
    end)

    mob:addListener('COMBAT_TICK', 'DOMINA_OPEN_VOLLEY', function(mobArg)
        local step = mobArg:getLocalVar('dominaOpenStep')
        if step == 0 then
            return
        end

        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local lines = { STONE_LINE, BLIZZARD_LINE, WATER_LINE }
        local spellId = bestInLine(mobArg, lines[step])
        if spellId then
            mobArg:castSpell(spellId, battleTarget)
        end

        if step >= 3 then
            mobArg:setLocalVar('dominaOpenStep', 0)
            mobArg:setAutoAttackEnabled(true)
            mobArg:setMobAbilityEnabled(true)
        else
            mobArg:setLocalVar('dominaOpenStep', step + 1)
        end
    end)

    -- Opening volley also blocks gambit nukes via AA-off; after open, hate mute is via gambit.

    mob:addListener('WEAPONSKILL_USE', 'DOMINA_SALVATION', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == xi.mobSkill.SALVATION_SCYTHE then
            -- Steel yourself for a wicked fright!
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
