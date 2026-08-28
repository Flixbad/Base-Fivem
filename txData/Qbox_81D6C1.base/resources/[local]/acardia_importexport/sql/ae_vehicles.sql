CREATE TABLE IF NOT EXISTS `ae_vehicles` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `society` VARCHAR(64) NOT NULL,
  `model` VARCHAR(64) NOT NULL,
  `label` VARCHAR(64) NOT NULL,
  `plate` VARCHAR(12) NOT NULL,
  `props` LONGTEXT DEFAULT NULL,
  `stored` TINYINT(1) NOT NULL DEFAULT 1,
  `bought_by` VARCHAR(64) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plate` (`plate`),
  KEY `idx_society_stored` (`society`, `stored`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
