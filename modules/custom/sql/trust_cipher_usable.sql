-- ============================================================================
-- trust_cipher_usable.sql
--
-- Makes retail Trust Cipher items (10112-10193) usable like spell scrolls:
-- use item -> learn trust -> consume cipher. No Wetata/Gondebaud trade needed.
--
-- Lua: scripts/globals/trust.lua, scripts/items/_trust_cipher.lua,
--      modules/custom/lua/trust_cipher_usable.lua
--
-- Apply once against the xi database:
--   mysql -u root -p xi < modules/custom/sql/trust_cipher_usable.sql
--
-- Safe to re-apply (UPDATE + INSERT IGNORE are idempotent).
-- Server restart required (item tables cached at boot).
-- ============================================================================

-- Mark ciphers as usable items (type 5) and allow client Use command (flag 512).
UPDATE `item_basic`
SET
    `type`  = 5,
    `flags` = `flags` | 512
WHERE `itemid` BETWEEN 10112 AND 10193;

-- Scroll-like activation: self-target, white-magic scroll animation.
INSERT IGNORE INTO `item_usable`
    (`itemid`, `name`, `validTargets`, `activation`, `animation`, `animationTime`, `maxCharges`, `useDelay`, `reuseDelay`, `aoe`)
SELECT
    b.`itemid`,
    b.`name`,
    1,
    1,
    11,
    5,
    0,
    0,
    0,
    0
FROM `item_basic` AS b
WHERE b.`itemid` BETWEEN 10112 AND 10193;
