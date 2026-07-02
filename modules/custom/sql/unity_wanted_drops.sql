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
INSERT INTO mob_droplist VALUES (50001, 0, 0, 1000, 21350, 500); -- Wingcutter +1
INSERT INTO mob_droplist VALUES (50001, 0, 0, 1000, 27994, 500); -- Macabre Gaunt. +1

-- 50002  Keeper of Heiligtum (groupId=28)
INSERT INTO mob_droplist VALUES (50002, 0, 0, 1000, 21035, 500); -- Kunimune +1
INSERT INTO mob_droplist VALUES (50002, 0, 0, 1000, 27231, 500); -- Zoar Subligar +1

-- 50003  Jester Malatrix (groupId=33)
INSERT INTO mob_droplist VALUES (50003, 0, 0, 1000, 20807, 500); -- Buramgh +1
INSERT INTO mob_droplist VALUES (50003, 0, 0, 1000, 27637, 500); -- Evalach +1

-- 50004  Immanibugard (groupId=34)
INSERT INTO mob_droplist VALUES (50004, 0, 0, 1000, 27410, 500); -- Hippo. Socks +1
INSERT INTO mob_droplist VALUES (50004, 0, 0, 1000, 27561, 500); -- Apeile Ring +1

-- 50005  Orcfeltrap (groupId=70)
INSERT INTO mob_droplist VALUES (50005, 0, 0, 1000, 20988, 500); -- Tancho +1
INSERT INTO mob_droplist VALUES (50005, 0, 0, 1000, 28424, 500); -- Shinjutsu-no-Obi +1

-- 50006  Sybaritic Samantha (groupId=73)
INSERT INTO mob_droplist VALUES (50006, 0, 0, 1000, 27563, 500); -- Metamor. Ring +1
INSERT INTO mob_droplist VALUES (50006, 0, 0, 1000, 27509, 500); -- Unmoving Collar +1

-- 50007  Valkurm Imperator (groupId=75)
INSERT INTO mob_droplist VALUES (50007, 0, 0, 1000, 26710, 500); -- Imp. Wing Hair. +1
INSERT INTO mob_droplist VALUES (50007, 0, 0, 1000, 28274, 500); -- Regal Pumps +1

-- 50008  Joyous Green (groupId=76)
INSERT INTO mob_droplist VALUES (50008, 0, 0, 1000, 28430, 500); -- Acuity Belt +1
INSERT INTO mob_droplist VALUES (50008, 0, 0, 1000, 28353, 500); -- Canto Necklace +1

-- 50009  Warblade Beak (groupId=77)
INSERT INTO mob_droplist VALUES (50009, 0, 0, 1000, 27996, 500); -- Shigure Tekko +1
INSERT INTO mob_droplist VALUES (50009, 0, 0, 1000, 28491, 500); -- Handler's Earring +1

-- 50010  Cactrot Veloz (groupId=78)
INSERT INTO mob_droplist VALUES (50010, 0, 0, 1000, 21223, 500); -- Mengado +1
INSERT INTO mob_droplist VALUES (50010, 0, 0, 1000, 28487, 500); -- Arete del Luna +1

-- 50011  Woodland Mender (groupId=79)
INSERT INTO mob_droplist VALUES (50011, 0, 0, 1000, 21163, 500); -- Pouwhenua +1
INSERT INTO mob_droplist VALUES (50011, 0, 0, 1000, 26869, 500); -- Ros. Jaseran +1

-- 50012  Emperor Arthro (groupId=80)
INSERT INTO mob_droplist VALUES (50012, 0, 0, 1000, 28137, 500); -- Augury Cuisses +1
INSERT INTO mob_droplist VALUES (50012, 0, 0, 1000, 28428, 500); -- Sailfi Belt +1

-- 50013  Tiyanak (groupId=81)
INSERT INTO mob_droplist VALUES (50013, 0, 0, 1000, 26897, 500); -- Lugra Cloak +1
INSERT INTO mob_droplist VALUES (50013, 0, 0, 1000, 28482, 500); -- Lugra Earring +1

