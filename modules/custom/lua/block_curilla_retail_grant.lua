-----------------------------------
-- block_curilla_retail_grant.lua
-- Corvus is a PAID custom trust (Void Keeper) that sits on the RETAIL Curilla
-- spell id (902). The stock "Trust: San d'Oria" quest NPC (Curilla, in Chateau
-- d'Oraguille) hands spell 902 out for FREE in its onEventFinish (csid 573,
-- option 2 -> addSpell(CURILLA)). The grant-all NPC already excludes 902
-- (see Character_Upgrader.lua); this module closes the remaining free path.
--
-- Approach: let the quest event run fully (key item / dialogue / flags are all
-- preserved by super()), then strip spell 902 afterward -- UNLESS the player
-- already owned it, so a Void Keeper buyer who happens to run the quest keeps
-- their Corvus. Players who learned it free BEFORE this fix keep it too
-- (block future chars only).
--
-- Mirrors modules/custom/lua/block_meat_retail_grant.lua. Pure Lua, no rebuild;
-- takes effect on the next map restart.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Chateau_dOraguille/Zone')

local m = Module:new('block_curilla_retail_grant')

-- CURILLA is a core enum (scripts/enum/magic.lua) = 902, the slot Corvus
-- repurposes. Literal fallback covers module load order.
local CORVUS_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.CURILLA) or 902

m:addOverride('xi.zones.Chateau_dOraguille.npcs.Curilla.onEventFinish', function(player, csid, option, npc)
    local ownedBefore = player:hasSpell(CORVUS_SPELL)

    super(player, csid, option, npc)

    -- Revoke the Corvus/Curilla trust the quest just handed out, but only if the
    -- player didn't already have it (don't strip a real Void Keeper buyer).
    if not ownedBefore and player:hasSpell(CORVUS_SPELL) then
        player:delSpell(CORVUS_SPELL)
        player:printToPlayer(
            'The Black Arrow answers only to those who seek the Void Keeper at GM Home.',
            xi.msg.channel.SYSTEM_3)
    end
end)

return m
