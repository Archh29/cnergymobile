-- Fix ALL plan_id 1 subscriptions that have wrong end_date (30 days instead of 365 days)
-- This finds subscriptions where plan_id=1 and duration is approximately 30 days instead of 365 days

UPDATE subscription 
SET end_date = DATE_ADD(start_date, INTERVAL 365 DAY)
WHERE plan_id = 1 
AND status_name IN (SELECT id FROM subscription_status WHERE status_name = 'approved')
AND DATEDIFF(end_date, start_date) BETWEEN 25 AND 35  -- Fix subscriptions with ~30 day duration
AND DATEDIFF(end_date, start_date) < 300; -- Only fix if less than 300 days (to avoid breaking correct ones)

-- Verify the fixes
SELECT 
    id, 
    plan_id, 
    start_date, 
    end_date, 
    DATEDIFF(end_date, start_date) as days,
    (SELECT plan_name FROM member_subscription_plan WHERE id = plan_id) as plan_name
FROM subscription 
WHERE DATEDIFF(end_date, start_date) BETWEEN 360 AND 370  -- Show 365-day subscriptions
ORDER BY id DESC
LIMIT 10;

