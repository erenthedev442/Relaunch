-- Excenmille: restore starter PLD kit on spell/pool 899.
-- NOTE: modules/custom/sql/trusts/trust_meat.sql previously hijacked this slot
-- (spell name 'meat', pool 'Meat', empty skill list). Re-applying Meat AFTER
-- this file will undo the restore — keep Meat off 899 if Excenmille is desired.

-- Spell binds to scripts/actions/spells/trust/excenmille.lua
UPDATE `spell_list` SET `name` = 'excenmille' WHERE `spellid` = 899;

-- Retail Trust pool: PLD/PLD, Polearm, spell list 311, skill list 1014.
UPDATE `mob_pools` SET
    `name` = 'excenmille',
    `packet_name` = 'Excenmille',
    `speciesid` = 293,
    `modelid` = UNHEX('0000BB0B00000000000000000000000000000000'),
    `mJob` = 7,
    `sJob` = 7,
    `cmbSkill` = 8,
    `cmbDelay` = 390,
    `cmbDmgMult` = 150,
    `spellList` = 311,
    `skill_list_id` = 1014,
    `resist_id` = 145
WHERE `poolid` = 5899;

-- Skill list: Double Thrust / Leg Sweep / Penta Thrust (no Impulse Drive).
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1014;
INSERT INTO `mob_skill_lists` VALUES
('TRUST_Excenmille',1014,112), -- Double Thrust
('TRUST_Excenmille',1014,115), -- Leg Sweep
('TRUST_Excenmille',1014,116); -- Penta Thrust

-- Spell list: Cure I-IV + Flash (id 311). Wipe Meat's spell_list_id 899 if present.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 899;
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 311;
INSERT INTO `mob_spell_lists` VALUES
('TRUST_Excenmille',311,1,5,255),
('TRUST_Excenmille',311,2,17,255),
('TRUST_Excenmille',311,3,30,255),
('TRUST_Excenmille',311,4,55,255),
('TRUST_Excenmille',311,112,45,255);

-- Drop Meat-only skill list row if present.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 5899;
