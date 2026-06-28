-----------------------------------
-- block_nanaa_retail_grant.lua
-- Gemma is a PAID custom trust (Void Keeper) that sits on the RETAIL Nanaa
-- Mihgo spell id (901). The stock Trust Windurst quest NPC (Windurst Woods /
-- Nanaa Mihgo) hands spell 901 out for FREE in its onEventFinish
-- (csid 865 opt 2 -> addSpell(NANAA_MIHGO)). The grant-all NPC already excludes
-- 901 (see Character_Upgrader.lua); this module closes the remaining free path,
-- mirroring block_meat_retail_grant.lua (Meat / spell 899).
--
-- Approach: let the quest run fully (permit key item, title, flags, completion
-- are all preserved by super()), then strip spell 901 afterward -- UNLESS the
-- player already owned it, so a Void Keeper buyer who happens to run the quest
-- keeps their Gemma. Players who got Gemma free BEFORE this fix keep it too
-- (block future chars only).
--
-- Pure Lua, no rebuild; takes effect on the next map restart.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Windurst_Woods/Zone')

local m = Module:new('block_nanaa_retail_grant')

-- NANAA_MIHGO is a core enum (scripts/enum/magic.lua) = 901, the slot Gemma
-- repurposes. Literal fallback covers module load order.
local GEMMA_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.NANAA_MIHGO) or 901

m:addOverride('xi.zones.Windurst_Woods.npcs.Nanaa_Mihgo.onEventFinish', function(player, csid, option, npc)
    local ownedBefore = player:hasSpell(GEMMA_SPELL)

    super(player, csid, option, npc)

    -- Revoke the Gemma/Nanaa Mihgo trust the quest just handed out, but only if
    -- the player didn't already have it (don't strip a real Void Keeper buyer).
    if not ownedBefore and player:hasSpell(GEMMA_SPELL) then
        player:delSpell(GEMMA_SPELL)
        player:printToPlayer(
            'Nanaa Mihgo answers only to those who seek the Void Keeper at GM Home.',
            xi.msg.channel.SYSTEM_3)
    end
end)

return m
