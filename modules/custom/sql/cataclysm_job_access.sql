-- Cataclysm is available to every job that meets its staff-skill requirement.
-- Skill 290 remains the actual gate; no additional main/sub-job filter applies.

UPDATE `weapon_skills`
SET `jobs` = 0x01010101010101010101010101010101010101010101
WHERE `weaponskillid` = 189;
