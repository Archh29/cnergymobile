-- =====================================================
-- COMPLETELY FIXED NOTIFICATION TRIGGERS
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS `notify_subscription_expiry_7days`;
DROP TRIGGER IF EXISTS `notify_subscription_expiry_3days`;
DROP TRIGGER IF EXISTS `notify_subscription_expiry_1day`;
DROP TRIGGER IF EXISTS `notify_subscription_renewed`;
DROP TRIGGER IF EXISTS `notify_workout_completed`;
DROP TRIGGER IF EXISTS `notify_personal_record`;
DROP TRIGGER IF EXISTS `notify_workout_streak`;
DROP TRIGGER IF EXISTS `notify_coach_message`;
DROP TRIGGER IF EXISTS `notify_program_assigned`;
DROP TRIGGER IF EXISTS `notify_goal_achieved`;
DROP TRIGGER IF EXISTS `notify_goal_achieved_member_goals`;
DROP TRIGGER IF EXISTS `notify_goal_deadline`;
DROP TRIGGER IF EXISTS `notify_weight_change`;
DROP TRIGGER IF EXISTS `notify_missed_workouts`;
DROP TRIGGER IF EXISTS `notify_member_registration_enhanced`;
DROP TRIGGER IF EXISTS `notify_routine_limit`;

-- Drop stored procedure if it exists
DROP PROCEDURE IF EXISTS `SendWeeklyProgressSummary`;

-- =====================================================
-- RECREATE NOTIFICATION TRIGGERS WITH CORRECT SYNTAX
-- =====================================================

-- First, let's ensure we have all necessary notification types
INSERT IGNORE INTO `notification_type` (`id`, `type_name`) VALUES
(1, 'info'),
(2, 'warning'),
(3, 'success'),
(4, 'error'),
(5, 'reminder'),
(6, 'achievement'),
(7, 'coach'),
(8, 'membership'),
(9, 'workout'),
(10, 'goal');

-- Ensure we have all necessary notification statuses
INSERT IGNORE INTO `notification_status` (`id`, `status_name`) VALUES
(1, 'Unread'),
(2, 'Read');

-- =====================================================
-- 1. SUBSCRIPTION EXPIRATION REMINDERS
-- =====================================================

-- Trigger for subscription expiration (7 days before)
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

-- Trigger for subscription expiration (3 days before)
DELIMITER $$
CREATE TRIGGER `notify_subscription_expiry_3days` 
AFTER UPDATE ON `subscription` 
FOR EACH ROW 
BEGIN
    IF NEW.end_date IS NOT NULL AND OLD.end_date IS NOT NULL THEN
        -- Check if subscription expires in 3 days
        IF DATEDIFF(NEW.end_date, CURDATE()) = 3 AND NEW.end_date > CURDATE() THEN
            INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
            VALUES (
                NEW.user_id, 
                '🚨 URGENT: Your membership expires in 3 days! Renew immediately to avoid service interruption.',
                1, 
                2, 
                NOW()
            );
        END IF;
    END IF;
END$$
DELIMITER ;

-- Trigger for subscription expiration (1 day before)
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
                '🔥 FINAL WARNING: Your membership expires TOMORROW! Renew now to keep your progress!',
                1, 
                2, 
                NOW()
            );
        END IF;
    END IF;
END$$
DELIMITER ;

-- Trigger for successful subscription renewal
DELIMITER $$
CREATE TRIGGER `notify_subscription_renewed` 
AFTER INSERT ON `subscription` 
FOR EACH ROW 
BEGIN
    INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
    VALUES (
        NEW.user_id, 
        CONCAT('✅ Payment successful! Your membership is active until ', DATE_FORMAT(NEW.end_date, '%M %d, %Y')),
        1, 
        3, 
        NOW()
    );
END$$
DELIMITER ;

-- =====================================================
-- 2. WORKOUT & FITNESS NOTIFICATIONS
-- =====================================================

-- Trigger for workout completion
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

-- Trigger for personal records
DELIMITER $$
CREATE TRIGGER `notify_personal_record` 
AFTER INSERT ON `personal_records` 
FOR EACH ROW 
BEGIN
    DECLARE exercise_name_var VARCHAR(255);
    
    -- Get exercise name from exercise table
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

