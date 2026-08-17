-- Runtime-safe Puppetmaster attachment data repairs.
-- Keep these idempotent so existing Relaunch databases receive the same data
-- as fresh installs without requiring a base-table rebuild.

UPDATE `item_puppet`
SET
    `name` = 'armor_plate_iv',
    `slot` = 3,
    `element` = 20480
WHERE `itemid` = 8556;

REPLACE INTO `automaton_abilities`
    (`abilityid`, `abilityname`, `reqframe`, `skilllevel`)
VALUES
    (3485, 'regulator', 0, 0);
