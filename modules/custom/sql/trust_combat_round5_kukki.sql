-- Kukki-Chebukki: BLM/BLM day-element nuker. No WS (Occult Acumen TP unused).
-- Spell list 374 already retail (ST I–V, -ga, -aja, ele debuffs, Sleepga).
-- Fix Aero IV max_level typo (was 82). Affirm empty skill list + BLM/BLM Staff.
-- C-tier nuker (apprentice) — custom day AI in Lua (no nuker kit).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1076;

-- Aero IV was capped at 82 in base dump; unlock for trust level curve.
UPDATE `mob_spell_lists`
SET `max_level` = 255
WHERE `spell_list_id` = 374 AND `spell_id` = 157;

-- BLM/BLM, Staff. No TP moves. Day AI + ~15' range in Lua.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 4,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1076,
    `spellList` = 374
WHERE `poolid` = 5961;
