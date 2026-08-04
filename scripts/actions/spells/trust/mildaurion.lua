-----------------------------------
-- Trust: Mildaurion
-- PLD/SAM. Palm-blast H2H (blunt). Zilartian WS kit.
-- WS: Light Blade / Stellar Burst / Great Wheel / Vortex (all Lv2 SC props).
-- Opens for the player only when master TP >= 1500 (not other trusts).
-- Closes SCs with players/trusts; otherwise dumps at 3000 TP.
-- MP+100% (no spells). DA from weaponskill power path + H2H multi-hit.
-- A-tier melee_dd (weaponskill) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local WS_POOL =
{
    3470, -- Great Wheel (Fragmentation/Scission)
    3471, -- Light Blade (Light/Fusion)
    3472, -- Vortex (Distortion/Reverberation)
    3473, -- Stellar Burst (Darkness/Gravitation)
}

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.PRISHE] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ULMIA] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Retail: MP+100% (unused). H2H pool = blunt palm AA + multi-hit;
    -- weaponskill package supplies DA. MATT helps Vortex / Stellar Burst land.
    mob:addMod(xi.mod.MPP, 100)
    mob:addMod(xi.mod.MATT, 120)
    mob:addMod(xi.mod.MACC, 80)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Block built-in OPENER (it treats other trusts as party TP).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    mob:setLocalVar('mildWsLock', 0)

    mob:addListener('COMBAT_TICK', 'MILDAURION_TP', function(mobArg)
        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('mildWsLock', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Close SCs opened by player or other trusts.
        if battleTarget:getStatusEffect(xi.effect.SKILLCHAIN) then
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
            return
        end

        -- Hold auto-WS. Open only for the summoner @1500, else dump @3000.
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)

        if mobArg:getLocalVar('mildWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        local master = mobArg:getMaster()
        local openForPlayer = master and master:getTP() >= 1500
        if not openForPlayer and tp < 3000 then
            return
        end

        mobArg:setLocalVar('mildWsLock', 1)
        mobArg:useMobAbility(WS_POOL[math.random(#WS_POOL)], battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'MILDAURION_WS', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('mildWsLock', 0)
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)

        if skill:getID() == xi.mobSkill.LIGHT_BLADE_3 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- For Vana'diel!
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
