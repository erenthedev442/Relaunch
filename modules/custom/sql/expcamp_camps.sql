-- ============================================================
-- expcamp_camps.sql
-- !expcamp packs: relocate EXISTING in-zone spawn IDs onto
-- isolated groups 20100-20105 so the client DAT already has
-- the right name. No new high-targid inserts (those showed as
-- NPC / Moogle / leftover NM names).
--
-- Idempotent: drop leftover high-targid inserts, restore any
-- previously claimed retail rows to their stock group, then
-- re-apply the camp packs.
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `groupid` BETWEEN 20100 AND 20105
   AND ((`mobid` >> 12) & 0xFFF) IN (25,52,61,79,88,102,103,108,117,123,124,125,126,153,174,197,212,261,262,263,266,267)
   AND (`mobid` & 0xFFF) >= 700;

-- Put leftover mixed-trash claims (targid < 700) back on their
-- stock group so they do not inherit the new camp pool.
UPDATE `mob_spawn_points` AS c
INNER JOIN (
    SELECT `zoneid`, `name`, MIN(`groupid`) AS `stock_gid`
      FROM `mob_groups`
     WHERE `groupid` < 20000
     GROUP BY `zoneid`, `name`
) AS g
   ON g.`zoneid` = ((c.`mobid` >> 12) & 0xFFF)
  AND g.`name` = c.`mobname`
   SET c.`groupid` = g.`stock_gid`
 WHERE c.`groupid` BETWEEN 20100 AND 20105
   AND (c.`mobid` & 0xFFF) < 700;

DELETE FROM `mob_groups`
 WHERE `groupid` BETWEEN 20100 AND 20105
   AND `zoneid` IN (25,52,61,79,88,102,103,108,117,123,124,125,126,153,174,197,212,261,262,263,266,267);

