-- Robel-Akbel: restore staff kit (list was empty) + Null Blast / Quietus Sphere.
-- BLM/SMN. Spirit Taker / Quietus Sphere (AoE Dark) / Null Blast (MP restore; preferred when dry).
-- Spell list: ST I–V, Stun, -aja only (no -ga). WS@2000; NO_MOVE AA. AI in Lua.
-- B-tier nuker (burst) — no kit inject.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1092;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Robel-Akbel',1092,183),  -- Spirit Taker
('TRUST_Robel-Akbel',1092,3537), -- Quietus Sphere (AoE Dark)
('TRUST_Robel-Akbel',1092,3538); -- Null Blast (preferred — last for HIGHEST when OOM)

UPDATE `mob_skills` SET
    `mob_anim_id` = 143,
    `mob_skill_name` = 'spirit_taker',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 183;

-- Quietus Sphere: was commented out in base dump.
INSERT INTO `mob_skills` VALUES
(3537,3281,'quietus_sphere',1,10.0,15.0,2000,1500,4,0,0,0,2,0,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = 3281,
    `mob_skill_name` = 'quietus_sphere',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 2,
    `secondary_sc` = 0,
    `tertiary_sc` = 0;

-- Null Blast: Mystic Boon-style anim; ranged; Gravitation; MP drain in Lua.
UPDATE `mob_skills` SET
    `mob_anim_id` = 87,
    `mob_skill_name` = 'null_blast',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3538;

-- Retail spell kit: ST I–V, Stun, -aja (no -ga).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 390;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Robel-Akbel',390,144,13,255),  -- fire
('TRUST_Robel-Akbel',390,145,38,255),  -- fire_ii
('TRUST_Robel-Akbel',390,146,62,255),  -- fire_iii
('TRUST_Robel-Akbel',390,147,73,255),  -- fire_iv
('TRUST_Robel-Akbel',390,148,86,255),  -- fire_v
('TRUST_Robel-Akbel',390,149,17,255),  -- blizzard
('TRUST_Robel-Akbel',390,150,42,255),  -- blizzard_ii
('TRUST_Robel-Akbel',390,151,64,255),  -- blizzard_iii
('TRUST_Robel-Akbel',390,152,74,255),  -- blizzard_iv
('TRUST_Robel-Akbel',390,153,89,255),  -- blizzard_v
('TRUST_Robel-Akbel',390,154,9,255),   -- aero
('TRUST_Robel-Akbel',390,155,34,255),  -- aero_ii
('TRUST_Robel-Akbel',390,156,59,255),  -- aero_iii
('TRUST_Robel-Akbel',390,157,72,255),  -- aero_iv
('TRUST_Robel-Akbel',390,158,83,255),  -- aero_v
('TRUST_Robel-Akbel',390,159,1,255),   -- stone
('TRUST_Robel-Akbel',390,160,26,255),  -- stone_ii
('TRUST_Robel-Akbel',390,161,51,255),  -- stone_iii
('TRUST_Robel-Akbel',390,162,68,255),  -- stone_iv
('TRUST_Robel-Akbel',390,163,77,255),  -- stone_v
('TRUST_Robel-Akbel',390,164,21,255),  -- thunder
('TRUST_Robel-Akbel',390,165,46,255),  -- thunder_ii
('TRUST_Robel-Akbel',390,166,66,255),  -- thunder_iii
('TRUST_Robel-Akbel',390,167,75,255),  -- thunder_iv
('TRUST_Robel-Akbel',390,168,92,255),  -- thunder_v
('TRUST_Robel-Akbel',390,169,5,255),   -- water
('TRUST_Robel-Akbel',390,170,30,255),  -- water_ii
('TRUST_Robel-Akbel',390,171,55,255),  -- water_iii
('TRUST_Robel-Akbel',390,172,70,255),  -- water_iv
('TRUST_Robel-Akbel',390,173,80,255),  -- water_v
('TRUST_Robel-Akbel',390,252,45,255),  -- stun
('TRUST_Robel-Akbel',390,496,90,255),  -- firaja
('TRUST_Robel-Akbel',390,497,93,255),  -- blizzaja
('TRUST_Robel-Akbel',390,498,87,255),  -- aeroja
('TRUST_Robel-Akbel',390,499,81,255),  -- stoneja
('TRUST_Robel-Akbel',390,500,87,255),  -- thundaja
('TRUST_Robel-Akbel',390,501,84,255);  -- waterja

-- BLM/SMN, Staff. NO_MOVE + ranged Null/Quietus in Lua/SQL.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 15,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1092,
    `spellList` = 390
WHERE `poolid` = 5977;
