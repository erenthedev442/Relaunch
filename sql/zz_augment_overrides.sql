-- ---------------------------------------------------------------------------
-- zz_augment_overrides.sql
--
-- Custom tweaks to augment VALUES (sql/augments.sql), applied as an override so
-- they ride the zz_ deploy path (your deploy buttons reload sql/zz_*.sql, but
-- NOT the base augments.sql). zz_ prefix loads AFTER sql/augments.sql, so these
-- win. Mirror every change here back into sql/augments.sql too, so a full
-- rebuild and the augment-catalog generator stay consistent.
--
-- The augments table is read at gear-equip time, so this also retro-updates
-- gear already augmented with these (no re-trade needed). Requires a map
-- restart to reload the table in memory.
-- ---------------------------------------------------------------------------

-- Five Of Coins Card (item 1003) -> augId 796 "All elemental resists": +1 -> +10.
-- augId 796 grants the 8 elemental-resist mods (15-22); set each to value 10.
UPDATE `augments` SET `value` = 10 WHERE `augmentId` = 796 AND `value` <> 0;
