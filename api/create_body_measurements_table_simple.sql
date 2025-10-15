-- Create body measurements table for weight tracking (without foreign key constraint)
CREATE TABLE IF NOT EXISTS `body_measurements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `weight` decimal(5,2) DEFAULT NULL COMMENT 'Weight in kg',
  `body_fat_percentage` decimal(4,2) DEFAULT NULL COMMENT 'Body fat percentage',
  `bmi` decimal(4,2) DEFAULT NULL COMMENT 'Body Mass Index',
  `chest_cm` decimal(5,2) DEFAULT NULL COMMENT 'Chest measurement in cm',
  `waist_cm` decimal(5,2) DEFAULT NULL COMMENT 'Waist measurement in cm',
  `hips_cm` decimal(5,2) DEFAULT NULL COMMENT 'Hips measurement in cm',
  `arms_cm` decimal(5,2) DEFAULT NULL COMMENT 'Arms measurement in cm',
  `thighs_cm` decimal(5,2) DEFAULT NULL COMMENT 'Thighs measurement in cm',
  `notes` text DEFAULT NULL COMMENT 'Additional notes',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
