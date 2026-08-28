CREATE TABLE IF NOT EXISTS `ae_society` (
  `name` VARCHAR(64) NOT NULL,
  `balance` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ae_transactions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `society` VARCHAR(64) NOT NULL,
  `citizenid` VARCHAR(64) DEFAULT NULL,
  `player_name` VARCHAR(128) DEFAULT NULL,
  `type` VARCHAR(32) NOT NULL,
  `amount` INT NOT NULL DEFAULT 0,
  `details` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_society_created` (`society`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ae_employees_log` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `society` VARCHAR(64) NOT NULL,
  `actor_citizenid` VARCHAR(64) DEFAULT NULL,
  `target_citizenid` VARCHAR(64) DEFAULT NULL,
  `action` VARCHAR(32) NOT NULL,
  `details` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `ae_society` (`name`, `balance`)
VALUES ('importexport', 0)
ON DUPLICATE KEY UPDATE `name` = `name`;
