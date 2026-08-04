-----------------------------------
-- Trust: Rainemard
-- RDM/PLD. Sword. Burning / Red Lotus / Vorpal / Savage Blade.
-- Self-only enhancing (Haste II, Phalanx, Protect/Shell, Enspells).
-- Enspell vs enemy elemental weakness; Refresh @ <50% MP; Composure.
-- A-tier hybrid (pressure) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local ENSPELLS =
{
    { effect = xi.effect.ENFIRE,     spell = xi.magic.spell.ENFIRE,     sdt = xi.mod.FIRE_SDT },
    { effect = xi.effect.ENBLIZZARD, spell = xi.magic.spell.ENBLIZZARD, sdt = xi.mod.ICE_SDT },
    { effect = xi.effect.ENAERO,     spell = xi.magic.spell.ENAERO,     sdt = xi.mod.WIND_SDT },
    { effect = xi.effect.ENSTONE,    spell = xi.magic.spell.ENSTONE,    sdt = xi.mod.EARTH_SDT },
    { effect = xi.effect.ENTHUNDER,  spell = xi.magic.spell.ENTHUNDER,  sdt = xi.mod.THUNDER_SDT },
    { effect = xi.effect.ENWATER,    spell = xi.magic.spell.ENWATER,    sdt = xi.mod.WATER_SDT },
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function currentEnspellSpell(mobArg)
    for _, entry in ipairs(ENSPELLS) do
        if mobArg:hasStatusEffect(entry.effect) then
            return entry.spell
        end
    end

    return 0
end

-- Highest SDT = weakest to that element (same pattern as Luzaf QD).
local function pickEnspell(target)
    local bestSpell = xi.magic.spell.ENFIRE
    local bestSdt   = -100000

    for _, entry in ipairs(ENSPELLS) do
        local sdt = target:getMod(entry.sdt)
        if sdt > bestSdt then
            bestSdt   = sdt
            bestSpell = entry.spell
        end
    end

    return bestSpell
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.CURILLA] = xi.trust.messageOffset.TEAMWORK_1,
    })

    local lvl = mob:getMainLvl()
    -- Retail: enspells are extremely powerful (≈50–350+ with level / MAB).
    -- Base enhancing power + hybrid MATT; flat/pct bonus closes the gap.
    mob:addMod(xi.mod.ENSPELL_DMG_BONUS, math.floor(25 + lvl * 1.6))
    mob:addMod(xi.mod.ENSPELL_DMG_PCT, math.floor(40 + lvl * 0.9))
    mob:addMod(xi.mod.FASTCAST, 35)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COMPOSURE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.COMPOSURE })

    -- Debuffs on the enemy.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.EVASION_DOWN }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.DISTRACT }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.MAGIC_EVASION_DOWN }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FRAZZLE }, 60)

    -- Enhancing: self only (retail).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PHALANX }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PHALANX })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELL })

    -- Refresh only when MP is low.
    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)

    -- Recheck enspell on each engage (new enemy family / SDT profile).
    mob:addListener('ENGAGE', 'RAINEMARD_ENGAGE', function(mobArg, target)
        mobArg:setLocalVar('rainEnForce', 1)
    end)

    mob:addListener('COMBAT_TICK', 'RAINEMARD_ENSPELL', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local want = pickEnspell(battleTarget)
        local have = currentEnspellSpell(mobArg)
        local force = mobArg:getLocalVar('rainEnForce') ~= 0

        if have == want and not force then
            return
        end

        mobArg:setLocalVar('rainEnForce', 0)
        mobArg:castSpell(want, mobArg)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
