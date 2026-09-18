-- Private instance used by The Name Beyond the Ferry.
--
-- Ghelsba Outpost is already HYBRID_INSTANCED for the private Unity trials;
-- retain that bit here so this migration is independently idempotent.
UPDATE `zone_settings`
SET `zonetype` = `zonetype` | 512
WHERE `zoneid` = 140;

INSERT INTO `instance_list`
    (`instanceid`, `instance_name`, `instance_zone`, `entrance_zone`,
     `time_limit`, `start_x`, `start_y`, `start_z`, `start_rot`,
     `music_day`, `music_night`, `battlesolo`, `battlemulti`)
VALUES
    (14001, 'eren_quest_trial', 140, 44, 25,
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
