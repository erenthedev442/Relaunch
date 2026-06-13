-----------------------------------
-- block_meat_retail_grant.lua
-- Meat is a PAID custom trust (Void Keeper, 50,000,000 gil) that sits on the
-- RETAIL Excenmille spell id (899). The stock Trust San d'Oria quest NPC
-- (Northern San d'Oria / Excenmille) hands spell 899 out for FREE in its
-- onEventFinish (csid 893 = first trust, csid 897 = quest complete ->
-- addSpell(EXCENMILLE)). The grant-all NPC already excludes 899
-- (see Character_Upgrader.lua); this module closes the remaining free path.
--
-- Approach: let the quest run fully (permit key item, title, SandoriaFirstTrust
-- flag, completion are all preserved by super()), then strip spell 899
-- afterward -- UNLESS the player already owned it, so a Void Keeper buyer who
-- happens to run the quest keeps their Meat. Players who got Meat free BEFORE
-- this fix keep it too (the owner's explicit call: block future chars only).
--
-- Pure Lua, no rebuild; takes effect on the next map restart.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Northern_San_dOria/Zone')

local m = Module:new('block_meat_retail_grant')

-- EXCENMILLE is a core enum (scripts/enum/magic.lua) = 899, the slot Meat
-- repurposes. Literal fallback covers module load order.
local MEAT_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.EXCENMILLE) or 899

m:addOverride('xi.zones.Northern_San_dOria.npcs.Excenmille.onEventFinish', function(player, csid, option, npc)
    local ownedBefore = player:hasSpell(MEAT_SPELL)

    super(player, csid, option, npc)

    -- Revoke the Meat/Excenmille trust the quest just handed out, but only if
    -- the player didn't already have it (don't strip a real Void Keeper buyer).
    if not ownedBefore and player:hasSpell(MEAT_SPELL) then
        player:delSpell(MEAT_SPELL)
        player:printToPlayer(
            'Excenmille answers only to those who seek the Void Keeper at GM Home.',
            xi.msg.channel.SYSTEM_3)
    end
end)

return m
