-- Hybrid dungeon instances
--
-- HYBRID_INSTANCED (0x0200) keeps each normal public zone alive while also
-- allowing any number of private CInstance copies of the same map.

UPDATE `zone_settings`
SET `zonetype` = `zonetype` | 512
WHERE `zoneid` IN (112, 153, 166, 174, 193, 196, 197, 204, 205, 212);

INSERT INTO `instance_list`
    (`instanceid`, `instance_name`, `instance_zone`, `entrance_zone`,
     `time_limit`, `start_x`, `start_y`, `start_z`, `start_rot`,
     `music_day`, `music_night`, `battlesolo`, `battlemulti`)
VALUES
    (11200, 'dungeon_xarcabard',        112, 210, 30,  594.4312,   0.1920, -258.5914, 113, NULL, NULL, NULL, NULL),
    (15300, 'dungeon_boyahda_tree',     153, 210, 30,  421.8891,   8.8088,  -65.7778,  75, NULL, NULL, NULL, NULL),
    (16600, 'dungeon_ranguemont_pass',  166, 210, 30, -178.8350,   4.0000, -154.8855, 192, NULL, NULL, NULL, NULL),
    (17400, 'dungeon_kuftal_tunnel',    174, 210, 30,   44.4200,  -9.8930,  260.3208,   8, NULL, NULL, NULL, NULL),
    (19300, 'dungeon_ordelles_caves',   193, 210, 30,   15.000,  32.000,  185.000, 127, NULL, NULL, NULL, NULL),
    -- 2026-07-13 (Lant): Y=-67.88 was ~7 units below the walkable floor -- players spawned
    -- underground and needed the leash tick to snap them up. Y=-60.20 matches the stock
    -- Gusgen floor Y (56 stock spawns cluster at Y=-60). Restart-gated (instance_list is
    -- read at map boot); a fresh run after the deploy loads the corrected entry.
    (19600, 'dungeon_gusgen_mines',     196, 210, 30,   46.4247, -60.2000, -340.0449, 249, NULL, NULL, NULL, NULL),
    (19700, 'dungeon_crawlers_nest',    197, 210, 30,  380.617, -34.610,    4.581,  59, NULL, NULL, NULL, NULL),
    -- Fei'Yin entry moved 2026-07-10 (Jamesta: the 07-09 z=5.45 point spawns
    -- the player in a sealed alcove SOUTH of the Fei'Yin gate -- the door
    -- won't open in the instance and mobs clip through the wall, so the
    -- player is trapped. The gate sits at z<19; the dungeon's Talos mob
    -- corridor is at z>=19 (mob @ -62.33/19.03). New point is just NORTH of
    -- the gate at the corridor's south mouth, ~4.6y off the nearest mob,
    -- inside the retail Talos roam area. Restart-gated; verify with !pos.
    (20400, 'dungeon_feiyin',           204, 210, 30,  -57.000,   -0.200,   21.000,  64, NULL, NULL, NULL, NULL),
    (20500, 'dungeon_ifrits_cauldron',  205, 210, 30,   98.1775,   0.3434, -301.9413, 133, NULL, NULL, NULL, NULL),
    (21200, 'dungeon_gustav_tunnel',    212, 210, 30,  300.8949, -40.1816,   69.8268,  54, NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
    `instance_name` = VALUES(`instance_name`),
    `instance_zone` = VALUES(`instance_zone`),
    `entrance_zone` = VALUES(`entrance_zone`),
    `time_limit` = VALUES(`time_limit`),
    `start_x` = VALUES(`start_x`),
    `start_y` = VALUES(`start_y`),
    `start_z` = VALUES(`start_z`),
    `start_rot` = VALUES(`start_rot`);

-- Each zone owns groups 11900-11912.  Pool IDs and drop-list IDs are global,
-- so every individual dungeon mob receives a distinct value generated from
-- its dungeon's reserved base range.
DELETE FROM `mob_groups`
WHERE
    `zoneid` IN (112, 153, 166, 174, 193, 196, 197, 204, 205, 212) AND
    `groupid` BETWEEN 11900 AND 11912;

DELETE FROM `mob_pools`
WHERE `poolid` BETWEEN 30100 AND 31012;

-- These IDs are reserved even while drops are disabled in the runtime.  This
-- prevents a future loot table from inheriting or sharing another mob's list.
DELETE FROM `mob_droplist`
WHERE `dropId` BETWEEN 3500 AND 3772;

DROP TEMPORARY TABLE IF EXISTS `dungeon_def`;
CREATE TEMPORARY TABLE `dungeon_def`
(
    `zoneid`        SMALLINT UNSIGNED NOT NULL,
    `pool_base`     INT UNSIGNED NOT NULL,
    `drop_base`     INT UNSIGNED NOT NULL,
    `first_prefix`  VARCHAR(21) NOT NULL,
    `second_prefix` VARCHAR(21) NOT NULL,
    `boss_name`     VARCHAR(24) NOT NULL,
    `first_source`  INT UNSIGNED NOT NULL,
    `second_source` INT UNSIGNED NOT NULL,
    `boss_source`   INT UNSIGNED NOT NULL,
    PRIMARY KEY (`zoneid`)
);

INSERT INTO `dungeon_def`
    (`zoneid`, `pool_base`, `drop_base`, `first_prefix`, `second_prefix`,
     `boss_name`, `first_source`, `second_source`, `boss_source`)
VALUES
    (197, 30100, 3500, 'Dungeon_Crawler',   'Dungeon_Wasp',      'Nestblight_Exoray', 831,  1810, 1271),
    (112, 30200, 3600, 'Xarcabard_Demon',   'Xarcabard_Weapon',  'Xarcabard_Dragon',  991,   868, 3575),
    (153, 30300, 3620, 'Boyahda_Crawler',   'Boyahda_Crab',      'Ancient_Guardian', 3200,  3768,  123),
    (193, 30400, 3640, 'Ordelle_Leech',     'Ordelle_Crab',      'Mireheart_Slime',  3165,  5733,  439),
    (196, 30500, 3660, 'Gusgen_Skeleton',   'Gusgen_Hound',      'Grieving_Spirit',  6551,  1926, 1514),
    (174, 30600, 3680, 'Kuftal_Worm',       'Kuftal_Lizard',     'Needleback',         668,  3456, 6898),
    (212, 30700, 3700, 'Gustav_Bat',        'Gustav_Fly',        'Ironclaw',           1924,  1901, 1537),
    (205, 30800, 3720, 'Cauldron_Bomb',     'Cauldron_Goblin',   'Cinderlord_Ifrit',   4245,  1705, 4645),
    (204, 30900, 3740, 'FeiYin_Golem',      'FeiYin_Pot',        'Frostmaw_Morbol',     770,  2480, 2741),
    (166, 31000, 3760, 'Ranguemont_Eye',    'Ranguemont_Weapon', 'Watcher_Ahriman',    1912,  1267,   65);

DROP TEMPORARY TABLE IF EXISTS `dungeon_slot`;
CREATE TEMPORARY TABLE `dungeon_slot`
(
    `slot`     TINYINT UNSIGNED NOT NULL,
    `family`   TINYINT UNSIGNED NOT NULL,
    `sequence` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`slot`)
);

