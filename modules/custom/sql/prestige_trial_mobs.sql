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
    -- FJB 2026-06-15: tiers 1-4 REPOOLED to Provenance-safe models. The original
    -- pools (Sarameya 3465, Kaggen 4694, Omega 2973, etc.) use monster models the
    -- client does NOT load in zone 222, so those bosses spawned INVISIBLE. The
    -- poolids below are all confirmed to render in Provenance: native zone-222
    -- mobs (Crystal_Fetter + the RoV "Naphula" chess pieces) and the proven
    -- tier-0 avatars (Diabolos/Odin/Medusa) + the Provenance Watcher. The pool
    -- ALSO carries the TP-move kit, so each boss now uses its new pool's moves --
    -- the higher tiers actually GAIN dread kits (Medusa petrify / Diabolos
    -- nightmare / Odin Zantetsuken). Stats/HP (the real difficulty) are catalog-
    -- driven and unchanged. Boss NAMES are kept (the mob just wears a stand-in
    -- model). To restore a specific original look, the model must be one zone 222
    -- loads, or override it post-spawn via setModelId in Prestige_System.lua.
    -- ---- Tier 1 : The Voidwalkers (P.Lv 10-19) --------------------------
    (11381, 4664, 222, 'Sarameya',             0, 128, 0,  95000, 10000, 0, NULL),  -- Asb (native 222)
    (11382, 4663, 222, 'Kaggen',               0, 128, 0,  90000, 10000, 0, NULL),  -- Rukh (native 222)
    (11383, 4666, 222, 'Qilin',                0, 128, 0,  92000, 10000, 0, NULL),  -- Wazir (native 222)
    -- ---- Tier 2 : The Jailers (P.Lv 20-29) ------------------------------
    (11384, 4667, 222, 'Jailer_of_Justice',    0, 128, 0,  95000, 30000, 0, NULL),  -- Shah (native 222)
    (11385, 4665, 222, 'Jailer_of_Fortitude',  0, 128, 0,  92000, 30000, 0, NULL),  -- Sarbaz (native 222)
    (11386, 5315, 222, 'Jailer_of_Temperance', 0, 128, 0, 105000, 30000, 0, NULL),  -- Pil (native 222)
    -- ---- Tier 3 : The Voidwalker Lords (P.Lv 30-39) ---------------------
    (11387, 5314, 222, 'Kreutzet',             0, 128, 0, 100000, 30000, 0, NULL),  -- Crystal_Fetter (native 222)
    (11388, 2606, 222, 'Raja',                 0, 128, 0, 100000, 30000, 0, NULL),  -- Medusa (proven; petrify kit)
    (11389, 1027, 222, 'Maere',                0, 128, 0,  98000, 30000, 0, NULL),  -- Diabolos (proven; nightmare kit)
    -- ---- Tier 4 : The World's End (P.Lv 40+) ----------------------------
    (11390, 2941, 222, 'Omega',                0, 128, 0, 105000, 30000, 0, NULL),  -- Odin (proven; Zantetsuken kit)
    (11391, 4654, 222, 'Ultima',               0, 128, 0, 105000, 30000, 0, NULL),  -- Provenance Watcher (shares 11392's look)
    (11392, 4654, 222, 'Provenance_Watcher',   0, 128, 0, 110000, 30000, 0, NULL);  -- native apex (unchanged)
