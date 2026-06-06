-- ---------------------------------------------------------------------------
-- zz_cross_job_abilities.sql
--
-- Deploy copy of the char_cross_job_abilities table (canonical definition:
-- modules/custom/sql/cross_job_abilities.sql) placed in sql/ with the zz_
-- prefix so it auto-applies through the zz_ reload path:
--   * azure-update.bat / deploy-to-azure.bat  (sudo mariadb xidb < each zz_*.sql)
--   * tools/apply_custom_sql.py / apply-custom-sql.bat
-- so the table exists on the live server without a manual one-off apply.
--
-- It is the source of truth for which "borrowed" abilities each character has
-- bought from the Cross-Job Ability Trainer; the C++ module
-- modules/custom/cpp/cross_job_ability_bindings.cpp re-injects them into the
-- live ability table on zone-in / ability-table rebuild.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS never drops existing rows, so it is
-- safe to run on every deploy. Pure DDL (no item_mods), so no LOCK TABLES.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `char_cross_job_abilities` (
  `charid`    int(10) unsigned     NOT NULL,
  `abilityId` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`charid`,`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
