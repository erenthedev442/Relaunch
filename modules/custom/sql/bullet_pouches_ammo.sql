-- ============================================================================
-- bullet_pouches_ammo.sql
--
-- Makes the four "Bullet Pouch" items function as TRUE infinite ammo: a player
-- equips ONE pouch and never runs out (instead of buying stacks of consumable
-- bullets). They shipped INERT on this server -- item_basic.type = 6 (EQUIPMENT,
-- so the engine loaded them as armor with NO ranged stats) and item_equipment
-- slot = 1024 (Waist) instead of 8 (Ammo).
--
-- Fix = pure DATA (no C++):
--   1. type 6 (EQUIPMENT) -> 7 (WEAPON) so they load with ranged stats.
--   2. item_weapon: the bullet's ranged profile (skill 26 Marksmanship, dly 240).
--   3. item_equipment: AMMO slot (8), iLvl 119, RNG/COR jobs (per bullet).
--   4. item_mods: the bullet's mods + Mod::RECYCLE (305) = 100. The ranged-attack
--      code consumes ammo only when rand(100) > recycleChance, so RECYCLE >= 100
--      means it is NEVER consumed (battleentity.cpp ~3203). The pouch stays RARE
--      (stackSize 1), so one equipped pouch = permanent infinite ammo.
--
-- Pouch                          <- bullet  (dmg, jobs,   mods)
--   26350 Chrono Bullet Pouch      21296    (300, RNG+COR, RATT 20 / RACC 20)
--   26348 Living Bullet Pouch      21326    (245, COR,     MATT 35 / MACC 25)
--   26347 Eradicating Bullet Pouch 21327    (289, RNG,     RATT 30 / RACC 30)
--   26349 Devastating Bullet Pouch 21325    (277, RNG+COR, RACC 35 / MACC 35)
--
-- Apply, then restart the map (item data is cached at startup). Idempotent.
-- ============================================================================

-- ----- 1. class: EQUIPMENT (6) -> WEAPON (7) ---------------------------------
UPDATE `item_basic` SET `type` = 7 WHERE `itemid` IN (26347, 26348, 26349, 26350);

-- ----- 2. ranged weapon stats (skill 26 = Marksmanship, delay 240) ----------
DELETE FROM `item_weapon` WHERE `itemId` IN (26347, 26348, 26349, 26350);
INSERT INTO `item_weapon` VALUES
    (26350,'chrono_bullet_pouch',     26,1,0,0,0,1,1,240,300,0),
    (26348,'living_bullet_pouch',     26,1,0,0,0,1,1,240,245,0),
    (26347,'eradicating_bullet_pouch',26,1,0,0,0,1,1,240,289,0),
    (26349,'devastating_bullet_pouch',26,1,0,0,0,1,1,240,277,0);

-- ----- 3. equip in the AMMO slot (8), iLvl 119, jobs copied from each bullet -
DELETE FROM `item_equipment` WHERE `itemId` IN (26347, 26348, 26349, 26350);
INSERT INTO `item_equipment` VALUES
    (26350,'chrono_bullet_pouch',     99,119,66560,0,0,0,8,0,0,0),
    (26348,'living_bullet_pouch',     99,119,65536,0,0,0,8,0,0,0),
    (26347,'eradicating_bullet_pouch',99,119, 1024,0,0,0,8,0,0,0),
    (26349,'devastating_bullet_pouch',99,119,66560,0,0,0,8,0,0,0);

-- ----- 4. mods: each bullet's mods + RECYCLE(305)=100 (never consumed) -------
DELETE FROM `item_mods` WHERE `itemId` IN (26347, 26348, 26349, 26350);
INSERT INTO `item_mods` (`itemId`,`modId`,`value`) VALUES
    (26350,  24, 20), (26350,  26, 20), (26350, 305, 100),   -- Chrono:      RATT 20, RACC 20
    (26348,  28, 35), (26348,  30, 25), (26348, 305, 100),   -- Living:      MATT 35, MACC 25
    (26347,  24, 30), (26347,  26, 30), (26347, 305, 100),   -- Eradicating: RATT 30, RACC 30
    (26349,  26, 35), (26349,  30, 35), (26349, 305, 100);   -- Devastating: RACC 35, MACC 35
