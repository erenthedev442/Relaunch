-----------------------------------
-- Spell stub: Mortal Ray
-- AUTO-GENERATED placeholder for spell_list row id 686 (group 3).
-- No real implementation existed -- the cast was silently no-op'ing.
-- This stub now prints a clear "not implemented" message to the caster
-- and a `[spell-stub]` line to the server log so admins can see how
-- often each missing spell is being attempted.
--
-- To finish: replace this file with the real damage / status formula
-- and remove the corresponding row from docs/admin/missing-spells.md.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    print('[spell-stub] cast of "mortal_ray" (id 686, group 3) -- not implemented; no effect applied')
    if caster:getObjType() == xi.objType.PC then
        caster:printToPlayer(
            '[Spell] "Mortal Ray" is not yet implemented on this server, kupo.',
            xi.msg.channel.SYSTEM_3)
    end
    return 0
end

return spellObject
