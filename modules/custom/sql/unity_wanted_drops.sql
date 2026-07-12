-- unity_wanted_drops.sql
-- Retail-accurate item drops for Unity Wanted NMs in zone 288 (Escha-Zi'tah).
-- Source: bg-wiki.com/ffxi/Category:Unity_Rewards
-- 50 of 56 NMs have identified retail drops; 6 T1 NMs drop accolades only.
--
-- mob_droplist schema: (dropId, dropType, groupId, groupRate, itemId, itemRate)
--   dropId    = matches mob_groups.dropid
--   dropType  = 0 (normal drop)
--   groupId   = 0 (single group; all items roll independently)
--   groupRate = 1000 (group always fires)
--   itemId    = item_basic.itemid
--   itemRate  = 500 (50% per item — all tiers)
--
-- Idempotent: DELETE clears our range before re-inserting.
-- Run after unity_wanted_mobs.sql (which creates the mob_groups rows).

DELETE FROM mob_droplist WHERE dropId BETWEEN 50001 AND 50050;

-- =============================================================================
-- TIER 1  (lv 75-80)  — 50% per item
-- NMs 1-3, 9, 10, 12 (Hugemaw Harold / Prickly Pitriv / Serpopard Ninlil /
-- Ironhorn Baldurno / Sleepy Mabel / Bounding Belinda) have no retail drop.
-- =============================================================================

-- 50001  Abyssdiver (groupId=27)
INSERT INTO mob_droplist VALUES (50001, 0, 0, 1000, 21349, 500); -- Wingcutter
INSERT INTO mob_droplist VALUES (50001, 0, 0, 1000, 27993, 500); -- Macabre Gaunt.

-- 50002  Keeper of Heiligtum (groupId=28)
INSERT INTO mob_droplist VALUES (50002, 0, 0, 1000, 21034, 500); -- Kunimune
INSERT INTO mob_droplist VALUES (50002, 0, 0, 1000, 27230, 500); -- Zoar Subligar

-- 50003  Jester Malatrix (groupId=33)
INSERT INTO mob_droplist VALUES (50003, 0, 0, 1000, 20806, 500); -- Buramgh
INSERT INTO mob_droplist VALUES (50003, 0, 0, 1000, 27636, 500); -- Evalach

-- 50004  Immanibugard (groupId=34)
INSERT INTO mob_droplist VALUES (50004, 0, 0, 1000, 27409, 500); -- Hippo. Socks
INSERT INTO mob_droplist VALUES (50004, 0, 0, 1000, 27560, 500); -- Apeile Ring

-- 50005  Orcfeltrap (groupId=70)
INSERT INTO mob_droplist VALUES (50005, 0, 0, 1000, 20987, 500); -- Tancho
INSERT INTO mob_droplist VALUES (50005, 0, 0, 1000, 28423, 500); -- Shinjutsu-no-Obi

-- 50006  Sybaritic Samantha (groupId=73)
INSERT INTO mob_droplist VALUES (50006, 0, 0, 1000, 27562, 500); -- Metamor. Ring
INSERT INTO mob_droplist VALUES (50006, 0, 0, 1000, 27508, 500); -- Unmoving Collar

-- 50007  Valkurm Imperator (groupId=75)
INSERT INTO mob_droplist VALUES (50007, 0, 0, 1000, 26709, 500); -- Imp. Wing Hair.
INSERT INTO mob_droplist VALUES (50007, 0, 0, 1000, 28273, 500); -- Regal Pumps

-- 50008  Joyous Green (groupId=76)
INSERT INTO mob_droplist VALUES (50008, 0, 0, 1000, 28429, 500); -- Acuity Belt
INSERT INTO mob_droplist VALUES (50008, 0, 0, 1000, 28352, 500); -- Canto Necklace

-- 50009  Warblade Beak (groupId=77)
INSERT INTO mob_droplist VALUES (50009, 0, 0, 1000, 27995, 500); -- Shigure Tekko
INSERT INTO mob_droplist VALUES (50009, 0, 0, 1000, 28490, 500); -- Handler's Earring

-- 50010  Cactrot Veloz (groupId=78)
INSERT INTO mob_droplist VALUES (50010, 0, 0, 1000, 21222, 500); -- Mengado
INSERT INTO mob_droplist VALUES (50010, 0, 0, 1000, 28486, 500); -- Arete del Luna

-- 50011  Woodland Mender (groupId=79)
INSERT INTO mob_droplist VALUES (50011, 0, 0, 1000, 21162, 500); -- Pouwhenua
INSERT INTO mob_droplist VALUES (50011, 0, 0, 1000, 26868, 500); -- Ros. Jaseran

-- 50012  Emperor Arthro (groupId=80)
INSERT INTO mob_droplist VALUES (50012, 0, 0, 1000, 28136, 500); -- Augury Cuisses
INSERT INTO mob_droplist VALUES (50012, 0, 0, 1000, 28427, 500); -- Sailfi Belt

-- 50013  Tiyanak (groupId=81)
INSERT INTO mob_droplist VALUES (50013, 0, 0, 1000, 26896, 500); -- Lugra Cloak
INSERT INTO mob_droplist VALUES (50013, 0, 0, 1000, 28481, 500); -- Lugra Earring

-- 50014  Vermillion Fishfly (groupId=82)
INSERT INTO mob_droplist VALUES (50014, 0, 0, 1000, 25601, 500); -- Blistering Sallet
INSERT INTO mob_droplist VALUES (50014, 0, 0, 1000, 10770, 500); -- Cacoethic Ring

-- 50015  Intuila (groupId=83)
INSERT INTO mob_droplist VALUES (50015, 0, 0, 1000, 28134, 500); -- Assid. Pants

-- =============================================================================
-- TIER 2  (lv 99-119)  — 50% per item
-- =============================================================================

-- 50016  Muut (groupId=29)
INSERT INTO mob_droplist VALUES (50016, 0, 0, 1000, 20606, 500); -- Anathema Harpe

-- 50017  Voso (groupId=32)
INSERT INTO mob_droplist VALUES (50017, 0, 0, 1000, 26942, 500); -- Agony Jerkin

-- 50018  Beist (groupId=35)
INSERT INTO mob_droplist VALUES (50018, 0, 0, 1000, 26714, 500); -- Adorned Helm
INSERT INTO mob_droplist VALUES (50018, 0, 0, 1000, 26872, 500); -- Hime Domaru

-- 50019  Lumber Jill (groupId=84)
INSERT INTO mob_droplist VALUES (50019, 0, 0, 1000, 20611, 500); -- Sangarius
INSERT INTO mob_droplist VALUES (50019, 0, 0, 1000, 27601, 500); -- Ground. Mantle

-- 50020  Largantua (groupId=85)
INSERT INTO mob_droplist VALUES (50020, 0, 0, 1000, 26870, 500); -- Emet Harness
INSERT INTO mob_droplist VALUES (50020, 0, 0, 1000, 27504, 500); -- Warder's Charm

-- 50021  Garbage Gel (groupId=86)
INSERT INTO mob_droplist VALUES (50021, 0, 0, 1000, 20521, 500); -- Emeici
INSERT INTO mob_droplist VALUES (50021, 0, 0, 1000, 10768, 500); -- Gelatinous Ring

-- 50022  King Uropygid (groupId=87)
INSERT INTO mob_droplist VALUES (50022, 0, 0, 1000, 26731, 500); -- Stinger Helm

-- 50023  Vedrfolnir (groupId=88)
INSERT INTO mob_droplist VALUES (50023, 0, 0, 1000, 20527, 500); -- Fists of Fury
INSERT INTO mob_droplist VALUES (50023, 0, 0, 1000, 21159, 500); -- Marin Staff

-- 50024  Glazemane (groupId=89)
INSERT INTO mob_droplist VALUES (50024, 0, 0, 1000, 20580, 500); -- Kustawi
INSERT INTO mob_droplist VALUES (50024, 0, 0, 1000, 21690, 500); -- Ushenzi

-- 50025  Volatile Cluster (groupId=90)
INSERT INTO mob_droplist VALUES (50025, 0, 0, 1000, 21029, 500); -- Norifusa
INSERT INTO mob_droplist VALUES (50025, 0, 0, 1000, 27619, 500); -- Aurist's Cape

-- 50026  Strix (groupId=91)
INSERT INTO mob_droplist VALUES (50026, 0, 0, 1000, 21099, 500); -- Magesmasher
INSERT INTO mob_droplist VALUES (50026, 0, 0, 1000, 28275, 500); -- Jute Boots

-- 50027  Sovereign Behemoth (groupId=92)
INSERT INTO mob_droplist VALUES (50027, 0, 0, 1000, 22266, 500); -- Antitail
INSERT INTO mob_droplist VALUES (50027, 0, 0, 1000, 27542, 500); -- Domin. Earring
INSERT INTO mob_droplist VALUES (50027, 0, 0, 1000, 26001, 500); -- Loricate Torque

-- 50028  Arke (groupId=93)
INSERT INTO mob_droplist VALUES (50028, 0, 0, 1000, 20613, 500); -- Pukulatmuj
INSERT INTO mob_droplist VALUES (50028, 0, 0, 1000, 21164, 500); -- Ababinili

-- 50029  Douma Weapon (groupId=94)
INSERT INTO mob_droplist VALUES (50029, 0, 0, 1000, 26887, 500); -- Shomonjijoe
INSERT INTO mob_droplist VALUES (50029, 0, 0, 1000, 21418, 500); -- Rigorous Grip

-- 50030  Kubool Jas Mhuufya (groupId=95)
INSERT INTO mob_droplist VALUES (50030, 0, 0, 1000, 20799, 500); -- Mdomo Axe
INSERT INTO mob_droplist VALUES (50030, 0, 0, 1000, 27532, 500); -- Zwazo Earring

-- 50031  Thu'ban (groupId=96)
INSERT INTO mob_droplist VALUES (50031, 0, 0, 1000, 21748, 500); -- Habilitator
INSERT INTO mob_droplist VALUES (50031, 0, 0, 1000, 25923, 500); -- Tatena. Sune.
INSERT INTO mob_droplist VALUES (50031, 0, 0, 1000, 26021, 500); -- Vim Torque

-- 50032  Tumult Curator (groupId=97)
INSERT INTO mob_droplist VALUES (50032, 0, 0, 1000, 20507, 500); -- Comeuppances
INSERT INTO mob_droplist VALUES (50032, 0, 0, 1000, 25732, 500); -- Tatena. Harama.
INSERT INTO mob_droplist VALUES (50032, 0, 0, 1000, 22057, 500); -- Contemplator

-- =============================================================================
-- TIER 3  (lv 128-145)  — 50% per item
-- =============================================================================

-- 50033  Specter Worm (groupId=98)
INSERT INTO mob_droplist VALUES (50033, 0, 0, 1000, 21702, 500); -- Kladenets
INSERT INTO mob_droplist VALUES (50033, 0, 0, 1000, 21343, 500); -- Ghastly Tathlum

-- 50034  Bakunawa (groupId=99)
INSERT INTO mob_droplist VALUES (50034, 0, 0, 1000, 20708, 500); -- Demers. Degen
INSERT INTO mob_droplist VALUES (50034, 0, 0, 1000, 27517, 500); -- Bathy Choker

-- 50035  Mephitas (groupId=100)
INSERT INTO mob_droplist VALUES (50035, 0, 0, 1000, 20603, 500); -- Ternion Dagger
INSERT INTO mob_droplist VALUES (50035, 0, 0, 1000, 27558, 500); -- Mephitas's Ring

-- 50036  Vidmapire (groupId=101)
INSERT INTO mob_droplist VALUES (50036, 0, 0, 1000, 20980, 500); -- Raicho
INSERT INTO mob_droplist VALUES (50036, 0, 0, 1000, 27609, 500); -- Fi Follet Cape

-- 50037  Shedu (groupId=102)
INSERT INTO mob_droplist VALUES (50037, 0, 0, 1000, 20681, 500); -- Flyssa
INSERT INTO mob_droplist VALUES (50037, 0, 0, 1000, 21075, 500); -- Septoptic
INSERT INTO mob_droplist VALUES (50037, 0, 0, 1000, 27148, 500); -- Tatena. Gote

-- 50038  Azure-toothed Clawberry (groupId=103)
INSERT INTO mob_droplist VALUES (50038, 0, 0, 1000, 27106, 500); -- Asteria Mitts
INSERT INTO mob_droplist VALUES (50038, 0, 0, 1000, 27108, 500); -- Lamassu Mitts

-- 50039  Centurio XX-I (groupId=104)
INSERT INTO mob_droplist VALUES (50039, 0, 0, 1000, 25680, 500); -- Cohort Cloak
INSERT INTO mob_droplist VALUES (50039, 0, 0, 1000, 28412, 500); -- Kentarch Belt

-- 50040  Wyvernhunter Bambrox (groupId=105)
INSERT INTO mob_droplist VALUES (50040, 0, 0, 1000, 21805, 500); -- Pixquizpan
INSERT INTO mob_droplist VALUES (50040, 0, 0, 1000, 22120, 500); -- Imati

-- 50041  Tolba (groupId=106)
INSERT INTO mob_droplist VALUES (50041, 0, 0, 1000, 21483, 500); -- Malison
INSERT INTO mob_droplist VALUES (50041, 0, 0, 1000, 25709, 500); -- Obviat. Cuirass
INSERT INTO mob_droplist VALUES (50041, 0, 0, 1000, 26401, 500); -- Forfend

-- 50042  Ayapec (groupId=107)
INSERT INTO mob_droplist VALUES (50042, 0, 0, 1000, 20804, 500); -- Perun
INSERT INTO mob_droplist VALUES (50042, 0, 0, 1000, 26784, 500); -- Hike Khat

-- 50043  Hidhaegg (groupId=108)
INSERT INTO mob_droplist VALUES (50043, 0, 0, 1000, 20696, 500); -- Combuster
INSERT INTO mob_droplist VALUES (50043, 0, 0, 1000, 21695, 500); -- Nullis
INSERT INTO mob_droplist VALUES (50043, 0, 0, 1000, 25635, 500); -- Loess Barbuta

-- 50044  Coca (groupId=109)
INSERT INTO mob_droplist VALUES (50044, 0, 0, 1000, 20942, 500); -- Gae Derg
INSERT INTO mob_droplist VALUES (50044, 0, 0, 1000, 27638, 500); -- Ajax

-- 50045  Grand Grenade (groupId=110)
INSERT INTO mob_droplist VALUES (50045, 0, 0, 1000, 21090, 500); -- Loxotic Mace
INSERT INTO mob_droplist VALUES (50045, 0, 0, 1000, 22254, 500); -- Seeth. Bomblet

-- 50046  Sarama (groupId=111)
INSERT INTO mob_droplist VALUES (50046, 0, 0, 1000, 21688, 500); -- Montante
INSERT INTO mob_droplist VALUES (50046, 0, 0, 1000, 20679, 500); -- Tanmogayi
INSERT INTO mob_droplist VALUES (50046, 0, 0, 1000, 25855, 500); -- Tatena. Haidate

-- 50047  Azrael (groupId=112)
INSERT INTO mob_droplist VALUES (50047, 0, 0, 1000, 20851, 500); -- Aizkora
INSERT INTO mob_droplist VALUES (50047, 0, 0, 1000, 26786, 500); -- Alhazen Hat

-- 50048  Carousing Celine (groupId=113)
INSERT INTO mob_droplist VALUES (50048, 0, 0, 1000, 27150, 500); -- Gazu Bracelets
INSERT INTO mob_droplist VALUES (50048, 0, 0, 1000, 27548, 500); -- Odnowa Earring

-- 50049  Camahueto (groupId=114)
INSERT INTO mob_droplist VALUES (50049, 0, 0, 1000, 20898, 500); -- Triska Scythe
INSERT INTO mob_droplist VALUES (50049, 0, 0, 1000, 27407, 500); -- Hygieia Clogs

-- 50050  Borealis Shadow (groupId=115)
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 20853, 500); -- Beheader
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 20527, 500); -- Fists of Fury
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 21219, 500); -- Paloma Bow
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 27640, 500); -- Deliverance

