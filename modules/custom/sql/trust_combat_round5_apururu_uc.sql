-- Apururu UC: WHM/RDM S-tier CORE healer.
-- No AA. Nott (3502) is listener-driven — skill list stays EMPTY so the
-- engine's TP-before-gambit path cannot steal cure priority (retail Nott
-- is lowest priority; she may keep curing even at 3000 TP).
-- Spell kit already on list 367 (Cure/Curaga/-na/Prot/Shell/Haste/Erase/Stoneskin).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1070;
-- Keep empty — Nott fired via useMobAbility(3502), not auto TP skills.

-- Self-target club anim; no SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 89,
    `mob_skill_name` = 'nott',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3502;

UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 5,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 0,
    `spellList` = 367
WHERE `poolid` = 5955;
