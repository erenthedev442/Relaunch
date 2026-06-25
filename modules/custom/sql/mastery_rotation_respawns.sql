-- ============================================================
-- mastery_rotation_respawns.sql
--
-- Camp-viability override for the 20 overworld NMs used by the
-- Spell & Skill Mastery rotation (spell_skill_mastery_catalog.lua).
--
-- Owner policy (2026-06-25): any custom-content NM you must kill to
-- unlock things, and that ISN'T force-spawned, gets a flat 30-minute
-- respawn. These 20 are real, naturally-spawning overworld NMs (NOT
-- dynamic-entity / command pops like Hunting League, Reforge, Apex,
-- Gauntlet, World Boss, Invasion, Abyssea-??? — those are excluded).
--
-- Vanilla defaults make them unusable for a daily rotation: most are
-- SCRIPTED (spawntype=128, respawntime=0 — never naturally appear) or
-- LOTTERY (spawntype=32), and the few NORMAL ones sit on multi-hour
-- windows. This flips the open-world copy of each to NORMAL respawn
-- (spawntype=0) on a 30-min (1800s) timer so the rotation target is
-- reliably farmable.
--
-- Scoped to the specific (zoneid, groupid) of each NM's OPEN-WORLD
-- spawn (resolved from the live xi_relaunch DB); template copies in the
-- holding zone (210/77) and alternate instanced copies are left alone.
--
-- Idempotent + reversible (re-run sql/mob_groups.sql to restore stock).
-- Pattern mirrors modules/custom/sql/hunters_guild_hunt_respawns.sql.
-- ============================================================

UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 100 AND `groupid` =  25; -- Jaggedy-Eared Jack (West Ronfaure)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 101 AND `groupid` =  26; -- Bigmouth Billy     (East Ronfaure)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 104 AND `groupid` =   7; -- King Arthro        (Jugner Forest)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 105 AND `groupid` =   8; -- Lumber Jack        (Batallia Downs)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 107 AND `groupid` =  17; -- Carnero            (South Gustaberg)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 108 AND `groupid` =  27; -- Stray Mary         (Konschtat Highlands)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 111 AND `groupid` =  24; -- Nue                (Beaucedine Glacier)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 111 AND `groupid` =  31; -- Gargantua          (Beaucedine Glacier)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 112 AND `groupid` =  29; -- Koenigstiger       (Xarcabard)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 113 AND `groupid` =  38; -- Stolas             (Cape Teriggan)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 113 AND `groupid` =  27; -- Kreutzet           (Cape Teriggan)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 117 AND `groupid` =  19; -- Serpopard Ishtar   (Tahrongi Canyon)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 118 AND `groupid` =  53; -- Botulus Rex        (Buburimu Peninsula)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 119 AND `groupid` =  65; -- Orcus              (Meriphataud Mountains)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 120 AND `groupid` =  31; -- Old Sabertooth     (Sauromugue Champaign)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 121 AND `groupid` =  34; -- Bastet             (Sanctuary of Zi'Tah)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 123 AND `groupid` =  28; -- Voluptuous Vilma   (Yuhtunga Jungle)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 124 AND `groupid` =  25; -- Powderer Penny     (Yhoator Jungle)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 126 AND `groupid` =   5; -- Kraken             (Qufim Island)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 174 AND `groupid` =  38; -- Guivre             (Kuftal Tunnel)
