-- Migration Script: Change Plan ID from 8 to 6
-- This script safely updates all foreign key references before updating the primary key
-- IMPORTANT: Backup your database before running this script!

-- Step 1: Check if plan_id 6 already exists
SELECT * FROM member_subscription_plan WHERE id = 6;

-- Step 2: Check current data for plan_id 8
SELECT 'subscription_feature' as table_name, COUNT(*) as count FROM subscription_feature WHERE plan_id = 8
UNION ALL
SELECT 'subscription' as table_name, COUNT(*) as count FROM subscription WHERE plan_id = 8
UNION ALL
SELECT 'sales_details' as table_name, COUNT(*) as count FROM sales_details sd
JOIN subscription s ON sd.subscription_id = s.id WHERE s.plan_id = 8;

-- Step 3: Check if plan_id 6 exists and has data
SELECT 'subscription_feature' as table_name, COUNT(*) as count FROM subscription_feature WHERE plan_id = 6
UNION ALL
SELECT 'subscription' as table_name, COUNT(*) as count FROM subscription WHERE plan_id = 6;

-- ============================================
-- IF PLAN_ID 6 DOES NOT EXIST OR IS EMPTY:
-- ============================================

-- Option A: If plan_id 6 doesn't exist, update all references first, then update the primary key
-- Step A1: Temporarily disable foreign key checks (use with caution)
SET FOREIGN_KEY_CHECKS = 0;

-- Step A2: Update all subscription_feature records
UPDATE subscription_feature SET plan_id = 6 WHERE plan_id = 8;

-- Step A3: Update all subscription records
UPDATE subscription SET plan_id = 6 WHERE plan_id = 8;

-- Step A4: Update the primary key in member_subscription_plan
UPDATE member_subscription_plan SET id = 6 WHERE id = 8;

-- Step A5: Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- IF PLAN_ID 6 ALREADY EXISTS:
-- ============================================

-- Option B: If plan_id 6 exists and you want to merge data
-- Step B1: Update subscription_feature (merge features - you may need to handle duplicates)
-- First, check for duplicate features
SELECT sf1.plan_id, sf1.feature_name, sf2.plan_id as plan_6_id, sf2.feature_name as plan_6_feature
FROM subscription_feature sf1
LEFT JOIN subscription_feature sf2 ON sf1.feature_name = sf2.feature_name AND sf2.plan_id = 6
WHERE sf1.plan_id = 8;

-- Step B2: Delete duplicate features from plan_id 8 (if any)
-- DELETE FROM subscription_feature WHERE plan_id = 8 
-- AND feature_name IN (SELECT feature_name FROM subscription_feature WHERE plan_id = 6);

-- Step B3: Update subscription_feature to point to plan_id 6 (non-duplicates)
UPDATE subscription_feature SET plan_id = 6 WHERE plan_id = 8;

-- Step B4: Update subscription records
UPDATE subscription SET plan_id = 6 WHERE plan_id = 8;

-- Step B5: Delete plan_id 8 from member_subscription_plan (since 6 already exists)
DELETE FROM member_subscription_plan WHERE id = 8;

-- ============================================
-- SAFER ALTERNATIVE: Use a temporary ID
-- ============================================

-- Option C: If you're unsure, use a temporary high ID first
-- Step C1: Update to a temporary ID (e.g., 999) first
SET FOREIGN_KEY_CHECKS = 0;
UPDATE subscription_feature SET plan_id = 999 WHERE plan_id = 8;
UPDATE subscription SET plan_id = 999 WHERE plan_id = 8;
UPDATE member_subscription_plan SET id = 999 WHERE id = 8;
SET FOREIGN_KEY_CHECKS = 1;

-- Step C2: Check if plan_id 6 exists
-- If plan_id 6 doesn't exist, update from 999 to 6
SET FOREIGN_KEY_CHECKS = 0;
UPDATE subscription_feature SET plan_id = 6 WHERE plan_id = 999;
UPDATE subscription SET plan_id = 6 WHERE plan_id = 999;
UPDATE member_subscription_plan SET id = 6 WHERE id = 999;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify no records with plan_id 8 exist
SELECT 'subscription_feature' as table_name, COUNT(*) as remaining FROM subscription_feature WHERE plan_id = 8
UNION ALL
SELECT 'subscription' as table_name, COUNT(*) as remaining FROM subscription WHERE plan_id = 8
UNION ALL
SELECT 'member_subscription_plan' as table_name, COUNT(*) as remaining FROM member_subscription_plan WHERE id = 8;

-- Verify plan_id 6 exists and has correct data
SELECT * FROM member_subscription_plan WHERE id = 6;
SELECT COUNT(*) as feature_count FROM subscription_feature WHERE plan_id = 6;
SELECT COUNT(*) as subscription_count FROM subscription WHERE plan_id = 6;




