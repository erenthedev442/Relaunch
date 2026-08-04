-- Mildaurion: restore Zilartian unique WS kit (was remapped to sword WS).
-- Great Wheel / Light Blade / Vortex / Stellar Burst.
-- PLD/SAM Hand-to-Hand (palm blasts / Mammet stance).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1086;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Mildaurion',1086,3470), -- Great Wheel (Fragmentation/Scission, AoE + knockback)
('TRUST_Mildaurion',1086,3471), -- Light Blade (Light/Fusion)
('TRUST_Mildaurion',1086,3472), -- Vortex (Distortion/Reverberation)
('TRUST_Mildaurion',1086,3473); -- Stellar Burst (Darkness/Gravitation)

-- Affirm unique anims / SC props / AoE.
UPDATE `mob_skills` SET
    `mob_anim_id` = 2493,
    `mob_skill_name` = 'great_wheel',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 1,
    `primary_sc` = 12,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3470;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2495,
    `mob_skill_name` = 'light_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3471;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2492,
    `mob_skill_name` = 'vortex',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 10,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3472;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2494,
    `mob_skill_name` = 'stellar_burst',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 14,
    `secondary_sc` = 9,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3473;

-- PLD/SAM, Hand-to-Hand (blunt palm AA), delay 240.
UPDATE `mob_pools` SET
    `mJob` = 7,
    `sJob` = 12,
    `cmbSkill` = 1,
    `cmbDelay` = 240
WHERE `poolid` = 5971;
