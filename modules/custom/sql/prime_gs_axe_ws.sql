-- ============================================================================
-- prime_gs_axe_ws.sql -- enable missing Prime weaponskills (+AM)
-- ----------------------------------------------------------------------------
-- LSB ships the player WS SCRIPTS for the Great Sword Prime WS (Fimbulvetr) and
-- the Axe Prime WS (Blitz) -- scripts/actions/weaponskills/{fimbulvetr,blitz}.lua
-- -- but NEVER added their weapon_skills TABLE rows, so the engine didn't know
-- they exist and prime_blade (GS, 21650) + prime_pickaxe (Axe, 21726) had no
-- Prime WS and no aftermath. This adds the rows + grants them on the weapons.
--
-- WS ids are the REAL CLIENT ids (verified in Windower res/weapon_skills.lua),
-- so they show up in the in-client WS menu -- same method as the 9 working
-- Primes (imperator=233, dagda=234, oshala=235 all match):
--   62 Fimbulvetr (GS,  type 4): SC Detonation/Compression/Distortion
--   78 Blitz      (Axe, type 5): SC Liquefaction/Impaction/Fragmentation
-- The rows clone imperator's (233) "weapon-granted" template: all-zero jobs
-- (44 hex zeros), skilllevel 0, unlock_id 0, main_only 1 -> granted ONLY by
-- equipping the weapon (BuildingCharWeaponSkills == main_ws), never by job/level.
-- element 0 / range 3 match the server's other Prime WS rows. Animations are
-- borrowed (GS=118 resolution, Axe=59 ruinator) as weapon-type-appropriate
-- placeholders -- the client may play its own Fimbulvetr/Blitz animation anyway.
--
-- Both WS scripts call xi.aftermath.addStatusEffect(PRIME); the aftermath id 46
-- (physical Damage Limit) matches the other physical Primes (see
-- prime_aftermath_mods.sql / scripts/globals/aftermath.lua).
--
-- Idempotent. weapon_skills + item_mods load at map boot -> needs a restart.
-- ============================================================================

-- ---- enable missing Prime weaponskills (clone imperator 233's weapon-granted
--      template: all-zero jobs literal below) -------------------------------
INSERT INTO `weapon_skills`
    (`weaponskillid`, `name`, `jobs`, `type`, `skilllevel`, `element`, `animation`, `animationTime`, `range`, `aoe`, `radius`, `primary_sc`, `secondary_sc`, `tertiary_sc`, `main_only`, `unlock_id`)
VALUES
    (62, 'fimbulvetr', 0x00000000000000000000000000000000000000000000, 4, 0, 0, 118, 2000, 3, 0, 0, 6, 2, 10, 1, 0),
    (78, 'blitz',      0x00000000000000000000000000000000000000000000, 5, 0, 0,  59, 2000, 3, 0, 0, 3, 8, 12, 1, 0),
    (142, 'zesho_meppo', 0x00000000000000000000000000000000000000000000, 9, 0, 0, 165, 2000, 3, 0, 0, 7, 5, 11, 1, 0)
ON DUPLICATE KEY UPDATE
    `name`=VALUES(`name`), `jobs`=VALUES(`jobs`), `type`=VALUES(`type`), `skilllevel`=VALUES(`skilllevel`),
    `element`=VALUES(`element`), `animation`=VALUES(`animation`), `animationTime`=VALUES(`animationTime`),
    `range`=VALUES(`range`), `aoe`=VALUES(`aoe`), `radius`=VALUES(`radius`),
    `primary_sc`=VALUES(`primary_sc`), `secondary_sc`=VALUES(`secondary_sc`), `tertiary_sc`=VALUES(`tertiary_sc`),
    `main_only`=VALUES(`main_only`), `unlock_id`=VALUES(`unlock_id`);

-- Helheim's completed form is granted Fimbulvetr in prime_weapons_gear.sql.
-- Keep only the Axe bootstrap here; earlier Helheim variants must not gain it.
INSERT INTO `item_mods` (`itemid`, `modid`, `value`) VALUES
    (21726, 355, 78),  -- prime_pickaxe (Axe)         -> ADDS_WEAPONSKILL Blitz (78)
    (21726, 256, 46)   -- prime_pickaxe               -> AFTERMATH physical (Damage Limit)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
