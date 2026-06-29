-- zz_augment_catalyst_drops.sql
-- Kill-drop (dropType=0) entries for augment catalysts that previously had only
-- Despoil/Steal entries or no entries at all.
--
-- Applied unconditionally on every deploy (zz_ convention).
-- Idempotent: DELETE matching row then INSERT, so re-runs don't duplicate.
--
-- Rate scale (itemRate out of 1000):
--   Tier 0 = 500 (50%)   Tier 1 = 300 (30%)
--   Tier 2 = 200 (20%)   Tier 4 = 100 (10%)
--
-- dropId chosen = mob family that made thematic sense at tier difficulty.
-- mob_groups already maps these dropIds to the listed mob/zone.

-- -----------------------------------------------------------------------
-- 820  Haste (Tier 1) → Gigas family, Lufaise Meadows (dropId 981)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=981 AND droptype=0 AND itemid=820;
INSERT INTO mob_droplist VALUES (981, 0, 0, 1000, 820, 300);

-- -----------------------------------------------------------------------
-- 821  Slow (Tier 4) → Shore Spider, Abyssea-Misareaux (dropId 2242)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=2242 AND droptype=0 AND itemid=821;
INSERT INTO mob_droplist VALUES (2242, 0, 0, 1000, 821, 100);

-- -----------------------------------------------------------------------
-- 832  Phantom Roll ability delay (Tier 4) → Mosshorn, Caedarva Mire (dropId 1741)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1741 AND droptype=0 AND itemid=832;
INSERT INTO mob_droplist VALUES (1741, 0, 0, 1000, 832, 100);

-- -----------------------------------------------------------------------
-- 864  Dagger skill (Tier 1) → Beach Pugil / Greater Pugil, Valkurm/Qufim (dropId 248)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=248 AND droptype=0 AND itemid=864;
INSERT INTO mob_droplist VALUES (248, 0, 0, 1000, 864, 300);

-- -----------------------------------------------------------------------
-- 944  Polearm skill (Tier 1) → Tonberry Creeper, Yhoator Jungle (dropId 2431)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=2431 AND droptype=0 AND itemid=944;
INSERT INTO mob_droplist VALUES (2431, 0, 0, 1000, 944, 300);

-- -----------------------------------------------------------------------
-- 1201 Lightning Affinity (Tier 4) → Maritime Peiste, Abyssea-Misareaux (dropId 1621)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1621 AND droptype=0 AND itemid=1201;
INSERT INTO mob_droplist VALUES (1621, 0, 0, 1000, 1201, 100);

-- -----------------------------------------------------------------------
-- 1268 Fire Affinity / Avatar perp. cost (Tier 4) → Manipulator, Temple of Uggalepih (dropId 1614)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1614 AND droptype=0 AND itemid=1268;
INSERT INTO mob_droplist VALUES (1614, 0, 0, 1000, 1268, 100);

-- -----------------------------------------------------------------------
-- 1269 Ninja tool expertise (Tier 0) → Goblin Leecher, Valkurm Dunes (dropId 1098)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1098 AND droptype=0 AND itemid=1269;
INSERT INTO mob_droplist VALUES (1098, 0, 0, 1000, 1269, 500);

-- -----------------------------------------------------------------------
-- 2147 Counter (Tier 2) → Marid / Grand Marid, Wajaom Woodlands (dropId 1617)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1617 AND droptype=0 AND itemid=2147;
INSERT INTO mob_droplist VALUES (1617, 0, 0, 1000, 2147, 200);

-- -----------------------------------------------------------------------
-- 2154 Ninjutsu skill (Tier 1) → Gugru Orobon, Open Sea to Al Zahbi (dropId 969)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=969 AND droptype=0 AND itemid=2154;
INSERT INTO mob_droplist VALUES (969, 0, 0, 1000, 2154, 300);

-- -----------------------------------------------------------------------
-- 2155 Singing skill (Tier 1) → Marid, Wajaom Woodlands (dropId 1617)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1617 AND droptype=0 AND itemid=2155;
INSERT INTO mob_droplist VALUES (1617, 0, 0, 1000, 2155, 300);

-- -----------------------------------------------------------------------
-- 2831 Occ. resist to stat ailments (Tier 2) → Hecteyes, Attohwa Chasm (dropId 1287)
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=1287 AND droptype=0 AND itemid=2831;
INSERT INTO mob_droplist VALUES (1287, 0, 0, 1000, 2831, 200);

-- -----------------------------------------------------------------------
-- 1011 King of Coins Card — removed as TH catalyst; clean up Haty drop
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=253 AND droptype=0 AND itemid=1011;

-- -----------------------------------------------------------------------
-- 1525 Treasure Hunter (Tier 0) → Adamantoise (NM), Valley of Sorrows (dropId 21)
--      augId 147 / xi.mod.TREASURE_HUNTER — always flat TH+1 (multiplier=0 in augments.sql)
--      Aspidochelone (HNM) also drops 1525 at 24%; regular Adamantoise at 30%.
-- -----------------------------------------------------------------------
DELETE FROM mob_droplist WHERE dropid=21 AND droptype=0 AND itemid=1525;
INSERT INTO mob_droplist VALUES (21, 0, 0, 1000, 1525, 300);
