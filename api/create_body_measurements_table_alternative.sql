-- Alternative: Create body measurements table without foreign key constraint
-- This will work regardless of your user table structure

-- First, let's check what user tables exist in your database
-- Run this query first to see your table structure:
-- SHOW TABLES LIKE '%user%';
-- SHOW TABLES LIKE '%member%';

-- Then create the body_measurements table without foreign key:
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

-- If you want to add the foreign key constraint later, first check your user table:
-- 1. Find the correct table name (could be 'users', 'members', 'member', etc.)
-- 2. Find the correct primary key column name (could be 'id', 'user_id', etc.)
-- 3. Then run: ALTER TABLE body_measurements ADD CONSTRAINT body_measurements_ibfk_1 FOREIGN KEY (user_id) REFERENCES your_user_table(your_primary_key) ON DELETE CASCADE;
