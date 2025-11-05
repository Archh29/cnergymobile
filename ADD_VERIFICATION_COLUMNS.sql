-- Add verification deadline columns to user table
-- Run this SQL on your database to support 3-day auto-deletion of unverified accounts

-- Add registration_date column to track when user registered
ALTER TABLE `user` ADD COLUMN `registration_date` DATETIME NULL AFTER `created_at`;

-- Add verification_deadline column to track when verification period expires (3 days from registration)
ALTER TABLE `user` ADD COLUMN `verification_deadline` DATETIME NULL AFTER `registration_date`;

-- Optional: Add index on verification_deadline for faster cleanup queries
ALTER TABLE `user` ADD INDEX `idx_verification_deadline` (`verification_deadline`);

-- Verify the changes
DESCRIBE `user`;





