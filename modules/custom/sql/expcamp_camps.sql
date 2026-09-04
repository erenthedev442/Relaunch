-- ============================================================
-- expcamp_camps.sql
-- Densify !expcamp warps, put nearby trash on the advertised
-- level band, and give those camp packs a smooth HP curve plus
-- half-respawn. Isolated via groupid 20100-20105 per zone so the
-- rest of each zone keeps retail groups / respawn / HP.
--
-- Reserved: groupid 20100-20105 (PK is zoneid+groupid).
-- New mobids use targids 830-899 (< 0x400). Affinity NMs use 901-924.
-- Idempotent: DELETE our ids/groups, then INSERT/UPDATE.
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `groupid` BETWEEN 20100 AND 20105
   AND ((`mobid` >> 12) & 0xFFF) IN (25,52,61,79,88,102,103,108,117,123,124,125,126,153,174,197,212,261,262,263,266,267)
   AND (`mobid` & 0xFFF) >= 700;

DELETE FROM `mob_groups`
 WHERE `groupid` BETWEEN 20100 AND 20105
   AND `zoneid` IN (25,52,61,79,88,102,103,108,117,123,124,125,126,153,174,197,212,261,262,263,266,267);

-- ---- camp 1 La Theine  10-25  HP=350 ----
INSERT INTO `mob_groups` VALUES (20100,1791,102,'Grass_Funguar',150,0,1217,350,0,0,NULL);
INSERT INTO `mob_spawn_points` VALUES (17195770,0,'Grass_Funguar','Grass Funguar',20100,10,25,787.350,29.000,-18.570,0);
INSERT INTO `mob_spawn_points` VALUES (17195771,0,'Grass_Funguar','Grass Funguar',20100,10,25,783.542,29.000,-9.378,32);
INSERT INTO `mob_spawn_points` VALUES (17195772,0,'Grass_Funguar','Grass Funguar',20100,10,25,774.350,29.000,-5.570,64);
INSERT INTO `mob_spawn_points` VALUES (17195773,0,'Grass_Funguar','Grass Funguar',20100,10,25,765.158,29.000,-9.378,96);
INSERT INTO `mob_spawn_points` VALUES (17195774,0,'Grass_Funguar','Grass Funguar',20100,10,25,761.350,29.000,-18.570,128);
INSERT INTO `mob_spawn_points` VALUES (17195775,0,'Grass_Funguar','Grass Funguar',20100,10,25,765.158,29.000,-27.762,160);
INSERT INTO `mob_spawn_points` VALUES (17195776,0,'Grass_Funguar','Grass Funguar',20100,10,25,774.350,29.000,-31.570,192);
INSERT INTO `mob_spawn_points` VALUES (17195777,0,'Grass_Funguar','Grass Funguar',20100,10,25,783.542,29.000,-27.762,224);
INSERT INTO `mob_spawn_points` VALUES (17195778,0,'Grass_Funguar','Grass Funguar',20100,10,25,797.350,29.000,-18.570,0);
INSERT INTO `mob_spawn_points` VALUES (17195779,0,'Grass_Funguar','Grass Funguar',20100,10,25,774.350,29.000,4.430,64);
INSERT INTO `mob_spawn_points` VALUES (17195780,0,'Grass_Funguar','Grass Funguar',20100,10,25,751.350,29.000,-18.570,128);
INSERT INTO `mob_spawn_points` VALUES (17195781,0,'Grass_Funguar','Grass Funguar',20100,10,25,774.350,29.000,-41.570,192);

