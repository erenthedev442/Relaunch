-- ============================================================
-- tokko_voluspa_mods.sql
--
-- Populates item_mods for the Tokko (15 gold marks) and Voluspa
-- (12 gold marks) weapon lines sold by the gold vendor in
-- modules/custom/lua/gear_progression_catalog.lua. Upstream LSB
-- shipped these with base DMG/Delay set but empty item_mods,
-- making them dead content (players grind gold marks, get a
-- weapon with zero stat bonuses).
--
-- Strategy: per-skill stat templates calibrated below REMA III /
-- Aeonic but above the Arasy entry line. Tokko = Voluspa + small
-- additive bonus (~15-20% stat upgrade) to reflect the 25% cost
-- premium.
--
-- INSERT IGNORE: re-runnable, preserves any existing mod rows.
-- ============================================================

-- Tokko (15 marks) — H2H: tokkosho
INSERT IGNORE INTO `item_mods` VALUES (21530, 2, 65);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21530, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21530, 9, 10);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21530, 23, 27);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21530, 25, 27);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21530, 165, 3);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21530, 384, 250);   -- HASTE_GEAR

-- Tokko (15 marks) — Axe: tokko_axe
INSERT IGNORE INTO `item_mods` VALUES (21718, 2, 75);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21718, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21718, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21718, 23, 30);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21718, 25, 23);   -- ACC

-- Tokko (15 marks) — Archery: tokko_bow
INSERT IGNORE INTO `item_mods` VALUES (22108, 9, 10);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (22108, 11, 14);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (22108, 24, 27);   -- RATT
INSERT IGNORE INTO `item_mods` VALUES (22108, 26, 27);   -- RACC

-- Tokko (15 marks) — Great Axe: tokko_chopper
INSERT IGNORE INTO `item_mods` VALUES (21775, 2, 95);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21775, 8, 16);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21775, 10, 12);   -- VIT
INSERT IGNORE INTO `item_mods` VALUES (21775, 23, 35);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21775, 25, 20);   -- ACC

-- Tokko (15 marks) — Great Sword: tokko_claymore
INSERT IGNORE INTO `item_mods` VALUES (21670, 2, 85);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21670, 8, 16);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21670, 10, 10);   -- VIT
INSERT IGNORE INTO `item_mods` VALUES (21670, 23, 33);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21670, 25, 23);   -- ACC

-- Tokko (15 marks) — Katana: tokko_katana
INSERT IGNORE INTO `item_mods` VALUES (21918, 8, 8);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21918, 9, 14);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21918, 23, 25);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21918, 25, 30);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21918, 165, 4);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21918, 384, 250);   -- HASTE_GEAR

-- Tokko (15 marks) — Dagger: tokko_knife
INSERT IGNORE INTO `item_mods` VALUES (21561, 9, 14);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21561, 11, 10);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (21561, 23, 23);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21561, 25, 33);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21561, 68, 22);   -- EVA
INSERT IGNORE INTO `item_mods` VALUES (21561, 165, 4);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21561, 384, 350);   -- HASTE_GEAR

-- Tokko (15 marks) — H2H: tokko_knuckles
INSERT IGNORE INTO `item_mods` VALUES (21515, 2, 65);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21515, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21515, 9, 10);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21515, 23, 27);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21515, 25, 27);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21515, 165, 3);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21515, 384, 250);   -- HASTE_GEAR

-- Tokko (15 marks) — Polearm: tokko_lance
INSERT IGNORE INTO `item_mods` VALUES (21879, 2, 85);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21879, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21879, 9, 10);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21879, 23, 33);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21879, 25, 23);   -- ACC

-- Tokko (15 marks) — Club: tokko_rod
INSERT IGNORE INTO `item_mods` VALUES (22027, 5, 65);   -- MP
INSERT IGNORE INTO `item_mods` VALUES (22027, 12, 8);   -- INT
INSERT IGNORE INTO `item_mods` VALUES (22027, 13, 14);   -- MND
INSERT IGNORE INTO `item_mods` VALUES (22027, 28, 14);   -- MATT
INSERT IGNORE INTO `item_mods` VALUES (22027, 30, 12);   -- MACC
INSERT IGNORE INTO `item_mods` VALUES (22027, 311, 100);   -- MAGIC_DAMAGE

