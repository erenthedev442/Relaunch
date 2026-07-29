-- Guarantee that three Abyssea-era BLU spells present in the repository are
-- also present in older live databases. Without the spell_list rows the map
-- server does not register these IDs, so addSpell() silently rejects them.
--
-- The map server caches both tables at startup. Apply this SQL, restart xi_map,
-- then relog/re-grant so blu_spell_progression can add the spells.

INSERT INTO `spell_list`
    (`spellid`, `name`, `jobs`, `group`, `family`, `element`, `zonemisc`,
     `validTargets`, `skill`, `mpCost`, `castTime`, `recastTime`,
     `message`, `magicBurstMessage`, `animation`, `animationTime`,
     `AOE`, `base`, `multiplier`, `CE`, `VE`, `requirements`,
     `spell_range`, `radius`, `content_tag`)
VALUES
    (701, 'tempestuous_upheaval', 0x00000000000000000000000000000063000000000000,
     3, 0, 3, 0, 4, 43, 133, 500, 7000, 2, 0, 908, 4000,
     1, 0, 1.00, 0, 0, 0, 100, 100, 'ABYSSEA'),
    (708, 'subduction', 0x00000000000000000000000000000063000000000000,
     3, 0, 3, 0, 4, 43, 27, 500, 30000, 2, 252, 925, 4000,
     1, 0, 1.00, 0, 0, 0, 100, 100, 'ABYSSEA'),
    (710, 'erratic_flutter', 0x00000000000000000000000000000063000000000000,
     3, 0, 3, 0, 1, 43, 63, 500, 30000, 230, 0, 937, 4000,
     6, 0, 1.00, 0, 0, 0, 0, 0, 'ABYSSEA')
ON DUPLICATE KEY UPDATE
    `name`              = VALUES(`name`),
    `jobs`              = VALUES(`jobs`),
    `group`             = VALUES(`group`),
    `family`            = VALUES(`family`),
    `element`           = VALUES(`element`),
    `zonemisc`          = VALUES(`zonemisc`),
    `validTargets`      = VALUES(`validTargets`),
    `skill`             = VALUES(`skill`),
    `mpCost`            = VALUES(`mpCost`),
    `castTime`          = VALUES(`castTime`),
    `recastTime`        = VALUES(`recastTime`),
    `message`           = VALUES(`message`),
    `magicBurstMessage` = VALUES(`magicBurstMessage`),
    `animation`         = VALUES(`animation`),
    `animationTime`     = VALUES(`animationTime`),
    `AOE`               = VALUES(`AOE`),
    `base`              = VALUES(`base`),
    `multiplier`        = VALUES(`multiplier`),
    `CE`                = VALUES(`CE`),
    `VE`                = VALUES(`VE`),
    `requirements`      = VALUES(`requirements`),
    `spell_range`       = VALUES(`spell_range`),
    `radius`            = VALUES(`radius`),
    `content_tag`       = VALUES(`content_tag`);

DELETE FROM `blue_spell_list`
WHERE `spellid` IN (701, 708, 710);

INSERT INTO `blue_spell_list`
    (`spellid`, `mob_skill_id`, `set_points`, `trait_category`,
     `trait_category_weight`, `primary_sc`, `secondary_sc`, `tertiary_sc`,
     `knockback`)
VALUES
    (701, 2950, 6, 18, 8, 0, 0, 0, NULL),
    (708, 2930, 6, 24, 8, 0, 0, 0, NULL),
    (710, 1952, 4, 17, 2, 0, 0, 0, NULL);
