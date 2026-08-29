-- Canonical set-point corrections for the four settable level-99 spells.
-- Safe to re-run after importing the base blue_spell_list table.
UPDATE `blue_spell_list`
SET `set_points` = CASE `spellid`
    WHEN 711 THEN 7
    WHEN 712 THEN 6
    WHEN 713 THEN 6
    WHEN 714 THEN 6
END
WHERE `spellid` IN (711, 712, 713, 714);
