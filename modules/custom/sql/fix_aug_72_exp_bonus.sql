-- Welcome Moogle uses augment 72 with exdata value 14 to produce EXP +15%.
-- Upstream maps this augment to Mod::NONE, making the displayed bonus cosmetic.
-- The engine's augment formula is (base 1 + exdata 14) = 15 percent.
UPDATE `augments`
SET    `modId` = 382 -- Mod::EXP_BONUS
WHERE  `augmentId` = 72;
