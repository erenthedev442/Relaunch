-- Persistent per-character storage for Arcane Augmenter catalysts.
-- Quantities are consumed atomically by the catalyst-bank C++ bindings.
-- ON DELETE CASCADE prevents orphaned balances when a character is deleted.

CREATE TABLE IF NOT EXISTS `char_augment_catalysts` (
  `charid`   int(10) unsigned      NOT NULL,
  `itemid`   smallint(5) unsigned  NOT NULL,
  `quantity` int(10) unsigned      NOT NULL DEFAULT 0,
  PRIMARY KEY (`charid`, `itemid`),
  CONSTRAINT `fk_char_augment_catalysts_char`
    FOREIGN KEY (`charid`) REFERENCES `chars` (`charid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
