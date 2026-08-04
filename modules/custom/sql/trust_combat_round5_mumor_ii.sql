-- Mumor II: restore dance kit (list was empty) + Firesday Night Fever.
-- BLM/DNC Club. Samba / Waltz / Neo / Super / Eternal / Final / Fever.
-- Spell list: ST I–V + Stun + -ja only (no free -ga; MB-only AI in Lua).
-- A-tier nuker (burst) — no kit inject.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1130;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Mumor_II',1130,3637), -- Shining Summer Samba
('TRUST_Mumor_II',1130,3638), -- Lovely Miracle Waltz
('TRUST_Mumor_II',1130,3639), -- Neo Crystal Jig
('TRUST_Mumor_II',1130,3640), -- Super Crusher Jig
('TRUST_Mumor_II',1130,3641), -- Eternal Vana Illusion
('TRUST_Mumor_II',1130,3642), -- Final Eternal Heart (AoE)
('TRUST_Mumor_II',1130,3643); -- Firesday Night Fever (self)

-- Unique dance / fever skills (were commented out in base dump).
INSERT INTO `mob_skills` VALUES
(3637,2037,'shining_summer_samba',0,0.0,7.0,2000,1500,4,0,0,0,2,0,0),
(3638,3382,'lovely_miracle_waltz',0,0.0,7.0,2000,1500,4,0,0,0,13,11,0),
(3639,2039,'neo_crystal_jig',0,0.0,7.0,2000,1500,4,0,0,0,10,0,0),
(3640,3384,'super_crusher_jig',0,0.0,7.0,2000,1500,4,0,0,0,11,0,0),
(3641,3385,'eternal_vana_illusion',0,0.0,7.0,2000,1500,4,0,0,0,12,0,0),
(3642,3386,'final_eternal_heart',1,10.0,7.0,2000,1500,4,0,0,0,13,11,0),
(3643,3387,'firesday_night_fever',0,0.0,7.0,2000,1500,1,0,0,0,0,0,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = VALUES(`mob_skill_aoe`),
    `mob_skill_aoe_radius` = VALUES(`mob_skill_aoe_radius`),
    `mob_skill_distance` = VALUES(`mob_skill_distance`),
    `mob_valid_targets` = VALUES(`mob_valid_targets`),
    `mob_prepare_time` = VALUES(`mob_prepare_time`),
    `primary_sc` = VALUES(`primary_sc`),
    `secondary_sc` = VALUES(`secondary_sc`),
    `tertiary_sc` = VALUES(`tertiary_sc`);

-- Retail spell kit: ST I–V, Stun, -ja (no -ga free-nukes).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 424;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Mumor_II',424,144,13,255),  -- fire
('TRUST_Mumor_II',424,145,38,255),  -- fire_ii
('TRUST_Mumor_II',424,146,62,255),  -- fire_iii
('TRUST_Mumor_II',424,147,73,255),  -- fire_iv
('TRUST_Mumor_II',424,148,86,255),  -- fire_v
('TRUST_Mumor_II',424,149,17,255),  -- blizzard
('TRUST_Mumor_II',424,150,42,255),  -- blizzard_ii
('TRUST_Mumor_II',424,151,64,255),  -- blizzard_iii
('TRUST_Mumor_II',424,152,74,255),  -- blizzard_iv
('TRUST_Mumor_II',424,153,89,255),  -- blizzard_v
('TRUST_Mumor_II',424,154,9,255),   -- aero
('TRUST_Mumor_II',424,155,34,255),  -- aero_ii
('TRUST_Mumor_II',424,156,59,255),  -- aero_iii
('TRUST_Mumor_II',424,157,72,255),  -- aero_iv
('TRUST_Mumor_II',424,158,83,255),  -- aero_v
('TRUST_Mumor_II',424,159,1,255),   -- stone
('TRUST_Mumor_II',424,160,26,255),  -- stone_ii
('TRUST_Mumor_II',424,161,51,255),  -- stone_iii
('TRUST_Mumor_II',424,162,68,255),  -- stone_iv
('TRUST_Mumor_II',424,163,77,255),  -- stone_v
('TRUST_Mumor_II',424,164,21,255),  -- thunder
('TRUST_Mumor_II',424,165,46,255),  -- thunder_ii
('TRUST_Mumor_II',424,166,66,255),  -- thunder_iii
('TRUST_Mumor_II',424,167,75,255),  -- thunder_iv
('TRUST_Mumor_II',424,168,92,255),  -- thunder_v
('TRUST_Mumor_II',424,169,5,255),   -- water
('TRUST_Mumor_II',424,170,30,255),  -- water_ii
('TRUST_Mumor_II',424,171,55,255),  -- water_iii
('TRUST_Mumor_II',424,172,70,255),  -- water_iv
('TRUST_Mumor_II',424,173,80,255),  -- water_v
('TRUST_Mumor_II',424,252,45,255),  -- stun
('TRUST_Mumor_II',424,496,90,255),  -- firaja
('TRUST_Mumor_II',424,497,93,255),  -- blizzaja
('TRUST_Mumor_II',424,498,87,255),  -- aeroja
('TRUST_Mumor_II',424,499,81,255),  -- stoneja
('TRUST_Mumor_II',424,500,87,255),  -- thundaja
('TRUST_Mumor_II',424,501,84,255);  -- waterja

-- BLM/DNC, Club (wand) AA.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 19,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1130,
    `spellList` = 424
WHERE `poolid` = 6015;
