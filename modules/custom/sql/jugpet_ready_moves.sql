-- =====================================================================
-- jugpet_ready_moves.sql
-- Give every BST jug pet a working, thematically-correct DAMAGING Ready move.
--
-- THE BUG (found via tools/audit_jugpet_skills.py): a jug pet's Ready/Sic
-- moves come from its pool's mob_skill_list (CMobController::MobSkill picks a
-- random valid skill from it -- the same path BstJugPetOverhaul's auto-ready
-- taps via useMobAbility()). But many Jug_* lists only reference OLD duplicate
-- skill ids that were long ago commented out of mob_skills.sql (e.g. 697
-- 'berserk', 700-706 job abilities, 756-760 'howl'). Those dangling rows are
-- deleted at boot by fix_dangling_mob_skills.sql, leaving 16 families with
-- either NO working move at all, or only self-buffs (perfect_dodge, invincible,
-- charm, howl...) -- so they could never DD on auto-ready.
--
-- THE FIX: the real, thematically-correct retail moves already exist in
-- mob_skills AND already have scripts in scripts/actions/mobskills/ -- the
-- lists just never pointed at them. Wire each broken family to its real moves
-- (mostly enemy-damage, with a flavour buff/debuff or two). Two Chapuli
-- signatures (sensilla_blades 2946, tegmina_buffet 2947) had no script engine-
-- wide; those are authored alongside this file.
--
-- petid->pool->skill_list verified live; every id below is ACTIVE in
-- mob_skills and has a mobskill script (audited). Pets melee at endgame ATT
-- (BstJugPetOverhaul), so these moves land for real, capped damage.
--
-- Idempotent (INSERT IGNORE; PK = skill_list_id+mob_skill_id). mob skill lists
-- are cached into mob data at zone load / boot, so APPLY + RESTART the map.
-- =====================================================================

-- ── NONE families (had zero working Ready move) ──────────────────────
-- Jug_Fly (742): Somersault, Cursed Sphere, Drainkiss
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Fly',742,318),('Jug_Fly',742,659),('Jug_Fly',742,417);
-- Jug_Funguar (740): Dark Spore (dmg+poison), Numbing Noise (paralyze), Frightful Roar (def down)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Funguar',740,315),('Jug_Funguar',740,517),('Jug_Funguar',740,501);
-- Jug_Apkallu (755): Wing Slap, Beak Lunge, Spinning Top
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Apkallu',755,1714),('Jug_Apkallu',755,1715),('Jug_Apkallu',755,365);
-- Jug_Pugil (756): Splash Breath, Aqua Ball, Screwdriver
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Pugil',756,451),('Jug_Pugil',756,450),('Jug_Pugil',756,452);
-- Jug_Colibri (763): Pecking Flurry, Back Heel, Helldive
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Colibri',763,1699),('Jug_Colibri',763,576),('Jug_Colibri',763,622);
-- Jug_Mosquito (2096): Proboscis (HP drain), Toxic Spit (poison)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Mosquito',2096,1953),('Jug_Mosquito',2096,515);
-- Jug_Cactuar (739): 1000 Needles, Needleshot
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Cactuar',739,322),('Jug_Cactuar',739,321);

-- ── BUFFS-ONLY families (only self-buffs worked) ─────────────────────
-- Jug_Crab (738): Big Scissors, Spikeball, Metallic Body (keeps perfect_dodge/invincible/etc.)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Crab',738,444),('Jug_Crab',738,789),('Jug_Crab',738,448);
-- Jug_Sheep (737): Lamb Chop, Sheep Charge, Rage (atk up)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Sheep',737,260),('Jug_Sheep',737,262),('Jug_Sheep',737,261);
-- Jug_Beetle (741): Rhino Attack, Power Attack, Magnetite Cloud
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Beetle',741,340),('Jug_Beetle',741,3875),('Jug_Beetle',741,791);
-- Jug_Raaz (759): Sudden Lunge (dmg+stun), Tail Blow, Wild Horn
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Raaz',759,2178),('Jug_Raaz',759,366),('Jug_Raaz',759,628);
-- Jug_Acuex (762): Vampiric Lash (dmg+drain), Somersault
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Acuex',762,317),('Jug_Acuex',762,318);
-- Jug_Tulfaire (758): Tail Blow, Helldive, Blackout (blind)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Tulfaire',758,366),('Jug_Tulfaire',758,622),('Jug_Tulfaire',758,2952);
-- Jug_Chapuli (757): Diffusion Ray plus the canonical pet_skills mappings.
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Chapuli',757,2054),('Jug_Chapuli',757,3927),('Jug_Chapuli',757,3928);
-- Jug_Coeurl (747): Charged Whisker (thunder AoE), Blaster (dmg+paralyze), Chaotic Eye (silence)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Coeurl',747,483),('Jug_Coeurl',747,652),('Jug_Coeurl',747,653);
