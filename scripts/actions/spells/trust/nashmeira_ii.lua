-----------------------------------
-- Trust: Nashmeira II
-- WHM/PUP. H2H. Imperial Authority (Stun) @1000 TP.
-- Cure I–VI, Curaga I–V, -na, Erase.
-- HP-10%, MP+15%.
-- Curaga when 3+ party members are <75% HP, or anyone is asleep.
-- A-tier healer (support) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_IMPERIAL_AUTHORITY = 3243

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
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

-- Count party members below 75% HP (for Curaga threshold).
local function yellowCount(mob)
    local yellow = 0
    local firstHurt = nil
    local master = mob:getMaster()
    if not master then
        return yellow, firstHurt
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and mob:checkDistance(member) <= 20 then
            if member:getHPP() < 75 then
                yellow = yellow + 1
                firstHurt = firstHurt or member
            end
        end
    end

    return yellow, firstHurt
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.NASHMEIRA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.LILISETTE_II] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ARCIELA_II] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.IROHA_II] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.LION_II] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.PRISHE_II] = xi.trust.messageOffset.TEAMWORK_5,
    })

    mob:addMod(xi.mod.HPP, -10)
    mob:addMod(xi.mod.MPP, 15)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Sleep → Curaga; single-target Cure when yellow; Curaga for 3+ via tick.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)

    mob:addListener('COMBAT_TICK', 'NASHMEIRA_II_CURAGA', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local yellow, target = yellowCount(mobArg)
        if yellow >= 3 and target then
            mobArg:castSpell(highestCuraga(mobArg), target)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'NASHMEIRA_II_WS', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_IMPERIAL_AUTHORITY then
            -- No! Stand back!
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
