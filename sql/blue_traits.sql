SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Table structure for blue_traits
-- ----------------------------
DROP TABLE IF EXISTS `blue_traits`;
CREATE TABLE `blue_traits` (
  `trait_category` smallint(2) unsigned NOT NULL,
  `trait_points_needed` smallint(2) unsigned NOT NULL,
  `traitid` tinyint(3) unsigned NOT NULL,
  `modifier` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL,
  `tier` tinyint(3) unsigned NOT NULL,
  `job_points_only` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`trait_category`,`trait_points_needed`,`modifier`,`tier`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Trait points use the values displayed by the retail client.  Most spells
-- contribute 4 points, the original level-99 groups contribute 6, and the
-- later level-99 spells contribute 8.
INSERT INTO `blue_traits` VALUES (1,8,32,230,8,1,0);      -- Beast Killer
INSERT INTO `blue_traits` VALUES (2,8,9,370,1,1,0);       -- Auto Regen I
INSERT INTO `blue_traits` VALUES (2,16,9,370,2,2,1);      -- Auto Regen II (JP gift)
INSERT INTO `blue_traits` VALUES (2,24,9,370,3,3,1);      -- Auto Regen III (JP gift)
INSERT INTO `blue_traits` VALUES (3,8,35,227,8,1,0);      -- Lizard Killer
INSERT INTO `blue_traits` VALUES (4,8,24,295,3,1,0);      -- Clear Mind I
INSERT INTO `blue_traits` VALUES (4,16,24,295,6,2,0);     -- Clear Mind II
INSERT INTO `blue_traits` VALUES (4,24,24,295,9,3,0);     -- Clear Mind III
INSERT INTO `blue_traits` VALUES (4,24,24,71,1,3,0);
INSERT INTO `blue_traits` VALUES (4,32,24,295,12,4,0);    -- Clear Mind IV
INSERT INTO `blue_traits` VALUES (4,32,24,71,1,4,0);
INSERT INTO `blue_traits` VALUES (4,40,24,295,15,5,1);    -- Clear Mind V (JP gift)
INSERT INTO `blue_traits` VALUES (4,40,24,71,2,5,1);
INSERT INTO `blue_traits` VALUES (4,48,24,295,18,6,1);    -- Clear Mind VI (JP gift)
INSERT INTO `blue_traits` VALUES (4,48,24,71,3,6,1);
INSERT INTO `blue_traits` VALUES (5,8,48,240,10,1,0);     -- Resist Sleep
INSERT INTO `blue_traits` VALUES (6,8,5,28,20,1,0);       -- Magic Attack Bonus I
INSERT INTO `blue_traits` VALUES (6,16,5,28,24,2,0);
INSERT INTO `blue_traits` VALUES (6,24,5,28,28,3,0);
INSERT INTO `blue_traits` VALUES (6,32,5,28,32,4,0);
INSERT INTO `blue_traits` VALUES (6,40,5,28,36,5,1);
INSERT INTO `blue_traits` VALUES (6,48,5,28,40,6,1);
INSERT INTO `blue_traits` VALUES (7,8,39,231,8,1,0);      -- Undead Killer
INSERT INTO `blue_traits` VALUES (8,8,3,23,10,1,0);       -- Attack Bonus I
INSERT INTO `blue_traits` VALUES (8,8,3,24,10,1,0);
INSERT INTO `blue_traits` VALUES (8,16,3,23,22,2,0);
INSERT INTO `blue_traits` VALUES (8,16,3,24,22,2,0);
INSERT INTO `blue_traits` VALUES (8,24,3,23,35,3,0);
INSERT INTO `blue_traits` VALUES (8,24,3,24,35,3,0);
INSERT INTO `blue_traits` VALUES (8,32,3,23,48,4,0);
INSERT INTO `blue_traits` VALUES (8,32,3,24,48,4,0);
INSERT INTO `blue_traits` VALUES (8,40,3,23,60,5,1);
INSERT INTO `blue_traits` VALUES (8,40,3,24,60,5,1);
INSERT INTO `blue_traits` VALUES (8,48,3,23,72,6,1);
INSERT INTO `blue_traits` VALUES (8,48,3,24,72,6,1);
INSERT INTO `blue_traits` VALUES (9,8,11,359,25,1,0);     -- Rapid Shot
INSERT INTO `blue_traits` VALUES (10,8,8,5,10,1,0);       -- Max MP Boost I
INSERT INTO `blue_traits` VALUES (10,16,8,5,20,2,0);
INSERT INTO `blue_traits` VALUES (10,24,8,5,40,3,1);
INSERT INTO `blue_traits` VALUES (10,32,8,5,60,4,1);
INSERT INTO `blue_traits` VALUES (11,8,4,1,10,1,0);       -- Defense Bonus I
INSERT INTO `blue_traits` VALUES (11,16,4,1,22,2,0);
INSERT INTO `blue_traits` VALUES (11,24,4,1,35,3,0);
INSERT INTO `blue_traits` VALUES (11,32,4,1,48,4,0);
INSERT INTO `blue_traits` VALUES (11,40,4,1,60,5,1);
INSERT INTO `blue_traits` VALUES (11,48,4,1,72,6,1);
INSERT INTO `blue_traits` VALUES (12,8,33,229,8,1,0);     -- Plantoid Killer
INSERT INTO `blue_traits` VALUES (13,8,6,29,10,1,0);      -- Magic Defense Bonus I
INSERT INTO `blue_traits` VALUES (13,16,6,29,12,2,0);
INSERT INTO `blue_traits` VALUES (13,24,6,29,14,3,0);
INSERT INTO `blue_traits` VALUES (13,32,6,29,16,4,1);
INSERT INTO `blue_traits` VALUES (13,40,6,29,18,5,1);
INSERT INTO `blue_traits` VALUES (14,8,10,369,1,1,0);     -- Auto Refresh
INSERT INTO `blue_traits` VALUES (15,8,7,1095,30,1,0);    -- Max HP Boost I
INSERT INTO `blue_traits` VALUES (15,16,7,1095,60,2,0);
INSERT INTO `blue_traits` VALUES (15,24,7,1095,120,3,0);
INSERT INTO `blue_traits` VALUES (15,32,7,1095,180,4,0);
INSERT INTO `blue_traits` VALUES (15,40,7,1095,240,5,1);
INSERT INTO `blue_traits` VALUES (15,48,7,1095,300,6,1);
INSERT INTO `blue_traits` VALUES (16,8,1,25,10,1,0);      -- Accuracy Bonus I
INSERT INTO `blue_traits` VALUES (16,8,1,26,10,1,0);
INSERT INTO `blue_traits` VALUES (16,16,1,25,22,2,0);
INSERT INTO `blue_traits` VALUES (16,16,1,26,22,2,0);
INSERT INTO `blue_traits` VALUES (16,24,1,25,35,3,0);
INSERT INTO `blue_traits` VALUES (16,24,1,26,35,3,0);
INSERT INTO `blue_traits` VALUES (16,32,1,25,48,4,0);
INSERT INTO `blue_traits` VALUES (16,32,1,26,48,4,0);
INSERT INTO `blue_traits` VALUES (16,40,1,25,60,5,1);
INSERT INTO `blue_traits` VALUES (16,40,1,26,60,5,1);
INSERT INTO `blue_traits` VALUES (16,48,1,25,72,6,1);
INSERT INTO `blue_traits` VALUES (16,48,1,26,72,6,1);
INSERT INTO `blue_traits` VALUES (17,8,13,296,25,1,0);    -- Conserve MP I
INSERT INTO `blue_traits` VALUES (17,16,13,296,28,2,0);
INSERT INTO `blue_traits` VALUES (17,24,13,296,31,3,0);
INSERT INTO `blue_traits` VALUES (17,32,13,296,34,4,1);
INSERT INTO `blue_traits` VALUES (17,40,13,296,37,5,1);
INSERT INTO `blue_traits` VALUES (18,8,2,68,10,1,0);      -- Evasion Bonus I
INSERT INTO `blue_traits` VALUES (18,16,2,68,22,2,0);
INSERT INTO `blue_traits` VALUES (18,24,2,68,35,3,0);
INSERT INTO `blue_traits` VALUES (18,32,2,68,48,4,1);
INSERT INTO `blue_traits` VALUES (18,40,2,68,60,5,1);
INSERT INTO `blue_traits` VALUES (19,8,58,249,10,1,0);    -- Resist Gravity
INSERT INTO `blue_traits` VALUES (20,8,14,73,10,1,0);     -- Store TP I
INSERT INTO `blue_traits` VALUES (20,16,14,73,15,2,0);
INSERT INTO `blue_traits` VALUES (20,24,14,73,20,3,0);
INSERT INTO `blue_traits` VALUES (20,32,14,73,25,4,1);
INSERT INTO `blue_traits` VALUES (20,40,14,73,30,5,1);
INSERT INTO `blue_traits` VALUES (21,8,17,291,8,1,0);     -- Counter I
INSERT INTO `blue_traits` VALUES (21,16,17,291,12,2,1);
INSERT INTO `blue_traits` VALUES (21,24,17,291,16,3,1);
INSERT INTO `blue_traits` VALUES (22,8,12,170,5,0,0);     -- Fast Cast 0
INSERT INTO `blue_traits` VALUES (22,16,12,170,10,1,0);
INSERT INTO `blue_traits` VALUES (22,24,12,170,15,2,0);
INSERT INTO `blue_traits` VALUES (22,32,12,170,20,3,1);
INSERT INTO `blue_traits` VALUES (22,40,12,170,25,4,1);
INSERT INTO `blue_traits` VALUES (23,8,106,174,8,1,0);    -- Skillchain Bonus I
INSERT INTO `blue_traits` VALUES (23,16,106,174,12,2,0);
INSERT INTO `blue_traits` VALUES (23,24,106,174,16,3,0);
INSERT INTO `blue_traits` VALUES (23,32,106,174,20,4,1);
INSERT INTO `blue_traits` VALUES (23,40,106,174,23,5,1);
INSERT INTO `blue_traits` VALUES (24,8,15,288,7,0,0);     -- Double Attack
INSERT INTO `blue_traits` VALUES (24,16,16,302,5,1,0);    -- Triple Attack
INSERT INTO `blue_traits` VALUES (25,8,18,259,10,1,0);    -- Dual Wield I
INSERT INTO `blue_traits` VALUES (25,16,18,259,15,2,0);
INSERT INTO `blue_traits` VALUES (25,24,18,259,25,3,0);
INSERT INTO `blue_traits` VALUES (25,32,18,259,30,4,0);
INSERT INTO `blue_traits` VALUES (25,40,18,259,35,5,1);
INSERT INTO `blue_traits` VALUES (25,48,18,259,37,6,1);
INSERT INTO `blue_traits` VALUES (26,8,70,306,15,1,0);    -- Zanshin
INSERT INTO `blue_traits` VALUES (27,8,110,487,5,1,0);    -- Magic Burst Bonus I
INSERT INTO `blue_traits` VALUES (27,16,110,487,7,2,0);
INSERT INTO `blue_traits` VALUES (27,24,110,487,9,3,0);
INSERT INTO `blue_traits` VALUES (27,32,110,487,11,4,1);
INSERT INTO `blue_traits` VALUES (27,40,110,487,13,5,1);
INSERT INTO `blue_traits` VALUES (28,8,20,897,1,1,0);     -- Gilfinder
INSERT INTO `blue_traits` VALUES (28,16,19,303,1,2,0);    -- Treasure Hunter
INSERT INTO `blue_traits` VALUES (29,8,52,244,10,1,0);    -- Resist Silence
INSERT INTO `blue_traits` VALUES (30,8,125,30,10,1,0);    -- Magic Accuracy Bonus I
INSERT INTO `blue_traits` VALUES (30,16,125,30,22,2,1);
INSERT INTO `blue_traits` VALUES (30,24,125,30,35,3,1);
INSERT INTO `blue_traits` VALUES (31,8,126,31,10,1,0);    -- Magic Evasion Bonus I
INSERT INTO `blue_traits` VALUES (31,16,126,31,22,2,1);
INSERT INTO `blue_traits` VALUES (31,24,126,31,35,3,1);
INSERT INTO `blue_traits` VALUES (32,8,98,421,5,1,0);     -- Critical Attack Bonus I
INSERT INTO `blue_traits` VALUES (32,16,98,421,8,2,1);
INSERT INTO `blue_traits` VALUES (32,24,98,421,11,3,1);
INSERT INTO `blue_traits` VALUES (33,8,118,963,5,1,0);    -- Inquartata I
INSERT INTO `blue_traits` VALUES (33,16,118,963,7,2,1);
INSERT INTO `blue_traits` VALUES (33,24,118,963,9,3,1);
INSERT INTO `blue_traits` VALUES (34,8,117,240,5,1,0);    -- Tenacity I
INSERT INTO `blue_traits` VALUES (34,8,117,241,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,242,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,243,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,244,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,245,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,246,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,247,5,1,0);
INSERT INTO `blue_traits` VALUES (34,8,117,248,5,1,0);
INSERT INTO `blue_traits` VALUES (34,16,117,240,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,241,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,242,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,243,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,244,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,245,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,246,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,247,7,2,1);
INSERT INTO `blue_traits` VALUES (34,16,117,248,7,2,1);
INSERT INTO `blue_traits` VALUES (34,24,117,240,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,241,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,242,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,243,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,244,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,245,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,246,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,247,9,3,1);
INSERT INTO `blue_traits` VALUES (34,24,117,248,9,3,1);
