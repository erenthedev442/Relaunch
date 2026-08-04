-- Kayeel-Payeel: restore staff kit (list was empty).
-- BLM/SMN. Sunburst / Tartarus Torpor / Gate of Tartarus (AM Refresh when OOM).
-- Ice + Lightning spell list already retail-correct (389). ASAP Gate when dry; else WS@1500.
-- A-tier nuker (burst) — custom AI in Lua (no nuker kit; kit disables AA).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1091;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Kayeel-Payeel',1091,180), -- Sunburst
('TRUST_Kayeel-Payeel',1091,240), -- Tartarus Torpor (AoE Sleep + MDEF/MEVA down)
('TRUST_Kayeel-Payeel',1091,185); -- Gate of Tartarus (last — HIGHEST when OOM)

UPDATE `mob_skills` SET
    `mob_anim_id` = 140,
    `mob_skill_name` = 'sunburst',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 2,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 180;

UPDATE `mob_skills` SET
    `mob_anim_id` = 149,
    `mob_skill_name` = 'tartarus_torpor',
    `mob_skill_aoe` = 2,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 240;

UPDATE `mob_skills` SET
    `mob_anim_id` = 145,
    `mob_skill_name` = 'gate_of_tartarus',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 14,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 185;

-- BLM/SMN, Staff AA (delay 240). Does not path in (NO_MOVE in Lua).
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 15,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1091,
    `spellList` = 389
WHERE `poolid` = 5976;
