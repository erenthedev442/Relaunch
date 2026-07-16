-- Lionheart (21694) aftermath fix
-- Lionheart is Aeonic: Dimidiation is its native WS, but its aftermath is the
-- shared Aeonic melee effect (49), applied centrally after any melee WS.
UPDATE `item_mods` SET `value` = 61 WHERE `itemId` = 21694 AND `modId` = 355;
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES (21694, 256, 49)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