-- =============================================================================
-- Wire up mob_groups.dropid for zone-288 entries
-- NMs with no retail drop (groupIds 24,25,26,71,72,74) stay at dropid=0.
-- =============================================================================

-- Tier 1
UPDATE mob_groups SET dropid=50001 WHERE groupid=27  AND zoneid=288; -- Abyssdiver
UPDATE mob_groups SET dropid=50002 WHERE groupid=28  AND zoneid=288; -- Keeper of Heiligtum
UPDATE mob_groups SET dropid=50003 WHERE groupid=33  AND zoneid=288; -- Jester Malatrix
UPDATE mob_groups SET dropid=50004 WHERE groupid=34  AND zoneid=288; -- Immanibugard
UPDATE mob_groups SET dropid=50005 WHERE groupid=70  AND zoneid=288; -- Orcfeltrap
UPDATE mob_groups SET dropid=50006 WHERE groupid=73  AND zoneid=288; -- Sybaritic Samantha
UPDATE mob_groups SET dropid=50007 WHERE groupid=75  AND zoneid=288; -- Valkurm Imperator
UPDATE mob_groups SET dropid=50008 WHERE groupid=76  AND zoneid=288; -- Joyous Green
UPDATE mob_groups SET dropid=50009 WHERE groupid=77  AND zoneid=288; -- Warblade Beak
UPDATE mob_groups SET dropid=50010 WHERE groupid=78  AND zoneid=288; -- Cactrot Veloz
UPDATE mob_groups SET dropid=50011 WHERE groupid=79  AND zoneid=288; -- Woodland Mender
UPDATE mob_groups SET dropid=50012 WHERE groupid=80  AND zoneid=288; -- Emperor Arthro
UPDATE mob_groups SET dropid=50013 WHERE groupid=81  AND zoneid=288; -- Tiyanak
UPDATE mob_groups SET dropid=50014 WHERE groupid=82  AND zoneid=288; -- Vermillion Fishfly
UPDATE mob_groups SET dropid=50015 WHERE groupid=83  AND zoneid=288; -- Intuila