-- 50014  Vermillion Fishfly (groupId=82)
INSERT INTO mob_droplist VALUES (50014, 0, 0, 1000, 25602, 500); -- Blistering Sallet +1
INSERT INTO mob_droplist VALUES (50014, 0, 0, 1000, 10771, 500); -- Cacoethic Ring +1

-- 50015  Intuila (groupId=83)
INSERT INTO mob_droplist VALUES (50015, 0, 0, 1000, 28135, 500); -- Assid. Pants +1

-- =============================================================================
-- TIER 2  (lv 99-119)  — 50% per item
-- =============================================================================

-- 50016  Muut (groupId=29)
INSERT INTO mob_droplist VALUES (50016, 0, 0, 1000, 20607, 500); -- Anathema Harpe +1

-- 50017  Voso (groupId=32)
INSERT INTO mob_droplist VALUES (50017, 0, 0, 1000, 26943, 500); -- Agony Jerkin +1

-- 50018  Beist (groupId=35)
INSERT INTO mob_droplist VALUES (50018, 0, 0, 1000, 26715, 500); -- Adorned Helm +1
INSERT INTO mob_droplist VALUES (50018, 0, 0, 1000, 26873, 500); -- Hime Domaru +1

-- 50019  Lumber Jill (groupId=84)
INSERT INTO mob_droplist VALUES (50019, 0, 0, 1000, 20612, 500); -- Sangarius +1
INSERT INTO mob_droplist VALUES (50019, 0, 0, 1000, 27602, 500); -- Ground. Mantle +1

-- 50020  Largantua (groupId=85)
INSERT INTO mob_droplist VALUES (50020, 0, 0, 1000, 26871, 500); -- Emet Harness +1
INSERT INTO mob_droplist VALUES (50020, 0, 0, 1000, 27505, 500); -- Warder's Charm +1

-- 50021  Garbage Gel (groupId=86)
INSERT INTO mob_droplist VALUES (50021, 0, 0, 1000, 20522, 500); -- Emeici +1
INSERT INTO mob_droplist VALUES (50021, 0, 0, 1000, 10769, 500); -- Gelatinous Ring +1

-- 50022  King Uropygid (groupId=87)
INSERT INTO mob_droplist VALUES (50022, 0, 0, 1000, 26732, 500); -- Stinger Helm +1

-- 50023  Vedrfolnir (groupId=88)
INSERT INTO mob_droplist VALUES (50023, 0, 0, 1000, 20528, 500); -- Fists of Fury +1
INSERT INTO mob_droplist VALUES (50023, 0, 0, 1000, 21160, 500); -- Marin Staff +1

-- 50024  Glazemane (groupId=89)
INSERT INTO mob_droplist VALUES (50024, 0, 0, 1000, 20581, 500); -- Kustawi +1
INSERT INTO mob_droplist VALUES (50024, 0, 0, 1000, 21691, 500); -- Ushenzi +1

-- 50025  Volatile Cluster (groupId=90)
INSERT INTO mob_droplist VALUES (50025, 0, 0, 1000, 21030, 500); -- Norifusa +1
INSERT INTO mob_droplist VALUES (50025, 0, 0, 1000, 27620, 500); -- Aurist's Cape +1

-- 50026  Strix (groupId=91)
INSERT INTO mob_droplist VALUES (50026, 0, 0, 1000, 21100, 500); -- Magesmasher +1
INSERT INTO mob_droplist VALUES (50026, 0, 0, 1000, 28276, 500); -- Jute Boots +1

-- 50027  Sovereign Behemoth (groupId=92)
INSERT INTO mob_droplist VALUES (50027, 0, 0, 1000, 22267, 500); -- Antitail +1
INSERT INTO mob_droplist VALUES (50027, 0, 0, 1000, 27543, 500); -- Domin. Earring +1
INSERT INTO mob_droplist VALUES (50027, 0, 0, 1000, 26002, 500); -- Loricate Torque +1

