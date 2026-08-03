-- Restore BLM/RDM/SCH job levels on Tier V/VI elemental nukes so standard magic
-- tuning treats them as native main-job spells. Jobs blob is 22 bytes; SCH is
-- index 19 (0-based WAR=0). Requires map-server restart (spell_list cached).

UPDATE `spell_list` SET `jobs` = 0x000000565B00000000000000000000000000005B0000 WHERE `spellid` = 148; -- fire_v
UPDATE `spell_list` SET `jobs` = 0x000000595F00000000000000000000000000005F0000 WHERE `spellid` = 153; -- blizzard_v
UPDATE `spell_list` SET `jobs` = 0x00000053570000000000000000000000000000570000 WHERE `spellid` = 158; -- aero_v
UPDATE `spell_list` SET `jobs` = 0x0000004D4F00000000000000000000000000004F0000 WHERE `spellid` = 163; -- stone_v
UPDATE `spell_list` SET `jobs` = 0x0000005C630000000000000000000000000000630000 WHERE `spellid` = 168; -- thunder_v
UPDATE `spell_list` SET `jobs` = 0x00000050530000000000000000000000000000530000 WHERE `spellid` = 173; -- water_v

UPDATE `spell_list` SET `jobs` = 0x00000063000063000000000000000000000000630000 WHERE `spellid` = 849; -- fire_vi
UPDATE `spell_list` SET `jobs` = 0x00000063000063000000000000000000000000630000 WHERE `spellid` = 850; -- blizzard_vi
UPDATE `spell_list` SET `jobs` = 0x00000063000063000000000000000000000000630000 WHERE `spellid` = 851; -- aero_vi
UPDATE `spell_list` SET `jobs` = 0x00000063000063000000000000000000000000630000 WHERE `spellid` = 852; -- stone_vi
UPDATE `spell_list` SET `jobs` = 0x00000063000063000000000000000000000000630000 WHERE `spellid` = 853; -- thunder_vi
UPDATE `spell_list` SET `jobs` = 0x00000063000063000000000000000000000000630000 WHERE `spellid` = 854; -- water_vi
