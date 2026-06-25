-- ============================================================
-- hunters_guild_hunt_respawns.sql
--
-- Camp-viability override for the 20 vanilla HNMs that the
-- Hunter's Guild v2 design uses as rep sources.
--
-- The vanilla LSB defaults for HNMs are punishing on a low-pop
-- private server:
--   * Most are SCRIPTED (spawntype=128) with respawntime=0,
--     meaning they never naturally appear — they need a BCNM
--     trigger or a quest event. Useless for a "hunt around
--     Vana'diel" grind.
--   * A few are NORMAL but with 21h-168h respawn windows
--     (Cerberus at 172800s = 48 hours is the worst offender).
--     Even with maximum patience that's one kill per day per
--     player at most.
--
-- This file flips them ALL to NORMAL respawn (spawntype=0) on a flat
-- 30-minute (1800s) timer.
--
-- Owner policy (2026-06-25): every custom-content NM you must kill to
-- unlock things, and that isn't force-spawned, gets a uniform 30-min
-- respawn (supersedes the earlier tier-based 20/25/30/40/60-min curve;
-- the same flat rule is applied to the Spell & Skill Mastery rotation
-- NMs in mastery_rotation_respawns.sql).
--
-- The two former LOTTERY NMs (Lord of Onzozo, Despot — spawntype=32)
-- are now flipped to NORMAL too, so they reliably reappear every 30 min
-- like the rest rather than rolling a placeholder.
--
-- Side effects to acknowledge:
--   * Vanilla CoP / Zilart BCNMs that gate off these HNM mob_groups
--     will see a respawning NM in the open zone instead of (or in
--     addition to) the BCNM version. On Legendary this is fine —
--     vanilla mission progression isn't the gameplay here.
--   * The alternate-zone spawn rows (Walk of Echoes / Nyzul Isle /
--     Bhaflau Remnants copies) are left alone; we only touch the
--     open-world copy each NM uses.
--
-- Reversibility:
--   * Re-run the vanilla sql/mob_groups.sql to restore originals.
--   * This file is idempotent — running it twice produces the
--     same result.
--
-- To apply:
--   mysql -u root -p your_db_name < modules/custom/sql/hunters_guild_hunt_respawns.sql
--
-- Pattern lifted from modules/custom/sql/hunting_league_gm_home_mobs.sql.
-- ============================================================

-- All 20 → flat 30-minute (1800s) NORMAL respawn (owner policy 2026-06-25).
-- ------------------------------------------------------------
-- AF Hunters' Guild — Wyrm Circuit
-- ------------------------------------------------------------
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 205 AND `groupid` = 29;   -- Tarasque       (Ifrits Cauldron)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 104 AND `groupid` = 76;   -- Capricornus    (Jugner Forest)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 176 AND `groupid` = 51;   -- Charybdis      (Sea Serpent Grotto)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` =   7 AND `groupid` = 46;   -- Tiamat         (Attohwa Chasm)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 154 AND `groupid` =  5;   -- Fafnir         (Dragon's Aery)

-- ------------------------------------------------------------
-- Relic Hunters' Guild — TOAU / Desert Beasts
-- ------------------------------------------------------------
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 114 AND `groupid` = 52;   -- Cactrot Rapido (Eastern Altepa Desert)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 213 AND `groupid` = 16;   -- Lord of Onzozo (Labyrinth of Onzozo) [was lottery]
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 125 AND `groupid` = 26;   -- King Vinegarroon (Western Altepa Desert)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` =  79 AND `groupid` = 59;   -- Khimaira       (Caedarva Mire)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` =  61 AND `groupid` = 37;   -- Cerberus       (Mount Zhayolm)

-- ------------------------------------------------------------
-- Empy Hunters' Guild — Sky Court
-- ------------------------------------------------------------
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 178 AND `groupid` =  6;   -- Faust          (Shrine of Ru'Avitau)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 130 AND `groupid` = 13;   -- Despot         (Ru'Aun Gardens) [was lottery]
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 177 AND `groupid` = 15;   -- Steam Cleaner  (VeLugannon Palace)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 177 AND `groupid` = 14;   -- Brigandish Blade (VeLugannon Palace)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` =  29 AND `groupid` = 17;   -- Bahamut        (Riverne Site B01)

-- ------------------------------------------------------------
-- League Hunters' Guild — Apex World Bosses
-- ------------------------------------------------------------
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 212 AND `groupid` =  6;   -- Bune           (Gustav Tunnel)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` =  30 AND `groupid` = 12;   -- Carmine Dobsonfly (Riverne Site A01)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 128 AND `groupid` =  7;   -- Aspidochelone  (Valley of Sorrows)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 127 AND `groupid` =  9;   -- Behemoth       (Behemoth's Dominion)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` =   5 AND `groupid` = 40;   -- Jormungand     (Uleguerand Range)
