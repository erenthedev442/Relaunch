-- Relaunch Kraken Club reset and acquisition policy.
--
-- The wipe is guarded by a migration marker: it runs exactly once on an
-- existing database, while the source and auction restrictions are safe to
-- re-apply on every deploy.  Deploy applies custom SQL while xi_map is stopped,
-- preventing logged-in inventory state from writing deleted clubs back.

CREATE TABLE IF NOT EXISTS `relaunch_migrations` (
    `name`       varchar(100) NOT NULL,
    `applied_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `kraken_club_serials` (
    `serial`      int(10) unsigned NOT NULL AUTO_INCREMENT,
    `charid`      int(10) unsigned NOT NULL,
    `charname`    varchar(15) NOT NULL,
    `acquired_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`serial`),
    KEY `charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci AUTO_INCREMENT=1;

SET @wipe_kraken_clubs = (
    SELECT COUNT(*) = 0
    FROM `relaunch_migrations`
    WHERE `name` = '2026-08-29-kraken-club-reset'
);

-- Remove equipped references before deleting their inventory slots.
DELETE ce
FROM `char_equip` AS ce
INNER JOIN `char_inventory` AS ci
    ON ci.`charid` = ce.`charid`
   AND ci.`location` = ce.`containerid`
   AND ci.`slot` = ce.`slotid`
WHERE @wipe_kraken_clubs = 1
  AND ci.`itemId` = 17440;

-- Saved equipment sets store item IDs directly.
UPDATE `char_equip_saved`
SET
    `main`   = IF(`main`   = 17440, 0, `main`),
    `sub`    = IF(`sub`    = 17440, 0, `sub`),
    `ranged` = IF(`ranged` = 17440, 0, `ranged`),
    `ammo`   = IF(`ammo`   = 17440, 0, `ammo`),
    `head`   = IF(`head`   = 17440, 0, `head`),
    `body`   = IF(`body`   = 17440, 0, `body`),
    `hands`  = IF(`hands`  = 17440, 0, `hands`),
    `legs`   = IF(`legs`   = 17440, 0, `legs`),
    `feet`   = IF(`feet`   = 17440, 0, `feet`),
    `neck`   = IF(`neck`   = 17440, 0, `neck`),
    `waist`  = IF(`waist`  = 17440, 0, `waist`),
    `ear1`   = IF(`ear1`   = 17440, 0, `ear1`),
    `ear2`   = IF(`ear2`   = 17440, 0, `ear2`),
    `ring1`  = IF(`ring1`  = 17440, 0, `ring1`),
    `ring2`  = IF(`ring2`  = 17440, 0, `ring2`),
    `back`   = IF(`back`   = 17440, 0, `back`)
WHERE @wipe_kraken_clubs = 1
  AND 17440 IN (
      `main`, `sub`, `ranged`, `ammo`, `head`, `body`, `hands`, `legs`,
      `feet`, `neck`, `waist`, `ear1`, `ear2`, `ring1`, `ring2`, `back`
  );

DELETE FROM `char_inventory`
WHERE @wipe_kraken_clubs = 1
  AND `itemId` = 17440;

UPDATE `char_look`
SET
    `main`   = IF(`main`   = 17440, 0, `main`),
    `sub`    = IF(`sub`    = 17440, 0, `sub`),
    `ranged` = IF(`ranged` = 17440, 0, `ranged`)
WHERE @wipe_kraken_clubs = 1
  AND 17440 IN (`main`, `sub`, `ranged`);

UPDATE `char_style`
SET
    `main`   = IF(`main`   = 17440, 0, `main`),
    `sub`    = IF(`sub`    = 17440, 0, `sub`),
    `ranged` = IF(`ranged` = 17440, 0, `ranged`)
WHERE @wipe_kraken_clubs = 1
  AND 17440 IN (`main`, `sub`, `ranged`);

DELETE FROM `delivery_box`
WHERE @wipe_kraken_clubs = 1
  AND (`itemid` = 17440 OR `itemsubid` = 17440);

DELETE FROM `auction_house`
WHERE @wipe_kraken_clubs = 1
  AND `itemid` = 17440;

-- Clear any pre-release serial ledger only as part of the one-time clean slate.
DELETE FROM `kraken_club_serials`
WHERE @wipe_kraken_clubs = 1;

INSERT IGNORE INTO `relaunch_migrations` (`name`)
VALUES ('2026-08-29-kraken-club-reset');

-- Kraken Club may be traded directly, but cannot be listed on the AH.
UPDATE `item_basic`
SET `aH` = 0,
    -- Inscribable makes the LEG serial visible/reloadable; NoAuction blocks listings.
    `flags` = `flags` | 32 | 64
WHERE `itemid` = 17440;

DELETE FROM `auction_house_items`
WHERE `itemid` = 17440;

-- Lord of Onzozo: exactly one Kraken Club roll at 5%.
DELETE FROM `mob_droplist`
WHERE `dropId` = 1536
  AND `itemId` IN (18852, 17440);

INSERT INTO `mob_droplist`
    (`dropId`, `dropType`, `groupId`, `groupRate`, `itemId`, `itemRate`)
VALUES
    (1536, 0, 0, 1000, 17440, 50);
