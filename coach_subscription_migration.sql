-- Migration script to add new fields for coach subscription management
-- Run this script on your database to add the required fields

-- Add new fields to coach_member_list table
ALTER TABLE `coach_member_list` 
ADD COLUMN `remaining_sessions` INT(11) DEFAULT NULL COMMENT 'Remaining sessions for session packages',
ADD COLUMN `rate_type` ENUM('hourly', 'monthly', 'package') DEFAULT 'hourly' COMMENT 'Type of subscription rate';

-- Create table to track daily session usage
CREATE TABLE IF NOT EXISTS `coach_session_usage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coach_member_id` int(11) NOT NULL COMMENT 'Reference to coach_member_list.id',
  `usage_date` date NOT NULL COMMENT 'Date when session was used',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_daily_usage` (`coach_member_id`, `usage_date`),
  KEY `idx_coach_member_id` (`coach_member_id`),
  KEY `idx_usage_date` (`usage_date`),
  CONSTRAINT `fk_coach_session_usage_member` FOREIGN KEY (`coach_member_id`) REFERENCES `coach_member_list` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci COMMENT='Tracks daily session usage for coach packages';

-- Update existing records to have default rate_type
UPDATE `coach_member_list` SET `rate_type` = 'hourly' WHERE `rate_type` IS NULL;
