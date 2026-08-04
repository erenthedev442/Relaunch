-- Shantotto: BLM/BLM starter nuker. No WS (list stays empty).
-- Spell list 308 already Stone/Fire/… I–V only.
-- C-tier nuker (apprentice) — AI in Lua (hate mute + MP conserve).

-- No skill list rows (retail has no weapon skills).
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1011;

-- BLM/BLM, Staff slot (AA disabled in Lua; no melee).
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 4,
    `cmbSkill` = 12,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1011,
    `spellList` = 308
WHERE `poolid` = 5896;