-- Trigger for workout streak (every 7 days)
DELIMITER $$
CREATE TRIGGER `notify_workout_streak` 
AFTER INSERT ON `member_exercise_log` 
FOR EACH ROW 
BEGIN
    DECLARE streak_count INT DEFAULT 0;
    
    -- Count consecutive workout days
    SELECT COUNT(DISTINCT DATE(log_date)) INTO streak_count
    FROM member_exercise_log 
    WHERE member_id = NEW.member_id 
    AND log_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    AND log_date <= CURDATE();
    
    -- Notify for 7-day streak
    IF streak_count = 7 THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.member_id, 
            '🔥 7-Day Workout Streak! You\'re on fire! Keep it up!',
            1, 
            6, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 3. COACH & PROGRAM NOTIFICATIONS
-- =====================================================

-- Trigger for new coach message
DELIMITER $$
CREATE TRIGGER `notify_coach_message` 
AFTER INSERT ON `messages` 
FOR EACH ROW 
BEGIN
    DECLARE coach_name VARCHAR(255);
    DECLARE user_type INT;
    
    -- Get coach name and user type
    SELECT CONCAT(u.fname, ' ', u.lname), u.user_type_id 
    INTO coach_name, user_type
    FROM user u 
    WHERE u.id = NEW.sender_id;
    
    -- Notify if message is from a coach (user_type_id = 3)
    IF user_type = 3 THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.receiver_id, 
            CONCAT('💬 New message from your coach ', coach_name, ': ', LEFT(NEW.message, 50), '...'),
            1, 
            7, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- Trigger for program assignment
DELIMITER $$
CREATE TRIGGER `notify_program_assigned` 
AFTER INSERT ON `member_programhdr` 
FOR EACH ROW 
BEGIN
    DECLARE coach_name VARCHAR(255);
    
    IF NEW.created_by IS NOT NULL AND NEW.created_by != NEW.user_id THEN
        -- Get coach name from user table
        SELECT CONCAT(u.fname, ' ', u.lname) INTO coach_name
        FROM user u 
        WHERE u.id = NEW.created_by;
        
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('📋 New workout program assigned by ', COALESCE(coach_name, 'Your Coach'), ': ', COALESCE(NEW.goal, 'New Program')),
            1, 
            7, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 4. GOAL & PROGRESS NOTIFICATIONS
-- =====================================================

-- Trigger for goal achievement (member_fitness_goals table)
DELIMITER $$
CREATE TRIGGER `notify_goal_achieved` 
AFTER UPDATE ON `member_fitness_goals` 
FOR EACH ROW 
BEGIN
    IF NEW.is_achieved = 1 AND OLD.is_achieved = 0 THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('🎯 GOAL ACHIEVED! ', NEW.goal_name, ' - Congratulations!'),
            1, 
            6, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- Trigger for goal achievement (member_goals table)
DELIMITER $$
CREATE TRIGGER `notify_goal_achieved_member_goals` 
AFTER UPDATE ON `member_goals` 
FOR EACH ROW 
BEGIN
    IF NEW.status = 'achieved' AND OLD.status != 'achieved' THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('🎯 GOAL ACHIEVED! ', NEW.goal_type, ' - Congratulations!'),
            1, 
            6, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- Trigger for goal deadline approaching (member_goals table)
DELIMITER $$
CREATE TRIGGER `notify_goal_deadline` 
AFTER UPDATE ON `member_goals` 
FOR EACH ROW 
BEGIN
    IF NEW.target_date IS NOT NULL AND DATEDIFF(NEW.target_date, CURDATE()) = 7 THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('⏰ Goal deadline approaching: ', NEW.goal_type, ' in 7 days!'),
            1, 
            5, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 5. BODY MEASUREMENTS & PROGRESS
-- =====================================================

-- Trigger for significant weight change
DELIMITER $$
CREATE TRIGGER `notify_weight_change` 
AFTER INSERT ON `body_measurements` 
FOR EACH ROW 
BEGIN
    DECLARE prev_weight DECIMAL(5,2);
    DECLARE weight_diff DECIMAL(5,2);
    
    -- Get previous weight
    SELECT weight INTO prev_weight
    FROM body_measurements 
    WHERE user_id = NEW.user_id 
    AND id < NEW.id 
    ORDER BY id DESC 
    LIMIT 1;
    
    IF prev_weight IS NOT NULL THEN
        SET weight_diff = NEW.weight - prev_weight;
        
        -- Notify for significant weight change (more than 2 lbs)
        IF ABS(weight_diff) >= 2 THEN
            IF weight_diff > 0 THEN
                INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
                VALUES (
                    NEW.user_id, 
                    CONCAT('📈 Weight Update: +', ABS(weight_diff), ' lbs (', prev_weight, ' → ', NEW.weight, ' lbs)'),
                    1, 
                    1, 
                    NOW()
                );
            ELSE
                INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
                VALUES (
                    NEW.user_id, 
                    CONCAT('📉 Weight Update: -', ABS(weight_diff), ' lbs (', prev_weight, ' → ', NEW.weight, ' lbs)'),
                    1, 
                    1, 
                    NOW()
                );
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 6. ATTENDANCE & CONSISTENCY
-- =====================================================

