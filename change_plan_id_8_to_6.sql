-- Change Plan ID from 8 to 6
-- This script updates all foreign key references first, then updates the primary key
-- IMPORTANT: Backup your database before running this!

-- Step 1: Check if plan_id 6 already exists
SELECT 'Checking if plan_id 6 exists...' as status;
SELECT * FROM member_subscription_plan WHERE id = 6;

-- Step 2: Check current data for plan_id 8
SELECT 'Checking data for plan_id 8...' as status;
SELECT COUNT(*) as subscription_feature_count FROM subscription_feature WHERE plan_id = 8;
SELECT COUNT(*) as subscription_count FROM subscription WHERE plan_id = 8;

-- Step 3: Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- Step 4: Update all subscription_feature records from plan_id 8 to 6
UPDATE subscription_feature SET plan_id = 6 WHERE plan_id = 8;

-- Step 5: Update all subscription records from plan_id 8 to 6
UPDATE subscription SET plan_id = 6 WHERE plan_id = 8;

-- Step 6: Update the primary key in member_subscription_plan from 8 to 6
-- If plan_id 6 already exists, this will fail - you'll need to delete it first or merge data
UPDATE member_subscription_plan SET id = 6 WHERE id = 8;

-- Step 7: Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Step 8: Verify the changes
SELECT 'Verification - Plan ID 6:' as status;
SELECT * FROM member_subscription_plan WHERE id = 6;

SELECT 'Verification - No records with plan_id 8 should exist:' as status;
SELECT COUNT(*) as remaining_plan_id_8 FROM subscription_feature WHERE plan_id = 8;
SELECT COUNT(*) as remaining_plan_id_8 FROM subscription WHERE plan_id = 8;
SELECT COUNT(*) as remaining_plan_id_8 FROM member_subscription_plan WHERE id = 8;




