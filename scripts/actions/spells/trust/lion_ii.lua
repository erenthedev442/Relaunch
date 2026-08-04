-----------------------------------
-- Trust: Lion II
-- THF/NIN. Dagger. Utsusemi: Ichi/Ni.
-- WS: Walk the Plank / Pirate Pummel / Powder Keg / Grapeshot (all single-target).
-- Holds to 3000 TP to close skillchains.
-- Traits: Treasure Hunter 5, Gilfinder, Triple Attack.
-- S-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_WALK_THE_PLANK = 3494

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LION)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ZEID] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.PRISHE_II] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.LILISETTE_II] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.ARCIELA_II] = xi.trust.messageOffset.TEAMWORK_5,
    })

    -- THF/NIN traits (on top of S skirmisher package TA).
    mob:addMod(xi.mod.TREASURE_HUNTER, 5)
    mob:addMod(xi.mod.GILFINDER, 50)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 5)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COPY_IMAGE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.UTSUSEMI })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Hold to close SCs; dump at 3000. RANDOM opener; closer picks best SC.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)

    mob:addListener('WEAPONSKILL_USE', 'LION_II_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_WALK_THE_PLANK then
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
