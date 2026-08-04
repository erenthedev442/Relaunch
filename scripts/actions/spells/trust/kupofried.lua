-----------------------------------
-- Trust: Kupofried
-- Passive EXP/CP aura trust. Stays with the summoner; does not fight.
-- +20% EXP_BONUS / CAPACITY_BONUS (stacks with Dedication / Commitment rings).
-- Player icons are display-only (subPower 0 → no dedication/commitment payout).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local EXP_BONUS_PCT = 20
local AURA_RANGE    = 12

local ICON_FLAGS = bit.bor(xi.effectFlag.ALWAYS_EXPIRING, xi.effectFlag.NO_LOSS_MESSAGE)

local function clearKupofriedBonus(player)
    if not player or player:getObjType() ~= xi.objType.PC then
        return
    end

    if player:getLocalVar('KupofriedAuraActive') == 1 then
        player:delMod(xi.mod.EXP_BONUS, EXP_BONUS_PCT)
        player:delMod(xi.mod.CAPACITY_BONUS, EXP_BONUS_PCT)
        player:setLocalVar('KupofriedAuraActive', 0)
    end

    -- Remove display-only icons we applied (never touch ring Dedication/Commitment).
    if player:getLocalVar('KupofriedDedicationIcon') == 1 then
        local ded = player:getStatusEffect(xi.effect.DEDICATION)
        if ded and ded:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) then
            player:delStatusEffectSilent(xi.effect.DEDICATION)
        end

        player:setLocalVar('KupofriedDedicationIcon', 0)
    end

    if player:getLocalVar('KupofriedCommitmentIcon') == 1 then
        local com = player:getStatusEffect(xi.effect.COMMITMENT)
        if com and com:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) then
            player:delStatusEffectSilent(xi.effect.COMMITMENT)
        end

        player:setLocalVar('KupofriedCommitmentIcon', 0)
    end
end

local function refreshIcon(player, effectId, localVar)
    local existing = player:getStatusEffect(effectId)
    if existing then
        if player:getLocalVar(localVar) == 1 and existing:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) then
            -- Keep existing icon; ALWAYS_EXPIRING maintains the timer illusion.
            return
        end

        -- Ring (or other real source) owns this effect — do not overwrite.
        player:setLocalVar(localVar, 0)
        return
    end

    player:addStatusEffect(effectId, {
        power    = EXP_BONUS_PCT,
        tick     = 3,
        duration = 6,
        origin   = player,
        -- subPower 0: AddExpBonus / AddCapacityBonus pay 0 (no double-dip with mods).
        subPower = 0,
        flag     = ICON_FLAGS,
    })
    player:setLocalVar(localVar, 1)
end

local function applyKupofriedBonus(player)
    if not player or player:getObjType() ~= xi.objType.PC then
        return
    end

    if player:getLocalVar('KupofriedAuraActive') ~= 1 then
        player:addMod(xi.mod.EXP_BONUS, EXP_BONUS_PCT)
        player:addMod(xi.mod.CAPACITY_BONUS, EXP_BONUS_PCT)
        player:setLocalVar('KupofriedAuraActive', 1)
    end

    refreshIcon(player, xi.effect.DEDICATION, 'KupofriedDedicationIcon')
    refreshIcon(player, xi.effect.COMMITMENT, 'KupofriedCommitmentIcon')
end

local function syncKupofriedAura(mob)
    local master = mob:getMaster()
    if not master or master:getObjType() ~= xi.objType.PC then
        return
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return
    end

    for _, member in pairs(party) do
        if member:getObjType() == xi.objType.PC then
            if mob:checkDistance(member) <= AURA_RANGE then
                applyKupofriedBonus(member)
            else
                clearKupofriedBonus(member)
            end
        end
    end
end

local function cleanupParty(mob)
    local master = mob:getMaster()
    if not master or master:getObjType() ~= xi.objType.PC then
        return
    end

    local party = master:getPartyWithTrusts()
    if party then
        for _, member in pairs(party) do
            if member:getObjType() == xi.objType.PC then
                clearKupofriedBonus(member)
            end
        end
    else
        clearKupofriedBonus(master)
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Passive: never fight, never party-chain follow — stick to summoner.
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    mob:setLocalVar('TrustFollowMaster', 1)
    mob:setLocalVar('TrustNoEngage', 1)

    -- Visible colure bubble (Sakura / Cornelia pattern).
    mob:addStatusEffect(xi.effect.COLURE_ACTIVE, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_REFRESH,
        subPower = 1,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })

    syncKupofriedAura(mob)

    mob:addListener('EFFECTS_TICK', 'KUPOFRIED_AURA', function(mobArg)
        syncKupofriedAura(mobArg)
    end)

    mob:addListener('ROAM_TICK', 'KUPOFRIED_AURA_ROAM', function(mobArg)
        syncKupofriedAura(mobArg)
    end)
end

spellObject.onMobDespawn = function(mob)
    cleanupParty(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    cleanupParty(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
