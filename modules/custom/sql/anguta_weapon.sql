-- ============================================================================
-- anguta_weapon.sql
--
-- Finishes the Aeonic Scythe "Anguta" (item 20890), which shipped as a STUB
-- (only Store TP +10 and TP Bonus +500 -- no signature weapon skill, no Magic
-- Damage), exactly like Trishula was (see trishula_weapon.sql / commit
-- a15e97fa0f). Brings it up to the SAME complete Aeonic pattern used by Godhands
-- (Aeonic H2H): Store TP / Magic Damage / TP Bonus / ADDS_WEAPONSKILL.
--
-- Base weapon stats (item_weapon) were already fine: DMG 370, Delay 528,
-- Slashing, iLvl skill 269/269/242. We only top up ilvl_macc 242 -> 269 for
-- parity with the other finished endgame weapons.
--
-- Signature weapon skill: ENTROPY (WS 109) -- the merit-tier scythe WS (4-hit,
-- INT-based, returns ~20% of damage dealt as MP). It is the scythe parallel to
-- the merit WS the other finished Aeonics grant (Godhands->Shijin Spiral,
-- Sequence->Requiescat, Trishula->Stardiver). WS 109 is enabled in
-- weapon_skills.sql with a working action script at
-- scripts/actions/weaponskills/entropy.lua. ADDS_WEAPONSKILL (mod 355) grants it
-- on equip regardless of merits -- the same mechanism the Prime weapons use
-- (see prime_weapons_gear.sql).
--
-- Job access intentionally LEFT as Dark Knight-only (item_equipment jobs = 128);
-- scythe is DRK's weapon and this matches the server's single-job convention for
-- its top-tier weapons. Not changed here.
--
-- Mod ids: STORE_TP 73, MAGIC_DAMAGE 311, TP_BONUS 345, ADDS_WEAPONSKILL 355.
--
-- Apply, then restart the map (the engine caches item_weapon/item_mods at
-- startup). Idempotent.
-- ============================================================================

-- ----- base weapon: top up iLvl magic-accuracy for parity -------------------
UPDATE `item_weapon` SET `ilvl_macc` = 269 WHERE `itemId` = 20890; -- Anguta

-- ----- stat package + ADDS_WEAPONSKILL (Entropy) ----------------------------
DELETE FROM `item_mods` WHERE `itemId` = 20890;

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (20890,  73,  10),   -- STORE_TP +10
    (20890, 311, 155),   -- MAGIC_DAMAGE +155
    (20890, 345, 500),   -- TP_BONUS +500
    (20890, 355, 109);   -- ADDS_WEAPONSKILL -> 109 Entropy
