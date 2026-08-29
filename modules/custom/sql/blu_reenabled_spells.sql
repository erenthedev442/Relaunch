-- Synchronize the three formerly disabled BLU spells in existing live databases.
-- The map server caches spell metadata; restart xi_map after applying this file.

UPDATE `spell_list`
SET
    `element`      = 1,
    `validTargets` = 1,
    `mpCost`       = 12,
    `castTime`     = 500,
    `recastTime`   = 10000,
    `requirements` = 0
WHERE `spellid` = 674; -- Fantod

UPDATE `spell_list`
SET
    `element`      = 8,
    `validTargets` = 4,
    `mpCost`       = 267,
    `castTime`     = 8000,
    `recastTime`   = 150000,
    `requirements` = 0
WHERE `spellid` = 686; -- Mortal Ray

UPDATE `spell_list`
SET
    `element`      = 2,
    `validTargets` = 1,
    `mpCost`       = 50,
    `castTime`     = 1500,
    `recastTime`   = 30000,
    `requirements` = 16
WHERE `spellid` = 741; -- Pyric Bulwark

UPDATE `blue_spell_list`
SET `mob_skill_id` = 580, `set_points` = 1
WHERE `spellid` = 674;

UPDATE `blue_spell_list`
SET `mob_skill_id` = 502, `set_points` = 4
WHERE `spellid` = 686;

-- Retail's spell/mob move names are reversed: Pyric Bulwark is learned from
-- the Hydra move Polar Bulwark (1831). Unbridled spells use zero set points.
UPDATE `blue_spell_list`
SET `mob_skill_id` = 1831, `set_points` = 0
WHERE `spellid` = 741;

DELETE FROM `blue_spell_mods`
WHERE `spellId` IN (674, 686, 741);

INSERT INTO `blue_spell_mods` (`spellId`, `modid`, `value`)
VALUES
    (674, 2, -10),
    (674, 9, 2),
    (674, 11, 2),
    (686, 8, 2),
    (686, 13, 2),
    (741, 0, 0);
