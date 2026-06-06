-----------------------------------
-- Spell: Aurorastorm II
-- Geomancy-tier weather buff (II tier). Applies the AURORASTORM_II status
-- effect to the target for 3 minutes, conferring the weather aura
-- benefits (caster's Light-element spells gain Magic Damage and
-- accuracy bonuses while the effect is active).
--
-- Implementation note: bypasses xi.spells.enhancing.useEnhancingSpell
-- because the upstream pTable in scripts/globals/spells/enhancing_spell.lua
-- doesn't have Storm II entries. Direct effect application is
-- self-contained and works without touching upstream.
--
-- Potency formula: skill / 5 + 5  (Storm I is skill / 5 + 2 baseline).
-- Duration: 180s. Adjust if it feels under/overtuned.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect     = xi.effect.AURORASTORM_II
    local skillLevel = caster:getSkillLevel(spell:getSkillType())
    local potency    = math.floor(skillLevel / 5) + 5    -- II tier: +3 base over Storm I
    local duration   = 180

    -- Storm effects are mutually exclusive. Wipe any other -storm effect
    -- the target may have from a previous cast before applying ours.
    local stormEffects = {
        xi.effect.SANDSTORM,    xi.effect.RAINSTORM,    xi.effect.WINDSTORM,
        xi.effect.FIRESTORM,    xi.effect.HAILSTORM,    xi.effect.THUNDERSTORM,
        xi.effect.VOIDSTORM,    xi.effect.AURORASTORM,
        xi.effect.SANDSTORM_II, xi.effect.RAINSTORM_II, xi.effect.WINDSTORM_II,
        xi.effect.FIRESTORM_II, xi.effect.HAILSTORM_II, xi.effect.THUNDERSTORM_II,
        xi.effect.VOIDSTORM_II, xi.effect.AURORASTORM_II,
    }
    for _, e in ipairs(stormEffects) do
        if target:hasStatusEffect(e) then
            target:delStatusEffect(e)
        end
    end

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return effect
end

return spellObject
