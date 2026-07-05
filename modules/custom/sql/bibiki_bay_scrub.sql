-- ============================================================
-- bibiki_bay_scrub.sql
-- Wipes the native mob population of Bibiki Bay (zone 4) so
-- the Capacity Farm can own the zone.
--
-- The Capacity Farm (CapacityFarm.lua) spawns 200 Capacity
-- Phantoms dynamically via insertDynamicEntity using GM_Home
-- templates (groupZoneId=210). The vanilla zone population
-- (357 spawn_points across 50 mob_groups — Alraune, Opo-opo,
-- Uragnite, Jagil, Hobgoblins, Locus mobs, etc.) would compete
-- for AI ticks and clutter the CP grind experience.
--
-- What gets deleted:
--   1. mob_spawn_points rows in zone 4's mobid range
--      (16793600 .. 16797695), EXCEPT 6 SCRIPTED mobs that are
--      either referenced by GetFirstID() in IDs.lua or have
--      elaborate NM scripts with pet-offset dependencies:
--        15 = Serra      (IDs.lua SERRA)
--        18 = Peerifool  (IDs.lua PEERIFOOL)
--        24 = Intulo     (IDs.lua INTULO)
--        37 = Splacknuck (IDs.lua SPLACKNUCK)
--        48 = Shen       (Shen.lua uses GetMobByID offset +1/+2)
--        49 = Shens_Filtrate (Shen's pet mobs at offset +1/+2)
--   2. mob_groups rows with zoneid = 4, same exclusion list.
--
-- WHY the exclusion: GetFirstID() for the 4 IDs.lua mobs would
-- log "[error] GetFirstID(Intulo) in zone Bibiki_Bay: Returning nil"
-- on every zone-init otherwise. Shen/Filtrate are spared because
-- Shen.lua references GetMobByID(mobId+1) and GetMobByID(mobId+2)
-- for its pet mobs — deleting groupid 49 breaks that offset math.
--
-- Consequences:
--   * All regular zone pop (Alraune, Opo-opo, Jagil, Hobgoblins,
--     Locus mobs, NMs without scripts like Bismarck, Dalham, etc.)
--     will not appear in Bibiki Bay. The zone will feel empty
--     except for the 200 Capacity Phantoms.
--   * Fishing-spawned mobs (Ghost_Crab_fished, Kraken_fished etc.)
--     are removed — fishing spots may yield no catch in that zone.
--   * Serra/Peerifool/Intulo/Splacknuck and Shen remain spawnable
--     but won't be encountered casually (spawntype=128 + NM rules).
--
-- Reversibility:
--   * Re-run the vanilla sql/mob_spawn_points.sql and
--     sql/mob_groups.sql to restore the native population.
--   * This file is idempotent — running it twice is safe.
--
-- Needs a xi_map restart to take effect (mob tables cached at boot).
-- ============================================================

-- Wipe native population. The 6 scripted groupids are spared so
-- GetFirstID() / Shen offset lookups keep working silently.
DELETE FROM `mob_spawn_points`
 WHERE `mobid`   BETWEEN 16793600 AND 16797695
   AND `groupid` NOT IN (15, 18, 24, 37, 48, 49);

DELETE FROM `mob_groups`
 WHERE `zoneid`  = 4
   AND `groupid` NOT IN (15, 18, 24, 37, 48, 49);
