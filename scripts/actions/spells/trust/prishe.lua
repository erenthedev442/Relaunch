-----------------------------------
-- Trust: Prishe
-- MNK/WHM. H2H. Cure I–IV.
-- WS: Knuckle Sandwich / Nullifying Dropkick / Auroral Uppercut.
-- HP-5%, MP+75%. Cure only at very low HP (<25%); Ulmia synergy Cure @75%.
-- Uses TP ASAP @1000. B-tier melee_dd (bruiser) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_NULLIFYING = 3234
local MS_AURORAL    = 3235
local MS_KNUCKLE    = 3236

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

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.PRISHE_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ULMIA] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.CHERUKIKI] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.KUKKI_CHEBUKKI] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.MAKKI_CHEBUKKI] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.MILDAURION] = xi.trust.messageOffset.TEAMWORK_5,
    })

    mob:addMod(xi.mod.HPP, -5)
    mob:addMod(xi.mod.MPP, 75)
    -- Light magical WS (Knuckle Sandwich / Auroral Uppercut) ride weapon rating + MATT.
    mob:addMod(xi.mod.MATT, 100)
    mob:addMod(xi.mod.MACC, 70)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Retail: Cure only at very low health.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- ASAP @1000 (unique WS list: Knuckle / Dropkick / Auroral).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Ulmia synergy: Cure Ulmia at yellow (75%).
    mob:addListener('COMBAT_TICK', 'PRISHE_ULMIA', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local ulmia = findUlmia(mobArg)
        if ulmia and ulmia:getHPP() < 75 and mobArg:checkDistance(ulmia) <= 20 then
            mobArg:castSpell(highestCure(mobArg), ulmia)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'PRISHE_WS', function(mobArg, target, skill, tp, action, damage)
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
