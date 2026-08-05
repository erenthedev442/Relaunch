-- =====================================================================
-- fix_dangling_mob_skills.sql
-- Remove mob_skill_lists rows that point at a mob_skill_id which does NOT
-- exist in mob_skills. These dangling references:
--   * spam "CMobController::MobSkill -> Mobskill with ID (N) ... isn't
--     properly defined in mob_skills.sql" on every TP-move attempt, and
--   * CRASH the map when a list has NO valid skill left: the chooser loop in
--     CMobController::MobSkill skips every undefined entry, chosenSkillId stays
--     0, GetMobSkill(0) returns nullptr, and the next line derefs it.
--     (Live SIGSEGV 2026-06-20 20:00 -- skill-list 843, whose only skill 2585
--     isn't defined. Observed dangling skills today: 2585, 2586, 2391.)
--
-- A reference to a non-existent skill never worked (it always errored + was
-- skipped), so deleting it changes nothing functional -- the mob simply stops
-- trying to use a move it could never perform. To give such a mob a real TP
-- move later, define the skill in mob_skills.sql and re-add the list row.
--
-- The C++ null-guard in src/map/ai/controllers/mob_controller.cpp is the
-- permanent fix (no list can crash again); this SQL is the immediate,
-- no-rebuild relief that also clears the log spam.
--
-- Idempotent (re-running deletes nothing once clean). Apply + restart the map
-- (mob skill lists are cached into mob data at zone load / boot).
-- =====================================================================

-- Keep jug Ready ability IDs (672-798 range living in pet_skills.pet_skill_id).
-- Those are NOT mob_skills rows; deleting them strips Sensilla Blades, Wing Slap,
-- Infected Leech, etc. from the Ready menu even though pet_skills + scripts exist.
DELETE FROM `mob_skill_lists`
WHERE `mob_skill_id` NOT IN (SELECT `mob_skill_id` FROM `mob_skills`)
  AND `mob_skill_id` NOT IN (SELECT `pet_skill_id` FROM `pet_skills`);
