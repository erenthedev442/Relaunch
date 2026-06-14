-- ============================================================================
-- trishula_weapon.sql
--
-- Finishes the Aeonic Polearm "Trishula" (item 20935), which shipped as a STUB
-- (only Store TP +10 and TP Bonus +500 -- no signature weapon skill, no Magic
-- Damage). This brings it up to the SAME complete Aeonic pattern already used by
-- Godhands (Aeonic H2H): Store TP / Magic Damage / TP Bonus / ADDS_WEAPONSKILL.
--
-- Base weapon stats (item_weapon) were already fine: DMG 345, Delay 492,
-- Piercing, iLvl skill 269/269/228. We only top up ilvl_macc 228 -> 269 for
-- parity with the other finished endgame polearms.
--
-- Signature weapon skill: STARDIVER (WS 125) -- the modern best polearm WS and
-- the lore weapon skill of Aeonic Trishula. WS 125 already exists & is enabled
-- in weapon_skills.sql (job-gated + merit), with a working action script at
-- scripts/actions/weaponskills/stardiver.lua. ADDS_WEAPONSKILL (mod 355) grants
-- it on equip regardless of merits -- the same mechanism the Prime weapons use
-- (see prime_weapons_gear.sql).
--
-- Job access intentionally LEFT as Dragoon-only (item_equipment jobs = 8192),
-- matching this server's other top-tier polearms (Prime Lance, Ryunohige,
-- Gungnir). Not changed here.
--
-- Mod ids: STORE_TP 73, MAGIC_DAMAGE 311, TP_BONUS 345, ADDS_WEAPONSKILL 355.
--
-- Apply, then restart the map (the engine caches item_weapon/item_mods at
-- startup). Idempotent.
-- ============================================================================

-- ----- base weapon: top up iLvl magic-accuracy for parity -------------------
UPDATE `item_weapon` SET `ilvl_macc` = 269 WHERE `itemId` = 20935; -- Trishula

-- ----- stat package + ADDS_WEAPONSKILL (Stardiver) --------------------------
DELETE FROM `item_mods` WHERE `itemId` = 20935;

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (20935,  73,  10),   -- STORE_TP +10
    (20935, 311, 155),   -- MAGIC_DAMAGE +155
    (20935, 345, 500),   -- TP_BONUS +500
    (20935, 355, 125);   -- ADDS_WEAPONSKILL -> 125 Stardiver
