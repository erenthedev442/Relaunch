-- Teodor: restore unique Trust kit (skill list was empty; script was nuker-only).
-- BLM/DRK. Special cane AA + Sinner's Cross / Ravenous Assault / Frenzied Thrust /
-- Open Coffin / Hemocladis / Start from Scratch. MB-only -ga/-ja.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1101;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Teodor',1101,3632), -- Frenzied Thrust
('TRUST_Teodor',1101,3633), -- Sinner's Cross
('TRUST_Teodor',1101,3634), -- Open Coffin
('TRUST_Teodor',1101,3635), -- Ravenous Assault
('TRUST_Teodor',1101,3636), -- Hemocladis (aura-gated)
('TRUST_Teodor',1101,3631); -- Start from Scratch (script-gated)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2101;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Teodor_Melee',2101,3628), -- cane slash
('TRUST_Teodor_Melee',2101,3629), -- dark explosion
('TRUST_Teodor_Melee',2101,3630); -- silence strike

-- Special AA (capture anims 339-341 + 2048).
UPDATE `mob_skills` SET
    `mob_anim_id` = 2387,
    `mob_skill_name` = 'teodor_auto_attack',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 3628;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2388,
    `mob_skill_name` = 'teodor_auto_attack_b',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 3629;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2389,
    `mob_skill_name` = 'teodor_auto_attack_c',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 3630;

-- Trust WS (capture +2048 where needed).
UPDATE `mob_skills` SET
    `mob_anim_id` = 2390,
    `mob_skill_name` = 'start_from_scratch',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3631;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2391,
    `mob_skill_name` = 'frenzied_thrust',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3632;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2392,
    `mob_skill_name` = 'sinners_cross',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3633;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2393,
    `mob_skill_name` = 'open_coffin',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3634;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2394,
    `mob_skill_name` = 'ravenous_assault',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3635;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2395,
    `mob_skill_name` = 'hemocladis',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 14,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3636;

-- BLM/DRK, Club (cane). Spell list 399 = -ga/-ja only (no free T4/T5).
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 8,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `spellList` = 399,
    `skill_list_id` = 1101
WHERE `poolid` = 5986;

-- Retail magic: -ga / -ja only (MB). Drop the round2 single-target T4/T5 filler.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 399;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Teodor',399,174,28,255), -- firaga
('TRUST_Teodor',399,175,53,255), -- firaga_ii
('TRUST_Teodor',399,176,69,255), -- firaga_iii
('TRUST_Teodor',399,179,32,255), -- blizzaga
('TRUST_Teodor',399,180,57,255), -- blizzaga_ii
('TRUST_Teodor',399,181,71,255), -- blizzaga_iii
('TRUST_Teodor',399,184,23,255), -- aeroga
('TRUST_Teodor',399,185,48,255), -- aeroga_ii
('TRUST_Teodor',399,186,67,255), -- aeroga_iii
('TRUST_Teodor',399,189,15,255), -- stonega
('TRUST_Teodor',399,190,40,255), -- stonega_ii
('TRUST_Teodor',399,191,63,255), -- stonega_iii
('TRUST_Teodor',399,194,36,255), -- thundaga
('TRUST_Teodor',399,195,61,255), -- thundaga_ii
('TRUST_Teodor',399,196,73,255), -- thundaga_iii
('TRUST_Teodor',399,199,19,255), -- waterga
('TRUST_Teodor',399,200,44,255), -- waterga_ii
('TRUST_Teodor',399,201,65,255), -- waterga_iii
('TRUST_Teodor',399,496,90,255), -- firaja
('TRUST_Teodor',399,497,93,255), -- blizzaja
('TRUST_Teodor',399,498,87,255), -- aeroja
('TRUST_Teodor',399,499,81,255), -- stoneja
('TRUST_Teodor',399,500,87,255), -- thundaja
('TRUST_Teodor',399,501,84,255); -- waterja
