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

-- augId 2040: repurpose null placeholder -> Thunder Affinity (THUNDER_MAB, modId 36), +1/boost.
-- At max Sage boost (value 31): (1 + 31) * 1 = +32 Thunder Affinity per slot.
-- Usage: !additem <itemid> 1 2040 31 2040 31 2040 31 2040 31  (+128 Thunder Affinity, 4 slots)
DELETE FROM `augments` WHERE `augmentId` = 2040;
INSERT INTO `augments` VALUES (2040,0,36,1,0,0); -- Thunder Affinity +1 (THUNDER_MAB)
