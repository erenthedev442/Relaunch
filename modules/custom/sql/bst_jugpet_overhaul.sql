-- ============================================================================
-- BST jug-pet overhaul -- level band
--
-- Retail jug pets cap at maxLevel 35-119 (Sheep Familiar caps at 35!), so on a
-- level-99 / 150-160 server they spawn far below the master and the C++ stat
-- formulas (HP/ATT/DEF scale with pet LEVEL) start from a tiny base. Raise every
-- BST jug pet to the 99 band so it spawns at the master's level.
--
-- petid >= 21 = jug pets (0-7 spirits, 8-20 SMN avatars -- left untouched).
-- The actual DD power scaling is layered on at spawn time in
-- modules/custom/lua/BstJugPetOverhaul.lua (pure Lua, tunable).
--
-- Idempotent. pet_list is read into memory at map boot, so a restart applies it.
-- ============================================================================
UPDATE `pet_list` SET `maxLevel` = 99 WHERE `petid` >= 21 AND `maxLevel` < 99;

-- Make all jug pets effectively permanent: 24h timer outlasts any play session.
-- Retail timers (30-60 min) caused mid-fight despawns and sudden DPS loss.
UPDATE `pet_list` SET `time` = 86400 WHERE `petid` >= 21;
