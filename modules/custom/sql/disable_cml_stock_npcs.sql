-- Hide all stock npc_list NPCs in Celennia Memorial Library (zone 284).
-- Custom dynamic entities (SparksExchange, CraftingExchange, etc.) are not
-- in npc_list, so this only affects the retail/LSB NPCs we don't use.
-- Door_Back_to_Town (17940508) is our custom warp door -- preserve it.
UPDATE npc_list SET status = 2
WHERE ((npcid >> 12) & 0xFFF) = 284
  AND npcid != 17940508;
