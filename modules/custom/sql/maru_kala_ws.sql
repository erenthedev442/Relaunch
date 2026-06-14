-- ============================================================================
-- maru_kala_ws.sql
--
-- Makes Maru Kala (weapon skill ID 231) a usable PLAYER weapon skill.
--
-- Maru Kala is the Prime weapon skill for Varga Purnikawa (Hand-to-Hand,
-- items 21534 / 21535). Stock LSB ships it ONLY as a mob skill and leaves the
-- player weapon_skills row commented out (sql/weapon_skills.sql:264), so the
-- Varga Purnikawa's ADDS_WEAPONSKILL mod (item_mods 21534/21535 -> ws231)
-- pointed at a weapon skill that did not exist for players.
--
-- This file defines the player-side row. The behaviour lives in
--   scripts/actions/weaponskills/maru_kala.lua
-- The engine loads weapon_skills ONCE at startup (battleutils.cpp
-- LoadWeaponSkillsList), so apply this and then restart the map server.
--
-- How the unlock works (no quest / no jobs mask needed):
--   charutils::BuildingCharWeaponSkills() iterates the Hand-to-Hand WS list
--   and adds any WS where `CanUseWeaponskill() || PSkill->getID() == main_ws`,
--   where main_ws = the equipped weapon's ADDS_WEAPONSKILL value (231). The
--   `== main_ws` clause grants it directly from the weapon, bypassing the
--   jobs-bitmask check -- the same way Final Heaven (all-zero jobs) works.
--
-- Column reference:
--   weaponskillid, name, jobs(binary22), type, skilllevel, element,
--   animation, animationTime, range, aoe, radius,
--   primary_sc, secondary_sc, tertiary_sc, main_only, unlock_id
--
-- Values (faithful to retail per BG Wiki - https://www.bg-wiki.com/ffxi/Maru_Kala):
--   type       = 1   Hand-to-Hand. MUST match so the WS lands in the H2H list
--                    that GetWeaponSkills(SKILL_HAND_TO_HAND) returns.
--   skilllevel = 0   not skill-gated -- granted by the weapon.
--   jobs       = all-zero (see unlock note above).
--   element    = 0   none.
--   animation  = 30  PLACEHOLDER. LSB never captured this Prime WS's client
--                    animation index. 30 is a valid H2H WS animation, so it
--                    renders cleanly; the WS id (231) still tags it "Maru Kala"
--                    for damage / skillchain / chat log. If the visual looks
--                    wrong, this single value is the only thing to change.
--   range      = 3   H2H melee (every H2H WS uses 3).
--   aoe/radius = 0   single target.
--   primary/secondary/tertiary_sc = 6 / 2 / 10
--                    Detonation / Compression / Distortion.
--   main_only  = 1   H2H WS -- main hand only.
--   unlock_id  = 0   no separate unlock; the weapon grants it.
--
-- Idempotent: DELETE then INSERT, safe to re-apply.
-- ============================================================================

DELETE FROM `weapon_skills` WHERE `weaponskillid` = 231;

INSERT INTO `weapon_skills`
    (`weaponskillid`, `name`, `jobs`, `type`, `skilllevel`, `element`,
     `animation`, `animationTime`, `range`, `aoe`, `radius`,
     `primary_sc`, `secondary_sc`, `tertiary_sc`, `main_only`, `unlock_id`)
VALUES
    (231, 'maru_kala', 0x00000000000000000000000000000000000000000000, 1, 0, 0,
     30, 2000, 3, 0, 0,
     6, 2, 10, 1, 0);
