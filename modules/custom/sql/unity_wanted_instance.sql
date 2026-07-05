-- Parallel private-instance Unity Wanted test arena.
--
-- HYBRID_INSTANCED keeps normal Ghelsba Outpost and Save the Children intact
-- while allowing independent private CInstance copies of the same map.
UPDATE `zone_settings`
SET `zonetype` = `zonetype` | 512
WHERE `zoneid` = 140;

INSERT INTO `instance_list`
    (`instanceid`, `instance_name`, `instance_zone`, `entrance_zone`,
     `time_limit`, `start_x`, `start_y`, `start_z`, `start_rot`,
     `music_day`, `music_night`, `battlesolo`, `battlemulti`)
VALUES
    (14000, 'unity_wanted_trial', 140, 284, 15,
     -165.357, -11.672, 77.771, 191, NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
    `instance_name` = VALUES(`instance_name`),
    `instance_zone` = VALUES(`instance_zone`),
    `entrance_zone` = VALUES(`entrance_zone`),
    `time_limit` = VALUES(`time_limit`),
    `start_x` = VALUES(`start_x`),
    `start_y` = VALUES(`start_y`),
    `start_z` = VALUES(`start_z`),
    `start_rot` = VALUES(`start_rot`);
