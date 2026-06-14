-- Replace orphan Survival_Guide at npcid 17772854 with Syndella (March 2026 retail).
-- Retail position + look bytes verified via NPCLogger capture 2026-05-04.
-- See captures/processed/2026-05-04-alter-ego-points/.
SELECT npcid, CAST(name AS CHAR) AS name, pos_x, pos_y, pos_z FROM npc_list WHERE npcid = 17772854;

UPDATE npc_list
   SET name        = 'Syndella',
       pos_x       = 3.8,
       pos_y       = 2.0,
       pos_z       = 137.0,
       pos_rot     = 128,
       -- Look bytes are LITTLE-ENDIAN-uint16 wire format; NPCLogger logs big-endian-as-text,
       -- so each byte-pair from the capture must be swapped before storage.
       look        = UNHEX('010001027710862000305E405E50006000700000'),
       content_tag = 'SOA'
 WHERE npcid = 17772854;