-- Trigger for missed workout days (after 3 days)
DELIMITER $$
CREATE TRIGGER `notify_missed_workouts` 
AFTER INSERT ON `attendance` 
FOR EACH ROW 
BEGIN
    DECLARE days_since_last_workout INT;
    
    -- Calculate days since last workout
    SELECT DATEDIFF(CURDATE(), MAX(log_date)) INTO days_since_last_workout
    FROM member_exercise_log 
    WHERE member_id = NEW.user_id;
    
    -- Notify after 3 days of no workouts
    IF days_since_last_workout >= 3 THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            CONCAT('😴 You haven\'t worked out in ', days_since_last_workout, ' days. Time to get back on track!'),
            1, 
            5, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 7. GYM & COMMUNITY NOTIFICATIONS
-- =====================================================

-- Trigger for new member welcome (existing - enhanced)
DELIMITER $$
CREATE TRIGGER `notify_member_registration_enhanced` 
AFTER INSERT ON `user` 
FOR EACH ROW 
BEGIN
    IF NEW.user_type_id = 4 THEN
        -- Notify admins
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        SELECT 
            u.id,
            CONCAT('👋 New member registered: ', NEW.fname, ' ', NEW.lname, ' (', NEW.email, ')'),
            1, 
            1, 
            NOW()
        FROM `user` u 
        WHERE u.user_type_id = 1;
        
        -- Welcome the new member
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.id, 
            '🎉 Welcome to Cnergy Gym! Start your fitness journey today with our personalized programs.',
            1, 
            3, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 8. ROUTINE & PROGRAM LIMIT NOTIFICATIONS
-- =====================================================

-- Trigger for routine limit reached (basic users)
DELIMITER $$
CREATE TRIGGER `notify_routine_limit` 
AFTER INSERT ON `member_programhdr` 
FOR EACH ROW 
BEGIN
    DECLARE routine_count INT;
    DECLARE is_premium BOOLEAN DEFAULT FALSE;
    
    -- Count user's routines
    SELECT COUNT(*) INTO routine_count
    FROM member_programhdr 
    WHERE user_id = NEW.user_id;
    
    -- Check if user is premium (has active subscription with plan_id = 1)
    SELECT COUNT(*) > 0 INTO is_premium
    FROM subscription s
    WHERE s.user_id = NEW.user_id 
    AND s.plan_id = 1 
    AND s.end_date > CURDATE();
    
    -- Notify basic users when they reach routine limit
    IF NOT is_premium AND routine_count >= 1 THEN
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            NEW.user_id, 
            '🔒 You\'ve reached your routine limit! Upgrade to Premium for unlimited routines and advanced features.',
            1, 
            8, 
            NOW()
        );
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- 9. WEEKLY PROGRESS SUMMARY
-- =====================================================

-- This would be called by a scheduled job/cron, not a trigger
-- But we can create a stored procedure for it

DELIMITER $$
CREATE PROCEDURE `SendWeeklyProgressSummary`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE user_id_var INT;
    DECLARE workout_count INT;
    DECLARE user_cursor CURSOR FOR 
        SELECT DISTINCT user_id FROM user WHERE user_type_id = 4;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN user_cursor;
    
    read_loop: LOOP
        FETCH user_cursor INTO user_id_var;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Count workouts this week
        SELECT COUNT(DISTINCT log_date) INTO workout_count
        FROM member_exercise_log 
        WHERE member_id = user_id_var 
        AND log_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
        
        -- Send weekly summary
        INSERT INTO `notification` (`user_id`, `message`, `status_id`, `type_id`, `timestamp`)
        VALUES (
            user_id_var, 
            CONCAT('📊 Weekly Summary: You completed ', workout_count, ' workouts this week. ', 
                   CASE 
                       WHEN workout_count >= 5 THEN 'Excellent consistency! 🔥'
                       WHEN workout_count >= 3 THEN 'Good progress! Keep it up! 💪'
                       WHEN workout_count >= 1 THEN 'Every workout counts! 🏋️'
                       ELSE 'Time to get back on track! 💪'
                   END),
            1, 
            1, 
            NOW()
        );
        
    END LOOP;
    
    CLOSE user_cursor;
END$$
DELIMITER ;

-- =====================================================
-- END OF NOTIFICATION TRIGGERS
-- =====================================================
