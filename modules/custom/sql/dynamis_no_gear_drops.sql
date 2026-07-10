-- =====================================================================
-- dynamis_no_gear_drops.sql
-- NOTE: lives in modules/custom/sql/ (NOT sql/zz_) -- the relaunch OVH deploy
-- (vps-rebuild.ps1) only applies modules/custom/sql/*.sql, so a sql/zz_ file
-- would never run on deploy. A normal deploy does not reimport sql/mob_droplist,
-- so this DELETE runs against the live table and sticks; a FULL dbtool reimport
-- re-adds the stock rows AFTER modules/custom/sql -> re-run this after one.
-- Droplists are boot-cached, so a live apply needs an xi_map restart.
--
-- Dynamis mobs on Relaunch should drop CURRENCY + reforge MATERIALS only --
-- the custom reforge path (medals -> AF/Relic +1..+3) is the gear source, so the
-- retail armor drops are unwanted clutter.
--
-- An earlier GM scrub keyed off the item_equipment table, which MISSED:
--   * AF-1 / Relic-1 pieces  (item_basic.name '%-1') -- these are NOT in
--     item_equipment on this DB, so an equipment-based filter never matched them
--     (this is why "they didn't qualify as gear").
--   * JSE belts (waist) and capes (back) -- slots the GM's filter skipped.
--
-- This removes EVERY equippable item + EVERY '-1' item from every Dynamis-zone
-- mob droplist. Verified survivors = pure currency/materials (byne bills,
-- shells, medals, fragments/goads, Rusted/Blackened ID cards, attestations,
-- tome chapters, forgotten_*, odious_*, nightmare_*). Zones:
--   39-42 Valkurm/Buburimu/Qufim/Tavnazia, 134/135 Beaucedine/Xarcabard,
--   185-188 nation Dynamis, 294-297 Divergence [D] (custom droplists unaffected).
--
-- Idempotent: DELETE only, safe to re-run. Lives in sql/zz_*.sql so it re-applies
-- UNCONDITIONALLY every deploy -- keeps gear out even after a mob_droplist reimport.
-- Droplists are cached at map boot, so a live apply needs an xi_map restart.
--
-- To KEEP a specific piece (e.g. an Abyss cape), add:  AND dl.itemId <> <id>
-- =====================================================================
DELETE dl
FROM `mob_droplist` dl
JOIN `mob_groups` g ON g.`dropid` = dl.`dropId`
JOIN `item_basic`  i ON i.`itemid` = dl.`itemId`
WHERE g.`zoneid` IN (39,40,41,42,134,135,185,186,187,188,294,295,296,297)
  AND ( dl.`itemId` IN (SELECT `itemId` FROM `item_equipment`)
        OR i.`name` LIKE '%-1' );
