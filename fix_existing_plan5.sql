-- Fix existing Plan ID 5 subscriptions that were created with incorrect durations
-- This updates the end dates to correct values:
-- Plan ID 1 (Membership): Should be 365 days from start date
-- Plan ID 2 (Monthly Access): Should be 30 days from start date

-- Update Plan ID 1 (Membership) subscriptions that are part of a combination package
-- Check for users who have Plan ID 1, 2, and 5 with same start dates
UPDATE subscription s1
JOIN subscription s2 ON s1.user_id = s2.user_id AND s1.start_date = s2.start_date
JOIN subscription s5 ON s1.user_id = s5.user_id AND s1.start_date = s5.start_date
SET s1.end_date = DATE_ADD(s1.start_date, INTERVAL 365 DAY)
WHERE s1.plan_id = 1 
AND s2.plan_id = 2
AND s5.plan_id = 5
AND DATEDIFF(s1.end_date, s1.start_date) < 365;

-- Update Plan ID 2 (Monthly Access) subscriptions that are part of a combination package
UPDATE subscription s1
JOIN subscription s2 ON s1.user_id = s2.user_id AND s1.start_date = s2.start_date
JOIN subscription s5 ON s1.user_id = s5.user_id AND s1.start_date = s5.start_date
SET s1.end_date = DATE_ADD(s1.start_date, INTERVAL 30 DAY)
WHERE s1.plan_id = 2
AND s2.plan_id = 1
AND s5.plan_id = 5
AND DATEDIFF(s1.end_date, s1.start_date) < 30;

-- Display affected subscriptions
SELECT s.id, s.user_id, s.plan_id, p.plan_name, s.start_date, s.end_date, 
       DATEDIFF(s.end_date, s.start_date) as current_duration_days
FROM subscription s
JOIN member_subscription_plan p ON s.plan_id = p.id
WHERE s.plan_id IN (1, 2, 5)
AND EXISTS (
    SELECT 1 FROM subscription s1
    WHERE s1.user_id = s.user_id 
    AND s1.start_date = s.start_date
    AND s1.plan_id = 5
)
ORDER BY s.user_id, s.start_date, s.plan_id;









