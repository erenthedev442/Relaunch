-- ============================================================
-- Omen (Reisenjima Henge, zone 292)
--
-- Lua:  modules/custom/lua/omen_catalog.lua      (data / tuning)
--       modules/custom/lua/omen_instance.lua     (instance runtime)
--       modules/custom/lua/omen_mechanics.lua    (boss kits)
--       scripts/zones/Reisenjima/npcs/Incantrix.lua / Coelestrox.lua
--       scripts/zones/Reisenjima_Henge/instances/omen.lua
--
-- This file gives the zone-292 mob skeleton (upstream ships all 73
-- mob_groups with poolid = 0) real pools, and registers the Omen
-- instance template. Drops are paid out by the Lua runtime, so no
-- mob_droplist rows exist and every group keeps dropid = 0.
--
-- MODEL NOTE: the Caturae's true model IDs were never captured on any
-- public server (verified July 2026 -- upstream LSB, CatsEyeXI,
-- TabulaRasa, AirSkyBoat forks all lack them). Until someone captures
-- the real looks, the five Caturae wear the Escha Zdei arcana model and
-- Ou wears the Battleclad Chariot. Swap the copied `modelid` values
-- here when captures exist.
--
-- Re-runnable: DELETE + INSERT ... SELECT, UPDATEs are idempotent.
-- Apply: sudo mysql xidb < modules/custom/sql/omen.sql, then restart map.
-- ============================================================

-- ---- 1. Zone + instance registration ---------------------------------------
-- HYBRID_INSTANCED (0x0200): the public Henge hub stays up while private
-- Omen copies of the same map run beside it (same pattern as the
-- Hybrid Dungeons -- see dungeon_instances.sql).
UPDATE `zone_settings`
SET `zonetype` = `zonetype` | 512
WHERE `zoneid` = 292;

INSERT INTO `instance_list`
    (`instanceid`, `instance_name`, `instance_zone`, `entrance_zone`,
     `time_limit`, `start_x`, `start_y`, `start_z`, `start_rot`,
     `music_day`, `music_night`, `battlesolo`, `battlemulti`)
