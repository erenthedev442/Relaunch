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
-- These reuse STOCK mob_pools (model + skill kit) -- only the groupid/zone/HP
-- mapping is custom. spawntype 128 = SPAWNTYPE_SCRIPTED (script-popped, no
-- timer). dropid 0 = no loot (the reward is Trial progress, not items). The HP
-- column is BASE health; each boss's catalog `hpBoost` multiplies it at spawn.
--
-- Per-boss stats (level 150, mods, hpBoost, cry) live in prestige_catalog.lua
-- under trialBosses (tier 0) and trialScaling.tiers[N].roster.bosses (tier 1-4).
-- A boss's catalog `name` MUST match its mob_groups.name below.
--
-- Idempotent + scoped to groupIds 11370-11392 at zoneid 222 -- safe to re-run.
-- Apply (live Azure server): just run "Azure - Deploy to Server.bat" -- it
-- auto-applies any changed modules/custom/sql/*.sql and restarts xi_map for you.
-- (Manual equivalent on the box: sudo mariadb xidb < this-file, then
--  sudo systemctl restart xi_map. mob_groups are read at map-server boot.)
-- ============================================================================

DELETE FROM `mob_groups`
 WHERE `groupid` BETWEEN 11370 AND 11392
   AND `zoneid` = 222;

INSERT INTO `mob_groups`
    (`groupid`, `poolid`, `zoneid`, `name`, `respawntime`, `spawntype`, `dropid`, `HP`, `MP`, `allegiance`, `content_tag`)
VALUES
    -- ---- Tier 0 : The Nightmare Court (P.Lv 0-9) -------------------------
    (11370, 1027, 222, 'Diabolos', 0, 128, 0,  60000, 30000, 0, NULL),
    (11371, 2606, 222, 'Medusa',   0, 128, 0,  55000,     0, 0, NULL),  -- (legacy spare)
    (11372, 2941, 222, 'Odin',     0, 128, 0,  70000, 10000, 0, NULL),
    (11373, 2606, 222, 'Medusa',   0, 128, 0,  55000,     0, 0, NULL),
    -- ---- Tier 1 : The Voidwalkers (P.Lv 10-19) --------------------------
    (11381, 3465, 222, 'Sarameya',             0, 128, 0,  95000, 10000, 0, NULL),
    (11382, 4694, 222, 'Kaggen',               0, 128, 0,  90000, 10000, 0, NULL),
    (11383, 4716, 222, 'Qilin',                0, 128, 0,  92000, 10000, 0, NULL),
    -- ---- Tier 2 : The Jailers (P.Lv 20-29) ------------------------------
    (11384, 2133, 222, 'Jailer_of_Justice',    0, 128, 0,  95000, 30000, 0, NULL),
    (11385, 2131, 222, 'Jailer_of_Fortitude',  0, 128, 0,  92000, 30000, 0, NULL),
    (11386, 2136, 222, 'Jailer_of_Temperance', 0, 128, 0, 105000, 30000, 0, NULL),
    -- ---- Tier 3 : The Voidwalker Lords (P.Lv 30-39) ---------------------
    (11387, 2287, 222, 'Kreutzet',             0, 128, 0, 100000, 30000, 0, NULL),
    (11388, 3313, 222, 'Raja',                 0, 128, 0, 100000, 30000, 0, NULL),
    (11389, 2474, 222, 'Maere',                0, 128, 0,  98000, 30000, 0, NULL),
    -- ---- Tier 4 : The World's End (P.Lv 40+) ----------------------------
    (11390, 2973, 222, 'Omega',                0, 128, 0, 105000, 30000, 0, NULL),
    (11391, 4083, 222, 'Ultima',               0, 128, 0, 105000, 30000, 0, NULL),
    (11392, 4654, 222, 'Provenance_Watcher',   0, 128, 0, 110000, 30000, 0, NULL);
