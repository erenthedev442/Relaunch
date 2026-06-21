-----------------------------------
-- Linkshell Concierge (shared handler)
--
-- The Linkshell Concierge NPCs exist in each nation capital (Northern San
-- d'Oria, Bastok Markets, Windurst Woods) but shipped with no behaviour. This
-- gives them their core retail function: hand the player a "New Linkshell"
-- (gray, itemid 513) so anyone can establish their own linkshell -- the path
-- that went missing when the auto global-linkshell grant was removed.
--
-- IMPORTANT: this uses a plain npcUtil.giveItem ONLY. It deliberately does NOT
-- call addLinkpearl / auto-equip -- that auto-equip path is what crash-looped
-- the old new_player_linkshell system. The player equips the New Linkshell
-- themselves (Linkshell slot) to name and establish it.
-----------------------------------
require('scripts/globals/npc_util')

xi = xi or {}
xi.linkshellConcierge = xi.linkshellConcierge or {}

local NEW_LINKSHELL = 513 -- "Linkshell" (unestablished; equipping it creates a new linkshell)

xi.linkshellConcierge.onTrigger = function(player, npc)
    player:customMenu(
    {
        title = 'Linkshell Concierge',
        options =
        {
            {
                'Receive a New Linkshell',
                function(p)
                    if p:hasItem(NEW_LINKSHELL) then
                        p:printToPlayer('You already hold a new linkshell - equip it in your Linkshell slot to establish your own.', xi.msg.channel.SYSTEM_3)
                    elseif npcUtil.giveItem(p, NEW_LINKSHELL) then
                        p:printToPlayer('A new linkshell is yours. Equip it in your Linkshell slot to name and establish it.', xi.msg.channel.SYSTEM_3)
                    end
                    -- npcUtil.giveItem handles the inventory-full case (returns false + its own message).
                end,
            },
            { 'Maybe later', nil },
        },
    })
end

return xi.linkshellConcierge
