-- Lionheart (21694) aftermath fix
-- Bug 1: ADDS_WEAPONSKILL was 60 (Resolution, no aftermath) -- should be 61 (Dimidiation, MYTHIC aftermath)
-- Bug 2: AFTERMATH mod (256) was missing entirely -- needs 39 (Tier 3 Mythic, same as Epeolatry 21685)
UPDATE `item_mods` SET `value` = 61 WHERE `itemId` = 21694 AND `modId` = 355;
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`) VALUES (21694, 256, 39);
