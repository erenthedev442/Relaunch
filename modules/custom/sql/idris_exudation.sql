-- Idris / Exudation live-database repair.
-- Idempotent so deploys can apply it to existing characters and fresh DBs.
--
-- GEO+10 (mod 961) is 119 III only. Lower Idris stages are owned by
-- zz_epeo_idris_ladder.sql.

INSERT INTO `weapon_skills`
    VALUES (175,'exudation',0x00000000000000000000000000000000000000000000,11,0,0,91,2000,3,1,0,14,12,0,1,0)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `jobs` = VALUES(`jobs`),
    `skilllevel` = VALUES(`skilllevel`),
    `animation` = VALUES(`animation`);

-- Never leave GEO+10 on the lower Idris stages, even if item_mods.sql
-- is re-applied after the ladder file.
DELETE FROM `item_mods` WHERE `itemId` IN (19970, 19971, 21070) AND `modId` = 961;

INSERT INTO `item_mods` VALUES
    (21080,5,100),
    (21080,28,40),
    (21080,30,40),
    (21080,256,31),
    (21080,311,217),
    (21080,355,175),
    (21080,961,10)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
