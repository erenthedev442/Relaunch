-- ---------------------------------------------------------------------------
-- Fix client polling for missing static NPCs in Southern San d'Oria.
--
-- The retail FFXI client expects NPCs at targids 690-700 in zone 230
-- (Southern San d'Oria) — most likely Mog House decorator/wardrobe
-- entities added in later expansions. LSB's npc_list.sql leaves this
-- range unfilled, so the client's CHARREQ packets fail with:
--
--   [warn] Could not look up entity <694, 17719990> in zone <Southern_San_dOria (230)>
--
-- The client retries every 2 seconds forever once it decides an entity
-- "should" exist. A blank placeholder satisfies the query so the client
-- stops polling. The placeholder NPC is invisible, has no name, sits at
-- (0,0,0), and matches the existing LSB "blank" pattern used elsewhere
-- in this zone (see id 17719999 'blank' in the base npc_list.sql).
--
-- Apply with:
--   python tools/dbtool.py update modules/custom/sql/fix_ssd_targid_694.sql
-- ---------------------------------------------------------------------------

-- ID format for zone 230 static NPCs: ((4096 + 230) << 12) + targid
-- = 17719296 + targid
-- 17719986 = targid 690, 17719996 = targid 700.

-- Use REPLACE INTO so re-applying is safe (idempotent).
REPLACE INTO `npc_list` VALUES (17719986,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719987,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719988,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719989,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719990,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719991,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719992,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719993,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719994,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719995,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
REPLACE INTO `npc_list` VALUES (17719996,'blank','',0,0.000,0.000,0.000,0,50,50,0,0,0,2,2051,0x0000340000000000000000000000000000000000,0,NULL,0);
