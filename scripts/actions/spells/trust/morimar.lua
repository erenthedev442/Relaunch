-----------------------------------
-- Trust: Morimar
-- WAR/BST. Special GA AA (no haste/samba/slow/spikes). HP+10%, Beast Killer.
-- WS: Camaraderie / Into the Light / Arduous Decision (Silence).
-- Ability: Vehement Resolution (<50% HP, 3m CD) → glow → 12 Blades @2000 TP.
-- Holds for SC close @2000 TP. With Darrcuiln (and not glowing): ASAP@1000.
-- S-tier melee_dd (bruiser) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_VEHEMENT   = 3676
local MS_TWELVE     = 3680
local VEHEMENT_CD   = 180 -- seconds
local AA_SKILL_LIST = 2100

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function partyHasDarrcuiln(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return false
    end

    for _, member in pairs(party) do
        if member:getObjType() == xi.objType.TRUST and member:getTrustID() == 991 then
            return true
        end
    end

    return false
end

local function applyTpSettings(mob, withDarr, glowing)
    if glowing then
        -- Hold auto-WS; script fires 12 Blades at 2000.
        mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    elseif withDarr then
        -- Synergy: dump more often while Darrcuiln is out.
        mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    else
        -- Retail: save up to 2000 TP to close skillchains.
        mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
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

    mob:addMod(xi.mod.HPP, 10)
    mob:addMod(xi.mod.BEAST_KILLER, 15)
    -- Special AA: ignore Slow (does not benefit from Haste/Sambas either).
    mob:addImmunity(xi.immunity.SLOW)

    mob:setMobSkillAttack(AA_SKILL_LIST)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:setLocalVar('moriGlow', 0)
    mob:setLocalVar('moriVehementCD', 0)
    mob:setLocalVar('moriWsLock', 0)

    applyTpSettings(mob, partyHasDarrcuiln(mob), false)

    mob:addListener('COMBAT_TICK', 'MORIMAR_AI', function(mobArg)
        local now     = GetSystemTime() or os.time()
        local glowing = mobArg:getLocalVar('moriGlow') ~= 0
        local withDarr = partyHasDarrcuiln(mobArg)

        applyTpSettings(mobArg, withDarr, glowing)

        -- Vehement Resolution: <50% HP, 3 minute CD.
        if
            not glowing and
            canAct(mobArg) and
            mobArg:getHPP() < 50 and
            now >= mobArg:getLocalVar('moriVehementCD')
        then
            mobArg:setLocalVar('moriVehementCD', now + VEHEMENT_CD)
            mobArg:useMobAbility(MS_VEHEMENT)
            return
        end

        -- Glow state: no SC close; next WS is 12 Blades at 2000 TP.
        if glowing then
            if
                mobArg:getTP() >= 2000 and
                mobArg:getLocalVar('moriWsLock') == 0 and
                canAct(mobArg)
            then
                local battleTarget = mobArg:getTarget()
                if battleTarget and battleTarget:isAlive() then
                    mobArg:setLocalVar('moriWsLock', 1)
                    mobArg:useMobAbility(MS_TWELVE, battleTarget)
                end
            end
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'MORIMAR_WS', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('moriWsLock', 0)

        if skill:getID() == MS_TWELVE then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- Graaaaaaaaah!
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
