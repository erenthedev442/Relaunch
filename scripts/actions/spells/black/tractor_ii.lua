-----------------------------------
-- Spell: Tractor II
-- Move a KO'd player to the caster's position; same effect as Tractor
-- but at a higher MP cost. Spell row: sql/spell_list.sql id 265 (50 MP).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Mirrors scripts/actions/spells/black/tractor.lua
-- exactly — Tractor and Tractor II behave identically; the only
-- difference is the MP cost / availability.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    if
        target:isMob() or                             -- Because Prishe in CoP mission.
        target:isAlive() or                           -- Can't cast on alive targets.
        target:hasRaiseTractorMenu() or               -- Raise and tractor menus both block the casting.
        target:hasStatusEffect(xi.effect.BATTLEFIELD) -- Cannot be cast on BCNMs.
    then
        return xi.msg.basic.CANNOT_ON_THAT_TARG
    end

    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    if target:getObjType() == xi.objType.PC then
        target:sendTractor(caster:getXPos(), caster:getYPos(), caster:getZPos(), target:getRotPos())
        spell:setMsg(xi.msg.basic.MAGIC_CASTS_ON)
        return 1
    end

    return 0
end

return spellObject
