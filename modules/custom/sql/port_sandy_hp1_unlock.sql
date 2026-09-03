-- ============================================================================
-- port_sandy_hp1_unlock.sql
--
-- Port San d'Oria Home Point #1 was at -38, -4, -63 (same as its teleport
-- dest). That dumps you inside the crystal collision -- a movement lock --
-- and it is the wrong grid square (plaza, not H-10 by the Mog House).
--
-- Move the crystal to the captured H-10 !pos. Teleport dest is offset in
-- scripts/globals/homepoint.lua so arrivals stand beside it.
-- ============================================================================

UPDATE `npc_list`
SET `pos_x` = -67.963,
    `pos_y` = -4.000,
    `pos_z` = -105.023
WHERE `npcid` = 17727574
  AND `name` = 'HomePoint#1';
