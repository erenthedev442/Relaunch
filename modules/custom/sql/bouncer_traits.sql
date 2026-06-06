-- ============================================================================
-- bouncer_traits.sql   (Phase 4 of the custom "Bouncer" tank job)
--
-- Layers the Bouncer's innate DEFENSIVE / ENMITY / SUSTAIN / RETALIATION job
-- traits onto the GEO (job 21) slot.  See documentation/custom_tank_job_design.md.
--
-- Apply AFTER Phase 2 (bouncer_strip_geo.sql), which left job=21 holding only
-- the Phase-1 HP trait (traitid 7).  This file ADDS new traitids; it never
-- touches traitid 7, so the Phase-1 HP chassis is preserved.
--
-- HOW TRAITS STACK (verified against src/map/utils/battleutils.cpp::AddTraits):
--   The engine de-dupes only WITHIN a traitid (keeps the highest qualifying
--   rank).  Across DIFFERENT traitids, every trait's modifier is added -- so
--   two different traitids sharing one modifier STACK additively.
--
--   *** This corrects a Phase-1 oversight. ***  MNK is HP-grade A like the
--   Bouncer, and was assumed to "top out at 280 flat HP" (traitid 7).  But MNK
--   ALSO carries traitid 135 "max hp boost II" (+450 at L95) which STACKS:
--   MNK's real trait HP is 280 + 450 = 730 at cap.  Phase 1 gave the Bouncer
--   only traitid 7 (peak 480) -- LESS than MNK.  Section 1 below fixes this by
--   giving the Bouncer its own "max hp boost II" line, so combined trait HP is
--   510 / 720 / 930 at L75 / L85 / L95 -- decisively above MNK at every tier
--   (and the Phase-1 traitid 7 line already beats MNK below L75).  This honours
--   the locked design rule "HP higher than MNK".
--
-- Mod ids (from scripts/enum/mod.lua): DEF=1, ENMITY=27, MDEF=29, DMGPHYS=161,
--   COUNTER=291, REGEN=370, RESIST_SLEEP=240, CRIT_DEF=908, MAX_HP(flat)=1095.
-- DMGPHYS is a /10000 multiplier on physical damage taken (resist = 1 + v/10000,
--   battleutils.cpp:4706); NEGATIVE reduces damage, caps at -50% (-5000).
--
-- traitids 139 ("enmity boost") and 140 ("phys. dmg. taken down") are NEW: no
-- canonical trait carries ENMITY or a generic phys-DT reduction.  Both are <=143
-- so they fit the client's 18-byte (144-bit) trait mask (bit 138 already in use).
-- Their MOD effects apply server-side now; their client trait-menu LABELS are
-- cosmetic and arrive with the Phase 6 DAT pack (until then the whole job reads
-- as "GEO" client-side anyway).
--
-- All Bouncer traits use content_tag NULL = always active (no expansion gate).
--
-- This is data-only: no recompile.  A map-server restart reloads the changes.
--
-- Apply once against the live database:
--   "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/bouncer_traits.sql
--
-- Idempotent: each section DELETEs its own (job=21, traitid) rows then re-INSERTs
-- them, so re-applying is deterministic.  ALL VALUES ARE STARTING POINTS for the
-- Phase 7 balance pass.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. HP king fix: "max hp boost II" (traitid 135, mod 1095) -- STACKS on the
--    Phase-1 traitid 7 line.  Combined Bouncer trait HP: 510/720/930 at
--    L75/85/95 vs MNK's 430/580/730.  (Mirrors MNK's own II tiers 150/300/450.)
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 135;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (135, 'max hp boost II', 21, 75, 1, 1095, 150, NULL, 0),
    (135, 'max hp boost II', 21, 85, 2, 1095, 300, NULL, 0),
    (135, 'max hp boost II', 21, 95, 3, 1095, 450, NULL, 0);


-- ----------------------------------------------------------------------------
-- 2. Defense bonus (traitid 4, mod 1 = flat DEF).  Mirrors PLD's line; the
--    Bouncer has no shield, so raw DEF + HP + reflect carry its mitigation.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 4;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (4, 'defense bonus', 21, 10, 1, 1, 10, NULL, 0),
    (4, 'defense bonus', 21, 30, 2, 1, 22, NULL, 0),
    (4, 'defense bonus', 21, 50, 3, 1, 35, NULL, 0),
    (4, 'defense bonus', 21, 70, 4, 1, 48, NULL, 0),
    (4, 'defense bonus', 21, 85, 5, 1, 60, NULL, 0),
    (4, 'defense bonus', 21, 95, 6, 1, 72, NULL, 0);


