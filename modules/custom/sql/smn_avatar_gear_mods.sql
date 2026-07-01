-- SMN avatar gear mods -- Beckoner's Earring line (25504/25505/25506)
-- Mod 1040 = AVATAR_LVL_BONUS, Mod 117 = SUMMONING skill
-- PK is (itemId, modId) -- INSERT IGNORE is safe for re-runs
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
-- Beckoner's Earring (+0): Avatar: Lv.+1, Summoning magic +2
(25504, 1040, 1),
(25504,  117, 2),
-- Beckoner's Earring +1: Avatar: Lv.+1, Summoning magic +3
(25505, 1040, 1),
(25505,  117, 3),
-- Beckoner's Earring +2: Avatar: Lv.+2, Summoning magic +4
(25506, 1040, 2),
(25506,  117, 4);
