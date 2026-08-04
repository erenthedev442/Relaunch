-- Zeid II: exclusive Ground Strike (base list had Hard Slash…Scourge).
-- DRK/WAR GS. Stun + Absorb-Attri. CLOSER@3000. Level-50 GS gate in Lua.
-- S weaponskill CORE path; Desperate Blows via DRK traits + Last Resort.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1125;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Zeid_II',1125,56); -- Ground Strike only (Frag/Distortion)

-- Affirm player Ground Strike anim / SC (Fusion/Grav openers → Darkness).
UPDATE `mob_skills` SET
    `mob_anim_id` = 114,
    `mob_skill_name` = 'ground_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 0,
    `primary_sc` = 12,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 56;

-- Spell list 419 already Stun + Absorb-Attri; reaffirm for live.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 419;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Zeid_II',419,243,91,255), -- absorb-attri
('TRUST_Zeid_II',419,252,37,255); -- stun

-- DRK/WAR, Great Sword.
UPDATE `mob_pools` SET
    `mJob` = 8,
    `sJob` = 1,
    `cmbSkill` = 4,
    `cmbDelay` = 240,
    `skill_list_id` = 1125,
    `spellList` = 419
WHERE `poolid` = 6010;
