-- Hide all Meandering Leafkin NPCs in Leafallia (zone 281).
-- status=2 = DISAPPEAR (invisible/disabled). Idempotent.
UPDATE npc_list SET status = 2
WHERE ((npcid >> 12) & 0xFFF) = 281
  AND name LIKE '%Leafkin%';
