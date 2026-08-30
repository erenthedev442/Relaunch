-- ============================================================================
-- blu_spells.sql
--
-- Adds 23 Blue Mage spells (level 99, SOA era) to spell_list that were
-- missing from the live DB:
--
--   20 NEW (scripts in Calvin, not on server at all):
--     715 molting_plumage   716 nectarous_deluge  717 sweeping_gouge
--     719 searing_tempest   720 spectral_floe      721 anvil_lightning
--     722 entomb             723 saurian_slide      724 palling_salvo
--     725 blinding_fulgor   726 scouring_spate     727 silent_storm
--     728 tenebral_crush    747 uproot              748 crashing_thunder
--     749 polar_roar        750 mighty_guard        751 cruel_joke
--     752 cesspool          753 tearing_gust
--
--   3 STUBS that existed on server but had commented-out DB entries:
--     744 droning_whirlwind  745 carcharian_verve   746 blistering_roar
--
-- Spell scripts live in:
--   scripts/actions/spells/blue/<name>.lua   (copied from Calvin)
--
-- For an existing database, apply this spell overlay and the canonical trait
-- migration together, then perform a full map rebuild/restart:
--   mysql -u root xidb < modules/custom/sql/blu_spells.sql
--   mysql -u root xidb < modules/custom/sql/blu_trait_correctness.sql
--
-- Safe to re-apply; the upsert repairs stale rows in existing databases.
-- ============================================================================

SET @ELEMENT_NONE   = 0;
SET @ELEMENT_FIRE   = 1;
SET @ELEMENT_ICE    = 2;
SET @ELEMENT_WIND   = 3;
SET @ELEMENT_EARTH  = 4;
SET @ELEMENT_THUNDER= 5;
SET @ELEMENT_WATER  = 6;
SET @ELEMENT_LIGHT  = 7;
SET @ELEMENT_DARK   = 8;
SET @SKILL_BLUE     = 43;

-- Jobs bitmask (BINARY 22): byte 15 = BLU minimum level.
-- 0x63 = 99.  All spells here are BLU-only at level 99.
-- 0x00000000000000000000000000000063000000000000

-- Column order:
--   spellid, name, jobs, group, family, element, zonemisc,
--   validTargets, skill, mpCost, castTime(ms), recastTime(ms),
--   message, magicBurstMessage,
--   animation, animationTime,
--   AOE, base, multiplier, CE, VE,
--   requirements, spell_range, radius, content_tag
--
-- validTargets: 4 = enemy, 1 = self
-- requirements: 0 = none, 16 = Unbridled Learning
-- AOE:          0 = single-target, 1 = area-of-effect
-- message:      2 = damage taken, 230 = self enchantment
-- SOA BLU animations borrow existing TOAU/Abyssea BLU looks. This client has
-- no Seekers spell DATs at 915-937 (921 Trust spawn, 922 Trust dismiss, 929
-- Haste II, 930 Geo-ish, 933 Warp).

INSERT INTO `spell_list`
    (`spellid`, `name`, `jobs`,
     `group`, `family`, `element`, `zonemisc`,
     `validTargets`, `skill`,
     `mpCost`, `castTime`, `recastTime`,
     `message`, `magicBurstMessage`,
     `animation`, `animationTime`,
     `AOE`, `base`, `multiplier`,
     `CE`, `VE`, `requirements`,
     `spell_range`, `radius`, `content_tag`)