-- ----------------------------------------------------------------------------
-- 3. Magic def. bonus (traitid 6, mod 29 = MDEF).  Mirrors RUN -- a tank must
--    survive magic too.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 6;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (6, 'magic def. bonus', 21, 10, 1, 29, 10, NULL, 0),
    (6, 'magic def. bonus', 21, 30, 2, 29, 12, NULL, 0),
    (6, 'magic def. bonus', 21, 50, 3, 29, 14, NULL, 0),
    (6, 'magic def. bonus', 21, 70, 4, 29, 16, NULL, 0),
    (6, 'magic def. bonus', 21, 76, 5, 29, 18, NULL, 0),
    (6, 'magic def. bonus', 21, 91, 6, 29, 20, NULL, 0),
    (6, 'magic def. bonus', 21, 99, 7, 29, 22, NULL, 0);


-- ----------------------------------------------------------------------------
-- 4. Counter (traitid 17, mod 291).  The "active retaliation" signature in
--    trait form -- the Bouncer swings back when struck in melee.  Mirrors MNK.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 17;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (17, 'counter', 21, 10, 1, 291, 10, NULL, 0),
    (17, 'counter', 21, 81, 2, 291, 12, NULL, 0);


-- ----------------------------------------------------------------------------
-- 5. Enmity boost (traitid 139 NEW, mod 27 = ENMITY).  The defining trait of an
--    enmity tank: every action holds more hate.  Modest, progressive.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 139;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (139, 'enmity boost', 21, 15, 1, 27,  3, NULL, 0),
    (139, 'enmity boost', 21, 35, 2, 27,  5, NULL, 0),
    (139, 'enmity boost', 21, 55, 3, 27,  7, NULL, 0),
    (139, 'enmity boost', 21, 75, 4, 27, 10, NULL, 0),
    (139, 'enmity boost', 21, 95, 5, 27, 12, NULL, 0);


-- ----------------------------------------------------------------------------
-- 6. Physical damage taken down (traitid 140 NEW, mod 161 = DMGPHYS).
--    NEGATIVE /10000 values reduce phys damage taken (-1000 = -10%); caps -50%.
--    Premier-tank innate mitigation.  *** Primary Phase-7 tuning knob. ***
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 140;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (140, 'phys. dmg. taken down', 21, 30, 1, 161,  -300, NULL, 0),  -- -3%
    (140, 'phys. dmg. taken down', 21, 55, 2, 161,  -500, NULL, 0),  -- -5%
    (140, 'phys. dmg. taken down', 21, 80, 3, 161,  -800, NULL, 0),  -- -8%
    (140, 'phys. dmg. taken down', 21, 95, 4, 161, -1000, NULL, 0);  -- -10%


-- ----------------------------------------------------------------------------
-- 7. Crit. def. bonus (traitid 99, mod 908).  Reduces critical-hit damage taken
--    at high level.  Mirrors PLD.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 99;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (99, 'crit. def. bonus', 21, 79, 1, 908,  5, NULL, 0),
    (99, 'crit. def. bonus', 21, 85, 2, 908,  8, NULL, 0),
    (99, 'crit. def. bonus', 21, 91, 3, 908, 11, NULL, 0),
    (99, 'crit. def. bonus', 21, 96, 4, 908, 14, NULL, 0);


-- ----------------------------------------------------------------------------
-- 8. Resist sleep (traitid 48, mod 240).  A slept tank is a dead party.
--    Mirrors PLD.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 48;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (48, 'resist sleep', 21, 20, 1, 240, 10, NULL, 0),
    (48, 'resist sleep', 21, 40, 2, 240, 15, NULL, 0),
    (48, 'resist sleep', 21, 60, 3, 240, 20, NULL, 0),
    (48, 'resist sleep', 21, 80, 4, 240, 25, NULL, 0),
    (48, 'resist sleep', 21, 95, 5, 240, 30, NULL, 0);


-- ----------------------------------------------------------------------------
-- 9. Auto Regen (traitid 9, mod 370).  Passive self-sustain -- complements the
--    leech theme.  Mirrors RUN.
-- ----------------------------------------------------------------------------
DELETE FROM `traits` WHERE `job` = 21 AND `traitid` = 9;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
    (9, 'auto regen', 21, 35, 1, 370, 1, NULL, 0),
    (9, 'auto regen', 21, 65, 2, 370, 2, NULL, 0),
    (9, 'auto regen', 21, 95, 3, 370, 3, NULL, 0);


-- ============================================================================
-- REVERSE (manual rollback -- removes every Phase-4 trait; leaves Phase-1's
-- traitid 7 HP chassis intact):
--
--   DELETE FROM `traits` WHERE `job` = 21 AND `traitid` IN (4,6,9,17,48,99,135,139,140);
-- ============================================================================
