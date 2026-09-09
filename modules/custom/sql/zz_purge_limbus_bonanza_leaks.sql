-- ---------------------------------------------------------------------------
-- One-time wipe of items players should not have from Voidwatch leaks
-- (or earlier Infamy dumps onto those tables). Item definitions stay.
--
-- Set A -- 2026-09-09-limbus-bonanza-purge
--   Limbus / Sortie SU4-SU5: 24120-24194
--     Hope / Perfection / Revelation, Trust / Prestige / Sworn,
--     Justice / Magnificent / Duty, Mercy / Grace / Clemency.
--   Bonanza prize weapons: Air Knife, Cath Palug Hammer, Ice Brand, etc.
--
-- Set B -- 2026-09-09-voidwatch-i119-leak-purge
--   Later-content i119 that was sitting on Voidwatch NM rare tables
--   (Skirmish / Delve / Reisenjima / HTBF / Incursion / Voluspa / WKR).
--   Srivatsa (26403) is NOT in this list -- players earn it at the
--   Aeonic Forge. Sortie JSE earrings stay; those are an intended chase.
--
-- Apply with xi_map STOPPED. A logged-in client can write the item back on
-- logout if the map still has it in memory. Next maintenance / deploy is
-- the intended window.
--
-- Re-run set A: DELETE FROM relaunch_migrations WHERE name = '2026-09-09-limbus-bonanza-purge';
-- Re-run set B: DELETE FROM relaunch_migrations WHERE name = '2026-09-09-voidwatch-i119-leak-purge';
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `relaunch_migrations` (
    `name`       varchar(100) NOT NULL,
    `applied_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `relaunch_limbus_bonanza_purge_log` (
    `id`         int(10) unsigned NOT NULL AUTO_INCREMENT,
    `charid`     int(10) unsigned NOT NULL DEFAULT 0,
    `charname`   varchar(15) DEFAULT NULL,
    `itemId`     smallint(5) unsigned NOT NULL,
    `source`     varchar(24) NOT NULL,
    `location`   smallint(5) unsigned DEFAULT NULL,
    `slot`       smallint(5) unsigned DEFAULT NULL,
    `purged_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET @purge_limbus_bonanza = (
    SELECT COUNT(*) = 0
    FROM `relaunch_migrations`
    WHERE `name` = '2026-09-09-limbus-bonanza-purge'
);

SET @purge_vw_i119 = (
    SELECT COUNT(*) = 0
    FROM `relaunch_migrations`
    WHERE `name` = '2026-09-09-voidwatch-i119-leak-purge'
);

SET @purge_any = IF(@purge_limbus_bonanza + @purge_vw_i119 > 0, 1, 0);

DROP TEMPORARY TABLE IF EXISTS `_purge_voidwatch_leaks`;
CREATE TEMPORARY TABLE `_purge_voidwatch_leaks` (
    `itemId` smallint(5) unsigned NOT NULL,
    PRIMARY KEY (`itemId`)
) ENGINE=MEMORY;

INSERT IGNORE INTO `_purge_voidwatch_leaks` (`itemId`)
SELECT 24120 + seq.n
  FROM (
        SELECT a.n + b.n * 10 AS n
          FROM (
                SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
               ) AS a
         CROSS JOIN (
                SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
                UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
               ) AS b
       ) AS seq
 WHERE @purge_limbus_bonanza = 1
   AND 24120 + seq.n <= 24194;

INSERT IGNORE INTO `_purge_voidwatch_leaks` (`itemId`)
SELECT `itemId` FROM (
    SELECT 20672 AS `itemId` UNION ALL -- Ice Brand
    SELECT 20673 UNION ALL -- Flametongue
    SELECT 21071 UNION ALL -- Cath Palug Hammer
    SELECT 21528 UNION ALL -- Dragon Fangs
    SELECT 21529 UNION ALL -- Premium Heart
    SELECT 21568 UNION ALL -- Acrontica
    SELECT 21569 UNION ALL -- Chocobo Knife
    SELECT 21570 UNION ALL -- Air Knife
    SELECT 21640 UNION ALL -- Onion Sword III
    SELECT 21641 UNION ALL -- Save the Queen III
    SELECT 21676 UNION ALL -- Brave Blade III
    SELECT 21725 UNION ALL -- Malefic Axe
    SELECT 21764 UNION ALL -- Drastic Axe
    SELECT 21814 UNION ALL -- Final Sickle
    SELECT 21885 UNION ALL -- Hebo's Spear
    SELECT 21927 UNION ALL -- Yagyu Darkblade
    SELECT 21980 UNION ALL -- Zanmato +2
    SELECT 21981 UNION ALL -- Mutsu-no-Kami Yoshiyuki
    SELECT 22042 UNION ALL -- Wizard's Rod
    SELECT 22101 UNION ALL -- Pandit's Staff
    SELECT 22145 UNION ALL -- Artemis's Bow +2
    SELECT 22152 UNION ALL -- Exeter
    SELECT 22249 UNION ALL -- Miracle Cheer
    SELECT 26488            -- Diamond Aspis
) AS bonanza
 WHERE @purge_limbus_bonanza = 1;

INSERT IGNORE INTO `_purge_voidwatch_leaks` (`itemId`)
SELECT `itemId` FROM (
    SELECT 20827 AS `itemId` UNION ALL -- Kerehcatl
    SELECT 20945 UNION ALL -- Nativus Halberd
    SELECT 21104 UNION ALL -- Eosuchus Club
    SELECT 21221 UNION ALL -- Brahmastra
    SELECT 21228 UNION ALL -- Falubeza
    SELECT 21256 UNION ALL -- Illapa
    SELECT 21712 UNION ALL -- Voluspa Axe
    SELECT 24274 UNION ALL -- Amin Turban
    SELECT 25600 UNION ALL -- Ma'iitsoh Haube
    SELECT 25654 UNION ALL -- Welkin Crown
    SELECT 25853 UNION ALL -- Querkening Brais
    SELECT 26400 UNION ALL -- Culminus
    SELECT 26487 UNION ALL -- Sacro Bulwark
    SELECT 26702 UNION ALL -- Gavialis Helm
    SELECT 26721 UNION ALL -- Rabid Visor
    SELECT 26970 UNION ALL -- Lapidary Tunic
    SELECT 27096 UNION ALL -- Count's Cuffs
    SELECT 27720 UNION ALL -- Umbani Cap
    SELECT 27724 UNION ALL -- Qaaxo Mask
    SELECT 27725 UNION ALL -- Artsieq Hat
    SELECT 27775 UNION ALL -- Nahtirah Hat
    SELECT 27857 UNION ALL -- Respite Cloak
    SELECT 28013 UNION ALL -- Hegira Wristbands
    SELECT 28015 UNION ALL -- Xaddi Gauntlets
    SELECT 28016 UNION ALL -- Qaaxo Mitaines
    SELECT 28152 UNION ALL -- Gorney Brayettes +1
    SELECT 28154 UNION ALL -- Weatherspoon Pants +1
    SELECT 28155 UNION ALL -- Scuffler's Cosciales
    SELECT 28174 UNION ALL -- Theurgist's Slacks
    SELECT 28280 UNION ALL -- Sokushitsu Sune-ate
    SELECT 28287 UNION ALL -- Durgai Leggings
    SELECT 28296 UNION ALL -- Artsieq Boots
    SELECT 28648 UNION ALL -- Priwen
    SELECT 28649            -- Rinda Shield
) AS i119
 WHERE @purge_vw_i119 = 1;

INSERT INTO `relaunch_limbus_bonanza_purge_log` (`charid`, `charname`, `itemId`, `source`, `location`, `slot`)
SELECT ci.`charid`, c.`charname`, ci.`itemId`, 'inventory', ci.`location`, ci.`slot`
  FROM `char_inventory` AS ci
  LEFT JOIN `chars` AS c ON c.`charid` = ci.`charid`
  INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` = ci.`itemId`
 WHERE @purge_any = 1;

INSERT INTO `relaunch_limbus_bonanza_purge_log` (`charid`, `charname`, `itemId`, `source`, `location`, `slot`)
SELECT db.`charid`, db.`charname`, db.`itemid`, 'delivery', db.`box`, db.`slot`
  FROM `delivery_box` AS db
  INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` IN (db.`itemid`, db.`itemsubid`)
 WHERE @purge_any = 1;

INSERT INTO `relaunch_limbus_bonanza_purge_log` (`charid`, `charname`, `itemId`, `source`, `location`, `slot`)
SELECT ah.`seller`, ah.`seller_name`, ah.`itemid`, 'auction', NULL, NULL
  FROM `auction_house` AS ah
  INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` = ah.`itemid`
 WHERE @purge_any = 1;

DELETE ce
  FROM `char_equip` AS ce
 INNER JOIN `char_inventory` AS ci
    ON ci.`charid` = ce.`charid`
   AND ci.`location` = ce.`containerid`
   AND ci.`slot` = ce.`slotid`
 INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` = ci.`itemId`
 WHERE @purge_any = 1;

UPDATE `char_equip_saved` AS ces
  LEFT JOIN `_purge_voidwatch_leaks` AS p_main   ON p_main.`itemId`   = ces.`main`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_sub    ON p_sub.`itemId`    = ces.`sub`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ranged ON p_ranged.`itemId` = ces.`ranged`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ammo   ON p_ammo.`itemId`   = ces.`ammo`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_head   ON p_head.`itemId`   = ces.`head`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_body   ON p_body.`itemId`   = ces.`body`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_hands  ON p_hands.`itemId`  = ces.`hands`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_legs   ON p_legs.`itemId`   = ces.`legs`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_feet   ON p_feet.`itemId`   = ces.`feet`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_neck   ON p_neck.`itemId`   = ces.`neck`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_waist  ON p_waist.`itemId`  = ces.`waist`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ear1   ON p_ear1.`itemId`   = ces.`ear1`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ear2   ON p_ear2.`itemId`   = ces.`ear2`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ring1  ON p_ring1.`itemId`  = ces.`ring1`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ring2  ON p_ring2.`itemId`  = ces.`ring2`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_back   ON p_back.`itemId`   = ces.`back`
   SET ces.`main`   = IF(p_main.`itemId`   IS NULL, ces.`main`,   0),
       ces.`sub`    = IF(p_sub.`itemId`    IS NULL, ces.`sub`,    0),
       ces.`ranged` = IF(p_ranged.`itemId` IS NULL, ces.`ranged`, 0),
       ces.`ammo`   = IF(p_ammo.`itemId`   IS NULL, ces.`ammo`,   0),
       ces.`head`   = IF(p_head.`itemId`   IS NULL, ces.`head`,   0),
       ces.`body`   = IF(p_body.`itemId`   IS NULL, ces.`body`,   0),
       ces.`hands`  = IF(p_hands.`itemId`  IS NULL, ces.`hands`,  0),
       ces.`legs`   = IF(p_legs.`itemId`   IS NULL, ces.`legs`,   0),
       ces.`feet`   = IF(p_feet.`itemId`   IS NULL, ces.`feet`,   0),
       ces.`neck`   = IF(p_neck.`itemId`   IS NULL, ces.`neck`,   0),
       ces.`waist`  = IF(p_waist.`itemId`  IS NULL, ces.`waist`,  0),
       ces.`ear1`   = IF(p_ear1.`itemId`   IS NULL, ces.`ear1`,   0),
       ces.`ear2`   = IF(p_ear2.`itemId`   IS NULL, ces.`ear2`,   0),
       ces.`ring1`  = IF(p_ring1.`itemId`  IS NULL, ces.`ring1`,  0),
       ces.`ring2`  = IF(p_ring2.`itemId`  IS NULL, ces.`ring2`,  0),
       ces.`back`   = IF(p_back.`itemId`   IS NULL, ces.`back`,   0)
 WHERE @purge_any = 1
   AND (p_main.`itemId` IS NOT NULL OR p_sub.`itemId` IS NOT NULL OR p_ranged.`itemId` IS NOT NULL
     OR p_ammo.`itemId` IS NOT NULL OR p_head.`itemId` IS NOT NULL OR p_body.`itemId` IS NOT NULL
     OR p_hands.`itemId` IS NOT NULL OR p_legs.`itemId` IS NOT NULL OR p_feet.`itemId` IS NOT NULL
     OR p_neck.`itemId` IS NOT NULL OR p_waist.`itemId` IS NOT NULL OR p_ear1.`itemId` IS NOT NULL
     OR p_ear2.`itemId` IS NOT NULL OR p_ring1.`itemId` IS NOT NULL OR p_ring2.`itemId` IS NOT NULL
     OR p_back.`itemId` IS NOT NULL);

DELETE ci
  FROM `char_inventory` AS ci
 INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` = ci.`itemId`
 WHERE @purge_any = 1;

UPDATE `char_look` AS cl
  LEFT JOIN `_purge_voidwatch_leaks` AS p_main   ON p_main.`itemId`   = cl.`main`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_sub    ON p_sub.`itemId`    = cl.`sub`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ranged ON p_ranged.`itemId` = cl.`ranged`
   SET cl.`main`   = IF(p_main.`itemId`   IS NULL, cl.`main`,   0),
       cl.`sub`    = IF(p_sub.`itemId`    IS NULL, cl.`sub`,    0),
       cl.`ranged` = IF(p_ranged.`itemId` IS NULL, cl.`ranged`, 0)
 WHERE @purge_any = 1
   AND (p_main.`itemId` IS NOT NULL OR p_sub.`itemId` IS NOT NULL OR p_ranged.`itemId` IS NOT NULL);

UPDATE `char_style` AS cs
  LEFT JOIN `_purge_voidwatch_leaks` AS p_main   ON p_main.`itemId`   = cs.`main`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_sub    ON p_sub.`itemId`    = cs.`sub`
  LEFT JOIN `_purge_voidwatch_leaks` AS p_ranged ON p_ranged.`itemId` = cs.`ranged`
   SET cs.`main`   = IF(p_main.`itemId`   IS NULL, cs.`main`,   0),
       cs.`sub`    = IF(p_sub.`itemId`    IS NULL, cs.`sub`,    0),
       cs.`ranged` = IF(p_ranged.`itemId` IS NULL, cs.`ranged`, 0)
 WHERE @purge_any = 1
   AND (p_main.`itemId` IS NOT NULL OR p_sub.`itemId` IS NOT NULL OR p_ranged.`itemId` IS NOT NULL);

DELETE db
  FROM `delivery_box` AS db
 INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` IN (db.`itemid`, db.`itemsubid`)
 WHERE @purge_any = 1;

DELETE ah
  FROM `auction_house` AS ah
 INNER JOIN `_purge_voidwatch_leaks` AS p ON p.`itemId` = ah.`itemid`
 WHERE @purge_any = 1;

INSERT IGNORE INTO `relaunch_migrations` (`name`)
VALUES
    ('2026-09-09-limbus-bonanza-purge'),
    ('2026-09-09-voidwatch-i119-leak-purge');
