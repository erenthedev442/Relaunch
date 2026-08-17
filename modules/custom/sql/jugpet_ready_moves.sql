-- =====================================================================
-- jugpet_ready_moves.sql
--
-- Final authoritative repair for lists previously polluted with arbitrary
-- enemy mob-skill IDs. The Ready menu is defined by pet_skills; runtime lists
-- use those rows' executable mob_skill_id values. Do not add "thematic" enemy
-- moves here: overlapping numeric namespaces caused Courier Carrie to expose
-- only Mega Scissors and produced unrelated commands on other families.
--
-- This file runs after bst_jug_restore_ready_abilities.sql and deliberately
-- rebuilds every list touched by the old augmentation file. Idempotent.
-- =====================================================================

DELETE FROM `mob_skill_lists`
WHERE `skill_list_id` IN
(
    737, 738, 739, 740, 741, 742, 747, 755,
    756, 757, 758, 759, 760, 762, 763, 2096
);

INSERT INTO `mob_skill_lists` VALUES
-- Sheep
('Jug_Sheep',737,3857), -- Lamb Chop
('Jug_Sheep',737,3858), -- Rage
('Jug_Sheep',737,3859), -- Sheep Charge
('Jug_Sheep',737,3860), -- Sheep Song
-- Crab: Courier Carrie / Crab Familiar
('Jug_Crab',738,3861), -- Bubble Shower
('Jug_Crab',738,3862), -- Bubble Curtain
('Jug_Crab',738,3863), -- Big Scissors
('Jug_Crab',738,3864), -- Scissor Guard
('Jug_Crab',738,3865), -- Metallic Body
-- Cactuar
('Jug_Cactuar',739,3866), -- Needleshot
('Jug_Cactuar',739,3867), -- 1000 Needles
-- Funguar
('Jug_Funguar',740,3868), -- Frogkick
('Jug_Funguar',740,3869), -- Spore
('Jug_Funguar',740,3870), -- Queasyshroom
('Jug_Funguar',740,3871), -- Numbshroom
('Jug_Funguar',740,3872), -- Shakeshroom
('Jug_Funguar',740,3873), -- Silence Gas
('Jug_Funguar',740,3874), -- Dark Spore
-- Beetle
('Jug_Beetle',741,3875), -- Power Attack
('Jug_Beetle',741,3876), -- Hi-Freq Field
('Jug_Beetle',741,3877), -- Rhino Attack
('Jug_Beetle',741,3878), -- Rhino Guard
('Jug_Beetle',741,3879), -- Spoil
-- Fly
('Jug_Fly',742,3880), -- Cursed Sphere
('Jug_Fly',742,3881), -- Venom
('Jug_Fly',742,3938), -- Somersault
-- Coeurl / Lynx
('Jug_Coeurl',747,3898), -- Chaotic Eye
('Jug_Coeurl',747,3899), -- Blaster
('Jug_Coeurl',747,3912), -- Charged Whisker
-- Apkallu
('Jug_Apkallu',755,3922), -- Wing Slap
('Jug_Apkallu',755,3923), -- Beak Lunge
-- Pugil
('Jug_Pugil',756,3924), -- Intimidate
('Jug_Pugil',756,3925), -- Recoil Dive
('Jug_Pugil',756,3926), -- Water Wall
-- Chapuli
('Jug_Chapuli',757,3927), -- Sensilla Blades
('Jug_Chapuli',757,3928), -- Tegmina Buffet
-- Tulfaire
('Jug_Tulfaire',758,3929), -- Molting Plumage
('Jug_Tulfaire',758,3930), -- Swooping Frenzy
('Jug_Tulfaire',758,3933), -- Pentapeck
-- Raaz
('Jug_Raaz',759,3931), -- Sweeping Gouge
('Jug_Raaz',759,3932), -- Zealous Snort
-- Snapweed
('Jug_Snapweed',760,3934), -- Tickling Tendrils
('Jug_Snapweed',760,3935), -- Stink Bomb
('Jug_Snapweed',760,3936), -- Nectarous Deluge
('Jug_Snapweed',760,3937), -- Nepenthic Plunge
-- Acuex
('Jug_Acuex',762,3939), -- Foul Waters
('Jug_Acuex',762,3940), -- Pestilent Plume
-- Colibri
('Jug_Colibri',763,3941), -- Pecking Flurry
-- Mosquito
('Jug_Mosquito',2096,3945), -- Infected Leech
('Jug_Mosquito',2096,3946); -- Gloom Spray

-- Correct targeting/knockback metadata shared by manual and auto-Ready.
UPDATE `mob_skills`
SET `mob_skill_aoe` = 0
WHERE `mob_skill_id` IN (3064, 3933); -- Pentapeck is single-target

UPDATE `mob_skills`
SET `knockback` = 3
WHERE `mob_skill_id` IN (3063, 3929); -- Molting Plumage

UPDATE `pet_skills`
SET `knockback` = 3
WHERE `pet_skill_id` = 763; -- Molting Plumage
