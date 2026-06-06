-- ---------------------------------------------------------------------------
-- char_cross_job_abilities
--
-- Persists "borrowed" job abilities a character has purchased from the
-- Cross-Job Ability Trainer at GM Home. Each row = one ability the character
-- can use on ANY job (e.g. a PLD using Meditate).
--
-- The engine (charutils::BuildingCharAbilityTable) only ever rebuilds the
-- usable-ability bitmask from the player's current main/sub job, so these
-- borrowed abilities are re-injected into the live table by the companion
-- C++ module (modules/custom/cpp/cross_job_ability_bindings.cpp) on every
-- zone-in and after every ability-table rebuild. This table is the source of
-- truth for what to re-inject.
--
-- Apply this ONE statement by hand against the game database, e.g.:
--   mysql -u <user> -p <dbname> < modules/custom/sql/cross_job_abilities.sql
-- (or paste it into your DB GUI). It is a single standalone table, so a
-- by-hand apply is the surgical option.
--
-- Do NOT use `python tools/dbtool.py update full` just for this: although that
-- path would pick the file up (custom/sql/ is globbed from modules/init.txt),
-- a full update re-imports every non-protected game table -- which would wipe
-- the AH market-maker's auction_house listings. A plain `dbtool.py update`
-- (no "full") is version-gated and will skip this file entirely.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS never drops existing purchases, so
-- this is safe to re-run.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `char_cross_job_abilities` (
  `charid`    int(10) unsigned     NOT NULL,
  `abilityId` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`charid`,`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
