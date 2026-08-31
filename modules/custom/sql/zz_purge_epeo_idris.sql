-- ---------------------------------------------------------------------------
-- One-time wipe of every Epeolatry / Idris copy.
--
-- Retail has no 99-base IDs. The forge was issuing the 119s (20753 / 21070)
-- as starters. Remove every copy, including 119 III, from inventories, saved
-- sets, looks, delivery, and the AH.
--
-- Apply with xi_map STOPPED. A logged-in client can write the item back on
-- logout if the map still has it in memory.
--
-- Re-run: DELETE FROM relaunch_migrations WHERE name = '2026-08-31-epeo-idris-purge';
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `relaunch_migrations` (
    `name`       varchar(100) NOT NULL,
    `applied_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `relaunch_epeo_idris_purge_log` (
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

SET @purge_epeo_idris = (
    SELECT COUNT(*) = 0
    FROM `relaunch_migrations`
    WHERE `name` = '2026-08-31-epeo-idris-purge'
);

-- 19968/19969 Epeolatry 99 / 119 I, 20753 Epeolatry 119, 21685 119 III
-- 19970/19971 Idris 99 / 119 I,     21070 Idris 119,     21080 119 III
INSERT INTO `relaunch_epeo_idris_purge_log` (`charid`, `charname`, `itemId`, `source`, `location`, `slot`)
SELECT ci.`charid`, c.`charname`, ci.`itemId`, 'inventory', ci.`location`, ci.`slot`
  FROM `char_inventory` AS ci
  LEFT JOIN `chars` AS c ON c.`charid` = ci.`charid`
 WHERE @purge_epeo_idris = 1
   AND ci.`itemId` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080);

INSERT INTO `relaunch_epeo_idris_purge_log` (`charid`, `charname`, `itemId`, `source`, `location`, `slot`)
SELECT db.`charid`, db.`charname`, db.`itemid`, 'delivery', db.`box`, db.`slot`
  FROM `delivery_box` AS db
 WHERE @purge_epeo_idris = 1
   AND (db.`itemid` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080)
        OR db.`itemsubid` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080));

INSERT INTO `relaunch_epeo_idris_purge_log` (`charid`, `charname`, `itemId`, `source`, `location`, `slot`)
SELECT ah.`seller`, ah.`seller_name`, ah.`itemid`, 'auction', NULL, NULL
  FROM `auction_house` AS ah
 WHERE @purge_epeo_idris = 1
   AND ah.`itemid` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080);

DELETE ce
  FROM `char_equip` AS ce
 INNER JOIN `char_inventory` AS ci
    ON ci.`charid` = ce.`charid`
   AND ci.`location` = ce.`containerid`
   AND ci.`slot` = ce.`slotid`
 WHERE @purge_epeo_idris = 1
   AND ci.`itemId` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080);

UPDATE `char_equip_saved`
   SET `main`   = IF(`main`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `main`),
       `sub`    = IF(`sub`    IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `sub`),
       `ranged` = IF(`ranged` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ranged`),
       `ammo`   = IF(`ammo`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ammo`),
       `head`   = IF(`head`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `head`),
       `body`   = IF(`body`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `body`),
       `hands`  = IF(`hands`  IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `hands`),
       `legs`   = IF(`legs`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `legs`),
       `feet`   = IF(`feet`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `feet`),
       `neck`   = IF(`neck`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `neck`),
       `waist`  = IF(`waist`  IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `waist`),
       `ear1`   = IF(`ear1`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ear1`),
       `ear2`   = IF(`ear2`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ear2`),
       `ring1`  = IF(`ring1`  IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ring1`),
       `ring2`  = IF(`ring2`  IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ring2`),
       `back`   = IF(`back`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `back`)
 WHERE @purge_epeo_idris = 1
   AND (19968 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 19969 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 19970 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 19971 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 20753 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 21685 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 21070 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`)
     OR 21080 IN (`main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`, `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`));

DELETE FROM `char_inventory`
 WHERE @purge_epeo_idris = 1
   AND `itemId` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080);

UPDATE `char_look`
   SET `main`   = IF(`main`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `main`),
       `sub`    = IF(`sub`    IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `sub`),
       `ranged` = IF(`ranged` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ranged`)
 WHERE @purge_epeo_idris = 1
   AND (19968 IN (`main`, `sub`, `ranged`)
     OR 19969 IN (`main`, `sub`, `ranged`)
     OR 19970 IN (`main`, `sub`, `ranged`)
     OR 19971 IN (`main`, `sub`, `ranged`)
     OR 20753 IN (`main`, `sub`, `ranged`)
     OR 21685 IN (`main`, `sub`, `ranged`)
     OR 21070 IN (`main`, `sub`, `ranged`)
     OR 21080 IN (`main`, `sub`, `ranged`));

UPDATE `char_style`
   SET `main`   = IF(`main`   IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `main`),
       `sub`    = IF(`sub`    IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `sub`),
       `ranged` = IF(`ranged` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080), 0, `ranged`)
 WHERE @purge_epeo_idris = 1
   AND (19968 IN (`main`, `sub`, `ranged`)
     OR 19969 IN (`main`, `sub`, `ranged`)
     OR 19970 IN (`main`, `sub`, `ranged`)
     OR 19971 IN (`main`, `sub`, `ranged`)
     OR 20753 IN (`main`, `sub`, `ranged`)
     OR 21685 IN (`main`, `sub`, `ranged`)
     OR 21070 IN (`main`, `sub`, `ranged`)
     OR 21080 IN (`main`, `sub`, `ranged`));

DELETE FROM `delivery_box`
 WHERE @purge_epeo_idris = 1
   AND (`itemid` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080)
        OR `itemsubid` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080));

DELETE FROM `auction_house`
 WHERE @purge_epeo_idris = 1
   AND `itemid` IN (19968, 19969, 19970, 19971, 20753, 21685, 21070, 21080);

-- Pilgrimage indexes: relic(14) + empyrean(14) + mythic Epeo(21) / Idris(22) = 49 / 50.
UPDATE `char_vars`
   SET `value` = 0
 WHERE @purge_epeo_idris = 1
   AND `varname` IN ('LWP_Active1', 'LWP_Active2')
   AND `value` IN (49, 50);

DELETE FROM `char_vars`
 WHERE @purge_epeo_idris = 1
   AND `varname` IN (
       'LWP_49_C1', 'LWP_49_C2', 'LWP_49_C3',
       'LWP_49_M1', 'LWP_49_M2', 'LWP_49_M3',
       'LWP_50_C1', 'LWP_50_C2', 'LWP_50_C3',
       'LWP_50_M1', 'LWP_50_M2', 'LWP_50_M3'
   );

INSERT IGNORE INTO `relaunch_migrations` (`name`)
VALUES ('2026-08-31-epeo-idris-purge');