VALUES
    -- time_limit is the retail 50-minute hard cap; the runtime enforces
    -- the dynamic 10-min + extensions limit itself.
    (29200, 'omen', 292, 291, 50, -737.000, -439.900, -769.500, 100, NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
    `instance_name` = VALUES(`instance_name`),
    `instance_zone` = VALUES(`instance_zone`),
    `entrance_zone` = VALUES(`entrance_zone`),
    `time_limit`    = VALUES(`time_limit`),
    `start_x`       = VALUES(`start_x`),
    `start_y`       = VALUES(`start_y`),
    `start_z`       = VALUES(`start_z`),
    `start_rot`     = VALUES(`start_rot`);

-- ---- 2. Pool construction ---------------------------------------------------
-- Omen pool ids: 31100 + zone-292 groupid (31101-31173). Reserved here;
-- the Hybrid Dungeons own 30100-31012.
DELETE FROM `mob_pools` WHERE `poolid` BETWEEN 31101 AND 31173;

DROP TEMPORARY TABLE IF EXISTS `omen_map`;
CREATE TEMPORARY TABLE `omen_map`
(
    `groupid`       SMALLINT UNSIGNED NOT NULL,
    `source_poolid` INT UNSIGNED NOT NULL,
    `name`          VARCHAR(30) NOT NULL,
    `mob_type`      TINYINT UNSIGNED NOT NULL, -- 0 normal, 2 notorious
    PRIMARY KEY (`groupid`)
);

-- Era-appropriate donor pools per family (models / skill lists / stats):
--   Tiger 5366 Snaggletoothed_Tiger      Fly 7009 Farruca_Fly
--   Leech 1405 Forest_Leech              Beetle 5372 Rampaging_Beetle
--   Hippogryph 5382 Quarrelsome_Hippogryph  Goobbue 5540 Eschan_Goobbue
--   Faaz 5370 Indomitable_Faaz           Pugil 442 Blademaw_Pugil
--   Toad 5373 Lentic_Toad                Raptor 4218 Velociraptor
--   Mosquito 5369 Devouring_Mosquito     Bats 355 Bastion_Bats
--   Elemental 5374 Water_Elemental       Slime 654 Carrion_Slime
--   Lucani 5386 Lucani                   Worm 5538 Eschan_Worm
--   Chapuli 5368 Agitated_Chapuli        Treant 1193 Elder_Treant
--   Mantis 5371 Territorial_Mantis       Doomed 1080 Doomed_Pilgrims
--   Skeleton 5377 Macabre_Skeleton       Cyhiraeth 5380 Asphyxiating_Cyhiraeth
--   Ghost 5576 Ascended_Gefyrst          Doll 3094 Panzer_Doll
--   Rabbit 626 Canyon_Rarab              Mandragora 2546 Mandragora
--   Lizard 3381 Rock_Lizard              Vulture 6446 Eschan_Vulture
--   Ladybug 5387 Glowering_Ladybug       Porxie 5379 Porxie
--   Panopt 5367 Obstreperous_Panopt      Unseelie 5376 Officious_Unseelie
--   Glassy: Craver_PV 6643 / Gorger_PV 6644 / Thinker_PV 6649
--   Caturae stand-ins: Eschan_Zdei 5625; Ou: Battleclad_Chariot 364
INSERT INTO `omen_map` (`groupid`, `source_poolid`, `name`, `mob_type`) VALUES
    ( 1, 5366, 'Sweetwater_Tiger',       0), ( 2, 7009, 'Sweetwater_Fly',        0),
    ( 3, 5366, 'Transcended_Tiger',      2), ( 4, 7009, 'Transcended_Fly',       2),
    ( 5, 1405, 'Sweetwater_Leech',       0), ( 6, 5372, 'Sweetwater_Beetle',     0),
    ( 7, 5372, 'Transcended_Beetle',     2), ( 8, 1405, 'Transcended_Leech',     2),
    ( 9, 6649, 'Glassy_Thinker',         2), (10, 6643, 'Glassy_Craver',         2),
    (11, 6644, 'Glassy_Gorger',          2),
    (12, 5382, 'Sweetwater_Hippogryph',  0), (13, 5540, 'Sweetwater_Goobbue',    0),
    (14, 5370, 'Sweetwater_Faaz',        0), (15,  442, 'Sweetwater_Pugil',      0),
    (16, 5382, 'Transcended_Hippogryph', 2), (17, 5540, 'Transcended_Goobbue',   2),
    (18, 5370, 'Transcended_Faaz',       2), (19,  442, 'Transcended_Pugil',     2),
    (20, 5373, 'Sweetwater_Toad',        0), (21, 4218, 'Sweetwater_Raptor',     0),
    (22, 5369, 'Sweetwater_Mosquito',    0), (23,  355, 'Sweetwater_Bats',       0),
    (24, 5373, 'Transcended_Toad',       2), (25, 4218, 'Transcended_Raptor',    2),
    (26, 5369, 'Transcended_Mosquito',   2), (27,  355, 'Transcended_Bats',      2),
    (28, 5374, 'Sweetwater_Elemental',   0), (29,  654, 'Sweetwater_Slime',      0),
    (30, 5386, 'Sweetwater_Lucani',      0), (31, 5538, 'Sweetwater_Worm',       0),
    (32, 5374, 'Transcended_Elemental',  2), (33,  654, 'Transcended_Slime',     2),
    (34, 5386, 'Transcended_Lucani',     2), (35, 5538, 'Transcended_Worm',      2),
    (36, 5368, 'Sweetwater_Chapuli',     0), (37, 1193, 'Sweetwater_Treant',     0),
    (38, 5371, 'Sweetwater_Mantis',      0), (39, 1080, 'Sweetwater_Doomed',     0),
    (40, 5368, 'Transcended_Chapuli',    2), (41, 1193, 'Transcended_Treant',    2),
    (42, 5371, 'Transcended_Mantis',     2), (43, 1080, 'Transcended_Doomed',    2),
    (44, 5377, 'Sweetwater_Skeleton',    0), (45, 5380, 'Sweetwater_Cyhiraeth',  0),
    (46, 5576, 'Sweetwater_Ghost',       0), (47, 3094, 'Sweetwater_Doll',       0),
    (48, 5377, 'Transcended_Skeleton',   2), (49, 5380, 'Transcended_Cyhiraeth', 2),
    (50, 5576, 'Transcended_Ghost',      2), (51, 3094, 'Transcended_Doll',      2),
    (52, 5625, 'Kin',                    2), (53, 5625, 'Gin',                   2),
    (54, 5625, 'Kei',                    2), (55, 5625, 'Kyou',                  2),
    (56, 5625, 'Fu',                     2),
    (57,  626, 'Sweetwater_Rabbit',      0), (58, 2546, 'Sweetwater_Mandragora', 0),
    (59, 3381, 'Sweetwater_Lizard',      0), (60, 6446, 'Sweetwater_Vulture',    0),
    (61, 5387, 'Sweetwater_Ladybug',     0), (62, 5379, 'Sweetwater_Porxie',     0),
    (63, 5367, 'Sweetwater_Panopt',      0), (64, 5376, 'Sweetwater_Unseelie',   0),
    (65,  626, 'Transcended_Rabbit',     2), (66, 2546, 'Transcended_Mandragora',2),
    (67, 3381, 'Transcended_Lizard',     2), (68, 6446, 'Transcended_Vulture',   2),
    (69, 5387, 'Transcended_Ladybug',    2), (70, 5379, 'Transcended_Porxie',    2),
    (71, 5367, 'Transcended_Panopt',     2), (72, 5376, 'Transcended_Unseelie',  2),
    (73,  364, 'Ou',                     2);

INSERT INTO `mob_pools`
    (`poolid`, `name`, `packet_name`, `speciesid`, `modelid`, `mJob`, `sJob`,
     `cmbSkill`, `cmbDelay`, `cmbDmgMult`, `behavior`, `aggro`,
     `true_detection`, `links`, `mobType`, `immunity`, `name_prefix`, `flag`,
     `entityFlags`, `animationsub`, `hasSpellScript`, `spellList`, `namevis`,
     `roamflag`, `skill_list_id`, `resist_id`, `modelSize`, `modelHitboxSize`)
SELECT
    31100 + mapping.`groupid`, mapping.`name`, mapping.`name`,
    source.`speciesid`, source.`modelid`, source.`mJob`, source.`sJob`,
    source.`cmbSkill`, source.`cmbDelay`, source.`cmbDmgMult`,
    source.`behavior`, source.`aggro`, source.`true_detection`,
    source.`links`, mapping.`mob_type`, source.`immunity`,
    source.`name_prefix`, source.`flag`, source.`entityFlags`,
    source.`animationsub`, source.`hasSpellScript`, source.`spellList`,
    source.`namevis`, source.`roamflag`, source.`skill_list_id`,
    source.`resist_id`, source.`modelSize`, source.`modelHitboxSize`
FROM `omen_map` AS mapping
INNER JOIN `mob_pools` AS source
    ON source.`poolid` = mapping.`source_poolid`;

-- ---- 3. Boss pool overrides -------------------------------------------------
-- Caturae share retail mob_skill_lists 'Caturae' (450: Diabolic Claw,
-- Stygian Cyclone/Sphere, Deathly Diminuendo, Hellish Crescendo, Malign
-- Invocation, Afflicting Gaze, Shadow Wreck, Interference, Dark
-- Arrivisme, Besieger's Bane, Royal Decree). Signature moves without
-- captured animations are scripted in omen_mechanics.lua instead.
-- Jobs per bg-wiki: Kin BLM/WAR, Gin THF/BLM, Kei WHM/BLM, Kyou MNK/WHM,
-- Fu WAR/BLM, Ou RDM/WAR.
UPDATE `mob_pools` SET `mJob` = 4, `sJob` = 1, `spellList` = 28,
    `skill_list_id` = 450, `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` = 31152; -- Kin

UPDATE `mob_pools` SET `mJob` = 6, `sJob` = 4, `spellList` = 28,
    `skill_list_id` = 450, `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` = 31153; -- Gin

UPDATE `mob_pools` SET `mJob` = 3, `sJob` = 4, `spellList` = 20,
    `skill_list_id` = 450, `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` = 31154; -- Kei

UPDATE `mob_pools` SET `mJob` = 2, `sJob` = 3, `spellList` = 0,
    `skill_list_id` = 450, `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` = 31155; -- Kyou

UPDATE `mob_pools` SET `mJob` = 1, `sJob` = 4, `spellList` = 0,
    `skill_list_id` = 450, `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` = 31156; -- Fu

UPDATE `mob_pools` SET `mJob` = 5, `sJob` = 1, `spellList` = 468,
    `skill_list_id` = 450, `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` = 31173; -- Ou

-- Glassy mid-bosses: no adds, no roaming aggro inside the arena.
UPDATE `mob_pools` SET `true_detection` = 1, `immunity` = 7, `links` = 0, `aggro` = 0
WHERE `poolid` IN (31109, 31110, 31111);

-- ---- 4. Point the zone-292 groups at their pools ----------------------------
-- Groups keep dropid = 0 (all payouts are catalogue-driven in Lua) and
-- HP/MP = 0 (the runtime sets HP per spawn).
UPDATE `mob_groups` AS grp
INNER JOIN `omen_map` AS mapping
    ON mapping.`groupid` = grp.`groupid`
SET grp.`poolid` = 31100 + mapping.`groupid`
WHERE grp.`zoneid` = 292;

DROP TEMPORARY TABLE `omen_map`;
