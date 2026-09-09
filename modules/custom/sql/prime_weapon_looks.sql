-- ============================================================================
-- prime_weapon_looks.sql
--
-- Point every Prime family at its retail model ID. Stock LSB copied Relic
-- 119 III afterglow looks onto the named stages (Foenaria = Apocalypse 550,
-- Caliburnus = Excalibur 545, ...), so a current retail client still draws
-- the Relic. Stage-1 prime_* generics already match retail and stay as-is
-- except bow / gun / horn, which shipped as look 0.
--
-- Source: Dressup-Mod (June 2026 DAT brute-force) + LSB PR 11218 live-tested
-- afterglow IDs (vtable/ftable). Look IDs 907-928 are unused by any other
-- item_equipment row on this server.
--
-- Incomplete / 119 / 119 II = Prime mesh, no afterglow.
-- 119 III                    = Prime afterglow mesh.
--
-- Idempotent. Restart xi_map after apply (item_equipment is boot-cached).
-- ============================================================================

-- ----- H2H / Varga Purnikawa (already unique 475 / 474) --------------------
UPDATE `item_equipment` SET `MId` = 475 WHERE `itemId` IN (21532, 21533, 21534);
UPDATE `item_equipment` SET `MId` = 474 WHERE `itemId` = 21535;

-- ----- Dagger / Mpu Gandring (was Mandau AG 544) ---------------------------
UPDATE `item_equipment` SET `MId` = 907 WHERE `itemId` IN (21587, 21588, 21589);
UPDATE `item_equipment` SET `MId` = 918 WHERE `itemId` = 21590;

-- ----- Sword / Caliburnus (was Excalibur AG 545) ---------------------------
UPDATE `item_equipment` SET `MId` = 908 WHERE `itemId` IN (21643, 21644, 21645);
UPDATE `item_equipment` SET `MId` = 919 WHERE `itemId` = 21646;

-- ----- Great Sword / Helheim (was Ragnarok AG 546) -------------------------
UPDATE `item_equipment` SET `MId` = 909 WHERE `itemId` IN (21649, 21651, 21652);
UPDATE `item_equipment` SET `MId` = 920 WHERE `itemId` = 21653;

-- ----- Axe / Spalirisos (was Guttler AG 547) -------------------------------
UPDATE `item_equipment` SET `MId` = 910 WHERE `itemId` IN (21727, 21728, 21729);
UPDATE `item_equipment` SET `MId` = 921 WHERE `itemId` = 21730;

-- ----- Great Axe / Laphria (was Bravura AG 548) ----------------------------
UPDATE `item_equipment` SET `MId` = 911 WHERE `itemId` IN (21782, 21783, 21784);
UPDATE `item_equipment` SET `MId` = 922 WHERE `itemId` = 21785;

-- ----- Scythe / Foenaria (was Apocalypse AG 550) ---------------------------
UPDATE `item_equipment` SET `MId` = 913 WHERE `itemId` IN (21834, 21835, 21836);
UPDATE `item_equipment` SET `MId` = 924 WHERE `itemId` = 21837;

-- ----- Polearm / Gae Buide (was Gungnir AG 549) ----------------------------
UPDATE `item_equipment` SET `MId` = 912 WHERE `itemId` IN (21888, 21889, 21890);
UPDATE `item_equipment` SET `MId` = 923 WHERE `itemId` = 21891;

-- ----- Katana / Dokoku (was Kikoku AG 551) ---------------------------------
UPDATE `item_equipment` SET `MId` = 914 WHERE `itemId` IN (21929, 21930, 21931);
UPDATE `item_equipment` SET `MId` = 925 WHERE `itemId` = 21932;

-- ----- Great Katana / Kusanagi (was placeholder 514) -----------------------
UPDATE `item_equipment` SET `MId` = 915 WHERE `itemId` IN (21983, 21984, 21985);
UPDATE `item_equipment` SET `MId` = 926 WHERE `itemId` = 21986;

-- ----- Club / Lorg Mor (was Mjollnir AG 553) -------------------------------
UPDATE `item_equipment` SET `MId` = 916 WHERE `itemId` IN (21998, 22000, 22001);
UPDATE `item_equipment` SET `MId` = 927 WHERE `itemId` = 22002;

-- ----- Staff / Opashoro (was Claustrum AG 554) -----------------------------
UPDATE `item_equipment` SET `MId` = 917 WHERE `itemId` IN (22103, 22104, 22105);
UPDATE `item_equipment` SET `MId` = 928 WHERE `itemId` = 22106;

-- ----- Archery / Pinaka (was look 0) ---------------------------------------
UPDATE `item_equipment` SET `MId` =  82 WHERE `itemId` = 22155;                 -- Prime Bow (generic)
UPDATE `item_equipment` SET `MId` = 148 WHERE `itemId` IN (22156, 22157, 22158);
UPDATE `item_equipment` SET `MId` = 151 WHERE `itemId` = 22163;

-- ----- Marksmanship / Earp (was look 0) ------------------------------------
UPDATE `item_equipment` SET `MId` =  57 WHERE `itemId` = 22159;                 -- Prime Gun (generic)
UPDATE `item_equipment` SET `MId` = 149 WHERE `itemId` IN (22160, 22161, 22162);
UPDATE `item_equipment` SET `MId` = 152 WHERE `itemId` = 22164;

-- ----- Instrument / Loughnashade (was look 0) ------------------------------
UPDATE `item_equipment` SET `MId` =  64 WHERE `itemId` = 22303;                 -- Prime Horn (generic)
UPDATE `item_equipment` SET `MId` = 150 WHERE `itemId` IN (22304, 22305, 22306);
UPDATE `item_equipment` SET `MId` = 153 WHERE `itemId` = 22307;

-- ----- Shield / Duban (was look 0; Prime Shield mesh still uncaptured) -----
UPDATE `item_equipment` SET `MId` = 675 WHERE `itemId` IN (26492, 26493, 26494);
UPDATE `item_equipment` SET `MId` = 676 WHERE `itemId` = 26495;
