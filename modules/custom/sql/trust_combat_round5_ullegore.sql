-- Ullegore: restore Corse Trust kit (list was empty).
-- BLM/DRK. ST I–V + Comet + Stun. Memento / Silence Seal / Envoutement / Bored to Tears.
-- Anims reuse Corse family (900–903). A-tier nuker (pressure) — no kit inject.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1102;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ullegore',1102,3624), -- Memento Mori (self MAB)
('TRUST_Ullegore',1102,3625), -- Silence Seal (AoE Silence)
('TRUST_Ullegore',1102,3626), -- Envoutement (Dark magical; no Curse)
('TRUST_Ullegore',1102,3627); -- Bored to Tears (weak Slow)

-- Trust Corse kit: self Memento, AoE Silence Seal, unique Bored.
INSERT INTO `mob_skills` VALUES
(3624,900,'memento_mori',0,0.0,7.0,2000,1500,1,0,0,0,0,0,0),
(3625,901,'silence_seal',1,15.0,15.0,2000,1500,4,0,0,0,0,0,0),
(3626,902,'envoutement',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0),
(3627,903,'bored_to_tears',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = VALUES(`mob_skill_aoe`),
    `mob_skill_aoe_radius` = VALUES(`mob_skill_aoe_radius`),
    `mob_skill_distance` = VALUES(`mob_skill_distance`),
    `mob_prepare_time` = VALUES(`mob_prepare_time`),
    `mob_valid_targets` = VALUES(`mob_valid_targets`);

-- Spell kit: ST I–V, Comet, Stun (fix Aero IV max_level).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 400;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Ullegore',400,144,13,255),
('TRUST_Ullegore',400,145,38,255),
('TRUST_Ullegore',400,146,62,255),
('TRUST_Ullegore',400,147,73,255),
('TRUST_Ullegore',400,148,86,255),
('TRUST_Ullegore',400,149,17,255),
('TRUST_Ullegore',400,150,42,255),
('TRUST_Ullegore',400,151,64,255),
('TRUST_Ullegore',400,152,74,255),
('TRUST_Ullegore',400,153,89,255),
('TRUST_Ullegore',400,154,9,255),
('TRUST_Ullegore',400,155,34,255),
('TRUST_Ullegore',400,156,59,255),
('TRUST_Ullegore',400,157,72,255),
('TRUST_Ullegore',400,158,83,255),
('TRUST_Ullegore',400,159,1,255),
('TRUST_Ullegore',400,160,26,255),
('TRUST_Ullegore',400,161,51,255),
('TRUST_Ullegore',400,162,68,255),
('TRUST_Ullegore',400,163,77,255),
('TRUST_Ullegore',400,164,21,255),
('TRUST_Ullegore',400,165,46,255),
('TRUST_Ullegore',400,166,66,255),
('TRUST_Ullegore',400,167,75,255),
('TRUST_Ullegore',400,168,92,255),
('TRUST_Ullegore',400,169,5,255),
('TRUST_Ullegore',400,170,30,255),
('TRUST_Ullegore',400,171,55,255),
('TRUST_Ullegore',400,172,70,255),
('TRUST_Ullegore',400,173,80,255),
('TRUST_Ullegore',400,219,94,255),
('TRUST_Ullegore',400,252,45,255);

-- BLM/DRK, Staff.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 8,
    `cmbSkill` = 12,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1102,
    `spellList` = 400
WHERE `poolid` = 5987;
