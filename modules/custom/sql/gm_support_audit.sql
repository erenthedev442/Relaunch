-- GM1 support-command audit storage. Idempotent for existing deployments.
CREATE TABLE IF NOT EXISTS `audit_gm` (
    `date_time` DATETIME(3) NOT NULL,
    `gm_name` VARCHAR(16) NOT NULL,
    `command` VARCHAR(40) NOT NULL,
    `full_string` VARCHAR(200) NOT NULL,
    PRIMARY KEY (`date_time`, `gm_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
