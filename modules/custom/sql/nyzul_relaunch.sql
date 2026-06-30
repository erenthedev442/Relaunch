-- nyzul_relaunch.sql
-- Relaunch Nyzul Isle Investigation entry NPC: "Sorrowful Sage" at Mhaura (zone
-- 249), next to the Ambuscade NPCs. It registers a Nyzul Isle Investigation
-- instance (id 7704) directly, bypassing the retail ToAU Assault grind. The
-- in-instance Rune of Transfer handles floor selection / saved progress / rewards.
--
-- npcid 17797277 = 0x1000000 | (249<<12) | targid 157  (free; max Mhaura targid
-- was 155, and the pending Ambuscade Voucher Clerk reserves 156).
-- Clones all rendering fields (look/namevis/status/...) from Gorpa-Masorpa
-- (17797274) so it renders + is targetable; only id/name/position are overridden.
-- Idempotent: DELETE then INSERT.

DELETE FROM `npc_list` WHERE `npcid` = 17797277;
INSERT INTO `npc_list`
    (npcid, name, polutils_name, pos_rot, pos_x, pos_y, pos_z,
     flag, speed, speedsub, animation, animationsub, namevis, status,
     entityFlags, look, name_prefix, content_tag, widescan)
SELECT
    17797277, 'Sorrowful_Sage', 'Sorrowful Sage', 100, -25.200, -15.990, 52.565,
    flag, speed, speedsub, animation, animationsub, namevis, status,
    entityFlags, look, name_prefix, content_tag, widescan
FROM `npc_list` WHERE `npcid` = 17797274;  -- 17797274 = Gorpa-Masorpa (Mhaura)
