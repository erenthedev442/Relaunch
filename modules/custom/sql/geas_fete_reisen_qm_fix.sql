-- =====================================================================
-- geas_fete_reisen_qm_fix.sql
-- Reisenjima Geas Fete camps Taelmoth / Selkit / Strophadia:
--   1) ??? NPCs 17969974–76 used MODEL_DOOR looks / bad flags (untargetable).
--   2) 17969974 sat in an under-map trench.
--   3) Black "darkness" orbs (_830–_832) + fep1–3 share the same coords and
--      steal / block ??? targeting (Selkit report: orb visible, can't spawn).
-- =====================================================================

-- Taelmoth + Zduhac + Sarsaok — walkable ground near Sabotender camp.
UPDATE `npc_list`
SET
    pos_rot      = 0,
    pos_x        = -620.000,
    pos_y        = -39.500,
    pos_z        = -235.000,
    flag         = 1,
    animation    = 0,
    animationsub = 0,
    namevis      = 112,
    status       = 0,
    entityFlags  = 3,
    look         = 0x0000340000000000000000000000000000000000,
    name_prefix  = 2,
    widescan     = 1
WHERE npcid = 17969974;

-- Selkit + Bashmu — restore targetable ??? (keep stock XY; orb hidden below).
UPDATE `npc_list`
SET
    flag         = 1,
    animation    = 0,
    animationsub = 0,
    namevis      = 112,
    status       = 0,
    entityFlags  = 3,
    look         = 0x0000340000000000000000000000000000000000,
    name_prefix  = 2,
    widescan     = 1
WHERE npcid = 17969975;

-- Strophadia + Teles + Vinipata — same.
UPDATE `npc_list`
SET
    flag         = 1,
    animation    = 0,
    animationsub = 0,
    namevis      = 112,
    status       = 0,
    entityFlags  = 3,
    look         = 0x0000340000000000000000000000000000000000,
    name_prefix  = 2,
    widescan     = 1
WHERE npcid = 17969976;

-- Hide the overlapping orbs / fep markers (status 2 = disappeared).
UPDATE `npc_list` SET status = 2 WHERE npcid IN (17970032, 17970033, 17970034, 17970035, 17970036, 17970037);
