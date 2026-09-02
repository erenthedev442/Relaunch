-- One to be Feared arena 3: player entry sits on the ship at Y=-231,
-- but Omega/Ultima spawned at Y=-71 / Z=-203 (another platform).
-- Mirror arenas 1-2: same deck as the player, ~30 yalms forward.
-- T2/T3 copies use +118 / +148 from the T1 area-3 pair.
UPDATE `mob_spawn_points`
   SET `pos_x` = 638.3754, `pos_y` = -231.3476, `pos_z` = 560.2620, `pos_rot` = 85
 WHERE `mobid` IN (16908402, 16908520, 16908550)
   AND `mobname` = 'Omega';

UPDATE `mob_spawn_points`
   SET `pos_x` = 638.5294, `pos_y` = -231.3476, `pos_z` = 560.7830, `pos_rot` = 155
 WHERE `mobid` IN (16908403, 16908521, 16908551)
   AND `mobname` = 'Ultima';