-- Tier 2
UPDATE mob_groups SET dropid=50016 WHERE groupid=29  AND zoneid=288; -- Muut
UPDATE mob_groups SET dropid=50017 WHERE groupid=32  AND zoneid=288; -- Voso
UPDATE mob_groups SET dropid=50018 WHERE groupid=35  AND zoneid=288; -- Beist
UPDATE mob_groups SET dropid=50019 WHERE groupid=84  AND zoneid=288; -- Lumber Jill
UPDATE mob_groups SET dropid=50020 WHERE groupid=85  AND zoneid=288; -- Largantua
UPDATE mob_groups SET dropid=50021 WHERE groupid=86  AND zoneid=288; -- Garbage Gel
UPDATE mob_groups SET dropid=50022 WHERE groupid=87  AND zoneid=288; -- King Uropygid
UPDATE mob_groups SET dropid=50023 WHERE groupid=88  AND zoneid=288; -- Vedrfolnir
UPDATE mob_groups SET dropid=50024 WHERE groupid=89  AND zoneid=288; -- Glazemane
UPDATE mob_groups SET dropid=50025 WHERE groupid=90  AND zoneid=288; -- Volatile Cluster
UPDATE mob_groups SET dropid=50026 WHERE groupid=91  AND zoneid=288; -- Strix
UPDATE mob_groups SET dropid=50027 WHERE groupid=92  AND zoneid=288; -- Sovereign Behemoth
UPDATE mob_groups SET dropid=50028 WHERE groupid=93  AND zoneid=288; -- Arke
UPDATE mob_groups SET dropid=50029 WHERE groupid=94  AND zoneid=288; -- Douma Weapon
UPDATE mob_groups SET dropid=50030 WHERE groupid=95  AND zoneid=288; -- Kubool Jas Mhuufya
UPDATE mob_groups SET dropid=50031 WHERE groupid=96  AND zoneid=288; -- Thu'ban
UPDATE mob_groups SET dropid=50032 WHERE groupid=97  AND zoneid=288; -- Tumult Curator