INSERT INTO `dungeon_slot` (`slot`, `family`, `sequence`)
VALUES
    (0, 1, 1), (1, 1, 2), (2, 1, 3), (3, 1, 4), (4, 1, 5), (5, 1, 6),
    (6, 2, 1), (7, 2, 2), (8, 2, 3), (9, 2, 4), (10, 2, 5), (11, 2, 6),
    (12, 3, 0);

DROP TEMPORARY TABLE IF EXISTS `dungeon_mob_map`;
CREATE TEMPORARY TABLE `dungeon_mob_map` AS
SELECT
    definition.`zoneid`,
    11900 + slot.`slot` AS `groupid`,
    definition.`pool_base` + slot.`slot` AS `poolid`,
    definition.`drop_base` + slot.`slot` AS `dropid`,
    CASE slot.`family`
        WHEN 1 THEN CONCAT(definition.`first_prefix`, '_', LPAD(slot.`sequence`, 2, '0'))
        WHEN 2 THEN CONCAT(definition.`second_prefix`, '_', LPAD(slot.`sequence`, 2, '0'))
        ELSE definition.`boss_name`
    END AS `name`,
    CASE slot.`family`
        WHEN 1 THEN definition.`first_source`
        WHEN 2 THEN definition.`second_source`
        ELSE definition.`boss_source`
    END AS `source_poolid`,
    CASE WHEN slot.`family` = 3 THEN 2 ELSE 0 END AS `mob_type`
FROM `dungeon_def` AS definition
CROSS JOIN `dungeon_slot` AS slot;

-- Copy only family presentation/combat data into brand-new pool rows.  The
-- resulting pool IDs are not referenced by any public-zone group.
INSERT INTO `mob_pools`
    (`poolid`, `name`, `packet_name`, `speciesid`, `modelid`, `mJob`, `sJob`,
     `cmbSkill`, `cmbDelay`, `cmbDmgMult`, `behavior`, `aggro`,
     `true_detection`, `links`, `mobType`, `immunity`, `name_prefix`, `flag`,
     `entityFlags`, `animationsub`, `hasSpellScript`, `spellList`, `namevis`,
     `roamflag`, `skill_list_id`, `resist_id`, `modelSize`, `modelHitboxSize`)
SELECT
    mapping.`poolid`, mapping.`name`, mapping.`name`, source.`speciesid`,
    source.`modelid`, source.`mJob`, source.`sJob`, source.`cmbSkill`,
    source.`cmbDelay`, source.`cmbDmgMult`, source.`behavior`, source.`aggro`,
    source.`true_detection`, source.`links`, mapping.`mob_type`,
    source.`immunity`, source.`name_prefix`, source.`flag`, source.`entityFlags`,
    source.`animationsub`, source.`hasSpellScript`, source.`spellList`,
    source.`namevis`, source.`roamflag`, source.`skill_list_id`, source.`resist_id`,
    source.`modelSize`, source.`modelHitboxSize`
FROM `dungeon_mob_map` AS mapping
INNER JOIN `mob_pools` AS source
    ON source.`poolid` = mapping.`source_poolid`;

INSERT INTO `mob_groups`
    (`groupid`, `poolid`, `zoneid`, `name`, `respawntime`, `spawntype`,
     `dropid`, `HP`, `MP`, `allegiance`, `content_tag`)
SELECT
    mapping.`groupid`, mapping.`poolid`, mapping.`zoneid`, mapping.`name`,
    0, 128, mapping.`dropid`, 0, 0, 0, NULL
FROM `dungeon_mob_map` AS mapping;

DROP TEMPORARY TABLE `dungeon_mob_map`;
DROP TEMPORARY TABLE `dungeon_slot`;
DROP TEMPORARY TABLE `dungeon_def`;
