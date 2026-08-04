-- Rosulatia: restore Leafkin kit + special AA (list was empty).
-- BLM/DRK. Stone I–V only. Baneful / Wildwood / Dryad's Kiss / Depraved / Fiat.
-- Special AA: Tree Spike / Vines(+Bind) / Twister(+Silence).
-- Anims: capture 387–395 +2048. A-tier nuker (pressure) — no kit inject.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1100;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Rosulatia',1100,3662), -- Baneful Blades
('TRUST_Rosulatia',1100,3663), -- Wildwood Indignation
('TRUST_Rosulatia',1100,3664), -- Dryad's Kiss (self Haste+Regen @ yellow)
('TRUST_Rosulatia',1100,3665), -- Depraved Dandia
('TRUST_Rosulatia',1100,3666); -- Matriarchal Fiat (AoE)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2102;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Rosulatia_Melee',2102,3659), -- tree_spike (Earth)
('TRUST_Rosulatia_Melee',2102,3660), -- vines (Earth + Bind)
('TRUST_Rosulatia_Melee',2102,3661); -- twister (Slashing + Silence)

-- Special AA (setMobSkillAttack 2102). Capture 387–389 +2048.
INSERT INTO `mob_skills` VALUES
(3659,2435,'tree_spike',0,0.0,7.0,2000,0,4,4,0,0,0,0,0),
(3660,2436,'vines',0,0.0,7.0,2000,0,4,4,0,0,0,0,0),
(3661,2437,'twister',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = VALUES(`mob_skill_aoe`),
    `mob_skill_aoe_radius` = VALUES(`mob_skill_aoe_radius`),
    `mob_skill_distance` = VALUES(`mob_skill_distance`),
    `mob_anim_time` = VALUES(`mob_anim_time`),
    `mob_prepare_time` = VALUES(`mob_prepare_time`),
    `mob_valid_targets` = VALUES(`mob_valid_targets`),
    `mob_skill_flag` = VALUES(`mob_skill_flag`);

-- Trust WS. Capture 390–395 (+2048); skip 393 / Infected Illusion (NM-only).
INSERT INTO `mob_skills` VALUES
(3662,2438,'baneful_blades',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0),
(3663,2439,'wildwood_indignation',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0),
(3664,2440,'dryads_kiss',0,0.0,7.0,2000,1500,1,0,0,0,0,0,0),
(3665,2442,'depraved_dandia',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0),
(3666,2443,'matriarchal_fiat',1,10.0,7.0,2000,1500,4,0,0,0,0,0,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = VALUES(`mob_skill_aoe`),
    `mob_skill_aoe_radius` = VALUES(`mob_skill_aoe_radius`),
    `mob_skill_distance` = VALUES(`mob_skill_distance`),
    `mob_prepare_time` = VALUES(`mob_prepare_time`),
    `mob_valid_targets` = VALUES(`mob_valid_targets`);

-- Retail spell kit: Stone I–V only (no -ga / no MB kit).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 398;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Rosulatia',398,159,1,255),   -- stone
('TRUST_Rosulatia',398,160,26,255),  -- stone_ii
('TRUST_Rosulatia',398,161,51,255),  -- stone_iii
('TRUST_Rosulatia',398,162,68,255),  -- stone_iv
('TRUST_Rosulatia',398,163,77,255);  -- stone_v

-- BLM/DRK. Special AA via setMobSkillAttack (H2H slot).
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 8,
    `cmbSkill` = 1,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1100,
    `spellList` = 398
WHERE `poolid` = 5985;
