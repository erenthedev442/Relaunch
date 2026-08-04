-----------------------------------
-- Trust: Prishe II
-- WHM/MNK. H2H. Curaga I–V.
-- WS: Knuckle Sandwich / Nullifying Dropkick / Auroral Uppercut.
-- Psychoanima (phys immunity, once) / Hysteroanima (magic immunity, once).
-- HP+10%, MP+10%. Curaga on sleep / critical HP. ASAP@1000.
-- S-tier melee_dd (bruiser) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_NULLIFYING = 3234
local MS_AURORAL    = 3235
local MS_KNUCKLE    = 3236
-- mob_skills.sql: 3539 hysteroanima, 3540 psychoanima
local MS_HYSTERO    = 3539
local MS_PSYCHO     = 3540

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function findUlmia(mob)
    local master = mob:getMaster()
    if not master then
        return nil
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getObjType() == xi.objType.TRUST and
            member:getTrustID() == xi.magic.spell.ULMIA
        then
            return member
        end
    end

    return nil
end

local function highestCure(mobArg)
    local lvl = mobArg:getMainLvl()
    if lvl >= 82 then
        return xi.magic.spell.CURE_IV
    elseif lvl >= 42 then
        return xi.magic.spell.CURE_III
    elseif lvl >= 22 then
        return xi.magic.spell.CURE_II
    end

    return xi.magic.spell.CURE
end

local function highestCuraga(mobArg)
    local lvl = mobArg:getMainLvl()
    if lvl >= 91 then
        return xi.magic.spell.CURAGA_V
    elseif lvl >= 71 then
        return xi.magic.spell.CURAGA_IV
    elseif lvl >= 51 then
        return xi.magic.spell.CURAGA_III
    elseif lvl >= 31 then
        return xi.magic.spell.CURAGA_II
    end

    return xi.magic.spell.CURAGA
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.PRISHE)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.TENZEN_II] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.NASHMEIRA_II] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.LILISETTE_II] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.ARCIELA_II] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.IROHA_II] = xi.trust.messageOffset.TEAMWORK_5,
    })

    mob:addMod(xi.mod.HPP, 10)
    mob:addMod(xi.mod.MPP, 10)
    -- Light magical WS ride weapon rating + MATT (S bruiser owns AA/physical Dropkick).
    mob:addMod(xi.mod.MATT, 140)
    mob:addMod(xi.mod.MACC, 90)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:setLocalVar('prishePsychoUsed', 0)
    mob:setLocalVar('prisheHysteroUsed', 0)

    -- Curaga: critical HP or sleep. Ulmia synergy raises the party threshold to yellow.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Psychoanima: once, when a physical/ranged hit drops her to low HP.
    mob:addListener('TAKE_DAMAGE', 'PRISHE_II_PSYCHO', function(mobArg, amount, attacker, attackType, damageType)
        if mobArg:getLocalVar('prishePsychoUsed') ~= 0 then
            return
        end

        if
            attackType ~= xi.attackType.PHYSICAL and
            attackType ~= xi.attackType.RANGED
        then
            return
        end

        local hpAfter = mobArg:getHP() - amount
        local maxHp = mobArg:getMaxHP()
        if maxHp <= 0 or hpAfter > maxHp * 0.35 then
            return
        end

        mobArg:setLocalVar('prishePsychoUsed', 1)
        mobArg:useMobAbility(MS_PSYCHO, mobArg)
    end)

    -- Hysteroanima: once, preemptively when the battle target is casting.
    mob:addListener('COMBAT_TICK', 'PRISHE_II_HYSTERO', function(mobArg)
        if mobArg:getLocalVar('prisheHysteroUsed') ~= 0 or not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        if battleTarget:getCurrentAction() == xi.action.category.MAGIC_CASTING then
            mobArg:setLocalVar('prisheHysteroUsed', 1)
            mobArg:useMobAbility(MS_HYSTERO, mobArg)
        end
    end)

    -- Ulmia synergy: Curaga party at yellow; Cure I–IV on Ulmia only.
    mob:addListener('COMBAT_TICK', 'PRISHE_II_ULMIA', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local ulmia = findUlmia(mobArg)
        if not ulmia then
            return
        end

        if ulmia:getHPP() < 75 and mobArg:checkDistance(ulmia) <= 20 then
            mobArg:castSpell(highestCure(mobArg), ulmia)
            return
        end

        local master = mobArg:getMaster()
        if not master then
            return
        end

        for _, member in pairs(master:getPartyWithTrusts() or {}) do
            if
                member:isAlive() and
                member:getHPP() < 75 and
                mobArg:checkDistance(member) <= 20
            then
                mobArg:castSpell(highestCuraga(mobArg), member)
                return
            end
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'PRISHE_II_WS', function(mobArg, target, skill, tp, action, damage)
        local id = skill:getID()
        if id == MS_NULLIFYING then
            -- Welcome to Painville!
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        elseif id == MS_AURORAL or id == MS_KNUCKLE then
            if math.random(1, 100) <= 25 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
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