-- Tier 3
UPDATE mob_groups SET dropid=50033 WHERE groupid=98  AND zoneid=288; -- Specter Worm
UPDATE mob_groups SET dropid=50034 WHERE groupid=99  AND zoneid=288; -- Bakunawa
UPDATE mob_groups SET dropid=50035 WHERE groupid=100 AND zoneid=288; -- Mephitas
UPDATE mob_groups SET dropid=50036 WHERE groupid=101 AND zoneid=288; -- Vidmapire
UPDATE mob_groups SET dropid=50037 WHERE groupid=102 AND zoneid=288; -- Shedu
UPDATE mob_groups SET dropid=50038 WHERE groupid=103 AND zoneid=288; -- Azure-toothed Clawberry
UPDATE mob_groups SET dropid=50039 WHERE groupid=104 AND zoneid=288; -- Centurio XX-I
UPDATE mob_groups SET dropid=50040 WHERE groupid=105 AND zoneid=288; -- Wyvernhunter Bambrox
UPDATE mob_groups SET dropid=50041 WHERE groupid=106 AND zoneid=288; -- Tolba
UPDATE mob_groups SET dropid=50042 WHERE groupid=107 AND zoneid=288; -- Ayapec
UPDATE mob_groups SET dropid=50043 WHERE groupid=108 AND zoneid=288; -- Hidhaegg
UPDATE mob_groups SET dropid=50044 WHERE groupid=109 AND zoneid=288; -- Coca
UPDATE mob_groups SET dropid=50045 WHERE groupid=110 AND zoneid=288; -- Grand Grenade
UPDATE mob_groups SET dropid=50046 WHERE groupid=111 AND zoneid=288; -- Sarama
UPDATE mob_groups SET dropid=50047 WHERE groupid=112 AND zoneid=288; -- Azrael
UPDATE mob_groups SET dropid=50048 WHERE groupid=113 AND zoneid=288; -- Carousing Celine
UPDATE mob_groups SET dropid=50049 WHERE groupid=114 AND zoneid=288; -- Camahueto
UPDATE mob_groups SET dropid=50050 WHERE groupid=115 AND zoneid=288; -- Borealis Shadow
