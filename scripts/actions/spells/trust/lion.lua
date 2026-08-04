-----------------------------------
-- Trust: Lion
-- THF/THF. Dagger.
-- WS: Walk the Plank (AoE) / Pirate Pummel / Powder Keg (conal) / Grapeshot (conal).
-- ASAP @1000. Grapeshot interrupts enemy TP moves when she has TP.
-- Traits: Treasure Hunter I, Gilfinder, Triple Attack.
-- A-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_GRAPESHOT = 3198

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LION_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ZEID] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ALDO] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.GILGAMESH] = xi.trust.messageOffset.TEAMWORK_3,
    })

    -- THF traits (on top of A skirmisher package TA).
    mob:addMod(xi.mod.TREASURE_HUNTER, 1)
    mob:addMod(xi.mod.GILFINDER, 50)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 5)

    -- Aldo / Zeid synergy: attack speed ~6% / ~12%.
    local synergy = 0
    local master  = mob:getMaster()
    if master then
        for _, member in ipairs(master:getPartyWithTrusts()) do
            local tid = member:getTrustID()
            if tid == xi.magic.spell.ALDO or tid == xi.magic.spell.ZEID then
                synergy = synergy + 1
            end
        end
    end

    if synergy >= 1 then
        mob:addMod(xi.mod.HASTE_GEAR, synergy >= 2 and 123 or 61)
    end

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Grapeshot stun when enemy readies a TP move and Lion has TP ready.
    mob:addListener('COMBAT_TICK', 'LION_GRAPESHOT_STUN', function(mobArg)
        if mobArg:getTP() < 1000 then
            return
        end

        if mobArg:getCurrentAction() ~= xi.action.category.BASIC_ATTACK then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local act = battleTarget:getCurrentAction()
        if
            act == xi.action.category.WEAPONSKILL_START or
            act == xi.action.category.MOBABILITY_START or
            act == xi.action.category.MOBABILITY_USING
        then
            mobArg:useMobAbility(MS_GRAPESHOT, battleTarget)
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
