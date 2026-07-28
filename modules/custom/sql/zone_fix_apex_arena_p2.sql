-- Apex Trials moved from Walk_of_Echoes_[P2] (279) to Walk_of_Echoes (182).
-- MISC_PET (0x80=128) gates PUP Activate/Deus, BST Call Beast, SMN avatars,
-- DRG wyverns, and GEO luopans. Preserve every other current-arena flag
-- (notably its 0x1000 bit). MISC_TRUST remains off for Apex's solo-only rule;
-- retain the legacy zone's previous pet-only repair for old characters.
UPDATE `zone_settings`
SET `misc` = `misc` | 128
WHERE `zoneid` = 182;

UPDATE `zone_settings`
SET `misc` = 128
WHERE `zoneid` = 279;
