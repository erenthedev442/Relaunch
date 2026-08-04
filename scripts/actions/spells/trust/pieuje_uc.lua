-----------------------------------
-- Trust: Pieuje UC
-- Spell ID: 953 | Pool ID: 5953
-- WHM/PLD club. Afflatus Misery + Auspice (Enlight-like AA). Sacrosanctity vs SP.
-- Regain 34. NO_MOVE after engage; clubs nearby foes. Prefer Nott for MP.
-- Haste any job. Esuna in Misery. A-tier healer (support) + meleeChip for AA.
-- No kit inject (healer kit disables AA / wrong range).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_STARLIGHT = 163
local MS_MOONLIGHT = 164
local MS_NOTT      = 3502

local RECAST_SACRO = 33 -- abilities.sql sacrosanctity recastId

local SP_EFFECTS =
{
    xi.effect.MANAFONT,
    xi.effect.CHAINSPELL,
    xi.effect.ASTRAL_FLOW,
    xi.effect.MIGHTY_STRIKES,
    xi.effect.HUNDRED_FISTS,
    xi.effect.BLOOD_WEAPON,
    xi.effect.SOUL_VOICE,
    xi.effect.AZURE_LORE,
    xi.effect.TABULA_RASA,
    xi.effect.ELEMENTAL_SFORZO,
}

local function isWearingPieujeShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.PIEUJE_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function enemyHasSP(target)
    if not target or not target:isAlive() then
        return false
    end

    for i = 1, #SP_EFFECTS do
        if target:hasStatusEffect(SP_EFFECTS[i]) then
            return true
        end
    end

    return false
end

local function partyNeedsEsuna(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            mobArg:checkDistance(member) <= 14 and
            member:countEffectWithFlag(xi.effectFlag.ERASABLE) > 0
        then
            return true
        end
    end

    return false
end

local function castHasteOnParty(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    -- Retail: Haste players regardless of job (includes trusts in range).
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            not member:hasStatusEffect(xi.effect.HASTE) and
            mobArg:checkDistance(member) <= 21
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
    if master and isWearingPieujeShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Retail: Regain 34 TP/tick. WHM/PLD sleep resist.
    mob:addMod(xi.mod.REGAIN, 34)
    mob:addMod(xi.mod.SLEEPRES, 100)
    mob:addMod(xi.mod.LULLABYRES, 100)

    -- Stationary after engage; still AAs with club when the foe is in range.
    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    -- Afflatus Misery + Auspice (Misery + Auspice → Enlight-like AA).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AFFLATUS_MISERY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AFFLATUS_MISERY })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AUSPICE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AUSPICE })

    -- Triage → status → yellow → shields. No Curaga (retail specialty of others).
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
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })

    -- Flash when he has hate (PLD sub flavor).
    mob:addGambit(ai.t.TARGET, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH })

    mob:setLocalVar('pieujeWsLock', 0)

    mob:addListener('COMBAT_TICK', 'PIEUJE_UC_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()

        -- Sacrosanctity vs enemy SP (Manafont / Chainspell / Astral Flow, etc.).
        if
            mobArg:getMainLvl() >= 95 and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_SACRO) and
            enemyHasSP(battleTarget)
        then
            mobArg:useJobAbility(xi.ja.SACROSANCTITY, mobArg)
            return
        end

        -- Esuna in Misery: remove erasable ailments from self/party in range.
        if
            mobArg:hasStatusEffect(xi.effect.AFFLATUS_MISERY) and
            mobArg:getMainLvl() >= 61 and
            partyNeedsEsuna(mobArg)
        then
            mobArg:castSpell(xi.magic.spell.ESUNA, mobArg)
            return
        end

        -- Haste any job (retail).
        if castHasteOnParty(mobArg) then
            return
        end

        -- TP → MP recovery. Prefer Nott; else Starlight / Moonlight.
        local tp = mobArg:getTP()
        local mpp = mobArg:getMPP()
        if tp < 1000 or mpp >= 80 or mobArg:getLocalVar('pieujeWsLock') ~= 0 then
            return
        end

        local lvl = mobArg:getMainLvl()
        local wsId = nil
        if lvl >= 50 then
            wsId = MS_NOTT
        elseif lvl >= 25 then
            wsId = MS_MOONLIGHT
        elseif lvl >= 5 then
            wsId = MS_STARLIGHT
        end

        if wsId then
            mobArg:setLocalVar('pieujeWsLock', 1)
            mobArg:useMobAbility(wsId, mobArg)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'PIEUJE_UC_WS_UNLOCK', function(mobArg)
        mobArg:setLocalVar('pieujeWsLock', 0)
    end)

    mob:addListener('WEAPONSKILL_STATE_EXIT', 'PIEUJE_UC_WS_EXIT', function(mobArg)
        mobArg:setLocalVar('pieujeWsLock', 0)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