-- 50028  Arke (groupId=93)
INSERT INTO mob_droplist VALUES (50028, 0, 0, 1000, 20614, 500); -- Pukulatmuj +1
INSERT INTO mob_droplist VALUES (50028, 0, 0, 1000, 21165, 500); -- Ababinili +1

-- 50029  Douma Weapon (groupId=94)
INSERT INTO mob_droplist VALUES (50029, 0, 0, 1000, 26888, 500); -- Shomonjijoe +1
INSERT INTO mob_droplist VALUES (50029, 0, 0, 1000, 21419, 500); -- Rigorous Grip +1

-- 50030  Kubool Jas Mhuufya (groupId=95)
INSERT INTO mob_droplist VALUES (50030, 0, 0, 1000, 20800, 500); -- Mdomo Axe +1
INSERT INTO mob_droplist VALUES (50030, 0, 0, 1000, 27533, 500); -- Zwazo Earring +1

-- 50031  Thu'ban (groupId=96)
INSERT INTO mob_droplist VALUES (50031, 0, 0, 1000, 21749, 500); -- Habilitator +1
INSERT INTO mob_droplist VALUES (50031, 0, 0, 1000, 25924, 500); -- Tatena. Sune. +1
INSERT INTO mob_droplist VALUES (50031, 0, 0, 1000, 26022, 500); -- Vim Torque +1

-- 50032  Tumult Curator (groupId=97)
INSERT INTO mob_droplist VALUES (50032, 0, 0, 1000, 20508, 500); -- Comeuppances +1
INSERT INTO mob_droplist VALUES (50032, 0, 0, 1000, 25733, 500); -- Tatena. Harama. +1
INSERT INTO mob_droplist VALUES (50032, 0, 0, 1000, 22058, 500); -- Contemplator +1

-- =============================================================================
-- TIER 3  (lv 128-145)  — 50% per item
-- =============================================================================

-- 50033  Specter Worm (groupId=98)
INSERT INTO mob_droplist VALUES (50033, 0, 0, 1000, 21703, 500); -- Kladenets +1
INSERT INTO mob_droplist VALUES (50033, 0, 0, 1000, 21344, 500); -- Ghastly Tathlum +1

-- 50034  Bakunawa (groupId=99)
INSERT INTO mob_droplist VALUES (50034, 0, 0, 1000, 20709, 500); -- Demers. Degen +1
INSERT INTO mob_droplist VALUES (50034, 0, 0, 1000, 27518, 500); -- Bathy Choker +1

-- 50035  Mephitas (groupId=100)
INSERT INTO mob_droplist VALUES (50035, 0, 0, 1000, 20604, 500); -- Ternion Dagger +1
INSERT INTO mob_droplist VALUES (50035, 0, 0, 1000, 27559, 500); -- Mephitas's Ring +1

-- 50036  Vidmapire (groupId=101)
INSERT INTO mob_droplist VALUES (50036, 0, 0, 1000, 20981, 500); -- Raicho +1
INSERT INTO mob_droplist VALUES (50036, 0, 0, 1000, 27610, 500); -- Fi Follet Cape +1

-- 50037  Shedu (groupId=102)
INSERT INTO mob_droplist VALUES (50037, 0, 0, 1000, 20682, 500); -- Flyssa +1
INSERT INTO mob_droplist VALUES (50037, 0, 0, 1000, 21076, 500); -- Septoptic +1
INSERT INTO mob_droplist VALUES (50037, 0, 0, 1000, 27149, 500); -- Tatena. Gote +1

-- 50038  Azure-toothed Clawberry (groupId=103)
INSERT INTO mob_droplist VALUES (50038, 0, 0, 1000, 27107, 500); -- Asteria Mitts +1
INSERT INTO mob_droplist VALUES (50038, 0, 0, 1000, 27109, 500); -- Lamassu Mitts +1

