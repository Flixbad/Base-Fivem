CREATE TABLE IF NOT EXISTS `at_orders` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(64) NOT NULL,
  `customer_name` VARCHAR(128) DEFAULT NULL,
  `vehicle_model` VARCHAR(64) NOT NULL,
  `vehicle_label` VARCHAR(64) NOT NULL,
  `price` INT NOT NULL DEFAULT 0,
  `deposit_paid` INT NOT NULL DEFAULT 0,
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  `assigned_to` VARCHAR(64) DEFAULT NULL,
  `delivery_garage` VARCHAR(64) DEFAULT 'pillboxgarage',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `at_thefts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `mission_id` INT DEFAULT NULL,
  `plate` VARCHAR(12) NOT NULL,
  `vehicle_model` VARCHAR(64) NOT NULL,
  `vehicle_label` VARCHAR(128) DEFAULT NULL,
  `driver_citizenid` VARCHAR(64) DEFAULT NULL,
  `driver_name` VARCHAR(128) DEFAULT NULL,
  `reporter_citizenid` VARCHAR(64) DEFAULT NULL,
  `reporter_name` VARCHAR(128) DEFAULT NULL,
  `last_coords` VARCHAR(128) DEFAULT NULL,
  `status` VARCHAR(32) NOT NULL DEFAULT 'open',
  `special` TINYINT(1) NOT NULL DEFAULT 0,
  `stolen_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_plate_status` (`plate`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `at_missions_log` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(64) NOT NULL,
  `player_name` VARCHAR(128) DEFAULT NULL,
  `label` VARCHAR(128) NOT NULL,
  `mode` VARCHAR(16) NOT NULL,
  `vehicle_model` VARCHAR(64) NOT NULL,
  `payout` INT NOT NULL DEFAULT 0,
  `special` TINYINT(1) NOT NULL DEFAULT 0,
  `completed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `ae_society` (`name`, `balance`) VALUES ('autotransport', 0) ON DUPLICATE KEY UPDATE `name` = `name`;
INSERT INTO `ae_society` (`name`, `balance`) VALUES ('cardealer', 0) ON DUPLICATE KEY UPDATE `name` = `name`;