-- Tokko (15 marks) — Scythe: tokko_scythe
INSERT IGNORE INTO `item_mods` VALUES (21826, 2, 75);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21826, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21826, 12, 10);   -- INT
INSERT IGNORE INTO `item_mods` VALUES (21826, 13, 10);   -- MND
INSERT IGNORE INTO `item_mods` VALUES (21826, 23, 27);   -- ATT

-- Tokko (15 marks) — Staff: tokko_staff
INSERT IGNORE INTO `item_mods` VALUES (22082, 5, 85);   -- MP
INSERT IGNORE INTO `item_mods` VALUES (22082, 12, 14);   -- INT
INSERT IGNORE INTO `item_mods` VALUES (22082, 13, 12);   -- MND
INSERT IGNORE INTO `item_mods` VALUES (22082, 28, 16);   -- MATT
INSERT IGNORE INTO `item_mods` VALUES (22082, 30, 12);   -- MACC
INSERT IGNORE INTO `item_mods` VALUES (22082, 311, 120);   -- MAGIC_DAMAGE

-- Tokko (15 marks) — Sword: tokko_sword
INSERT IGNORE INTO `item_mods` VALUES (21617, 2, 65);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21617, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21617, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21617, 23, 27);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21617, 25, 27);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21617, 165, 4);   -- CRITHITRATE

-- Tokko (15 marks) — Great Katana: tokko_tachi
INSERT IGNORE INTO `item_mods` VALUES (21971, 2, 75);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21971, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21971, 9, 10);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21971, 23, 30);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21971, 25, 27);   -- ACC

-- Voluspa (12 marks) — Archery: voluspa_arrow
INSERT IGNORE INTO `item_mods` VALUES (22289, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (22289, 11, 12);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (22289, 24, 22);   -- RATT
INSERT IGNORE INTO `item_mods` VALUES (22289, 26, 22);   -- RACC

-- Voluspa (12 marks) — Axe: voluspa_axe
INSERT IGNORE INTO `item_mods` VALUES (21712, 2, 60);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21712, 8, 12);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21712, 9, 6);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21712, 23, 25);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21712, 25, 18);   -- ACC

-- Voluspa (12 marks) — Great Sword: voluspa_blade
INSERT IGNORE INTO `item_mods` VALUES (21665, 2, 70);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21665, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21665, 10, 8);   -- VIT
INSERT IGNORE INTO `item_mods` VALUES (21665, 23, 28);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21665, 25, 18);   -- ACC

-- Voluspa (12 marks) — Marksmanship: voluspa_bolt
INSERT IGNORE INTO `item_mods` VALUES (22290, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (22290, 11, 12);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (22290, 24, 22);   -- RATT
INSERT IGNORE INTO `item_mods` VALUES (22290, 26, 22);   -- RACC

-- Voluspa (12 marks) — Archery: voluspa_bow
INSERT IGNORE INTO `item_mods` VALUES (22133, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (22133, 11, 12);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (22133, 24, 22);   -- RATT
INSERT IGNORE INTO `item_mods` VALUES (22133, 26, 22);   -- RACC

-- Voluspa (12 marks) — Marksmanship: voluspa_bullet
INSERT IGNORE INTO `item_mods` VALUES (22291, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (22291, 11, 12);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (22291, 24, 22);   -- RATT
INSERT IGNORE INTO `item_mods` VALUES (22291, 26, 22);   -- RACC

-- Voluspa (12 marks) — Great Axe: voluspa_chopper
INSERT IGNORE INTO `item_mods` VALUES (21769, 2, 80);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21769, 8, 14);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21769, 10, 10);   -- VIT
INSERT IGNORE INTO `item_mods` VALUES (21769, 23, 30);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21769, 25, 15);   -- ACC