-- ---- camp 2 Konschtat  10-25  HP=350 ----
INSERT INTO `mob_groups` VALUES (20100,2473,108,'Mad_Sheep',150,0,368,350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,3792,108,'Strolling_Sapling',150,0,2346,350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,2679,108,'Mist_Lizard',150,0,1701,350,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=10, `maxLevel`=25 WHERE `mobid`=17219593;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=10, `maxLevel`=25 WHERE `mobid`=17219979;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25 WHERE `mobid`=17219983;
INSERT INTO `mob_spawn_points` VALUES (17220284,0,'Mad_Sheep','Mad Sheep',20100,10,25,-210.000,71.070,828.000,0);
INSERT INTO `mob_spawn_points` VALUES (17220285,0,'Mad_Sheep','Mad Sheep',20100,10,25,-213.808,71.070,837.192,32);
INSERT INTO `mob_spawn_points` VALUES (17220286,0,'Mad_Sheep','Mad Sheep',20100,10,25,-223.000,71.070,841.000,64);
INSERT INTO `mob_spawn_points` VALUES (17220287,0,'Mad_Sheep','Mad Sheep',20100,10,25,-232.192,71.070,837.192,96);
INSERT INTO `mob_spawn_points` VALUES (17220288,0,'Mad_Sheep','Mad Sheep',20100,10,25,-236.000,71.070,828.000,128);
INSERT INTO `mob_spawn_points` VALUES (17220289,0,'Mad_Sheep','Mad Sheep',20100,10,25,-232.192,71.070,818.808,160);
INSERT INTO `mob_spawn_points` VALUES (17220290,0,'Mad_Sheep','Mad Sheep',20100,10,25,-223.000,71.070,815.000,192);
INSERT INTO `mob_spawn_points` VALUES (17220291,0,'Mad_Sheep','Mad Sheep',20100,10,25,-213.808,71.070,818.808,224);
INSERT INTO `mob_spawn_points` VALUES (17220292,0,'Mad_Sheep','Mad Sheep',20100,10,25,-200.000,71.070,828.000,0);
INSERT INTO `mob_spawn_points` VALUES (17220293,0,'Mad_Sheep','Mad Sheep',20100,10,25,-223.000,71.070,851.000,64);
INSERT INTO `mob_spawn_points` VALUES (17220294,0,'Mad_Sheep','Mad Sheep',20100,10,25,-246.000,71.070,828.000,128);
INSERT INTO `mob_spawn_points` VALUES (17220295,0,'Mad_Sheep','Mad Sheep',20100,10,25,-223.000,71.070,805.000,192);

-- ---- camp 3 Tahrongi  10-25  HP=350 ----
INSERT INTO `mob_groups` VALUES (20100,2228,117,'Killer_Bee',150,0,584,350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,4341,117,'Wild_Dhalmel',150,0,2655,350,0,0,NULL);
INSERT INTO `mob_spawn_points` VALUES (17257150,0,'Killer_Bee','Killer Bee',20100,10,25,-147.000,47.250,647.110,0);
INSERT INTO `mob_spawn_points` VALUES (17257151,0,'Killer_Bee','Killer Bee',20100,10,25,-150.808,47.250,656.302,32);
INSERT INTO `mob_spawn_points` VALUES (17257152,0,'Killer_Bee','Killer Bee',20100,10,25,-160.000,47.250,660.110,64);
INSERT INTO `mob_spawn_points` VALUES (17257153,0,'Killer_Bee','Killer Bee',20100,10,25,-169.192,47.250,656.302,96);
INSERT INTO `mob_spawn_points` VALUES (17257154,0,'Killer_Bee','Killer Bee',20100,10,25,-173.000,47.250,647.110,128);
INSERT INTO `mob_spawn_points` VALUES (17257155,0,'Killer_Bee','Killer Bee',20100,10,25,-169.192,47.250,637.918,160);
INSERT INTO `mob_spawn_points` VALUES (17257156,0,'Killer_Bee','Killer Bee',20100,10,25,-160.000,47.250,634.110,192);
INSERT INTO `mob_spawn_points` VALUES (17257157,0,'Killer_Bee','Killer Bee',20100,10,25,-150.808,47.250,637.918,224);
INSERT INTO `mob_spawn_points` VALUES (17257158,0,'Killer_Bee','Killer Bee',20100,10,25,-137.000,47.250,647.110,0);
INSERT INTO `mob_spawn_points` VALUES (17257159,0,'Killer_Bee','Killer Bee',20100,10,25,-160.000,47.250,670.110,64);
INSERT INTO `mob_spawn_points` VALUES (17257160,0,'Killer_Bee','Killer Bee',20100,10,25,-183.000,47.250,647.110,128);
INSERT INTO `mob_spawn_points` VALUES (17257161,0,'Killer_Bee','Killer Bee',20100,10,25,-160.000,47.250,624.110,192);

-- ---- camp 4 Valkurm  15-30  HP=480 ----
INSERT INTO `mob_groups` VALUES (20100,1683,103,'Goblin_Leecher',150,0,1098,480,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,548,103,'Brutal_Sheep',150,0,368,480,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,5733,103,'Snipper',150,0,2281,480,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,3901,103,'Thread_Leech',150,0,18,480,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,899,103,'Damselfly',150,0,562,480,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20105,3455,103,'Sand_Hare',150,0,2150,480,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199296;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199297;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199305;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199313;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199314;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199315;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199316;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199317;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199318;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199319;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199320;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199354;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199356;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199357;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199358;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199363;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199374;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199376;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199383;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30 WHERE `mobid`=17199386;
INSERT INTO `mob_spawn_points` VALUES (17199804,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,150.900,-7.500,97.000,0);
INSERT INTO `mob_spawn_points` VALUES (17199805,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,147.092,-7.500,106.192,32);
INSERT INTO `mob_spawn_points` VALUES (17199806,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,137.900,-7.500,110.000,64);
INSERT INTO `mob_spawn_points` VALUES (17199807,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,128.708,-7.500,106.192,96);
INSERT INTO `mob_spawn_points` VALUES (17199808,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,124.900,-7.500,97.000,128);
INSERT INTO `mob_spawn_points` VALUES (17199809,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,128.708,-7.500,87.808,160);
INSERT INTO `mob_spawn_points` VALUES (17199810,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,137.900,-7.500,84.000,192);
INSERT INTO `mob_spawn_points` VALUES (17199811,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,147.092,-7.500,87.808,224);
INSERT INTO `mob_spawn_points` VALUES (17199812,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,160.900,-7.500,97.000,0);
INSERT INTO `mob_spawn_points` VALUES (17199813,0,'Goblin_Leecher','Goblin Leecher',20100,15,30,114.900,-7.500,97.000,128);

-- ---- camp 5 Qufim  25-40  HP=950 ----
INSERT INTO `mob_groups` VALUES (20100,743,126,'Clipper',150,0,93,950,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,1540,126,'Giant_Trapper',150,0,964,950,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,909,126,'Dark_Bats',150,0,82,950,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,40,126,'Acrophies',150,0,18,950,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,1625,126,'Glow_Bat',150,0,461,950,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20105,4337,126,'Wight_war',150,0,2651,950,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293507;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293508;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293509;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293510;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293515;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293518;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293539;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293544;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293545;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293552;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293557;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293561;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293564;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293565;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293566;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293567;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293568;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293570;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293573;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293576;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293579;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293583;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40 WHERE `mobid`=17293584;
INSERT INTO `mob_spawn_points` VALUES (17294012,0,'Clipper','Clipper',20100,25,40,-238.980,-19.960,298.210,0);
INSERT INTO `mob_spawn_points` VALUES (17294013,0,'Clipper','Clipper',20100,25,40,-242.788,-19.960,307.402,32);
INSERT INTO `mob_spawn_points` VALUES (17294014,0,'Clipper','Clipper',20100,25,40,-251.980,-19.960,311.210,64);
INSERT INTO `mob_spawn_points` VALUES (17294015,0,'Clipper','Clipper',20100,25,40,-261.172,-19.960,307.402,96);
INSERT INTO `mob_spawn_points` VALUES (17294016,0,'Clipper','Clipper',20100,25,40,-264.980,-19.960,298.210,128);
INSERT INTO `mob_spawn_points` VALUES (17294017,0,'Clipper','Clipper',20100,25,40,-261.172,-19.960,289.018,160);
INSERT INTO `mob_spawn_points` VALUES (17294018,0,'Clipper','Clipper',20100,25,40,-251.980,-19.960,285.210,192);
INSERT INTO `mob_spawn_points` VALUES (17294019,0,'Clipper','Clipper',20100,25,40,-242.788,-19.960,289.018,224);

-- ---- camp 6 Yuhtunga  30-45  HP=1350 ----
INSERT INTO `mob_groups` VALUES (20100,4476,123,'Young_Opo-opo',150,0,2783,1350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,1665,123,'Goblin_Furrier',150,0,1064,1350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,7034,123,'Soldier_Crawler',150,0,2022,1350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,833,123,'Creek_Sahagin',150,0,532,1350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,3073,123,'Overgrown_Rose',150,0,2922,1350,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20105,1709,123,'Goblin_Robber',150,0,1145,1350,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281242;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281244;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281245;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281246;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281247;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281248;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281249;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281250;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281251;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281252;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281253;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281254;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281255;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281259;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281260;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281261;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281262;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281266;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281267;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281274;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=30, `maxLevel`=45 WHERE `mobid`=17281275;
INSERT INTO `mob_spawn_points` VALUES (17281724,0,'Young_Opo-opo','Young Opo-opo',20100,30,45,-226.510,0.000,-402.770,0);
INSERT INTO `mob_spawn_points` VALUES (17281725,0,'Young_Opo-opo','Young Opo-opo',20100,30,45,-233.010,0.000,-391.512,43);
INSERT INTO `mob_spawn_points` VALUES (17281726,0,'Young_Opo-opo','Young Opo-opo',20100,30,45,-246.010,0.000,-391.512,85);
INSERT INTO `mob_spawn_points` VALUES (17281727,0,'Young_Opo-opo','Young Opo-opo',20100,30,45,-252.510,0.000,-402.770,128);
INSERT INTO `mob_spawn_points` VALUES (17281728,0,'Young_Opo-opo','Young Opo-opo',20100,30,45,-246.010,0.000,-414.028,171);
INSERT INTO `mob_spawn_points` VALUES (17281729,0,'Young_Opo-opo','Young Opo-opo',20100,30,45,-233.010,0.000,-414.028,213);

-- ---- camp 7 Yhoator  35-50  HP=1800 ----
INSERT INTO `mob_groups` VALUES (20100,4375,124,'Worker_Crawler',150,0,2022,1800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,3951,124,'Tonberry_Creeper',150,0,2431,1800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,3958,124,'Tonberry_Hexer',150,0,2437,1800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,3956,124,'Tonberry_Harasser',150,0,2435,1800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,4476,124,'Young_Opo-opo',150,0,2784,1800,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285349;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285350;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285467;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285468;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285469;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285491;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285492;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285493;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285494;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285495;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285497;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285498;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285499;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285504;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285505;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285506;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285517;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285520;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285523;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285530;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285531;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285532;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid`=17285533;
INSERT INTO `mob_spawn_points` VALUES (17285820,0,'Worker_Crawler','Worker Crawler',20100,35,50,210.820,0.000,-81.820,0);
INSERT INTO `mob_spawn_points` VALUES (17285821,0,'Worker_Crawler','Worker Crawler',20100,35,50,204.320,0.000,-70.562,43);
INSERT INTO `mob_spawn_points` VALUES (17285822,0,'Worker_Crawler','Worker Crawler',20100,35,50,191.320,0.000,-70.562,85);
INSERT INTO `mob_spawn_points` VALUES (17285823,0,'Worker_Crawler','Worker Crawler',20100,35,50,184.820,0.000,-81.820,128);
INSERT INTO `mob_spawn_points` VALUES (17285824,0,'Worker_Crawler','Worker Crawler',20100,35,50,191.320,0.000,-93.078,171);
INSERT INTO `mob_spawn_points` VALUES (17285825,0,'Worker_Crawler','Worker Crawler',20100,35,50,204.320,0.000,-93.078,213);

-- ---- camp 8 Crawlers Nest  45-60  HP=2600 ----
INSERT INTO `mob_groups` VALUES (20100,3697,197,'Soldier_Crawler',150,0,256,2600,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,6316,197,'Worker_Crawler',150,0,256,2600,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17584136;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17584137;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17584138;
INSERT INTO `mob_spawn_points` VALUES (17584828,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,377.000,-32.200,-22.030,0);
INSERT INTO `mob_spawn_points` VALUES (17584829,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,373.192,-32.200,-12.838,32);
INSERT INTO `mob_spawn_points` VALUES (17584830,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,364.000,-32.200,-9.030,64);
INSERT INTO `mob_spawn_points` VALUES (17584831,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,354.808,-32.200,-12.838,96);
INSERT INTO `mob_spawn_points` VALUES (17584832,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,351.000,-32.200,-22.030,128);
INSERT INTO `mob_spawn_points` VALUES (17584833,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,354.808,-32.200,-31.222,160);
INSERT INTO `mob_spawn_points` VALUES (17584834,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,364.000,-32.200,-35.030,192);
INSERT INTO `mob_spawn_points` VALUES (17584835,0,'Soldier_Crawler','Soldier Crawler',20100,45,60,373.192,-32.200,-31.222,224);

-- ---- camp 9 Gustav  45-60  HP=2600 ----
INSERT INTO `mob_groups` VALUES (20100,1924,212,'Hell_Bat',150,0,234,2600,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,1705,212,'Goblin_Reaper',150,0,1141,2600,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,1901,212,'Hawker',150,0,571,2600,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,1701,212,'Goblin_Poacher',150,0,1139,2600,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645590;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645612;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645615;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645616;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645617;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645618;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60 WHERE `mobid`=17645619;
INSERT INTO `mob_spawn_points` VALUES (17646268,0,'Hell_Bat','Hell Bat',20100,45,60,309.680,-40.420,64.680,0);
INSERT INTO `mob_spawn_points` VALUES (17646269,0,'Hell_Bat','Hell Bat',20100,45,60,305.872,-40.420,73.872,32);
INSERT INTO `mob_spawn_points` VALUES (17646270,0,'Hell_Bat','Hell Bat',20100,45,60,296.680,-40.420,77.680,64);
INSERT INTO `mob_spawn_points` VALUES (17646271,0,'Hell_Bat','Hell Bat',20100,45,60,287.488,-40.420,73.872,96);
INSERT INTO `mob_spawn_points` VALUES (17646272,0,'Hell_Bat','Hell Bat',20100,45,60,283.680,-40.420,64.680,128);
INSERT INTO `mob_spawn_points` VALUES (17646273,0,'Hell_Bat','Hell Bat',20100,45,60,287.488,-40.420,55.488,160);
INSERT INTO `mob_spawn_points` VALUES (17646274,0,'Hell_Bat','Hell Bat',20100,45,60,296.680,-40.420,51.680,192);
INSERT INTO `mob_spawn_points` VALUES (17646275,0,'Hell_Bat','Hell Bat',20100,45,60,305.872,-40.420,55.488,224);

-- ---- camp 10 Kuftal  50-60  HP=2900 ----
INSERT INTO `mob_groups` VALUES (20100,3456,174,'Sand_Lizard',150,0,2153,2900,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,3375,174,'Robber_Crab',150,0,2110,2900,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,1900,174,'Haunt',600,0,1281,2900,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489929;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489930;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489935;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489936;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489937;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489938;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489939;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489940;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489941;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489942;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489943;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489944;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489945;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489947;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489948;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17489973;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17490011;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17490012;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17490015;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17490021;
INSERT INTO `mob_spawn_points` VALUES (17490620,0,'Sand_Lizard','Sand Lizard',20100,50,60,-3.840,-20.470,-237.000,0);
INSERT INTO `mob_spawn_points` VALUES (17490621,0,'Sand_Lizard','Sand Lizard',20100,50,60,-10.340,-20.470,-225.742,43);
INSERT INTO `mob_spawn_points` VALUES (17490622,0,'Sand_Lizard','Sand Lizard',20100,50,60,-23.340,-20.470,-225.742,85);
INSERT INTO `mob_spawn_points` VALUES (17490623,0,'Sand_Lizard','Sand Lizard',20100,50,60,-29.840,-20.470,-237.000,128);
INSERT INTO `mob_spawn_points` VALUES (17490624,0,'Sand_Lizard','Sand Lizard',20100,50,60,-23.340,-20.470,-248.258,171);
INSERT INTO `mob_spawn_points` VALUES (17490625,0,'Sand_Lizard','Sand Lizard',20100,50,60,-10.340,-20.470,-248.258,213);

-- ---- camp 11 W Altepa  50-60  HP=2900 ----
INSERT INTO `mob_groups` VALUES (20100,1009,125,'Desert_Spider',150,0,635,2900,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17289230;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17289242;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17289244;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid`=17289245;
INSERT INTO `mob_spawn_points` VALUES (17289916,0,'Desert_Spider','Desert Spider',20100,50,60,432.330,-3.120,11.680,0);
INSERT INTO `mob_spawn_points` VALUES (17289917,0,'Desert_Spider','Desert Spider',20100,50,60,425.830,-3.120,22.938,43);
INSERT INTO `mob_spawn_points` VALUES (17289918,0,'Desert_Spider','Desert Spider',20100,50,60,412.830,-3.120,22.938,85);
INSERT INTO `mob_spawn_points` VALUES (17289919,0,'Desert_Spider','Desert Spider',20100,50,60,406.330,-3.120,11.680,128);
INSERT INTO `mob_spawn_points` VALUES (17289920,0,'Desert_Spider','Desert Spider',20100,50,60,412.830,-3.120,0.422,171);
INSERT INTO `mob_spawn_points` VALUES (17289921,0,'Desert_Spider','Desert Spider',20100,50,60,425.830,-3.120,0.422,213);

-- ---- camp 12 Boyahda  60-75  HP=3900 ----
INSERT INTO `mob_groups` VALUES (20100,3649,153,'Skimmer',150,0,571,3900,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,2754,153,'Moss_Eater',150,0,1742,3900,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,1191,153,'Elder_Goobbue',150,0,3012,3900,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=60, `maxLevel`=75 WHERE `mobid`=17404132;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=60, `maxLevel`=75 WHERE `mobid`=17404133;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75 WHERE `mobid`=17404163;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75 WHERE `mobid`=17404164;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75 WHERE `mobid`=17404172;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75 WHERE `mobid`=17404173;
INSERT INTO `mob_spawn_points` VALUES (17404604,0,'Skimmer','Skimmer',20100,60,75,101.000,-15.000,-217.000,0);
INSERT INTO `mob_spawn_points` VALUES (17404605,0,'Skimmer','Skimmer',20100,60,75,97.192,-15.000,-207.808,32);
INSERT INTO `mob_spawn_points` VALUES (17404606,0,'Skimmer','Skimmer',20100,60,75,88.000,-15.000,-204.000,64);
INSERT INTO `mob_spawn_points` VALUES (17404607,0,'Skimmer','Skimmer',20100,60,75,78.808,-15.000,-207.808,96);
INSERT INTO `mob_spawn_points` VALUES (17404608,0,'Skimmer','Skimmer',20100,60,75,75.000,-15.000,-217.000,128);
INSERT INTO `mob_spawn_points` VALUES (17404609,0,'Skimmer','Skimmer',20100,60,75,78.808,-15.000,-226.192,160);
INSERT INTO `mob_spawn_points` VALUES (17404610,0,'Skimmer','Skimmer',20100,60,75,88.000,-15.000,-230.000,192);
INSERT INTO `mob_spawn_points` VALUES (17404611,0,'Skimmer','Skimmer',20100,60,75,97.192,-15.000,-226.192,224);

-- ---- camp 13 Bhaflau  75-85  HP=5200 ----
INSERT INTO `mob_groups` VALUES (20100,765,52,'Colibri',150,0,500,5200,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=16990300;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=16990331;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=16990332;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=16990333;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=16990334;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=16990335;
INSERT INTO `mob_spawn_points` VALUES (16990908,0,'Colibri','Colibri',20100,75,85,21.000,-24.000,140.000,0);
INSERT INTO `mob_spawn_points` VALUES (16990909,0,'Colibri','Colibri',20100,75,85,17.192,-24.000,149.192,32);
INSERT INTO `mob_spawn_points` VALUES (16990910,0,'Colibri','Colibri',20100,75,85,8.000,-24.000,153.000,64);
INSERT INTO `mob_spawn_points` VALUES (16990911,0,'Colibri','Colibri',20100,75,85,-1.192,-24.000,149.192,96);
INSERT INTO `mob_spawn_points` VALUES (16990912,0,'Colibri','Colibri',20100,75,85,-5.000,-24.000,140.000,128);
INSERT INTO `mob_spawn_points` VALUES (16990913,0,'Colibri','Colibri',20100,75,85,-1.192,-24.000,130.808,160);
INSERT INTO `mob_spawn_points` VALUES (16990914,0,'Colibri','Colibri',20100,75,85,8.000,-24.000,127.000,192);
INSERT INTO `mob_spawn_points` VALUES (16990915,0,'Colibri','Colibri',20100,75,85,17.192,-24.000,130.808,224);
INSERT INTO `mob_spawn_points` VALUES (16990916,0,'Colibri','Colibri',20100,75,85,31.000,-24.000,140.000,0);
INSERT INTO `mob_spawn_points` VALUES (16990917,0,'Colibri','Colibri',20100,75,85,8.000,-24.000,163.000,64);
INSERT INTO `mob_spawn_points` VALUES (16990918,0,'Colibri','Colibri',20100,75,85,-15.000,-24.000,140.000,128);
INSERT INTO `mob_spawn_points` VALUES (16990919,0,'Colibri','Colibri',20100,75,85,8.000,-24.000,117.000,192);

-- ---- camp 14 Zhayolm  75-85  HP=5200 ----
INSERT INTO `mob_groups` VALUES (20100,3825,61,'Sweeping_Cluster',150,0,2367,5200,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,271,61,'Assassin_Fly',150,0,571,5200,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,2485,61,'Magmatic_Eruca',150,0,419,5200,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=17027273;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=17027296;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=17027316;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid`=17027317;
INSERT INTO `mob_spawn_points` VALUES (17027772,0,'Sweeping_Cluster','Sweeping Cluster',20100,75,85,671.480,-27.475,314.455,0);
INSERT INTO `mob_spawn_points` VALUES (17027773,0,'Sweeping_Cluster','Sweeping Cluster',20100,75,85,664.980,-27.475,325.713,43);
INSERT INTO `mob_spawn_points` VALUES (17027774,0,'Sweeping_Cluster','Sweeping Cluster',20100,75,85,651.980,-27.475,325.713,85);
INSERT INTO `mob_spawn_points` VALUES (17027775,0,'Sweeping_Cluster','Sweeping Cluster',20100,75,85,645.480,-27.475,314.455,128);
INSERT INTO `mob_spawn_points` VALUES (17027776,0,'Sweeping_Cluster','Sweeping Cluster',20100,75,85,651.980,-27.475,303.196,171);
INSERT INTO `mob_spawn_points` VALUES (17027777,0,'Sweeping_Cluster','Sweeping Cluster',20100,75,85,664.980,-27.475,303.196,213);

-- ---- camp 15 Misareaux  80-85  HP=5500 ----
INSERT INTO `mob_groups` VALUES (20100,6028,25,'Seaboard_Vulture',150,0,43,5500,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,1549,25,'Gigantobugard',150,0,979,5500,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,6283,25,'Orcish_Trooper',150,0,3255,5500,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879701;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879702;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879706;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879708;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879709;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879710;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879711;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879712;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879713;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879714;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879715;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879716;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879717;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879718;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=85 WHERE `mobid`=16879719;
INSERT INTO `mob_spawn_points` VALUES (16880316,0,'Seaboard_Vulture','Seaboard Vulture',20100,80,85,501.448,-22.128,260.901,0);
INSERT INTO `mob_spawn_points` VALUES (16880317,0,'Seaboard_Vulture','Seaboard Vulture',20100,80,85,494.948,-22.128,272.159,43);
INSERT INTO `mob_spawn_points` VALUES (16880318,0,'Seaboard_Vulture','Seaboard Vulture',20100,80,85,481.948,-22.128,272.159,85);
INSERT INTO `mob_spawn_points` VALUES (16880319,0,'Seaboard_Vulture','Seaboard Vulture',20100,80,85,475.448,-22.128,260.901,128);
INSERT INTO `mob_spawn_points` VALUES (16880320,0,'Seaboard_Vulture','Seaboard Vulture',20100,80,85,481.948,-22.128,249.642,171);
INSERT INTO `mob_spawn_points` VALUES (16880321,0,'Seaboard_Vulture','Seaboard Vulture',20100,80,85,494.948,-22.128,249.642,213);

-- ---- camp 16 Caedarva  80-90  HP=6000 ----
INSERT INTO `mob_groups` VALUES (20100,2580,79,'Marsh_Murre',150,0,1635,6000,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,603,79,'Caedarva_Leech',150,0,174,6000,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,3049,79,'Orderly_Imp',150,0,1002,6000,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,6354,79,'Treant_Sapling',150,0,0,6000,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,3224,79,'Puktrap',150,0,852,6000,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=80, `maxLevel`=90 WHERE `mobid`=17100836;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=80, `maxLevel`=90 WHERE `mobid`=17100837;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=80, `maxLevel`=90 WHERE `mobid`=17100838;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=90 WHERE `mobid`=17100839;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=80, `maxLevel`=90 WHERE `mobid`=17100840;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=80, `maxLevel`=90 WHERE `mobid`=17100841;
INSERT INTO `mob_spawn_points` VALUES (17101500,0,'Marsh_Murre','Marsh Murre',20100,80,90,295.705,-4.151,-703.402,0);
INSERT INTO `mob_spawn_points` VALUES (17101501,0,'Marsh_Murre','Marsh Murre',20100,80,90,291.897,-4.151,-694.210,32);
INSERT INTO `mob_spawn_points` VALUES (17101502,0,'Marsh_Murre','Marsh Murre',20100,80,90,282.705,-4.151,-690.402,64);
INSERT INTO `mob_spawn_points` VALUES (17101503,0,'Marsh_Murre','Marsh Murre',20100,80,90,273.512,-4.151,-694.210,96);
INSERT INTO `mob_spawn_points` VALUES (17101504,0,'Marsh_Murre','Marsh Murre',20100,80,90,269.705,-4.151,-703.402,128);
INSERT INTO `mob_spawn_points` VALUES (17101505,0,'Marsh_Murre','Marsh Murre',20100,80,90,273.512,-4.151,-712.595,160);
INSERT INTO `mob_spawn_points` VALUES (17101506,0,'Marsh_Murre','Marsh Murre',20100,80,90,282.705,-4.151,-716.402,192);
INSERT INTO `mob_spawn_points` VALUES (17101507,0,'Marsh_Murre','Marsh Murre',20100,80,90,291.897,-4.151,-712.595,224);
INSERT INTO `mob_spawn_points` VALUES (17101508,0,'Marsh_Murre','Marsh Murre',20100,80,90,305.705,-4.151,-703.402,0);
INSERT INTO `mob_spawn_points` VALUES (17101509,0,'Marsh_Murre','Marsh Murre',20100,80,90,298.968,-4.151,-687.139,32);
INSERT INTO `mob_spawn_points` VALUES (17101510,0,'Marsh_Murre','Marsh Murre',20100,80,90,282.705,-4.151,-680.402,64);
INSERT INTO `mob_spawn_points` VALUES (17101511,0,'Marsh_Murre','Marsh Murre',20100,80,90,266.441,-4.151,-687.139,96);
INSERT INTO `mob_spawn_points` VALUES (17101512,0,'Marsh_Murre','Marsh Murre',20100,80,90,259.705,-4.151,-703.402,128);
INSERT INTO `mob_spawn_points` VALUES (17101513,0,'Marsh_Murre','Marsh Murre',20100,80,90,266.441,-4.151,-719.666,160);
INSERT INTO `mob_spawn_points` VALUES (17101514,0,'Marsh_Murre','Marsh Murre',20100,80,90,282.705,-4.151,-726.402,192);
INSERT INTO `mob_spawn_points` VALUES (17101515,0,'Marsh_Murre','Marsh Murre',20100,80,90,298.968,-4.151,-719.666,224);

-- ---- camp 17 Ceizak  85-95  HP=6800 ----
INSERT INTO `mob_groups` VALUES (20100,5001,261,'Blanched_Mandragora',150,0,2956,6800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,5002,261,'Bight_Uragnite',150,0,0,6800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,5006,261,'Appetent_Umbril',150,0,0,6800,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846285;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846286;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846287;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846288;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846289;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846290;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846291;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846292;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846293;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846294;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=85, `maxLevel`=95 WHERE `mobid`=17846575;
INSERT INTO `mob_spawn_points` VALUES (17846972,0,'Blanched_Mandragora','Blanched Mandragora',20100,85,95,345.884,0.390,136.270,0);
INSERT INTO `mob_spawn_points` VALUES (17846973,0,'Blanched_Mandragora','Blanched Mandragora',20100,85,95,339.384,0.390,147.529,43);
INSERT INTO `mob_spawn_points` VALUES (17846974,0,'Blanched_Mandragora','Blanched Mandragora',20100,85,95,326.384,0.390,147.529,85);
INSERT INTO `mob_spawn_points` VALUES (17846975,0,'Blanched_Mandragora','Blanched Mandragora',20100,85,95,319.884,0.390,136.270,128);
INSERT INTO `mob_spawn_points` VALUES (17846976,0,'Blanched_Mandragora','Blanched Mandragora',20100,85,95,326.384,0.390,125.012,171);
INSERT INTO `mob_spawn_points` VALUES (17846977,0,'Blanched_Mandragora','Blanched Mandragora',20100,85,95,339.384,0.390,125.012,213);

-- ---- camp 18 Yorcia  90-99  HP=7400 ----
INSERT INTO `mob_groups` VALUES (20100,4940,263,'Nascent_Sapling',150,0,0,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,4937,263,'Droughted_Treant',150,0,0,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,4948,263,'Saptrap',150,0,0,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,4771,263,'Grove_Wasp',150,0,0,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,4935,263,'Twitherym',150,0,0,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20105,4933,263,'Swollen_Chigoe',150,0,0,7400,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854741;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854742;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854743;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854754;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854757;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854758;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854759;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854763;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854764;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854765;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854766;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854767;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854768;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854769;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17854771;
INSERT INTO `mob_spawn_points` VALUES (17855164,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-170.760,1.540,69.930,0);
INSERT INTO `mob_spawn_points` VALUES (17855165,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-174.568,1.540,79.122,32);
INSERT INTO `mob_spawn_points` VALUES (17855166,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-183.760,1.540,82.930,64);
INSERT INTO `mob_spawn_points` VALUES (17855167,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-192.952,1.540,79.122,96);
INSERT INTO `mob_spawn_points` VALUES (17855168,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-196.760,1.540,69.930,128);
INSERT INTO `mob_spawn_points` VALUES (17855169,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-192.952,1.540,60.738,160);
INSERT INTO `mob_spawn_points` VALUES (17855170,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-183.760,1.540,56.930,192);
INSERT INTO `mob_spawn_points` VALUES (17855171,0,'Nascent_Sapling','Nascent Sapling',20100,90,99,-174.568,1.540,60.738,224);

-- ---- camp 19 Marjami  90-99  HP=7400 ----
INSERT INTO `mob_groups` VALUES (20100,4996,266,'Whispering_Twitherym',150,0,0,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,4999,266,'Tulfaire',150,0,0,7400,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866758;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866759;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866760;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866761;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866949;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866950;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17866951;
INSERT INTO `mob_spawn_points` VALUES (17867452,0,'Whispering_Twitherym','Whispering Twitherym',20100,90,99,380.300,-59.270,145.730,0);
INSERT INTO `mob_spawn_points` VALUES (17867453,0,'Whispering_Twitherym','Whispering Twitherym',20100,90,99,367.300,-59.270,158.730,64);
INSERT INTO `mob_spawn_points` VALUES (17867454,0,'Whispering_Twitherym','Whispering Twitherym',20100,90,99,354.300,-59.270,145.730,128);
INSERT INTO `mob_spawn_points` VALUES (17867455,0,'Whispering_Twitherym','Whispering Twitherym',20100,90,99,367.300,-59.270,132.730,192);

-- ---- camp 20 Gustaberg S  90-99  HP=7400 ----
INSERT INTO `mob_groups` VALUES (20100,5339,88,'Drachenlizard',150,0,3024,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,3381,88,'Rock_Lizard',150,0,2119,7400,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,2400,88,'Lesser_Wivre',150,0,1515,7400,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17137994;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138017;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138018;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138023;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138024;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138025;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138026;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138027;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138028;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138029;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138030;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138031;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138032;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138033;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=99 WHERE `mobid`=17138034;
INSERT INTO `mob_spawn_points` VALUES (17138411,0,'Drachenlizard','Drachenlizard',20100,90,99,-534.553,39.776,434.598,0);
INSERT INTO `mob_spawn_points` VALUES (17138412,0,'Drachenlizard','Drachenlizard',20100,90,99,-541.053,39.776,445.856,43);
INSERT INTO `mob_spawn_points` VALUES (17138419,0,'Drachenlizard','Drachenlizard',20100,90,99,-554.053,39.776,445.856,85);
INSERT INTO `mob_spawn_points` VALUES (17138424,0,'Drachenlizard','Drachenlizard',20100,90,99,-560.553,39.776,434.598,128);
INSERT INTO `mob_spawn_points` VALUES (17138426,0,'Drachenlizard','Drachenlizard',20100,90,99,-554.053,39.776,423.339,171);
INSERT INTO `mob_spawn_points` VALUES (17138445,0,'Drachenlizard','Drachenlizard',20100,90,99,-541.053,39.776,423.339,213);

-- ---- camp 21 Hennetiel  95-99  HP=7800 ----
INSERT INTO `mob_groups` VALUES (20100,4964,262,'Glutinous_Clot',150,0,0,7800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,4916,262,'Shrouded_Obdella',150,0,0,7800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20102,5095,262,'Hoary_Craklaw',150,0,2973,7800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20103,4967,262,'Velkk_Sage',150,0,2978,7800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20104,4969,262,'Scummy_Slug',150,0,2980,7800,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20105,4968,262,'Velkk_Destructeur',150,0,2979,7800,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850656;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850657;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850658;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850660;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850661;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850662;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850663;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850664;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850665;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850667;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850668;
UPDATE `mob_spawn_points` SET `groupid`=20102, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850669;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850671;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850672;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850673;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850674;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850676;
UPDATE `mob_spawn_points` SET `groupid`=20103, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850677;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850679;
UPDATE `mob_spawn_points` SET `groupid`=20104, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850680;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850681;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850682;
UPDATE `mob_spawn_points` SET `groupid`=20105, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850683;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=95, `maxLevel`=99 WHERE `mobid`=17850712;
INSERT INTO `mob_spawn_points` VALUES (17851068,0,'Glutinous_Clot','Glutinous Clot',20100,95,99,-407.140,-6.170,181.500,0);
INSERT INTO `mob_spawn_points` VALUES (17851069,0,'Glutinous_Clot','Glutinous Clot',20100,95,99,-413.640,-6.170,192.758,43);
INSERT INTO `mob_spawn_points` VALUES (17851070,0,'Glutinous_Clot','Glutinous Clot',20100,95,99,-426.640,-6.170,192.758,85);
INSERT INTO `mob_spawn_points` VALUES (17851071,0,'Glutinous_Clot','Glutinous Clot',20100,95,99,-433.140,-6.170,181.500,128);
INSERT INTO `mob_spawn_points` VALUES (17851072,0,'Glutinous_Clot','Glutinous Clot',20100,95,99,-426.640,-6.170,170.242,171);
INSERT INTO `mob_spawn_points` VALUES (17851073,0,'Glutinous_Clot','Glutinous Clot',20100,95,99,-413.640,-6.170,170.242,213);

-- ---- camp 22 Kamihr  95-99  HP=7800 ----
INSERT INTO `mob_groups` VALUES (20100,4809,267,'Ashen_Tiger',480,0,0,7800,0,0,NULL);
INSERT INTO `mob_spawn_points` VALUES (17871548,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,223.000,20.300,315.000,0);
INSERT INTO `mob_spawn_points` VALUES (17871549,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,219.192,20.300,324.192,32);
INSERT INTO `mob_spawn_points` VALUES (17871550,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,210.000,20.300,328.000,64);
INSERT INTO `mob_spawn_points` VALUES (17871551,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,200.808,20.300,324.192,96);
INSERT INTO `mob_spawn_points` VALUES (17871552,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,197.000,20.300,315.000,128);
INSERT INTO `mob_spawn_points` VALUES (17871553,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,200.808,20.300,305.808,160);
INSERT INTO `mob_spawn_points` VALUES (17871554,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,210.000,20.300,302.000,192);
INSERT INTO `mob_spawn_points` VALUES (17871555,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,219.192,20.300,305.808,224);
INSERT INTO `mob_spawn_points` VALUES (17871556,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,233.000,20.300,315.000,0);
INSERT INTO `mob_spawn_points` VALUES (17871557,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,221.500,20.300,334.919,43);
INSERT INTO `mob_spawn_points` VALUES (17871558,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,198.500,20.300,334.919,85);
INSERT INTO `mob_spawn_points` VALUES (17871559,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,187.000,20.300,315.000,128);
INSERT INTO `mob_spawn_points` VALUES (17871560,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,198.500,20.300,295.081,171);
INSERT INTO `mob_spawn_points` VALUES (17871561,0,'Ashen_Tiger','Ashen Tiger',20100,95,99,221.500,20.300,295.081,213);

