-- =====================================================
-- Simplified Support Ticket System Migration
-- =====================================================
-- Modifies existing support_requests table and adds messaging
-- Simple system for localized gym - no complex features
-- =====================================================

-- --------------------------------------------------------
-- Step 1: Modify existing support_requests table
-- Add necessary columns for ticket management
-- Uses IF NOT EXISTS pattern to make migration idempotent
-- --------------------------------------------------------

-- Add user_id column if it doesn't exist
SET @dbname = DATABASE();
SET @tablename = "support_requests";
SET @columnname = "user_id";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 'Column user_id already exists - skipping'",
  "ALTER TABLE support_requests ADD COLUMN user_id int(11) DEFAULT NULL AFTER id"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add ticket_number column if it doesn't exist
SET @columnname = "ticket_number";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 'Column ticket_number already exists - skipping'",
  "ALTER TABLE support_requests ADD COLUMN ticket_number varchar(20) DEFAULT NULL AFTER id"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add status column if it doesn't exist
SET @columnname = "status";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 'Column status already exists - skipping'",
  "ALTER TABLE support_requests ADD COLUMN status enum('pending','in_progress','resolved') DEFAULT 'pending' AFTER message"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add updated_at column if it doesn't exist
SET @columnname = "updated_at";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 'Column updated_at already exists - skipping'",
  "ALTER TABLE support_requests ADD COLUMN updated_at datetime DEFAULT NULL ON UPDATE current_timestamp() AFTER created_at"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add indexes for better performance (with IF NOT EXISTS check)
-- Check if index exists before adding
SET @indexname = "idx_user_id";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = @indexname)
  ) > 0,
  "SELECT 'Index idx_user_id already exists - skipping'",
  "ALTER TABLE support_requests ADD INDEX idx_user_id (user_id)"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

SET @indexname = "idx_status";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = @indexname)
  ) > 0,
  "SELECT 'Index idx_status already exists - skipping'",
  "ALTER TABLE support_requests ADD INDEX idx_status (status)"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

SET @indexname = "idx_ticket_number";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = @indexname)
  ) > 0,
  "SELECT 'Index idx_ticket_number already exists - skipping'",
  "ALTER TABLE support_requests ADD INDEX idx_ticket_number (ticket_number)"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add foreign key constraint for user_id if it doesn't exist
SET @constraintname = "fk_support_requests_user";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (CONSTRAINT_NAME = @constraintname)
  ) > 0,
  "SELECT 'Foreign key fk_support_requests_user already exists - skipping'",
  CONCAT("ALTER TABLE support_requests ADD CONSTRAINT ", @constraintname, " FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE SET NULL")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- --------------------------------------------------------
-- Step 2: Create simple messages table for ticket conversations
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `support_request_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL COMMENT 'Reference to support_requests.id',
  `sender_id` int(11) NOT NULL COMMENT 'User who sent the message',
  `message` text NOT NULL COMMENT 'Message content',
  `created_at` datetime DEFAULT current_timestamp() COMMENT 'When message was sent',
  PRIMARY KEY (`id`),
  KEY `idx_request_id` (`request_id`),
  KEY `idx_sender_id` (`sender_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_support_request_messages_request` 
    FOREIGN KEY (`request_id`) REFERENCES `support_requests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_support_request_messages_sender` 
    FOREIGN KEY (`sender_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Messages for support requests';

