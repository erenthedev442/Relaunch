-----------------------------------
-- Spell: Enlight II
-- Upgrades Enlight: adds light-element damage to the target's melee
-- attacks for 3 minutes. Stronger potency than Enlight I, applied via
-- the same ENLIGHT effect with a higher power value.
--
-- Potency formula mirrors Enlight (skill / 8 + 12.5) but adds a +5
-- baseline bump for the II tier. Adjust if it under/overperforms vs
-- the player's Enlight I.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Note: there is no separate ENLIGHT_II effect in scripts/enum/effect.lua,
    -- only ENLIGHT (id 274). Enlight II reuses the same effect ID with a
    -- stronger power value so any UI / damage hooks reading ENLIGHT pick
    -- up the buffed magnitude. Overrides any existing ENLIGHT stack.
    local effect     = xi.effect.ENLIGHT
    local skillLevel = target:getSkillLevel(xi.skill.DIVINE_MAGIC)
    local potency    = (skillLevel / 8) + 17.5    -- +5 over Enlight I baseline

    if target:hasStatusEffect(effect) then
        target:delStatusEffect(effect)
    end

    if target:addStatusEffect(effect, { power = potency, duration = 180, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return effect
end

return spellObject
