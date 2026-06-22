-- ============================================================================
-- tachi_mumei_ws.sql
--
-- Makes Tachi: Mumei (weapon skill ID 159) a usable PLAYER weapon skill.
--
-- Tachi: Mumei is the Prime weapon skill for the Kusanagi-no-Tsurugi (GK,
-- item 21986). Stock LSB ships it only as a mob skill and leaves the player
-- weapon_skills row commented out (sql/weapon_skills.sql near ID 159), so
-- the Kusanagi's ADDS_WEAPONSKILL mod (item_mods 21986 -> ws 159) had nothing
-- to unlock. This file defines the player-side row.
--
-- The behaviour lives in:
--   scripts/actions/weaponskills/tachi_mumei.lua
-- The engine loads weapon_skills once at startup (battleutils.cpp
-- LoadWeaponSkillsList), so apply this then restart the map server.
--
-- How the unlock works (same as Maru Kala / maru_kala_ws.sql):
--   charutils::BuildingCharWeaponSkills() iterates the Great-Katana WS list
--   and grants any WS where `CanUseWeaponskill() || PSkill->getID() == main_ws`
--   where main_ws = equipped weapon's ADDS_WEAPONSKILL (355) value (159).
--   The `== main_ws` clause bypasses the jobs-bitmask check so any job that
--   can equip the Kusanagi gets Mumei automatically.
--
-- Column reference (see sql/weapon_skills.sql CREATE TABLE):
--   weaponskillid, name, jobs(binary22), type, skilllevel, element,
--   animation, animationTime, range, aoe, radius,
--   primary_sc, secondary_sc, tertiary_sc, main_only, unlock_id
--
-- Values:
--   type        = 10  Great Katana (matches all other Tachi: entries).
--   skilllevel  = 0   Not skill-gated; granted by equipping the Kusanagi.
--   jobs        = all-zero (== main_ws bypass, same pattern as Maru Kala).
--   element     = 0   None.
--   animation   = 179 PLACEHOLDER -- same as Tachi: Shoha (highest-tier GK
--                     WS that has a defined retail animation). Update if the
--                     correct retail anim ID is ever found.
--   animationTime = 2000
--   range       = 3   GK melee (matches every other Tachi: WS).
--   aoe=1, radius=0   Single target.
--   primary/secondary/tertiary_sc = 6 / 2 / 10
--                     Detonation / Compression / Distortion.
--                     (6=Detonation confirmed from tachi_jinpu; 2/10 match
--                     the working maru_kala_ws.sql values for same SC attrs.)
--   main_only   = 1   GK WS.
--   unlock_id   = 0   No separate unlock; weapon grants it.
--
-- Idempotent: DELETE then INSERT, safe to re-apply.
-- ============================================================================

DELETE FROM `weapon_skills` WHERE `weaponskillid` = 159;

INSERT INTO `weapon_skills`
    (`weaponskillid`, `name`, `jobs`, `type`, `skilllevel`, `element`,
     `animation`, `animationTime`, `range`, `aoe`, `radius`,
     `primary_sc`, `secondary_sc`, `tertiary_sc`, `main_only`, `unlock_id`)
VALUES
    (159, 'tachi_mumei', 0x00000000000000000000000000000000000000000000, 10, 0, 0,
     179, 2000, 3, 1, 0,
     6, 2, 10, 1, 0);
