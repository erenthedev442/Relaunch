-- Restore the missing Myrmecoleon entity and ??? in Abyssea-Tahrongi.
-- The marks runtime relocates and scales the mob when the player buys the pop.
DELETE FROM `mob_spawn_points` WHERE `mobid` = 16961952;
INSERT INTO `mob_spawn_points`
VALUES (16961952,0,'Myrmecoleon','Myrmecoleon',49,85,85,0.000,0.000,0.000,0);

DELETE FROM `npc_list` WHERE `npcid` = 16961976;
INSERT INTO `npc_list`
VALUES (16961976,'qm_myrmecoleon','???',0,-30.234,-7.891,33.535,1,40,40,0,0,0,0,3,0x0000340000000000000000000000000000000000,0,'ABYSSEA',0);
