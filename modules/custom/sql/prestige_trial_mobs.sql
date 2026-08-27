-- ============================================================================
-- prestige_trial_mobs.sql  --  The Ascension Trial Courts (5 difficulty tiers)
-- ----------------------------------------------------------------------------
-- Registers every Ascension Trial boss so the Ascension Altar in Provenance
-- (zone 222) can summon them via insertDynamicEntity. The Altar pops them on
-- demand (menu "Face the Trial"), so -- exactly like the Hunting League NMs --
-- NO mob_spawn_points rows are needed, only mob_groups.
--
-- The Trial roster CHANGES with the prestige level of the job you are ascending,
-- in brackets of 10 (cfg.trialScaling.tiers in prestige_catalog.lua). Each tier
-- is a distinct "Court" of three Ascension-EXCLUSIVE bosses, so you are NOT
-- fighting the same three forever:
--   Tier 0  P.Lv 0-9    The Nightmare Court  : Diabolos / Medusa / Odin
--   Tier 1  P.Lv 10-19  The Voidwalkers      : Sarameya / Kaggen / Qilin
--   Tier 2  P.Lv 20-29  The Jailers          : Jailer of Justice / Fortitude / Temperance
--   Tier 3  P.Lv 30-39  The Voidwalker Lords : Kreutzet / Raja / Maere
--   Tier 4  P.Lv 40+    The World's End      : Omega / Ultima / Provenance Watcher
--
-- Picked to NOT collide with NMs your other custom systems use (Hunting League,
-- Hunters Guild, reforge NMs, GM-master arena). Provenance Watcher is native to
-- zone 222, a fitting apex for a trial held in Provenance itself.
--
-- These reuse stock model + skill-kit data. Pools whose retail flags can hide
-- dynamic entities are cloned below into Ascension-only pool IDs with
-- FLAG_HIDE_NAME/FLAG_HIDE_MODEL/FLAG_HIDE_HP cleared. This avoids changing
-- retail encounters.
-- spawntype 128 = SPAWNTYPE_SCRIPTED (script-popped, no timer). dropid 0 = no
-- loot (the reward is Trial progress, not items). The HP column is BASE health;
-- each boss's catalog `hpBoost` multiplies it at spawn.
--
-- Per-boss stats (level 150, mods, hpBoost, cry) live in prestige_catalog.lua
-- under trialBosses (tier 0) and trialScaling.tiers[N].roster.bosses (tier 1-4).
-- A boss's catalog `name` MUST match its mob_groups.name below.
--
-- Idempotent + scoped to groupIds 11370-11395 at zoneid 222 -- safe to re-run.
-- Apply (live Azure server): just run "Azure - Deploy to Server.bat" -- it
-- auto-applies any changed modules/custom/sql/*.sql and restarts xi_map for you.
-- (Manual equivalent on the box: sudo mariadb xidb < this-file, then
--  sudo systemctl restart xi_map. mob_groups are read at map-server boot.)
-- ============================================================================

-- Restore the eleven retail boss appearances that previously used avatar
-- stand-ins. Clone rather than UPDATE the shared retail pools: visibility flags
-- are safe for Provenance dynamic entities while retail behavior stays intact.
DELETE FROM `mob_pools` WHERE `poolid` BETWEEN 30100 AND 30110;
CREATE TEMPORARY TABLE `_prestige_retail_pools` AS
SELECT *
FROM `mob_pools`
WHERE `poolid` IN
(
    3465, -- Sarameya
    4694, -- Kaggen
    4716, -- Qilin
    2133, -- Jailer of Justice
    2131, -- Jailer of Fortitude
    2136, -- Jailer of Temperance
    2287, -- Kreutzet
    3313, -- Raja
    2474, -- Maere
    2973, -- Omega
    4083  -- Ultima
);

UPDATE `_prestige_retail_pools`
SET `poolid` =
    CASE `poolid`
        WHEN 3465 THEN 30100
        WHEN 4694 THEN 30101
        WHEN 4716 THEN 30102
        WHEN 2133 THEN 30103
        WHEN 2131 THEN 30104
        WHEN 2136 THEN 30105
        WHEN 2287 THEN 30106
        WHEN 3313 THEN 30107
        WHEN 2474 THEN 30108
        WHEN 2973 THEN 30109
        WHEN 4083 THEN 30110
    END,
    `entityFlags` = `entityFlags` & ~0x188,
    `namevis` = 1;

INSERT INTO `mob_pools` SELECT * FROM `_prestige_retail_pools`;
DROP TEMPORARY TABLE `_prestige_retail_pools`;

DELETE FROM `mob_groups`
 WHERE `groupid` BETWEEN 11370 AND 11395
   AND `zoneid` = 222;

INSERT INTO `mob_groups`
    (`groupid`, `poolid`, `zoneid`, `name`, `respawntime`, `spawntype`, `dropid`, `HP`, `MP`, `allegiance`, `content_tag`)
VALUES
    -- ---- Tier 0 : The Nightmare Court (P.Lv 0-9) -------------------------
    (11370, 1027, 222, 'Diabolos', 0, 128, 0,  60000, 30000, 0, NULL),
    (11372, 2941, 222, 'Odin',     0, 128, 0,  70000, 10000, 0, NULL),
    (11373, 2606, 222, 'Medusa',   0, 128, 0,  55000,     0, 0, NULL),
    -- ---- Tier 1 : The Voidwalkers (P.Lv 10-19) --------------------------
    (11381, 30100, 222, 'Sarameya',             0, 128, 0,  95000, 10000, 0, NULL),
    (11382, 30101, 222, 'Kaggen',               0, 128, 0,  90000, 10000, 0, NULL),
    (11383, 30102, 222, 'Qilin',                0, 128, 0,  92000, 10000, 0, NULL),
    -- ---- Tier 2 : The Jailers (P.Lv 20-29) ------------------------------
    (11384, 30103, 222, 'Jailer_of_Justice',    0, 128, 0,  95000, 30000, 0, NULL),
    (11385, 30104, 222, 'Jailer_of_Fortitude',  0, 128, 0,  92000, 30000, 0, NULL),
    (11386, 30105, 222, 'Jailer_of_Temperance', 0, 128, 0, 105000, 30000, 0, NULL),
    -- ---- Tier 3 : The Voidwalker Lords (P.Lv 30-39) ---------------------
    (11387, 30106, 222, 'Kreutzet',             0, 128, 0, 100000, 30000, 0, NULL),
    (11388, 30107, 222, 'Raja',                 0, 128, 0, 100000, 30000, 0, NULL),
    (11389, 30108, 222, 'Maere',                0, 128, 0,  98000, 30000, 0, NULL),
    -- ---- Tier 4 : The World's End (P.Lv 40+) ----------------------------
    (11390, 30109, 222, 'Omega',                0, 128, 0, 105000, 30000, 0, NULL),
    (11391, 30110, 222, 'Ultima',               0, 128, 0, 105000, 30000, 0, NULL),
    (11392, 4654, 222, 'Provenance_Watcher',   0, 128, 0, 110000, 30000, 0, NULL),  -- native apex (unchanged)
    -- ---- Tier 5 : The Celestial Wardens (P.Lv 60+) ----------------------
    -- Tiamat (3916), Kirin (2265), Absolute Virtue (21).  All three have
    -- retail FLAG_HIDE_MODEL; cleared below so they render as dynamic entities.
    (11393, 3916, 222, 'Tiamat',              0, 128, 0, 115000, 30000, 0, NULL),  -- 5-headed sky dragon
    (11394, 2265, 222, 'Kirin',               0, 128, 0, 120000, 30000, 0, NULL),  -- divine celestial sovereign
    (11395,   21, 222, 'Absolute_Virtue',     0, 128, 0, 130000, 30000, 0, NULL);  -- the eternal apex judge

-- ============================================================================
-- FJB 2026-06-21: Fix Provenance Watcher invisible + floating on dynamic spawn.
-- Pool 4654's entityFlags = 391 (0x187) includes FLAG_HIDE_MODEL (0x080) and
-- FLAG_HIDE_HP (0x100) -- battlefield-only flags set by retail so the mob is
-- invisible outside a Walk of Echoes BC (handled by the BC system there).
-- When we insertDynamicEntity these flags carry over: model hidden, HP bar gone.
-- The "up in the air" symptom is the targeting cursor appearing at the mob's
-- logical center (~15 units above the floor for this massive mob), with no
-- visible body below it.
-- Fix: clear both hide flags and set namevis=1 (normal cursor/name display).
-- entityFlags:  391 & ~0x180 = 391 - 128 - 256 = 7  (0x007)
-- Idempotent -- safe to re-run.
-- ============================================================================
UPDATE `mob_pools`
SET    `entityFlags` = `entityFlags` & ~0x180,  -- clear FLAG_HIDE_MODEL + FLAG_HIDE_HP
       `namevis`     = 1                         -- show targeting cursor + name
WHERE  `poolid` = 4654;

-- ============================================================================
-- FJB 2026-06-21: Tier 5 pools also carry retail FLAG_HIDE_MODEL (0x080).
-- Same cause as above: all three are battlefield-exclusive bosses in retail.
-- Clearing 0x80 so they render as dynamic entities in Provenance (zone 222).
-- namevis 0->1 for normal cursor + HP bar.
--   Tiamat (3916):          entityFlags 157 (0x9D) -> 29 (0x1D)
--   Kirin  (2265):          entityFlags 159 (0x9F) -> 31 (0x1F)
--   Absolute Virtue (21):   entityFlags 1183 (0x49F) -> 1055 (0x41F)
-- ============================================================================
UPDATE `mob_pools`
SET    `entityFlags` = `entityFlags` & ~0x80,
       `namevis`     = 1
WHERE  `poolid` IN (3916, 2265, 21);
