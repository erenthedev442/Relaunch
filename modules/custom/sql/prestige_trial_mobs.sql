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
    -- FJB 2026-06-15: tiers 1-4 REPOOLED so they actually RENDER in Provenance.
    -- Zone 222 loads a FIXED monster-model set; the original pools (Sarameya 3465,
    -- Omega 2973, etc.) use models the zone doesn't carry, so the bosses spawned
    -- INVISIBLE (still targetable/attackable, just not drawn). Remapped to fresh
    -- AVATAR models -- avatars render in ANY zone (exactly why the tier-0 Diabolos/
    -- Odin work), all DISTINCT, and NONE collide with NMs the other custom systems
    -- use (Bahamut was excluded -- it's the GM-Master Bahamut, group 11412). Ultima
    -- uses Crystal_Fetter (native to 222). Thematic: an apex "the void summons the
    -- eidolons" Court. The pool also carries the TP kit, so each boss gains its
    -- avatar's moveset; catalog stats/HP (the real difficulty) are unchanged and
    -- NAMES are kept. Diabolos 1027 / Odin 2941 / Medusa 2606 are NOT reused --
    -- they stay exclusive to the tier-0 Nightmare Court.
    -- ---- Tier 1 : The Voidwalkers (P.Lv 10-19) --------------------------
    (11381, 1322, 222, 'Sarameya',             0, 128, 0,  95000, 10000, 0, NULL),  -- Fenrir (wolf/hound)
    (11382, 2050, 222, 'Kaggen',               0, 128, 0,  90000, 10000, 0, NULL),  -- Ifrit (devouring flame)
    (11383, 1473, 222, 'Qilin',                0, 128, 0,  92000, 10000, 0, NULL),  -- Garuda (tempest)
    -- ---- Tier 2 : The Jailers (P.Lv 20-29) ------------------------------
    (11384,   82, 222, 'Jailer_of_Justice',    0, 128, 0,  95000, 30000, 0, NULL),  -- Alexander (lawgiver)
    (11385, 3931, 222, 'Jailer_of_Fortitude',  0, 128, 0,  92000, 30000, 0, NULL),  -- Titan (earthwall)
    (11386, 3607, 222, 'Jailer_of_Temperance', 0, 128, 0, 105000, 30000, 0, NULL),  -- Shiva (ice/restraint)
    -- ---- Tier 3 : The Voidwalker Lords (P.Lv 30-39) ---------------------
    (11387, 3317, 222, 'Kreutzet',             0, 128, 0, 100000, 30000, 0, NULL),  -- Ramuh (sky/storm)
    (11388, 2402, 222, 'Raja',                 0, 128, 0, 100000, 30000, 0, NULL),  -- Leviathan (primal beast)
    (11389, 6170, 222, 'Maere',                0, 128, 0,  98000, 30000, 0, NULL),  -- Siren (nightmare/enchantress)
    -- ---- Tier 4 : The World's End (P.Lv 40+) ----------------------------
    (11390, 6961, 222, 'Omega',                0, 128, 0, 105000, 30000, 0, NULL),  -- Odin Prime (apex doom)
    (11391, 5314, 222, 'Ultima',               0, 128, 0, 105000, 30000, 0, NULL),  -- Crystal_Fetter (native 222; ancient crystal weapon)
    (11392, 4654, 222, 'Provenance_Watcher',   0, 128, 0, 110000, 30000, 0, NULL);  -- native apex (unchanged)

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