VALUES
-- ---- 715-728: SOA batch 1 ------------------------------------------------
(715, 'molting_plumage',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WIND, 0, 4, @SKILL_BLUE,
 146, 1000, 25000, 2, 0, 695, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Mysterious Light

(716, 'nectarous_deluge',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WATER, 0, 4, @SKILL_BLUE,
 97, 3000, 45000, 2, 0, 690, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Maelstrom

(717, 'sweeping_gouge',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_NONE, 0, 4, @SKILL_BLUE,
 29, 500, 120000, 2, 0, 698, 2000, 0, 0, 1.00, 0, 0, 0, 30, 0, 'SOA'), -- Sickle Slash

(719, 'searing_tempest',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_FIRE, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 673, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Self-Destruct

(720, 'spectral_floe',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_ICE, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 721, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Ice Break

(721, 'anvil_lightning',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_THUNDER, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 697, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Blitzstrahl

(722, 'entomb',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_EARTH, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 631, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Sandspin

(723, 'saurian_slide',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_NONE, 0, 4, @SKILL_BLUE,
 109, 500, 35000, 2, 0, 692, 2000, 0, 0, 1.00, 0, 0, 0, 30, 0, 'SOA'), -- Uppercut

(724, 'palling_salvo',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_DARK, 0, 4, @SKILL_BLUE,
 175, 2000, 45000, 2, 0, 704, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Eyes On Me

(725, 'blinding_fulgor',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_LIGHT, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 741, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Actinic Burst

(726, 'scouring_spate',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WATER, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 690, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Maelstrom

(727, 'silent_storm',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WIND, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 695, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Mysterious Light

(728, 'tenebral_crush',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_DARK, 0, 4, @SKILL_BLUE,
 116, 5000, 60000, 2, 0, 661, 2000, 1, 0, 1.00, 0, 0, 0, 100, 100, 'SOA'), -- Blood Saber

-- ---- 744-746: previously commented-out stubs ------------------------------
(744, 'droning_whirlwind',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WIND, 0, 4, @SKILL_BLUE,
 224, 1500, 22000, 2, 0, 695, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- Mysterious Light

(745, 'carcharian_verve',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WATER, 0, 1, @SKILL_BLUE,
 65, 2000, 60000, 230, 0, 737, 2000, 0, 0, 1.00, 0, 0, 16, 0, 0, 'SOA'), -- Saline Coat

(746, 'blistering_roar',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_DARK, 0, 4, @SKILL_BLUE,
 43, 500, 120000, 2, 0, 703, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- Geist Wall

-- ---- 747-753: SOA batch 2 ------------------------------------------------
(747, 'uproot',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_LIGHT, 0, 4, @SKILL_BLUE,
 88, 3000, 30000, 2, 0, 724, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- 1000 Needles

(748, 'crashing_thunder',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_THUNDER, 0, 4, @SKILL_BLUE,
 172, 3000, 30000, 2, 0, 697, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- Blitzstrahl

(749, 'polar_roar',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_ICE, 0, 4, @SKILL_BLUE,
 126, 3000, 30000, 2, 0, 688, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- Frost Breath

(750, 'mighty_guard',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_LIGHT, 0, 1, @SKILL_BLUE,
 299, 3500, 30000, 230, 0, 654, 2000, 0, 0, 1.00, 0, 0, 16, 0, 0, 'SOA'), -- Cocoon

(751, 'cruel_joke',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_DARK, 0, 4, @SKILL_BLUE,
 187, 3000, 30000, 2, 0, 682, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- Soporific

(752, 'cesspool',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WATER, 0, 4, @SKILL_BLUE,
 166, 3000, 30000, 2, 0, 685, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA'), -- Cursed Sphere

(753, 'tearing_gust',
 0x00000000000000000000000000000063000000000000,
 3, 0, @ELEMENT_WIND, 0, 4, @SKILL_BLUE,
 202, 3000, 30000, 2, 0, 732, 2000, 1, 0, 1.00, 0, 0, 16, 100, 100, 'SOA') -- Hecatomb Wave
ON DUPLICATE KEY UPDATE
    `name`              = VALUES(`name`),
    `jobs`              = VALUES(`jobs`),
    `group`             = VALUES(`group`),
    `family`            = VALUES(`family`),
    `element`           = VALUES(`element`),
    `zonemisc`          = VALUES(`zonemisc`),
    `validTargets`      = VALUES(`validTargets`),
    `skill`             = VALUES(`skill`),
    `mpCost`            = VALUES(`mpCost`),
    `castTime`          = VALUES(`castTime`),
    `recastTime`        = VALUES(`recastTime`),
    `message`           = VALUES(`message`),
    `magicBurstMessage` = VALUES(`magicBurstMessage`),
    `animation`         = VALUES(`animation`),
    `animationTime`     = VALUES(`animationTime`),
    `AOE`               = VALUES(`AOE`),
    `base`              = VALUES(`base`),
    `multiplier`        = VALUES(`multiplier`),
    `CE`                = VALUES(`CE`),
    `VE`                = VALUES(`VE`),
    `requirements`      = VALUES(`requirements`),
    `spell_range`       = VALUES(`spell_range`),
    `radius`            = VALUES(`radius`),
    `content_tag`       = VALUES(`content_tag`);

DELETE FROM `blue_spell_list`
WHERE `spellid` IN
(
    715, 716, 717, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728,
    744, 745, 746, 747, 748, 749, 750, 751, 752, 753
);

INSERT INTO `blue_spell_list`
    (`spellid`, `mob_skill_id`, `set_points`, `trait_category`,
     `trait_category_weight`, `primary_sc`, `secondary_sc`, `tertiary_sc`,
     `knockback`)
VALUES
    (715, 3063, 6, 25, 8, 0, 0, 0, NULL),
    (716, 3099, 6, 1, 8, 0, 0, 0, NULL),
    (717, 3931, 6, 3, 8, 0, 0, 0, NULL),
    (719, 2735, 8, 8, 8, 0, 0, 0, NULL),
    (720, 2737, 8, 6, 8, 0, 0, 0, NULL),
    (721, 2739, 8, 16, 8, 0, 0, 0, NULL),
    (722, 2741, 8, 11, 8, 0, 0, 0, NULL),
    (723, 2991, 7, 33, 8, 0, 0, 0, NULL),
    (724, 3153, 7, 34, 8, 0, 0, 0, NULL),
    (725, 2736, 8, 31, 8, 0, 0, 0, NULL),
    (726, 2738, 8, 13, 8, 0, 0, 0, NULL),
    (727, 2740, 8, 18, 8, 0, 0, 0, NULL),
    (728, 2742, 8, 30, 8, 0, 0, 0, NULL),
    (744, 3005, 0, 0, 0, 0, 0, 0, NULL),
    (745, 3014, 0, 0, 0, 0, 0, 0, NULL),
    (746, 3020, 0, 0, 0, 0, 0, 0, NULL),
    (747, 3059, 0, 0, 0, 0, 0, 0, NULL),
    (748, 3072, 0, 0, 0, 0, 0, 0, NULL),
    (749, 3137, 0, 0, 0, 0, 0, 0, NULL),
    (750, 2667, 0, 0, 0, 0, 0, 0, NULL),
    (751, 3304, 0, 0, 0, 0, 0, 0, NULL),
    (752, 3372, 0, 0, 0, 0, 0, 0, NULL),
    (753, 3363, 0, 0, 0, 0, 0, 0, NULL);

DELETE FROM `blue_spell_mods`
WHERE `spellId` IN
(
    715, 716, 717, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728,
    744, 745, 746, 747, 748, 749, 750, 751, 752, 753
);

INSERT INTO `blue_spell_mods` (`spellId`, `modid`, `value`)
VALUES
    (715, 11, 8),
    (716, 13, 2),
    (717, 10, 2),
    (719, 8, 4),
    (720, 12, 4),
    (721, 5, 30),
    (721, 9, 8),
    (722, 5, 30),
    (722, 10, 8),
    (723, 2, 50),
    (723, 10, 6),
    (723, 12, -3),
    (724, 11, 4),
    (725, 2, 40),
    (725, 8, 4),
    (725, 9, 4),
    (725, 11, 4),
    (726, 5, 30),
    (726, 13, 8),
    (727, 11, 4),
    (728, 5, 30),
    (728, 10, 4),
    (728, 12, 4),
    (728, 13, 4);
