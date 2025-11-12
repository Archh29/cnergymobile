-- =====================================================
-- GYM CAPACITY NOTIFICATION TRIGGERS
-- Automatically creates notifications when gym capacity reaches thresholds
-- =====================================================

-- Drop existing capacity triggers and procedures if they exist
DROP TRIGGER IF EXISTS `notify_gym_capacity_after_checkin`;
DROP TRIGGER IF EXISTS `notify_gym_capacity_after_checkout`;
DROP PROCEDURE IF EXISTS `NotifyGymCapacity`;

-- Ensure we have capacity notification type (ID 11 for 'capacity')
INSERT IGNORE INTO `notification_type` (`id`, `type_name`) VALUES
(11, 'capacity');

-- Ensure we have unread status
INSERT IGNORE INTO `notification_status` (`id`, `status_name`) VALUES
(1, 'Unread'),
(2, 'Read');

-- =====================================================
-- STORED PROCEDURE: Notify all users about gym capacity
-- =====================================================
DELIMITER $$
CREATE PROCEDURE `NotifyGymCapacity`(
    IN p_current_count INT,
    IN p_max_capacity INT,
    IN p_is_full BOOLEAN
)
BEGIN
    DECLARE unread_status_id INT DEFAULT 1;
    DECLARE warning_type_id INT DEFAULT 2;
    DECLARE error_type_id INT DEFAULT 4;
    DECLARE capacity_percentage DECIMAL(5,2);
    DECLARE notification_message TEXT;
    DECLARE notification_type_id INT;
    DECLARE last_notification_time DATETIME;
    
    -- Calculate percentage
    SET capacity_percentage = (p_current_count / p_max_capacity) * 100;
    
    -- Determine notification type and message
    IF p_is_full = TRUE THEN
        SET notification_type_id = error_type_id;
        SET notification_message = CONCAT('🚫 Gym Fully Occupied: The gym has reached maximum capacity (', p_current_count, '/', p_max_capacity, '). Please wait or come back later.');
        
        -- Check if we already notified in the last 5 minutes
        SELECT MAX(`timestamp`) INTO last_notification_time
        FROM `notification`
        WHERE `type_id` = error_type_id
        AND `message` LIKE '%Gym Fully Occupied%'
        AND `timestamp` > DATE_SUB(NOW(), INTERVAL 5 MINUTE);
    ELSE
        SET notification_type_id = warning_type_id;
        SET notification_message = CONCAT('⚠️ Gym Almost Full: The gym is ', ROUND(capacity_percentage, 0), '% full (', p_current_count, '/', p_max_capacity, '). Only ', (p_max_capacity - p_current_count), ' spots remaining.');
        
        -- Check if we already notified in the last 5 minutes
        SELECT MAX(`timestamp`) INTO last_notification_time
        FROM `notification`
        WHERE `type_id` = warning_type_id
        AND `message` LIKE '%Gym Almost Full%'
        AND `timestamp` > DATE_SUB(NOW(), INTERVAL 5 MINUTE);
    END IF;
    
    -- Only notify if we haven't notified in the last 5 minutes
    IF last_notification_time IS NULL THEN
        -- Insert notification for all users
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        SELECT 
            u.id,
            notification_message,
            unread_status_id,
            notification_type_id,
            NOW()
        FROM `user` u
        WHERE u.id IS NOT NULL;
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- TRIGGER 1: After Check-In - Check if capacity reached threshold
-- =====================================================
DELIMITER $$
CREATE TRIGGER `notify_gym_capacity_after_checkin`
AFTER INSERT ON `attendance`
FOR EACH ROW
BEGIN
    DECLARE current_count INT;
    DECLARE max_capacity INT DEFAULT 30;
    
    -- Count current people in gym (checked in today, not checked out)
    SELECT COUNT(*) INTO current_count
    FROM `attendance`
    WHERE DATE(`check_in`) = CURDATE()
    AND `check_out` IS NULL;
    
    -- Check if we should notify
    IF current_count >= max_capacity THEN
        -- Gym is FULL
        CALL `NotifyGymCapacity`(current_count, max_capacity, TRUE);
    ELSEIF current_count >= 24 THEN
        -- Gym is ALMOST FULL (80% or 24+ people)
        CALL `NotifyGymCapacity`(current_count, max_capacity, FALSE);
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- TRIGGER 2: After Check-Out - Check if capacity still at threshold
-- =====================================================
DELIMITER $$
CREATE TRIGGER `notify_gym_capacity_after_checkout`
AFTER UPDATE ON `attendance`
FOR EACH ROW
BEGIN
    DECLARE current_count INT;
    DECLARE max_capacity INT DEFAULT 30;
    
    -- Only process if check_out was just set (was NULL, now has value)
    IF OLD.`check_out` IS NULL AND NEW.`check_out` IS NOT NULL THEN
        -- Count current people in gym (checked in today, not checked out)
        SELECT COUNT(*) INTO current_count
        FROM `attendance`
        WHERE DATE(`check_in`) = CURDATE()
        AND `check_out` IS NULL;
        
        -- Check if we should notify (capacity might still be at threshold)
        IF current_count >= max_capacity THEN
            -- Gym is FULL
            CALL `NotifyGymCapacity`(current_count, max_capacity, TRUE);
        ELSEIF current_count >= 24 THEN
            -- Gym is ALMOST FULL (80% or 24+ people)
            CALL `NotifyGymCapacity`(current_count, max_capacity, FALSE);
        END IF;
    END IF;
END$$
DELIMITER ;
