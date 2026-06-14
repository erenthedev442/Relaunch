-- ============================================================================
-- prime_weaponskills.sql
--
-- Enables 6 more Prime weapon skills as usable PLAYER weapon skills (Maru Kala,
-- id 231, is handled separately in maru_kala_ws.sql). Stock LSB leaves these
-- commented out in sql/weapon_skills.sql and ships them only as mob skills.
--
-- Behaviour lives in scripts/actions/weaponskills/<name>.lua. The weapon that
-- grants each (its ADDS_WEAPONSKILL mod) is wired in prime_weapons_gear.sql.
-- The engine loads weapon_skills once at startup -> apply, then restart the map.
--
-- columns: weaponskillid, name, jobs(binary22), type, skilllevel, element,
--          animation, animationTime, range, aoe, radius,
--          primary_sc, secondary_sc, tertiary_sc, main_only, unlock_id
--
-- jobs      = all-zero  -> granted purely by the weapon (BuildingCharWeaponSkills
--             `== main_ws` clause), exactly like Final Heaven / Maru Kala.
-- type      = weapon skill category (must match the granting weapon's skill):
--             1 H2H, 2 Dagger, 3 Sword, 11 Club, 12 Staff.
-- skilllevel/unlock_id = 0  -> no skill gate, no separate unlock.
-- animation = a VALID animation index for that weapon type (placeholder; LSB
--             never captured these Prime WS' real client indices). The WS id
--             still tags the correct name/damage/skillchain.
-- skillchain ids: 1 Transfixion 2 Compression 3 Liquefaction 4 Scission
--             5 Reverberation 6 Detonation 7 Induration 8 Impaction
--             9 Gravitation 10 Distortion 11 Fusion 12 Fragmentation
--
-- Idempotent: DELETE then INSERT.
-- ============================================================================

DELETE FROM `weapon_skills` WHERE `weaponskillid` IN (229, 230, 232, 233, 234, 235);

INSERT INTO `weapon_skills`
    (`weaponskillid`, `name`, `jobs`, `type`, `skilllevel`, `element`,
     `animation`, `animationTime`, `range`, `aoe`, `radius`,
     `primary_sc`, `secondary_sc`, `tertiary_sc`, `main_only`, `unlock_id`)
VALUES
    -- Fast Blade II (Sword / Naegling)  -- best-effort: no captured retail values
    (229, 'fast_blade_ii',    0x00000000000000000000000000000000000000000000, 3, 0, 0,  11, 2000, 3, 0, 0,  4, 1,  0, 1, 0),
    -- Dragon Blow (H2H / Prime Fists)
    (230, 'dragon_blow',      0x00000000000000000000000000000000000000000000, 1, 0, 0,  25, 2000, 3, 0, 0,  3, 8,  0, 1, 0),
    -- Merciless Strike / Ruthless Stroke (Dagger / Mpu Gandring)
    (232, 'merciless_strike', 0x00000000000000000000000000000000000000000000, 2, 0, 0, 236, 2000, 3, 0, 0,  3, 8, 12, 1, 0),
    -- Imperator (Sword / Prime Sword)
    (233, 'imperator',        0x00000000000000000000000000000000000000000000, 3, 0, 0,  15, 2000, 3, 0, 0,  6, 2, 10, 1, 0),
    -- Dagda (Club / Prime Maul)
    (234, 'dagda',            0x00000000000000000000000000000000000000000000,11, 0, 0,  85, 2000, 3, 0, 0,  1, 4,  9, 1, 0),
    -- Oshala (Staff / Prime Staff)
    (235, 'oshala',           0x00000000000000000000000000000000000000000000,12, 0, 0, 145, 2000, 3, 0, 0,  7, 5, 11, 1, 0);