-- 50039  Centurio XX-I (groupId=104)
INSERT INTO mob_droplist VALUES (50039, 0, 0, 1000, 25681, 500); -- Cohort Cloak +1
INSERT INTO mob_droplist VALUES (50039, 0, 0, 1000, 28413, 500); -- Kentarch Belt +1

-- 50040  Wyvernhunter Bambrox (groupId=105)
INSERT INTO mob_droplist VALUES (50040, 0, 0, 1000, 21806, 500); -- Pixquizpan +1
INSERT INTO mob_droplist VALUES (50040, 0, 0, 1000, 22121, 500); -- Imati +1

-- 50041  Tolba (groupId=106)
INSERT INTO mob_droplist VALUES (50041, 0, 0, 1000, 21484, 500); -- Malison +1
INSERT INTO mob_droplist VALUES (50041, 0, 0, 1000, 25710, 500); -- Obviat. Cuirass +1
INSERT INTO mob_droplist VALUES (50041, 0, 0, 1000, 26402, 500); -- Forfend +1

-- 50042  Ayapec (groupId=107)
INSERT INTO mob_droplist VALUES (50042, 0, 0, 1000, 20805, 500); -- Perun +1
INSERT INTO mob_droplist VALUES (50042, 0, 0, 1000, 26785, 500); -- Hike Khat +1

-- 50043  Hidhaegg (groupId=108)
INSERT INTO mob_droplist VALUES (50043, 0, 0, 1000, 20697, 500); -- Combuster +1
INSERT INTO mob_droplist VALUES (50043, 0, 0, 1000, 21696, 500); -- Nullis +1
INSERT INTO mob_droplist VALUES (50043, 0, 0, 1000, 25636, 500); -- Loess Barbuta +1

-- 50044  Coca (groupId=109)
INSERT INTO mob_droplist VALUES (50044, 0, 0, 1000, 20943, 500); -- Gae Derg +1
INSERT INTO mob_droplist VALUES (50044, 0, 0, 1000, 27639, 500); -- Ajax +1

-- 50045  Grand Grenade (groupId=110)
INSERT INTO mob_droplist VALUES (50045, 0, 0, 1000, 21091, 500); -- Loxotic Mace +1
INSERT INTO mob_droplist VALUES (50045, 0, 0, 1000, 22255, 500); -- Seeth. Bomblet +1

-- 50046  Sarama (groupId=111)
INSERT INTO mob_droplist VALUES (50046, 0, 0, 1000, 21689, 500); -- Montante +1
INSERT INTO mob_droplist VALUES (50046, 0, 0, 1000, 20680, 500); -- Tanmogayi +1
INSERT INTO mob_droplist VALUES (50046, 0, 0, 1000, 25856, 500); -- Tatena. Haidate +1

-- 50047  Azrael (groupId=112)
INSERT INTO mob_droplist VALUES (50047, 0, 0, 1000, 20852, 500); -- Aizkora +1
INSERT INTO mob_droplist VALUES (50047, 0, 0, 1000, 26787, 500); -- Alhazen Hat +1

-- 50048  Carousing Celine (groupId=113)
INSERT INTO mob_droplist VALUES (50048, 0, 0, 1000, 27151, 500); -- Gazu Bracelets +1
INSERT INTO mob_droplist VALUES (50048, 0, 0, 1000, 27549, 500); -- Odnowa Earring +1

-- 50049  Camahueto (groupId=114)
INSERT INTO mob_droplist VALUES (50049, 0, 0, 1000, 20899, 500); -- Triska Scythe +1
INSERT INTO mob_droplist VALUES (50049, 0, 0, 1000, 27408, 500); -- Hygieia Clogs +1

-- 50050  Borealis Shadow (groupId=115)
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 20854, 500); -- Beheader +1
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 20528, 500); -- Fists of Fury +1
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 21220, 500); -- Paloma Bow +1
INSERT INTO mob_droplist VALUES (50050, 0, 0, 1000, 27641, 500); -- Deliverance +1

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
