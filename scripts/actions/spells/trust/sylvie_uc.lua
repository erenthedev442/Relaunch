-----------------------------------
-- Trust: Sylvie UC
-- Spell ID: 981 | Pool ID: 5981
-- GEO/WHM. S-tier CORE buffer — Indi + Entrust job logic lives in C++
-- (GetBestIndiSpell / GetBestEntrustedSpell). No AA / no enemy casts.
-- Regain 50, DT -25%, Indi duration +180s (6 min total). Geomancy+3 @99.
-- Haste master + melee DDs. Nott for MP. Follows party (default pathing).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_NOTT    = 3502
local NOTT_MPP   = 66
local NOTT_FORCE = 15

local HASTE_MELEE_JOBS =
{
    [xi.job.WAR] = true,
    [xi.job.MNK] = true,
    [xi.job.THF] = true,
    [xi.job.PLD] = true,
    [xi.job.DRK] = true,
    [xi.job.BST] = true,
    [xi.job.SAM] = true,
    [xi.job.NIN] = true,
    [xi.job.DRG] = true,
    [xi.job.BLU] = true,
    [xi.job.PUP] = true,
    [xi.job.DNC] = true,
    [xi.job.RUN] = true,
}

local function isWearingSylvieShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.SYLVIE_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function castHasteOnMelee(mobArg, master)
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getID() ~= mobArg:getID() and
            member:getID() ~= master:getID() and
            not member:hasStatusEffect(xi.effect.HASTE) and
            HASTE_MELEE_JOBS[member:getMainJob()]
        then
            mobArg:castSpell(xi.magic.spell.HASTE, member)
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingSylvieShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    if not master then
        return
    end

    -- Retail: Regain 50, DT -25%, Indi duration to 6 minutes (base 180 + 180).
    mob:addMod(xi.mod.REGAIN, 50)
    mob:addMod(xi.mod.DMG, -2500)
    mob:addMod(xi.mod.INDI_DURATION, 180)
    -- Potency floor so Indi power tracks GEO skill; Geomancy+3 at 99.
    mob:addMod(xi.mod.GEOMANCY_SKILL, 8 * mob:getMainLvl() + 1)
    if mob:getMainLvl() >= 99 then
        mob:addMod(xi.mod.GEOMANCY_BONUS, 3)
    end

    -- No melee / no enemy magic. Follows party lineup (default trust pathing).
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)

    -- Triage / -na / Erase / yellow cures.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.MASTER, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Self Indi (job/hit-rate logic in C++ GetBestIndiSpell).
    if mob:getMainLvl() >= 20 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COLURE_ACTIVE }, { ai.r.MA, ai.s.BEST_INDI, xi.magic.spellFamily.NONE })
    end

    -- Entrust Indi (incl. GEO → Indi-Languor on first PLD/RUN/NIN via C++).
    -- Below 93, entrusted spells still resolve; full kit opens at Indi-Haste (93).
    if mob:getMainLvl() >= 76 then -- Indi-Frailty / Entrust utility band
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.ENTRUST }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ENTRUST })
        mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.ENTRUST }, { ai.r.MA, ai.s.ENTRUSTED, xi.magic.spellFamily.INDI_BUFF })
    end

    -- Haste summoner regardless of job; melee DDs via tick.
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    mob:addListener('COMBAT_TICK', 'SYLVIE_UC_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local masterArg = mobArg:getMaster()
        if not masterArg then
            return
        end

        if castHasteOnMelee(mobArg, masterArg) then
            return
        end

        -- Nott: TP for MP when MPP < 66% (force under 15% even if party is yellow).
        local tp = mobArg:getTP()
        local mpp = mobArg:getMPP()
        if mobArg:getMainLvl() < 50 or tp < 1000 or mpp >= NOTT_MPP then
            return
        end

        local yellow = false
        for _, member in pairs(masterArg:getPartyWithTrusts() or {}) do
            if member:isAlive() and member:getHPP() < 75 then
                yellow = true
                break
            end
        end

        if not yellow or mpp < NOTT_FORCE then
            mobArg:useMobAbility(MS_NOTT, mobArg)
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
