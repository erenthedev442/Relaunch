-- Per-character per-category Alter Ego upgrade rank.
-- One row per (charid, category). Category matches AlterEgoCategory enum (8..16).
-- Rank is the current upgrade level (0..50 in Phase 1; cap raised over time per SE).
CREATE TABLE IF NOT EXISTS `char_alter_ego_upgrades` (
  `charid`   INT(10) UNSIGNED NOT NULL,
  `category` TINYINT(3) UNSIGNED NOT NULL,
  `rank`     TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`charid`, `category`),
  CONSTRAINT `fk_char_alter_ego_upgrades_charid`
    FOREIGN KEY (`charid`) REFERENCES `chars` (`charid`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