-- --------------------------------------------------------
-- Step 3: Ticket number generation
-- Format: REQ-XXXXX (where XXXXX is the ID padded to 5 digits)
-- NOTE: Ticket numbers are generated in PHP code after insert
-- to avoid MySQL trigger restrictions (can't update same table in trigger)
-- --------------------------------------------------------
-- Drop the trigger if it exists (it causes errors)
DROP TRIGGER IF EXISTS `generate_support_request_number`;

-- No trigger needed - ticket numbers are generated in PHP API

-- --------------------------------------------------------
-- Step 4: Simple notification triggers
-- --------------------------------------------------------

-- Drop triggers if they exist (to allow re-running migration)
DROP TRIGGER IF EXISTS `notify_support_status_change`;
DROP TRIGGER IF EXISTS `notify_support_new_message`;
DROP TRIGGER IF EXISTS `notify_admin_new_support_request`;

-- Notify user when status changes
DELIMITER $$
CREATE TRIGGER `notify_support_status_change` 
AFTER UPDATE ON `support_requests`
FOR EACH ROW
BEGIN
    -- Only notify if status changed and user_id exists
    IF OLD.status != NEW.status AND NEW.user_id IS NOT NULL THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id,
            CASE 
                WHEN NEW.status = 'in_progress' THEN CONCAT('🔄 Your support request is being processed.')
                WHEN NEW.status = 'resolved' THEN CONCAT('✅ Your support request has been resolved.')
                ELSE CONCAT('📋 Your support request status has been updated.')
            END,
            1, -- Unread
            8, -- Info type
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- Notify user when admin replies
DELIMITER $$
CREATE TRIGGER `notify_support_new_message` 
AFTER INSERT ON `support_request_messages`
FOR EACH ROW
BEGIN
    DECLARE request_user_id INT;
    DECLARE sender_user_type INT;
    
    -- Get request user_id
    SELECT user_id INTO request_user_id FROM support_requests WHERE id = NEW.request_id;
    
    -- Get sender user type
    SELECT user_type_id INTO sender_user_type FROM user WHERE id = NEW.sender_id;
    
    -- Notify user if message is from admin/staff (user_type_id 1 or 2)
    IF request_user_id IS NOT NULL AND sender_user_type IN (1, 2) THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            request_user_id,
            CONCAT('💬 New reply on your support request: ', LEFT(NEW.message, 50), '...'),
            1, -- Unread
            8, -- Info type
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- Notify admin when new request is created
DELIMITER $$
CREATE TRIGGER `notify_admin_new_support_request` 
AFTER INSERT ON `support_requests`
FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE admin_id INT;
    DECLARE admin_cursor CURSOR FOR 
        SELECT id FROM user WHERE user_type_id = 1; -- Admin user type
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN admin_cursor;
    
    read_loop: LOOP
        FETCH admin_cursor INTO admin_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            admin_id,
            CONCAT('🎫 New support request: ', NEW.subject),
            1, -- Unread
            8, -- Info type
            NOW()
        );
    END LOOP;
    
    CLOSE admin_cursor;
END$$
DELIMITER ;

-- --------------------------------------------------------
-- Step 5: Remove priority column if it exists
-- Users should not be able to set priority - only admins can
-- --------------------------------------------------------
-- Safely remove priority column if it exists
SET @dbname = DATABASE();
SET @tablename = "support_requests";
SET @columnname = "priority";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  CONCAT("ALTER TABLE ", @tablename, " DROP COLUMN ", @columnname),
  "SELECT 'Column priority does not exist - skipping'"
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- --------------------------------------------------------
-- Step 6: Update existing records (if any)
-- Generate ticket numbers for existing support requests
-- --------------------------------------------------------
-- Update existing records to have ticket numbers
UPDATE `support_requests` 
SET `ticket_number` = CONCAT('REQ-', LPAD(id, 5, '0'))
WHERE `ticket_number` IS NULL OR `ticket_number` = '';

-- Optional: Populate user_id from user_email for existing records
-- Uncomment if you want to link existing requests to users
-- UPDATE `support_requests` sr
-- INNER JOIN `user` u ON sr.user_email = u.email
-- SET sr.user_id = u.id
-- WHERE sr.user_id IS NULL;

-- --------------------------------------------------------
-- Migration Complete
-- --------------------------------------------------------
-- Summary:
-- 1. Modified support_requests table:
--    - Added user_id (links to user table)
--    - Added status (pending, in_progress, resolved)
--    - Added ticket_number (simple REQ-XXXXX format)
--    - Added updated_at timestamp
-- 2. Created support_request_messages table for conversations
-- 3. Removed trigger for ticket number generation (causes MySQL errors)
--    - Ticket numbers are now generated in PHP API after insert
-- 4. Added simple triggers for:
--    - Notifying users on status changes
--    - Notifying users on admin replies
--    - Notifying admins on new requests
-- 5. Updated existing records with ticket numbers
--
-- Notes:
-- - user_email field is kept for backward compatibility
-- - New requests should use user_id instead of user_email
-- - Ticket numbers are auto-generated in PHP (REQ-00001, REQ-00002, etc.)
-- - Trigger was removed to avoid MySQL error: "Can't update table in trigger"
-- --------------------------------------------------------