-- ---- camp 1 La Theine  10-25  HP=350  Grass Funguar ----
INSERT INTO `mob_groups` VALUES (20100,1791,102,'Grass_Funguar',150,0,1217,350,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25 WHERE `mobid` IN (17195413,17195412,17195414);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=669.946, `pos_y`=31.626, `pos_z`=108.507, `pos_rot`=0 WHERE `mobid`=17195436;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=668.204, `pos_y`=31.626, `pos_z`=115.007, `pos_rot`=21 WHERE `mobid`=17195423;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=663.446, `pos_y`=31.626, `pos_z`=119.765, `pos_rot`=42 WHERE `mobid`=17195424;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=656.946, `pos_y`=31.626, `pos_z`=121.507, `pos_rot`=64 WHERE `mobid`=17195425;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=650.446, `pos_y`=31.626, `pos_z`=119.765, `pos_rot`=85 WHERE `mobid`=17195434;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=645.688, `pos_y`=31.626, `pos_z`=115.007, `pos_rot`=106 WHERE `mobid`=17195435;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=643.946, `pos_y`=31.626, `pos_z`=108.507, `pos_rot`=128 WHERE `mobid`=17195437;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=645.688, `pos_y`=31.626, `pos_z`=102.007, `pos_rot`=149 WHERE `mobid`=17195446;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=650.446, `pos_y`=31.626, `pos_z`=97.249, `pos_rot`=170 WHERE `mobid`=17195447;

-- ---- camp 2 Konschtat  10-25  HP=350  Mad Sheep ----
INSERT INTO `mob_groups` VALUES (20100,2473,108,'Mad_Sheep',150,0,368,350,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25 WHERE `mobid`=17219983;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-247.546, `pos_y`=67.379, `pos_z`=797.690, `pos_rot`=0 WHERE `mobid`=17219984;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-249.288, `pos_y`=67.379, `pos_z`=804.190, `pos_rot`=21 WHERE `mobid`=17219973;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-254.046, `pos_y`=67.379, `pos_z`=808.948, `pos_rot`=42 WHERE `mobid`=17219963;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-260.546, `pos_y`=67.379, `pos_z`=810.690, `pos_rot`=64 WHERE `mobid`=17219930;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-267.046, `pos_y`=67.379, `pos_z`=808.948, `pos_rot`=85 WHERE `mobid`=17219975;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-271.804, `pos_y`=67.379, `pos_z`=804.190, `pos_rot`=106 WHERE `mobid`=17219974;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-273.546, `pos_y`=67.379, `pos_z`=797.690, `pos_rot`=128 WHERE `mobid`=17219964;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-271.804, `pos_y`=67.379, `pos_z`=791.190, `pos_rot`=149 WHERE `mobid`=17219931;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-267.046, `pos_y`=67.379, `pos_z`=786.432, `pos_rot`=170 WHERE `mobid`=17219932;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-260.546, `pos_y`=67.379, `pos_z`=784.690, `pos_rot`=192 WHERE `mobid`=17219928;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-254.046, `pos_y`=67.379, `pos_z`=786.432, `pos_rot`=213 WHERE `mobid`=17219905;

-- ---- camp 3 Tahrongi  10-25  HP=350  Killer Bee ----
INSERT INTO `mob_groups` VALUES (20100,2228,117,'Killer_Bee',150,0,584,350,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25 WHERE `mobid` IN (17256829,17256828);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-145.254, `pos_y`=32.050, `pos_z`=444.549, `pos_rot`=0 WHERE `mobid`=17256684;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-146.996, `pos_y`=32.050, `pos_z`=451.049, `pos_rot`=21 WHERE `mobid`=17256855;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-151.754, `pos_y`=32.050, `pos_z`=455.807, `pos_rot`=42 WHERE `mobid`=17256848;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-158.254, `pos_y`=32.050, `pos_z`=457.549, `pos_rot`=64 WHERE `mobid`=17256846;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-164.754, `pos_y`=32.050, `pos_z`=455.807, `pos_rot`=85 WHERE `mobid`=17256866;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-169.512, `pos_y`=32.050, `pos_z`=451.049, `pos_rot`=106 WHERE `mobid`=17256847;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-171.254, `pos_y`=32.050, `pos_z`=444.549, `pos_rot`=128 WHERE `mobid`=17256808;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-169.512, `pos_y`=32.050, `pos_z`=438.049, `pos_rot`=149 WHERE `mobid`=17256806;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-164.754, `pos_y`=32.050, `pos_z`=433.291, `pos_rot`=170 WHERE `mobid`=17256807;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=10, `maxLevel`=25, `pos_x`=-158.254, `pos_y`=32.050, `pos_z`=431.549, `pos_rot`=192 WHERE `mobid`=17256626;

-- ---- camp 4 Valkurm  15-30  HP=480  Sand Hare ----
INSERT INTO `mob_groups` VALUES (20100,3455,103,'Sand_Hare',150,0,2150,480,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-725.061, `pos_y`=-6.150, `pos_z`=153.763, `pos_rot`=0 WHERE `mobid`=17199482;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-726.803, `pos_y`=-6.150, `pos_z`=160.263, `pos_rot`=21 WHERE `mobid`=17199484;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-731.561, `pos_y`=-6.150, `pos_z`=165.021, `pos_rot`=42 WHERE `mobid`=17199483;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-738.061, `pos_y`=-6.150, `pos_z`=166.763, `pos_rot`=64 WHERE `mobid`=17199481;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-744.561, `pos_y`=-6.150, `pos_z`=165.021, `pos_rot`=85 WHERE `mobid`=17199493;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-749.319, `pos_y`=-6.150, `pos_z`=160.263, `pos_rot`=106 WHERE `mobid`=17199495;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-751.061, `pos_y`=-6.150, `pos_z`=153.763, `pos_rot`=128 WHERE `mobid`=17199492;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-749.319, `pos_y`=-6.150, `pos_z`=147.263, `pos_rot`=149 WHERE `mobid`=17199494;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-744.561, `pos_y`=-6.150, `pos_z`=142.505, `pos_rot`=170 WHERE `mobid`=17199409;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-738.061, `pos_y`=-6.150, `pos_z`=140.763, `pos_rot`=192 WHERE `mobid`=17199410;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-731.561, `pos_y`=-6.150, `pos_z`=142.505, `pos_rot`=213 WHERE `mobid`=17199411;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=15, `maxLevel`=30, `pos_x`=-726.803, `pos_y`=-6.150, `pos_z`=147.263, `pos_rot`=234 WHERE `mobid`=17199412;

-- ---- camp 5 Qufim  25-40  HP=950  Giant Ranger / Hunter ----
INSERT INTO `mob_groups` VALUES (20100,1536,126,'Giant_Ranger',150,0,964,950,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,1530,126,'Giant_Hunter',150,0,968,950,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40, `pos_x`=244.115, `pos_y`=-19.503, `pos_z`=382.987, `pos_rot`=0 WHERE `mobid`=17293631;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40, `pos_x`=240.014, `pos_y`=-19.503, `pos_z`=392.886, `pos_rot`=32 WHERE `mobid`=17293635;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40, `pos_x`=230.115, `pos_y`=-19.503, `pos_z`=396.987, `pos_rot`=64 WHERE `mobid`=17293632;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=25, `maxLevel`=40, `pos_x`=220.216, `pos_y`=-19.503, `pos_z`=392.886, `pos_rot`=96 WHERE `mobid`=17293636;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40, `pos_x`=216.115, `pos_y`=-19.503, `pos_z`=382.987, `pos_rot`=128 WHERE `mobid`=17293637;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40, `pos_x`=220.216, `pos_y`=-19.503, `pos_z`=373.088, `pos_rot`=160 WHERE `mobid`=17293638;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40, `pos_x`=230.115, `pos_y`=-19.503, `pos_z`=368.987, `pos_rot`=192 WHERE `mobid`=17293634;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=25, `maxLevel`=40, `pos_x`=240.014, `pos_y`=-19.503, `pos_z`=373.088, `pos_rot`=224 WHERE `mobid`=17293633;

-- ---- camp 6 Yuhtunga  30-45  HP=1350  Young Opo-opo ----
INSERT INTO `mob_groups` VALUES (20100,4476,123,'Young_Opo-opo',150,0,2783,1350,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=30, `maxLevel`=45 WHERE `mobid` IN (17281250,17281249,17281253,17281242,17281266,17281244,17281246,17281267,17281247);

-- ---- camp 7 Yhoator  35-50  HP=1800  Worker Crawler ----
INSERT INTO `mob_groups` VALUES (20100,4375,124,'Worker_Crawler',150,0,2022,1800,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=35, `maxLevel`=50 WHERE `mobid` IN (17285467,17285531,17285492,17285469,17285491,17285530,17285497,17285533,17285468,17285504,17285532,17285512);

-- ---- camp 8 Crawler's Nest  45-60  HP=2600  Knight / Soldier Crawler ----
INSERT INTO `mob_groups` VALUES (20100,6318,197,'Knight_Crawler',150,0,1457,2600,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,3697,197,'Soldier_Crawler',150,0,256,2600,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60 WHERE `mobid` IN (17584413,17584412,17584420,17584322,17584421,17584411,17584422);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-205.600, `pos_y`=-0.253, `pos_z`=211.652, `pos_rot`=32 WHERE `mobid`=17584321;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-189.600, `pos_y`=-0.253, `pos_z`=211.652, `pos_rot`=96 WHERE `mobid`=17584323;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-189.600, `pos_y`=-0.253, `pos_z`=195.652, `pos_rot`=160 WHERE `mobid`=17584337;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-197.600, `pos_y`=-0.253, `pos_z`=193.652, `pos_rot`=192 WHERE `mobid`=17584338;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-205.600, `pos_y`=-0.253, `pos_z`=195.652, `pos_rot`=224 WHERE `mobid`=17584335;

-- ---- camp 9 Gustav  45-60  HP=2600  Greater Gaylas / Hell Bat ----
INSERT INTO `mob_groups` VALUES (20100,1804,212,'Greater_Gaylas',150,0,234,2600,0,0,NULL);
INSERT INTO `mob_groups` VALUES (20101,1924,212,'Hell_Bat',150,0,234,2600,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-63.860, `pos_y`=-10.455, `pos_z`=-164.878, `pos_rot`=0 WHERE `mobid`=17645630;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-65.388, `pos_y`=-10.455, `pos_z`=-160.176, `pos_rot`=26 WHERE `mobid`=17645591;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-69.388, `pos_y`=-10.455, `pos_z`=-157.270, `pos_rot`=51 WHERE `mobid`=17645572;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-74.332, `pos_y`=-10.455, `pos_z`=-157.270, `pos_rot`=77 WHERE `mobid`=17645569;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-78.332, `pos_y`=-10.455, `pos_z`=-160.176, `pos_rot`=102 WHERE `mobid`=17645570;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=45, `maxLevel`=60, `pos_x`=-79.860, `pos_y`=-10.455, `pos_z`=-164.878, `pos_rot`=128 WHERE `mobid`=17645629;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-78.332, `pos_y`=-10.455, `pos_z`=-169.580, `pos_rot`=154 WHERE `mobid`=17645618;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-74.332, `pos_y`=-10.455, `pos_z`=-172.486, `pos_rot`=179 WHERE `mobid`=17645617;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-69.388, `pos_y`=-10.455, `pos_z`=-172.486, `pos_rot`=205 WHERE `mobid`=17645619;
UPDATE `mob_spawn_points` SET `groupid`=20101, `minLevel`=45, `maxLevel`=60, `pos_x`=-65.388, `pos_y`=-10.455, `pos_z`=-169.580, `pos_rot`=230 WHERE `mobid`=17645590;

-- ---- camp 10 Kuftal  50-60  HP=2900  Sand Lizard (keep tunnel, pull the ledge one in) ----
INSERT INTO `mob_groups` VALUES (20100,3456,174,'Sand_Lizard',150,0,2153,2900,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid` IN (17490021,17490011,17489929,17490012);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=-10.000, `pos_y`=-20.470, `pos_z`=-220.000, `pos_rot`=32 WHERE `mobid`=17489930;

-- ---- camp 11 W Altepa  50-60  HP=2900  Desert Spider ----
INSERT INTO `mob_groups` VALUES (20100,1009,125,'Desert_Spider',150,0,635,2900,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60 WHERE `mobid` IN (17289242,17289245,17289275,17289244);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=419.042, `pos_y`=0.085, `pos_z`=70.112, `pos_rot`=0 WHERE `mobid`=17289260;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=417.300, `pos_y`=0.085, `pos_z`=76.612, `pos_rot`=21 WHERE `mobid`=17289243;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=412.542, `pos_y`=0.085, `pos_z`=81.370, `pos_rot`=42 WHERE `mobid`=17289274;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=406.042, `pos_y`=0.085, `pos_z`=83.112, `pos_rot`=64 WHERE `mobid`=17289273;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=399.542, `pos_y`=0.085, `pos_z`=81.370, `pos_rot`=85 WHERE `mobid`=17289230;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=394.784, `pos_y`=0.085, `pos_z`=76.612, `pos_rot`=106 WHERE `mobid`=17289229;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=393.042, `pos_y`=0.085, `pos_z`=70.112, `pos_rot`=128 WHERE `mobid`=17289231;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=50, `maxLevel`=60, `pos_x`=394.784, `pos_y`=0.085, `pos_z`=63.612, `pos_rot`=149 WHERE `mobid`=17289235;

-- ---- camp 12 Boyahda  60-75  HP=3900  Skimmer ----
INSERT INTO `mob_groups` VALUES (20100,3649,153,'Skimmer',150,0,571,3900,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75 WHERE `mobid` IN (17404164,17404163,17404173,17404156,17404172,17404157,17404147);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75, `pos_x`=50.472, `pos_y`=-18.236, `pos_z`=-159.364, `pos_rot`=0 WHERE `mobid`=17404135;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75, `pos_x`=47.472, `pos_y`=-18.236, `pos_z`=-152.364, `pos_rot`=42 WHERE `mobid`=17404140;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75, `pos_x`=40.472, `pos_y`=-18.236, `pos_z`=-149.364, `pos_rot`=64 WHERE `mobid`=17404146;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75, `pos_x`=33.472, `pos_y`=-18.236, `pos_z`=-152.364, `pos_rot`=85 WHERE `mobid`=17404137;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=60, `maxLevel`=75, `pos_x`=30.472, `pos_y`=-18.236, `pos_z`=-159.364, `pos_rot`=128 WHERE `mobid`=17404139;

-- ---- camp 13 Bhaflau  75-85  HP=5200  Colibri (keep retail slots) ----
INSERT INTO `mob_groups` VALUES (20100,765,52,'Colibri',150,0,500,5200,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=75, `maxLevel`=85 WHERE `mobid` IN (16990332,16990300,16990331,16990333,16990334,16990335,16990318,16990317,16990316,16990301,16990302,16990303);

-- ---- camp 14 Zhayolm  75-85  HP=5200  Sweeping Cluster lv 84 ----
INSERT INTO `mob_groups` VALUES (20100,3825,61,'Sweeping_Cluster',150,0,2367,5200,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=84, `maxLevel`=84 WHERE `mobid` IN (17027300,17027299,17027301,17027306,17027308,17027316,17027307,17027309,17027314,17027317);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=84, `maxLevel`=84, `pos_x`=608.110, `pos_y`=-23.504, `pos_z`=226.054, `pos_rot`=0 WHERE `mobid`=17027205;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=84, `maxLevel`=84, `pos_x`=582.110, `pos_y`=-23.504, `pos_z`=226.054, `pos_rot`=128 WHERE `mobid`=17027206;

-- ---- camp 15 Misareaux  80-85  HP=5600  Seaboard Vulture lv 86 ----
INSERT INTO `mob_groups` VALUES (20100,6028,25,'Seaboard_Vulture',150,0,43,5600,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=86, `maxLevel`=86 WHERE `mobid` IN (16879714,16879711,16879709,16879712,16879710,16879713,16879718,16879719,16879715,16879716,16879717,16879700);

-- ---- camp 16 Caedarva  80-90  HP=6000  Marsh Murre lv 90 ----
INSERT INTO `mob_groups` VALUES (20100,2580,79,'Marsh_Murre',150,0,1635,6000,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90 WHERE `mobid` IN (17100864,17100857,17100862);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=244.141, `pos_y`=0.500, `pos_z`=-548.079, `pos_rot`=0 WHERE `mobid`=17100850;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=242.399, `pos_y`=0.500, `pos_z`=-541.579, `pos_rot`=21 WHERE `mobid`=17100839;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=237.641, `pos_y`=0.500, `pos_z`=-536.821, `pos_rot`=42 WHERE `mobid`=17100834;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=231.141, `pos_y`=0.500, `pos_z`=-535.079, `pos_rot`=64 WHERE `mobid`=17100963;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=224.641, `pos_y`=0.500, `pos_z`=-536.821, `pos_rot`=85 WHERE `mobid`=17100841;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=219.883, `pos_y`=0.500, `pos_z`=-541.579, `pos_rot`=106 WHERE `mobid`=17100817;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=218.141, `pos_y`=0.500, `pos_z`=-548.079, `pos_rot`=128 WHERE `mobid`=17100818;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=219.883, `pos_y`=0.500, `pos_z`=-554.579, `pos_rot`=149 WHERE `mobid`=17100826;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=90, `maxLevel`=90, `pos_x`=224.641, `pos_y`=0.500, `pos_z`=-559.337, `pos_rot`=170 WHERE `mobid`=17100885;

-- ---- camp 17 Ceizak  85-95  HP=6800  Blanched Mandragora lv 95 ----
INSERT INTO `mob_groups` VALUES (20100,5001,261,'Blanched_Mandragora',150,0,2956,6800,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=95, `maxLevel`=95 WHERE `mobid` IN (17846288,17846290,17846287,17846289,17846285,17846286,17846301,17846303,17846302,17846304,17846305,17846306);

-- ---- camp 18 Yorcia  90-99  HP=8500  Corpse Flower lv 105 ----
INSERT INTO `mob_groups` VALUES (20100,4938,263,'Corpse_Flower',150,0,0,8500,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105 WHERE `mobid` IN (17854500,17854501,17854502,17854503,17854504);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=414.388, `pos_y`=0.000, `pos_z`=446.199, `pos_rot`=0 WHERE `mobid`=17854481;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=413.388, `pos_y`=0.000, `pos_z`=452.199, `pos_rot`=13 WHERE `mobid`=17854482;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=410.388, `pos_y`=0.000, `pos_z`=457.199, `pos_rot`=26 WHERE `mobid`=17854483;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=406.388, `pos_y`=0.000, `pos_z`=460.199, `pos_rot`=38 WHERE `mobid`=17854490;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=398.388, `pos_y`=0.000, `pos_z`=462.199, `pos_rot`=64 WHERE `mobid`=17854491;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=390.388, `pos_y`=0.000, `pos_z`=460.199, `pos_rot`=90 WHERE `mobid`=17854495;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=386.388, `pos_y`=0.000, `pos_z`=457.199, `pos_rot`=102 WHERE `mobid`=17854496;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=382.388, `pos_y`=0.000, `pos_z`=446.199, `pos_rot`=128 WHERE `mobid`=17854505;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=386.388, `pos_y`=0.000, `pos_z`=435.199, `pos_rot`=154 WHERE `mobid`=17854506;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=390.388, `pos_y`=0.000, `pos_z`=432.199, `pos_rot`=166 WHERE `mobid`=17854516;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=398.388, `pos_y`=0.000, `pos_z`=430.199, `pos_rot`=192 WHERE `mobid`=17854530;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=406.388, `pos_y`=0.000, `pos_z`=432.199, `pos_rot`=218 WHERE `mobid`=17854623;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=410.388, `pos_y`=0.000, `pos_z`=435.199, `pos_rot`=230 WHERE `mobid`=17854680;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=413.388, `pos_y`=0.000, `pos_z`=440.199, `pos_rot`=243 WHERE `mobid`=17854681;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=414.388, `pos_y`=0.000, `pos_z`=452.199, `pos_rot`=6 WHERE `mobid`=17854750;

-- ---- camp 19 Marjami  90-99  HP=8500  Whispering Twitherym lv 105 ----
INSERT INTO `mob_groups` VALUES (20100,4996,266,'Whispering_Twitherym',150,0,0,8500,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=384.920, `pos_y`=-59.093, `pos_z`=141.016, `pos_rot`=0 WHERE `mobid`=17866758;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=383.920, `pos_y`=-59.093, `pos_z`=147.016, `pos_rot`=13 WHERE `mobid`=17866759;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=380.920, `pos_y`=-59.093, `pos_z`=152.016, `pos_rot`=26 WHERE `mobid`=17866760;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=376.920, `pos_y`=-59.093, `pos_z`=155.016, `pos_rot`=38 WHERE `mobid`=17866761;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=368.920, `pos_y`=-59.093, `pos_z`=157.016, `pos_rot`=64 WHERE `mobid`=17866762;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=360.920, `pos_y`=-59.093, `pos_z`=155.016, `pos_rot`=90 WHERE `mobid`=17866763;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=356.920, `pos_y`=-59.093, `pos_z`=152.016, `pos_rot`=102 WHERE `mobid`=17866764;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=352.920, `pos_y`=-59.093, `pos_z`=141.016, `pos_rot`=128 WHERE `mobid`=17866767;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=356.920, `pos_y`=-59.093, `pos_z`=130.016, `pos_rot`=154 WHERE `mobid`=17866768;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=360.920, `pos_y`=-59.093, `pos_z`=127.016, `pos_rot`=166 WHERE `mobid`=17866769;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=368.920, `pos_y`=-59.093, `pos_z`=125.016, `pos_rot`=192 WHERE `mobid`=17866771;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=376.920, `pos_y`=-59.093, `pos_z`=127.016, `pos_rot`=218 WHERE `mobid`=17866772;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=380.920, `pos_y`=-59.093, `pos_z`=130.016, `pos_rot`=230 WHERE `mobid`=17866773;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=384.920, `pos_y`=-59.093, `pos_z`=135.016, `pos_rot`=243 WHERE `mobid`=17866861;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=372.920, `pos_y`=-59.093, `pos_z`=149.016, `pos_rot`=38 WHERE `mobid`=17866862;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=364.920, `pos_y`=-59.093, `pos_z`=149.016, `pos_rot`=77 WHERE `mobid`=17866863;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=360.920, `pos_y`=-59.093, `pos_z`=141.016, `pos_rot`=128 WHERE `mobid`=17866864;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=364.920, `pos_y`=-59.093, `pos_z`=133.016, `pos_rot`=166 WHERE `mobid`=17866865;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=372.920, `pos_y`=-59.093, `pos_z`=133.016, `pos_rot`=205 WHERE `mobid`=17866949;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=376.920, `pos_y`=-59.093, `pos_z`=141.016, `pos_rot`=230 WHERE `mobid`=17866950;

-- ---- camp 20 Gustaberg [S]  90-99  HP=8500  Drachenlizard lv 105 ----
INSERT INTO `mob_groups` VALUES (20100,5339,88,'Drachenlizard',150,0,3024,8500,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105 WHERE `mobid` IN (17138034,17138033,17138028,17138029,17138030,17138032,17138031,17138027,17138026,17138025,17138024,17137994,17138023);

-- ---- camp 21 Hennetiel  95-99  HP=8500  Scummy Slug lv 105 ----
INSERT INTO `mob_groups` VALUES (20100,4969,262,'Scummy_Slug',150,0,2980,8500,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105 WHERE `mobid` IN (17850491,17850484,17850489,17850482,17850490,17850483,17850488,17850487,17850486,17850692,17850493,17850494,17850495,17850496,17850498);

-- ---- camp 22 Kamihr  95-99  HP=8500  Ashen Tiger lv 105 ----
-- Spawn along the path between the warp and 167.98, 21.66, 314.68
INSERT INTO `mob_groups` VALUES (20100,4809,267,'Ashen_Tiger',150,0,0,8500,0,0,NULL);
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=210.000, `pos_y`=20.300, `pos_z`=315.000, `pos_rot`=128 WHERE `mobid`=17871008;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=206.180, `pos_y`=20.423, `pos_z`=314.971, `pos_rot`=128 WHERE `mobid`=17871009;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=202.360, `pos_y`=20.546, `pos_z`=314.942, `pos_rot`=128 WHERE `mobid`=17871010;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=198.540, `pos_y`=20.670, `pos_z`=314.913, `pos_rot`=128 WHERE `mobid`=17871020;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=194.720, `pos_y`=20.793, `pos_z`=314.884, `pos_rot`=128 WHERE `mobid`=17871019;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=190.900, `pos_y`=20.916, `pos_z`=314.855, `pos_rot`=128 WHERE `mobid`=17871021;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=187.080, `pos_y`=21.039, `pos_z`=314.825, `pos_rot`=128 WHERE `mobid`=17871013;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=183.260, `pos_y`=21.162, `pos_z`=314.796, `pos_rot`=128 WHERE `mobid`=17871014;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=179.440, `pos_y`=21.285, `pos_z`=314.767, `pos_rot`=128 WHERE `mobid`=17871023;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=175.620, `pos_y`=21.409, `pos_z`=314.738, `pos_rot`=128 WHERE `mobid`=17871024;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=171.800, `pos_y`=21.532, `pos_z`=314.709, `pos_rot`=128 WHERE `mobid`=17870997;
UPDATE `mob_spawn_points` SET `groupid`=20100, `minLevel`=105, `maxLevel`=105, `pos_x`=167.977, `pos_y`=21.655, `pos_z`=314.680, `pos_rot`=128 WHERE `mobid`=17870998;
