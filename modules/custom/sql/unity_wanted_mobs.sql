-- unity_wanted_mobs.sql
-- Adds zone 288 (Escha-Zi'tah / Reisenjima_Henge) mob_groups rows for Unity
-- Wanted NMs that don't already have a zone-288 entry.
-- poolid is copied from each NM's natural-zone entry; stats come from mob_pools.
-- NMs with poolid=0 lack a mob_pools entry in LSB - will spawn without proper
-- model/stats until a mob_pools row is added (functional for system testing).
-- respawntime=0 -> manual spawn only (insertDynamicEntity from unity_wanted.lua).
-- Idempotent: INSERT IGNORE skips rows that already exist (groupid+zoneid PK).
-- Already in zone 288: groupids 24-35 (Hugemaw_Harold, Prickly_Pitriv, etc.)

INSERT IGNORE INTO mob_groups (groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance)
VALUES
-- Tier 1 (lv 75-80) --
(70, 6809, 288, 'Orcfeltrap',            0, 0, 0, 0, 0, 0),
(71, 6826, 288, 'Ironhorn_Baldurno',     0, 0, 0, 0, 0, 0),
(72, 0,    288, 'Sleepy_Mabel',          0, 0, 0, 0, 0, 0),
(73, 0,    288, 'Sybaritic_Samantha',    0, 0, 0, 0, 0, 0),
(74, 6830, 288, 'Bounding_Belinda',      0, 0, 0, 0, 0, 0),
(75, 0,    288, 'Valkurm_Imperator',     0, 0, 0, 0, 0, 0),
(76, 6832, 288, 'Joyous_Green',          0, 0, 0, 0, 0, 0),
(77, 6839, 288, 'Warblade_Beak',         0, 0, 0, 0, 0, 0),
(78, 6838, 288, 'Cactrot_Veloz',         0, 0, 0, 0, 0, 0),
(79, 0,    288, 'Woodland_Mender',       0, 0, 0, 0, 0, 0),
(80, 6828, 288, 'Emperor_Arthro',        0, 0, 0, 0, 0, 0),
(81, 6741, 288, 'Tiyanak',               0, 0, 0, 0, 0, 0),
(82, 6738, 288, 'Vermillion_Fishfly',    0, 0, 0, 0, 0, 0),
(83, 6810, 288, 'Intuila',               0, 0, 0, 0, 0, 0),
-- Tier 2 (lv 99-119) --
(84, 0,    288, 'Lumber_Jill',           0, 0, 0, 0, 0, 0),
(85, 6834, 288, 'Largantua',             0, 0, 0, 0, 0, 0),
(86, 6723, 288, 'Garbage_Gel',           0, 0, 0, 0, 0, 0),
(87, 6853, 288, 'King_Uropygid',         0, 0, 0, 0, 0, 0),
(88, 6836, 288, 'Vedrfolnir',            0, 0, 0, 0, 0, 0),
(89, 6837, 288, 'Glazemane',             0, 0, 0, 0, 0, 0),
(90, 6742, 288, 'Volatile_Cluster',      0, 0, 0, 0, 0, 0),
(91, 6833, 288, 'Strix',                 0, 0, 0, 0, 0, 0),
(92, 6855, 288, 'Sovereign_Behemoth',    0, 0, 0, 0, 0, 0),
(93, 6840, 288, 'Arke',                  0, 0, 0, 0, 0, 0),
(94, 6843, 288, 'Douma_Weapon',          0, 0, 0, 0, 0, 0),
(95, 6744, 288, 'Kubool_Jas_Mhuufya',    0, 0, 0, 0, 0, 0),
(96, 6746, 288, 'Thuban',                0, 0, 0, 0, 0, 0),
(97, 0,    288, 'Tumult_Curator',        0, 0, 0, 0, 0, 0),
-- Tier 3 (lv 120-145) --
(98, 6884, 288, 'Specter_Worm',          0, 0, 0, 0, 0, 0),
(99, 6887, 288, 'Bakunawa',              0, 0, 0, 0, 0, 0),
(100,6891, 288, 'Mephitas',              0, 0, 0, 0, 0, 0),
(101,6757, 288, 'Vidmapire',             0, 0, 0, 0, 0, 0),
(102,6758, 288, 'Shedu',                 0, 0, 0, 0, 0, 0),
(103,6728, 288, 'Azure-toothed_Clawberry', 0, 0, 0, 0, 0, 0),
(104,6902, 288, 'Centurio_XX-I',         0, 0, 0, 0, 0, 0),
(105,6906, 288, 'Wyvernhunter_Bambrox',  0, 0, 0, 0, 0, 0),
(106,6856, 288, 'Tolba',                 0, 0, 0, 0, 0, 0),
(107,6876, 288, 'Ayapec',                0, 0, 0, 0, 0, 0),
(108,6877, 288, 'Hidhaegg',              0, 0, 0, 0, 0, 0),
(109,6897, 288, 'Coca',                  0, 0, 0, 0, 0, 0),
(110,6752, 288, 'Grand_Grenade',         0, 0, 0, 0, 0, 0),
(111,6753, 288, 'Sarama',                0, 0, 0, 0, 0, 0),
(112,6882, 288, 'Azrael',                0, 0, 0, 0, 0, 0),
(113,6896, 288, 'Carousing_Celine',      0, 0, 0, 0, 0, 0),
(114,6813, 288, 'Camahueto',             0, 0, 0, 0, 0, 0),
(115,6893, 288, 'Borealis_Shadow',       0, 0, 0, 0, 0, 0);