-- Voluspa (12 marks) — Marksmanship: voluspa_gun
INSERT IGNORE INTO `item_mods` VALUES (22144, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (22144, 11, 12);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (22144, 24, 22);   -- RATT
INSERT IGNORE INTO `item_mods` VALUES (22144, 26, 22);   -- RACC

-- Voluspa (12 marks) — Club: voluspa_hammer
INSERT IGNORE INTO `item_mods` VALUES (22006, 5, 50);   -- MP
INSERT IGNORE INTO `item_mods` VALUES (22006, 12, 6);   -- INT
INSERT IGNORE INTO `item_mods` VALUES (22006, 13, 12);   -- MND
INSERT IGNORE INTO `item_mods` VALUES (22006, 28, 12);   -- MATT
INSERT IGNORE INTO `item_mods` VALUES (22006, 30, 10);   -- MACC
INSERT IGNORE INTO `item_mods` VALUES (22006, 311, 80);   -- MAGIC_DAMAGE

-- Voluspa (12 marks) — Katana: voluspa_katana
INSERT IGNORE INTO `item_mods` VALUES (21912, 8, 6);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21912, 9, 12);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21912, 23, 20);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21912, 25, 25);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21912, 165, 3);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21912, 384, 200);   -- HASTE_GEAR

-- Voluspa (12 marks) — Dagger: voluspa_knife
INSERT IGNORE INTO `item_mods` VALUES (21566, 9, 12);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21566, 11, 8);   -- AGI
INSERT IGNORE INTO `item_mods` VALUES (21566, 23, 18);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21566, 25, 28);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21566, 68, 18);   -- EVA
INSERT IGNORE INTO `item_mods` VALUES (21566, 165, 3);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21566, 384, 300);   -- HASTE_GEAR

-- Voluspa (12 marks) — H2H: voluspa_knuckles
INSERT IGNORE INTO `item_mods` VALUES (21510, 2, 50);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21510, 8, 12);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21510, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21510, 23, 22);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21510, 25, 22);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21510, 165, 2);   -- CRITHITRATE
INSERT IGNORE INTO `item_mods` VALUES (21510, 384, 200);   -- HASTE_GEAR

-- Voluspa (12 marks) — Polearm: voluspa_lance
INSERT IGNORE INTO `item_mods` VALUES (21864, 2, 70);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21864, 8, 12);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21864, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21864, 23, 28);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21864, 25, 18);   -- ACC

-- Voluspa (12 marks) — Staff: voluspa_pole
INSERT IGNORE INTO `item_mods` VALUES (22088, 5, 70);   -- MP
INSERT IGNORE INTO `item_mods` VALUES (22088, 12, 12);   -- INT
INSERT IGNORE INTO `item_mods` VALUES (22088, 13, 10);   -- MND
INSERT IGNORE INTO `item_mods` VALUES (22088, 28, 14);   -- MATT
INSERT IGNORE INTO `item_mods` VALUES (22088, 30, 10);   -- MACC
INSERT IGNORE INTO `item_mods` VALUES (22088, 311, 100);   -- MAGIC_DAMAGE

-- Voluspa (12 marks) — Scythe: voluspa_scythe
INSERT IGNORE INTO `item_mods` VALUES (21822, 2, 60);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21822, 8, 12);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21822, 12, 8);   -- INT
INSERT IGNORE INTO `item_mods` VALUES (21822, 13, 8);   -- MND
INSERT IGNORE INTO `item_mods` VALUES (21822, 23, 22);   -- ATT

-- Voluspa (12 marks) — Sword: voluspa_sword
INSERT IGNORE INTO `item_mods` VALUES (21622, 2, 50);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21622, 8, 12);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21622, 9, 6);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21622, 23, 22);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21622, 25, 22);   -- ACC
INSERT IGNORE INTO `item_mods` VALUES (21622, 165, 3);   -- CRITHITRATE

-- Voluspa (12 marks) — Great Katana: voluspa_tachi
INSERT IGNORE INTO `item_mods` VALUES (21976, 2, 60);   -- HP
INSERT IGNORE INTO `item_mods` VALUES (21976, 8, 12);   -- STR
INSERT IGNORE INTO `item_mods` VALUES (21976, 9, 8);   -- DEX
INSERT IGNORE INTO `item_mods` VALUES (21976, 23, 25);   -- ATT
INSERT IGNORE INTO `item_mods` VALUES (21976, 25, 22);   -- ACC
