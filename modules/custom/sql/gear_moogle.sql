INSERT IGNORE INTO `npc_list`
    (`npcid`, `name`, `polutils_name`, `pos_rot`, `pos_x`, `pos_y`, `pos_z`,
     `flag`, `speed`, `speedsub`, `animation`, `animationsub`, `namevis`,
     `status`, `entityFlags`, `look`, `name_prefix`, `content_tag`, `widescan`)
VALUES
    (17720035, 'Gear_Moogle', 'Gear_Moogle', 0, -1.2, -9.4, 2.0,
     14, 40, 40, 0, 1, 0,
     27, 0, (SELECT look FROM npc_list WHERE npcid = 17719415), 32, NULL, 1);