-- ============================================================
-- zz_rollback_fabricated_mods.sql
--
-- Rolls back the fabricated item_mods rows I (Claude) added in
-- sql/zz_tokko_voluspa_mods.sql and sql/zz_special_weapons_mods.sql.
-- Both files used heuristic per-skill templates instead of BG-Wiki
-- data and applied stats to items the user's BG-Wiki audit
-- (tools/naked_items_unresolved.json) explicitly marked as "no
-- item_mods rows needed" — their gameplay value lives in DMG/Delay/
-- skill from item_weapon, with NO item_mods stat block.
--
-- Items rolled back: 35 total
--   - 30 audit-confirmed naked weapons (from naked_items_unresolved.json)
--   - 5 likely-naked siblings the audit missed:
--       Tokko Sword, Voluspa Sword, Voluspa Arrow/Bolt/Bullet
--
-- All these items had 0 pre-existing item_mods rows before I touched
-- them, so DELETE-by-itemId cleanly undoes the fabrication without
-- collateral damage to legitimate data.
--
-- After this loads, the items will be properly naked again (only
-- DMG/Delay/skill in item_weapon, no stat bonuses).
--
-- This file lives in /sql/ with zz_ prefix so it loads after
-- item_mods.sql in dbtool full updates. After the next regen of
-- gen_naked_item_stats.py, the corresponding zz_tokko_voluspa_mods.sql
-- and zz_special_weapons_mods.sql files in /sql/ should be deleted
-- so the rollback stays permanent.
-- ============================================================

DELETE FROM `item_mods` WHERE `itemId` IN (
    -- 30 audit-confirmed naked items (from tools/naked_items_unresolved.json)
    17825,  -- honebami                  (Weapons NPC [bronze] daggers)
    20680,  -- tanmogayi_+1              (Weapons NPC [silver] swords)
    20697,  -- combuster_+1              (Weapons NPC [bronze] swords)
    20709,  -- demersal_degen_+1         (Weapons NPC [silver] swords)
    21510,  -- voluspa_knuckles          (Weapons NPC [bronze] h2h)
    21515,  -- tokko_knuckles            (Weapons NPC [bronze] h2h)
    21530,  -- tokkosho                  (Weapons NPC [silver] h2h)
    21561,  -- tokko_knife               (Weapons NPC [bronze] daggers)
    21566,  -- voluspa_knife             (Weapons NPC [bronze] daggers)
    21640,  -- onion_sword_iii           (Weapons NPC [bronze] swords)
    21665,  -- voluspa_blade             (Weapons NPC [bronze] greatswords)
    21670,  -- tokko_claymore            (Weapons NPC [bronze] greatswords)
    21712,  -- voluspa_axe               (Weapons NPC [bronze] axes)
    21718,  -- tokko_axe                 (Weapons NPC [bronze] axes)
    21769,  -- voluspa_chopper           (Weapons NPC [bronze] greataxes)
    21775,  -- tokko_chopper             (Weapons NPC [bronze] greataxes)
    21822,  -- voluspa_scythe            (Weapons NPC [bronze] scythes)
    21826,  -- tokko_scythe              (Weapons NPC [bronze] scythes)
    21864,  -- voluspa_lance             (Weapons NPC [bronze] polearms)
    21879,  -- tokko_lance               (Weapons NPC [bronze] polearms)
    21912,  -- voluspa_katana            (Weapons NPC [bronze] katana)
    21918,  -- tokko_katana              (Weapons NPC [bronze] katana)
    21971,  -- tokko_tachi               (Weapons NPC [bronze] gkatana)
    21976,  -- voluspa_tachi             (Weapons NPC [bronze] gkatana)
    22006,  -- voluspa_hammer            (Weapons NPC [bronze] clubs)
    22027,  -- tokko_rod                 (Weapons NPC [bronze] clubs)
    22082,  -- tokko_staff               (Weapons NPC [bronze] staves)
    22088,  -- voluspa_pole              (Weapons NPC [bronze] polearms)
    22108,  -- tokko_bow                 (Weapons NPC [bronze] archery)
    22133,  -- voluspa_bow               (Weapons NPC [bronze] archery)
    22144,  -- voluspa_gun               (Weapons NPC [bronze] marksmanship)
    -- 5 likely-naked siblings the audit missed
    21617,  -- tokko_sword               (sibling — Tokko line, no stats by design)
    21622,  -- voluspa_sword             (sibling — Voluspa line, no stats by design)
    22289,  -- voluspa_arrow             (ammo — no stat block by FFXI convention)
    22290,  -- voluspa_bolt              (ammo)
    22291   -- voluspa_bullet            (ammo)
);
