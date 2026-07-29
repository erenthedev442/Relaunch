-- Cataclysm is listed for the standard staff-WS job set. Runtime execution is
-- narrowed in charutils::canUseWeaponSkill to WAR/MNK/WHM/PLD/GEO main or sub.

UPDATE `weapon_skills`
SET `jobs` = 0x01010101000001000001000000010100000000010100
WHERE `weaponskillid` = 189;
