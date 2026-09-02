-----------------------------------
-- Trust: Sylvie UC
-- Spell ID: 981 | Pool ID: 5981
-- GEO/WHM. Dual-bubble: her Indi stays on her, Entrust Indi on the master.
-- Recasts either when missing or the wrong colure is up. No AA / no enemy casts.
-- Regain 50, DT -25%, ~10' aura. Geomancy+3 @99. Haste + Nott. Sticks to summoner.
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

-- Mirrors CMobSpellContainer::GetBestIndiSpell / GetBestEntrustedSpell
-- (no hit-rate swap — Fury/Acumen stay up unless the colure is missing/wrong).
local INDI_MELEE =
{
    [xi.job.WAR] = true,
    [xi.job.MNK] = true,
    [xi.job.THF] = true,
    [xi.job.BST] = true,
    [xi.job.RNG] = true,
    [xi.job.SAM] = true,
    [xi.job.DRG] = true,
    [xi.job.COR] = true,
    [xi.job.PUP] = true,
    [xi.job.DNC] = true,
    [xi.job.DRK] = true,
    [xi.job.BLU] = true,
}

local INDI_REFRESH_JOBS =
{
    [xi.job.WHM] = true,
    [xi.job.BRD] = true,
    [xi.job.SMN] = true,
    [xi.job.GEO] = true,
}

local INDI_MAGE =
{
    [xi.job.BLM] = true,
    [xi.job.RDM] = true,
    [xi.job.SCH] = true,
}

local ENTRUST_MELEE =
{
    [xi.job.WAR] = true,
    [xi.job.MNK] = true,
    [xi.job.THF] = true,
    [xi.job.DRK] = true,
    [xi.job.BST] = true,
    [xi.job.RNG] = true,
    [xi.job.SAM] = true,
    [xi.job.DRG] = true,
    [xi.job.BLU] = true,
    [xi.job.COR] = true,
    [xi.job.PUP] = true,
    [xi.job.DNC] = true,
}

local ENTRUST_ACUMEN =
{
    [xi.job.WHM] = true,
    [xi.job.BRD] = true,
    [xi.job.SMN] = true,
}

local ENTRUST_REFRESH =
{
    [xi.job.BLM] = true,
    [xi.job.RDM] = true,
    [xi.job.SCH] = true,
    [xi.job.PLD] = true,
    [xi.job.RUN] = true,
}

local INDI_EFFECT =
{
    [xi.magic.spell.INDI_REGEN]     = xi.effect.GEO_REGEN,
    [xi.magic.spell.INDI_REFRESH]   = xi.effect.GEO_REFRESH,
    [xi.magic.spell.INDI_HASTE]     = xi.effect.GEO_HASTE,
    [xi.magic.spell.INDI_FURY]      = xi.effect.GEO_ATTACK_BOOST,
    [xi.magic.spell.INDI_ACUMEN]    = xi.effect.GEO_MAGIC_ATK_BOOST,
    [xi.magic.spell.INDI_FRAILTY]   = xi.effect.GEO_DEFENSE_DOWN,
    [xi.magic.spell.INDI_LANGUOR]   = xi.effect.GEO_MAGIC_EVASION_DOWN,
}

local function firstTankMember(master)
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() then
            local job = member:getMainJob()
            if job == xi.job.PLD or job == xi.job.RUN or job == xi.job.NIN then
                return member
            end
        end
    end

    return nil
end

local function colureIs(entity, expectedEffect)
    local colure = entity:getStatusEffect(xi.effect.COLURE_ACTIVE)
    return colure ~= nil and colure:getSubType() == expectedEffect
end

