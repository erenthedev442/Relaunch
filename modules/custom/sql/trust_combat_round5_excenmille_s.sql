-- Excenmille (S): restore unique Trust GS WS + Stag's Call ability.
-- Base/round3 had polearm player WS (Double…Impulse) and cmbSkill Polearm.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1119;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Excenmille_S',1119,3295), -- Songbird Swoop
('TRUST_Excenmille_S',1119,3292), -- Gyre Strike (Paralyze)
('TRUST_Excenmille_S',1119,3294), -- Orcsbane (AoE)
('TRUST_Excenmille_S',1119,3293); -- Stag's Charge
-- Stag's Call (3291) is an ability gambit, not a TP WS.

UPDATE `mob_skills` SET
    `mob_anim_id` = 1724,
    `mob_skill_name` = 'stags_call',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 3291;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1725,
    `mob_skill_name` = 'gyre_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3292;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1727,
    `mob_skill_name` = 'stags_charge',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3293;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1726,
    `mob_skill_name` = 'orcsbane',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 12.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3294;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1721,
    `mob_skill_name` = 'songbird_swoop',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3295;

-- WAR/PLD, Great Sword — only while this slot is still stock Exc_S.
-- Pool 6004 is Matsui-P (trusts/trust_matsui_p.sql); do not clobber it.
UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 7,
    `cmbSkill` = 4
WHERE `poolid` = 6004 AND `name` = 'excenmille_s';
