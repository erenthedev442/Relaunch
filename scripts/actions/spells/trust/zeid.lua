-----------------------------------
-- Trust: Zeid
-- DRK/DRK Great Sword.
-- Spells: Absorb-* (incl. Attri/TP), Endark, Drain/Aspir I/II, Stun.
-- JAs: Last Resort, Nether Void, Souleater (healer present; Automaton ignored).
-- WS: Freezebite / Ground Strike / Abyssal Drain / Abyssal Strike.
-- Low HP: Abyssal Drain + Nether Void → Drain II.
-- Absorb-TP in second half when enemy has TP.
-- Abyssal Strike / Stun interrupt enemy TP moves. ASAP @1000.
-- A-tier melee_dd (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_ABYSSAL_DRAIN  = 982
local MS_ABYSSAL_STRIKE = 983
local RECAST_SOULEATER  = 85

-- Absorb-STAT / ACC only (Absorb-TP is gated separately; HIGHEST ABSORB would always pick TP).
local ABSORB_STATS =
{
    xi.magic.spell.ABSORB_STR,
    xi.magic.spell.ABSORB_DEX,
    xi.magic.spell.ABSORB_VIT,
    xi.magic.spell.ABSORB_AGI,
    xi.magic.spell.ABSORB_INT,
    xi.magic.spell.ABSORB_MND,
    xi.magic.spell.ABSORB_CHR,
    xi.magic.spell.ABSORB_ACC,
}

local HEALER_JOBS =
{
    [xi.job.WHM] = true,
    [xi.job.RDM] = true,
    [xi.job.PLD] = true,
    [xi.job.SCH] = true,
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

-- Retail: Souleater only with a healer present. Automaton / pets do not count.
local function partyHasHealer(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getObjType() ~= xi.objType.PET and
            HEALER_JOBS[member:getMainJob()]
        then
            return true
        end
    end

    return false
end

local function targetReadyingTP(battleTarget)
    local act = battleTarget:getCurrentAction()
    return act == xi.action.category.WEAPONSKILL_START or
        act == xi.action.category.MOBABILITY_START or
        act == xi.action.category.MOBABILITY_USING
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ZEID_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ALDO] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.LION] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.KLARA] = xi.trust.messageOffset.TEAMWORK_3,
    })

    -- Aldo / Lion synergy: attack ~10% / ~20%.
    local synergy = 0
    local master  = mob:getMaster()
    if master then
        for _, member in ipairs(master:getPartyWithTrusts()) do
            local tid = member:getTrustID()
            if tid == xi.magic.spell.ALDO or tid == xi.magic.spell.LION then
                synergy = synergy + 1
            end
        end
    end

    if synergy >= 1 then
        mob:addMod(xi.mod.ATT, synergy >= 2 and 40 or 20)
    end

    -- Stun interrupt (spell). Abyssal Strike interrupt when TP-ready is COMBAT_TICK.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.LAST_RESORT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.LAST_RESORT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.ENDARK }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ENDARK }, 60)

    -- Absorb-Attri when the enemy has enhancements.
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_ATTRI }, 60)

    -- Second half of the fight: Absorb-TP when the enemy has TP.
    mob:addGambit(ai.t.TARGET, {
        { ai.c.HPP_LT, 50 },
        { ai.c.TP_GTE, 1000 },
    }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_TP }, 30)

    mob:setLocalVar('zeidAbsorbReady', 0)

    -- Low HP: Nether Void then Drain II (self check → enemy cast).
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, {
        { ai.c.HPP_LT, 40 },
        { ai.c.NOT_STATUS, xi.effect.NETHER_VOID },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.NETHER_VOID })
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, {
        { ai.c.HPP_LT, 40 },
    }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DRAIN_II })
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, {
        { ai.c.HPP_LT, 50 },
    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.DRAIN }, 20)

    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, 40 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ASPIR }, 30)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)

    mob:addListener('COMBAT_TICK', 'ZEID_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Souleater only with a healer (players / trusts); pets ignored.
        if
            partyHasHealer(mobArg) and
            not mobArg:hasStatusEffect(xi.effect.SOULEATER) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_SOULEATER)
        then
            mobArg:useJobAbility(xi.ja.SOULEATER, mobArg)
            return
        end

        local tp = mobArg:getTP()
        if tp >= 1000 then
            -- Prefer Abyssal Strike to stun a readying TP move.
            if targetReadyingTP(battleTarget) then
                mobArg:useMobAbility(MS_ABYSSAL_STRIKE, battleTarget)
                return
            end

            -- Low HP: dump Abyssal Drain instead of Ground Strike / Freezebite.
            if mobArg:getHPP() < 40 then
                mobArg:useMobAbility(MS_ABYSSAL_DRAIN, battleTarget)
                return
            end
        end

        -- Rotate Absorb-STAT / ACC (not Absorb-TP).
        if mobArg:getLocalVar('zeidAbsorbReady') <= os.time() then
            mobArg:setLocalVar('zeidAbsorbReady', os.time() + 45)
            mobArg:castSpell(ABSORB_STATS[math.random(#ABSORB_STATS)], battleTarget)
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