local function bestSelfIndiSpell(master)
    local job = master:getMainJob()
    local lvl = master:getMainLvl()
    if lvl < 20 then
        return nil
    end

    local choice = nil
    local subChoice = xi.magic.spell.INDI_REGEN

    if INDI_MELEE[job] then
        choice = xi.magic.spell.INDI_FURY
        subChoice = (job == xi.job.DRK or job == xi.job.BLU) and xi.magic.spell.INDI_REFRESH or xi.magic.spell.INDI_REGEN
    elseif INDI_REFRESH_JOBS[job] then
        choice = xi.magic.spell.INDI_REFRESH
        subChoice = xi.magic.spell.INDI_REFRESH
    elseif INDI_MAGE[job] then
        choice = xi.magic.spell.INDI_ACUMEN
        subChoice = xi.magic.spell.INDI_REFRESH
    elseif job == xi.job.PLD or job == xi.job.RUN then
        choice = xi.magic.spell.INDI_HASTE
        subChoice = xi.magic.spell.INDI_REFRESH
    elseif job == xi.job.NIN then
        choice = xi.magic.spell.INDI_HASTE
        subChoice = xi.magic.spell.INDI_REGEN
    end

    if lvl < 93 then
        choice = subChoice
        if choice == xi.magic.spell.INDI_REFRESH and lvl < 30 then
            choice = xi.magic.spell.INDI_REGEN
        end
    end

    return choice
end

local function maintainSelfIndi(mobArg, master)
    local spellId = bestSelfIndiSpell(master)
    if not spellId then
        return false
    end

    local expected = INDI_EFFECT[spellId]
    if expected and colureIs(mobArg, expected) then
        return false
    end

    mobArg:castSpell(spellId, mobArg)
    return true
end

local function entrustedChoice(master)
    local job = master:getMainJob()
    if ENTRUST_MELEE[job] then
        return xi.magic.spell.INDI_FRAILTY, master
    elseif ENTRUST_ACUMEN[job] then
        return xi.magic.spell.INDI_ACUMEN, master
    elseif ENTRUST_REFRESH[job] then
        return xi.magic.spell.INDI_REFRESH, master
    elseif job == xi.job.NIN then
        return xi.magic.spell.INDI_REGEN, master
    elseif job == xi.job.GEO then
        local tank = firstTankMember(master)
        if tank then
            return xi.magic.spell.INDI_LANGUOR, tank
        end
    end

    return nil, nil
end

local function masterNeedsEntrust(master)
    local spellId, target = entrustedChoice(master)
    if not spellId or not target then
        return false
    end

    return not colureIs(target, INDI_EFFECT[spellId])
end

local function maintainEntrust(mobArg, master)
    if mobArg:getMainLvl() < 76 or not masterNeedsEntrust(master) then
        return false
    end

    if mobArg:hasStatusEffect(xi.effect.ENTRUST) then
        local spellId, target = entrustedChoice(master)
        if spellId and target then
            mobArg:castSpell(spellId, target)
            return true
        end
    elseif not mobArg:hasRecast(xi.recast.ABILITY, xi.ja.ENTRUST) then
        mobArg:useJobAbility(xi.ja.ENTRUST, mobArg)
        return true
    end

    return false
end

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
    -- AURA_SIZE is *100; +400 = 10' bubble so melee on the far side of a mob stays covered.
    mob:addMod(xi.mod.REGAIN, 50)
    mob:addMod(xi.mod.DMG, -2500)
    mob:addMod(xi.mod.INDI_DURATION, 180)
    mob:addMod(xi.mod.AURA_SIZE, 400)
    -- Potency floor so Indi power tracks GEO skill; Geomancy+3 at 99.
    mob:addMod(xi.mod.GEOMANCY_SKILL, 8 * mob:getMainLvl() + 1)
    if mob:getMainLvl() >= 99 then
        mob:addMod(xi.mod.GEOMANCY_BONUS, 3)
    end

    -- No melee / no enemy magic. Stay on the summoner (Indi aura is ~10' around her).
    -- MID_RANGE used to park her 6' from the *enemy*, so the bubble missed the player.
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    mob:setLocalVar('TrustFollowMaster', 1)
    -- Casters / ranged never melee-swing; without this she never engages and never Indis.
    mob:setLocalVar('TrustEngageWithMaster', 1)

    -- Bubble first: yellow-cure gambits used to starve Indi for the whole fight.
    if mob:getMainLvl() >= 20 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COLURE_ACTIVE }, { ai.r.MA, ai.s.BEST_INDI, xi.magic.spellFamily.NONE })
    end

    -- Entrust is tick-driven so it only fires when the master lost their colure.
    -- A SELF ENTRUSTED gambit overwrites her Indi (one COLURE per entity).

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

        -- Keep both bubbles up: her Indi first, then Entrust on the master.
        if maintainSelfIndi(mobArg, masterArg) then
            return
        end

        if maintainEntrust(mobArg, masterArg) then
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
