-- =====================================================
-- CORRECTED NOTIFICATION TRIGGERS
-- Based on actual database schema from u773938685_cnergydb (23).sql
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS `notify_workout_completed`;
DROP TRIGGER IF EXISTS `notify_personal_record`;
DROP TRIGGER IF EXISTS `notify_program_assigned`;
DROP TRIGGER IF EXISTS `notify_goal_achieved`;
DROP TRIGGER IF EXISTS `notify_goal_achieved_my_goals`;
DROP TRIGGER IF EXISTS `notify_subscription_expiry_7days`;
DROP TRIGGER IF EXISTS `notify_subscription_expiry_1day`;
DROP TRIGGER IF EXISTS `notify_subscription_expired`;

-- =====================================================
-- 1. WORKOUT COMPLETED NOTIFICATION
-- =====================================================
DELIMITER $$
CREATE TRIGGER `notify_workout_completed` 
AFTER INSERT ON `member_exercise_log` 
FOR EACH ROW 
BEGIN
    INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
    VALUES (
        NEW.member_id, 
        '🏋️ Great job! You completed your workout. Keep up the momentum!',
        1, 
        9, 
        NOW()
    );
END$$
DELIMITER ;

-- =====================================================
-- 2. PERSONAL RECORD NOTIFICATION
-- =====================================================
DELIMITER $$
CREATE TRIGGER `notify_personal_record` 
AFTER INSERT ON `personal_records` 
FOR EACH ROW 
BEGIN
    DECLARE exercise_name_var VARCHAR(255);
    
    SELECT name INTO exercise_name_var
    FROM exercise 
    WHERE id = NEW.exercise_id;
    
    INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
    VALUES (
        NEW.user_id, 
        CONCAT('🏆 NEW PERSONAL RECORD! ', COALESCE(exercise_name_var, 'Exercise'), ': ', NEW.max_weight, ' kg'),
        1, 
        6, 
        NOW()
    );
END$$
DELIMITER ;

-- =====================================================
-- 3. PROGRAM ASSIGNED NOTIFICATION
-- =====================================================
DELIMITER $$
CREATE TRIGGER `notify_program_assigned` 
AFTER INSERT ON `member_programhdr` 
FOR EACH ROW 
BEGIN
    DECLARE coach_name VARCHAR(255);
    
    IF NEW.created_by IS NOT NULL AND NEW.created_by != NEW.user_id THEN
        SELECT CONCAT(u.fname, ' ', u.lname) INTO coach_name 
        FROM user u 
        WHERE u.id = NEW.created_by;
        
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('📋 New workout program assigned by ', COALESCE(coach_name, 'a Coach'), ': ', NEW.goal),
            1, 
            7, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 4. GOAL ACHIEVED NOTIFICATION (my_goals table)
-- Note: member_fitness_goals table has no status column, so no trigger for it
-- =====================================================
DELIMITER $$
CREATE TRIGGER `notify_goal_achieved_my_goals` 
AFTER UPDATE ON `my_goals` 
FOR EACH ROW 
BEGIN
    IF NEW.status = 'achieved' AND OLD.status != 'achieved' THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('🎯 GOAL ACHIEVED! ', NEW.goal, ' - Congratulations!'),
            1, 
            6, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 5. SUBSCRIPTION EXPIRY NOTIFICATIONS
-- =====================================================

-- 7 days before expiry
DELIMITER $$
CREATE TRIGGER `notify_subscription_expiry_7days` 
AFTER UPDATE ON `subscription` 
FOR EACH ROW 
BEGIN
    IF NEW.end_date IS NOT NULL AND OLD.end_date IS NOT NULL THEN
        -- Check if subscription expires in 7 days
        IF DATEDIFF(NEW.end_date, CURDATE()) = 7 AND NEW.end_date > CURDATE() THEN
            INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
            VALUES (
                NEW.user_id, 
                '⚠️ Your membership expires in 7 days. Renew now to continue enjoying all premium features!',
                1, 
                8, 
                NOW()
            );
        END IF;
    END IF;
END$$
DELIMITER ;

-- 1 day before expiry
DELIMITER $$
CREATE TRIGGER `notify_subscription_expiry_1day` 
AFTER UPDATE ON `subscription` 
FOR EACH ROW 
BEGIN
    IF NEW.end_date IS NOT NULL AND OLD.end_date IS NOT NULL THEN
        -- Check if subscription expires in 1 day
        IF DATEDIFF(NEW.end_date, CURDATE()) = 1 AND NEW.end_date > CURDATE() THEN
            INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
            VALUES (
                NEW.user_id, 
                '🚨 URGENT: Your membership expires tomorrow! Renew now to avoid service interruption!',
                1, 
                8, 
                NOW()
            );
        END IF;
    END IF;
END$$
DELIMITER ;

-- Subscription expired
DELIMITER $$
CREATE TRIGGER `notify_subscription_expired` 
AFTER UPDATE ON `subscription` 
FOR EACH ROW 
BEGIN
    IF NEW.end_date IS NOT NULL AND OLD.end_date IS NOT NULL THEN
        -- Check if subscription has expired
        IF NEW.end_date < CURDATE() AND OLD.end_date >= CURDATE() THEN
            INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
            VALUES (
                NEW.user_id, 
                '❌ Your membership has expired. Renew now to restore access to all features!',
                1, 
                8, 
                NOW()
            );
        END IF;
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 6. WEEKLY PROGRESS SUMMARY STORED PROCEDURE
-- =====================================================
DELIMITER $$
CREATE PROCEDURE `SendWeeklyProgressSummary`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE user_id_var INT;
    DECLARE user_cursor CURSOR FOR 
        SELECT DISTINCT user_id FROM subscription 
        WHERE end_date > CURDATE() AND status = 'active';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN user_cursor;
    
    read_loop: LOOP
        FETCH user_cursor INTO user_id_var;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Insert weekly progress summary notification
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            user_id_var,
            '📊 Your weekly progress summary is ready! Check your dashboard to see your achievements.',
            1,
            10,
            NOW()
        );
        
    END LOOP;
    
    CLOSE user_cursor;
END$$
DELIMITER ;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Show all triggers
SHOW TRIGGERS;

-- Show stored procedures
SHOW PROCEDURE STATUS WHERE Db = DATABASE();

-- Test notification table structure
DESCRIBE notification;


