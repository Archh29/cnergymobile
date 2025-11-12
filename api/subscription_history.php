<?php
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Max-Age: 86400');

    // Handle preflight requests
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }

    // Database configuration
    $host = "localhost";
    $dbname = "u773938685_cnergydb";
    $username = "u773938685_archh29";
    $password = "Gwapoko385@";

    try {
        $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed'
        ]);
        exit();
    }

    $method = $_SERVER['REQUEST_METHOD'];
    $action = $_GET['action'] ?? '';

    try {
        switch ($action) {
            case 'get-subscription-history':
                if ($method === 'GET' && isset($_GET['user_id'])) {
                    getSubscriptionHistory($pdo, (int)$_GET['user_id']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User ID required']);
                }
                break;
                
            case 'get-current-subscription':
                if ($method === 'GET' && isset($_GET['user_id'])) {
                    getCurrentSubscription($pdo, (int)$_GET['user_id']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User ID required']);
                }
                break;
                
            default:
                echo json_encode(['success' => false, 'message' => 'Invalid action']);
                break;
        }
    } catch (Exception $e) {
        error_log("ERROR - Subscription history API: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Server error']);
    }

    function getSubscriptionHistory($pdo, $userId) {
        try {
            error_log("Getting subscription history for user: $userId");
            
            // Debug: Test database connection
            if (!$pdo) {
                error_log("ERROR - Database connection is null");
                throw new Exception("Database connection failed");
            }
            
            // First, let's check if the user exists
            $userCheckStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE id = ?");
            $userCheckStmt->execute([$userId]);
            $user = $userCheckStmt->fetch(PDO::FETCH_ASSOC);
            
            
            if (!$user) {
                error_log("User with ID $userId not found");
                echo json_encode([
                    'success' => false,
                    'message' => 'User not found'
                ]);
                return;
            }
            
            error_log("User found: " . json_encode($user));
            
            // Test basic table existence first
            try {
                $testStmt = $pdo->prepare("SHOW TABLES LIKE 'coach_member_list'");
                $testStmt->execute();
                $tableExists = $testStmt->fetch(PDO::FETCH_ASSOC);
                error_log("coach_member_list table exists: " . ($tableExists ? 'Yes' : 'No'));
            } catch (Exception $e) {
                error_log("Error checking table existence: " . $e->getMessage());
            }
            
            // Check if there are any coach requests for this user
            try {
                $coachCheckStmt = $pdo->prepare("SELECT COUNT(*) as count FROM coach_member_list WHERE member_id = ?");
                $coachCheckStmt->execute([$userId]);
                $coachCount = $coachCheckStmt->fetch(PDO::FETCH_ASSOC);
                error_log("Coach requests count for user $userId: " . $coachCount['count']);
            } catch (Exception $e) {
                error_log("Error checking coach requests count: " . $e->getMessage());
            }
            
            // Test with a very basic query first
            try {
                $basicStmt = $pdo->prepare("SELECT * FROM coach_member_list WHERE member_id = ? LIMIT 1");
                $basicStmt->execute([$userId]);
                $basicResult = $basicStmt->fetch(PDO::FETCH_ASSOC);
                error_log("Basic query result: " . json_encode($basicResult));
            } catch (Exception $e) {
                error_log("Error in basic query: " . $e->getMessage());
            }
            
        // Get all coach requests and their status with complete coach details
        $stmt = $pdo->prepare("
            SELECT 
                cml.id as request_id,
                cml.coach_id,
                cml.member_id,
                CASE 
                    WHEN cml.status = '' OR cml.status IS NULL THEN 'expired'
                    ELSE cml.status
                END as status,
                cml.coach_approval,
                cml.staff_approval,
                cml.requested_at,
                cml.coach_approved_at,
                cml.staff_approved_at,
                cml.expires_at,
                cml.remaining_sessions,
                cml.rate_type,
                cml.handled_by_coach,
                cml.handled_by_staff,
                u.fname as coach_fname,
                u.lname as coach_lname,
                u.email as coach_email,
                c.session_package_rate,
                c.session_package_count,
                c.specialty,
                c.experience,
                 -- Get detailed request flow status
                 CASE 
                     WHEN cml.coach_approval = 'pending' THEN 'Waiting for Coach Approval'
                     WHEN cml.coach_approval = 'rejected' THEN 'Rejected by Coach'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'pending' THEN 'Waiting for Staff Approval'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'rejected' THEN 'Rejected by Staff'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'approved' AND (cml.status = 'active' OR cml.status = '') THEN 'Active - Go to Front Desk to Pay'
                     WHEN cml.status = 'expired' THEN 'Expired'
                     WHEN cml.status = 'disconnected' THEN 'Disconnected'
                     ELSE 'Unknown Status'
                 END as status_display,
                 -- Add request flow information
                 CASE 
                     WHEN cml.coach_approval = 'pending' THEN 'Coach needs to approve your request first'
                     WHEN cml.coach_approval = 'rejected' THEN 'Coach rejected your request - contact coach for details'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'pending' THEN 'Coach approved - waiting for staff final approval'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'rejected' THEN 'Staff rejected - contact front desk for details'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'approved' AND (cml.status = 'active' OR cml.status = '') THEN 'Both approved - go to front desk to complete payment'
                     WHEN cml.status = 'expired' THEN 'Coach session package expired'
                     WHEN cml.status = 'disconnected' THEN 'Coach connection ended'
                     ELSE 'Contact support for assistance'
                 END as request_flow_status,
                 -- Add next action needed
                 CASE 
                     WHEN cml.coach_approval = 'pending' THEN 'Wait for coach to approve your request'
                     WHEN cml.coach_approval = 'rejected' THEN 'Contact coach to discuss rejection'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'pending' THEN 'Wait for staff approval'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'rejected' THEN 'Contact front desk for assistance'
                     WHEN cml.coach_approval = 'approved' AND cml.staff_approval = 'approved' AND (cml.status = 'active' OR cml.status = '') THEN 'Go to front desk to pay for coach sessions'
                     WHEN cml.status = 'expired' THEN 'Request new coach package if needed'
                     WHEN cml.status = 'disconnected' THEN 'Request new coach if needed'
                     ELSE 'Contact support'
                 END as next_action,
                -- Calculate days remaining
                CASE 
                    WHEN cml.expires_at IS NOT NULL THEN 
                        DATEDIFF(cml.expires_at, NOW())
                    ELSE NULL
                END as days_remaining
            FROM coach_member_list cml
            LEFT JOIN user u ON u.id = cml.coach_id
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.member_id = ?
            ORDER BY cml.requested_at DESC
        ");
            
            $stmt->execute([$userId]);
            $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
            error_log("Coach requests query executed successfully, found " . count($requests) . " requests");
            
            // Debug: Check if there are any PDO errors
            if ($stmt->errorCode() !== '00000') {
                $errorInfo = $stmt->errorInfo();
                error_log("ERROR - Coach requests query error: " . json_encode($errorInfo));
            }
            
            // Test subscription table existence
            try {
                $subTestStmt = $pdo->prepare("SHOW TABLES LIKE 'subscription'");
                $subTestStmt->execute();
                $subTableExists = $subTestStmt->fetch(PDO::FETCH_ASSOC);
                error_log("subscription table exists: " . ($subTableExists ? 'Yes' : 'No'));
                
                // Debug: Check if there are any PDO errors
                if ($subTestStmt->errorCode() !== '00000') {
                    $errorInfo = $subTestStmt->errorInfo();
                    error_log("ERROR - Subscription table check error: " . json_encode($errorInfo));
                }
            } catch (Exception $e) {
                error_log("Error checking subscription table existence: " . $e->getMessage());
            }
            
        
         // Get ALL subscription history with detailed request flow
         $subscriptionHistoryStmt = $pdo->prepare("
             SELECT 
                 s.*,
                 msp.plan_name,
                 msp.price as original_price,
                 msp.duration_months,
                 msp.duration_days,
                 ss.status_name,
                 CASE 
                     WHEN ss.status_name = 'approved' AND s.end_date > CURDATE() THEN 'Active'
                     WHEN ss.status_name = 'approved' AND s.end_date <= CURDATE() THEN 'Expired'
                     WHEN ss.status_name = 'pending_approval' THEN 'Pending Staff Approval'
                     WHEN ss.status_name = 'rejected' THEN 'Rejected by Staff'
                     WHEN ss.status_name = 'cancelled' THEN 'Cancelled'
                     ELSE ss.status_name
                 END as display_status,
                 -- Add detailed request flow information
                 CASE 
                     WHEN ss.status_name = 'pending_approval' THEN 'Waiting for staff approval and payment at front desk'
                     WHEN ss.status_name = 'approved' THEN 'Approved and paid - membership active'
                     WHEN ss.status_name = 'rejected' THEN 'Rejected by staff - contact front desk for details'
                     WHEN ss.status_name = 'cancelled' THEN 'Cancelled by user'
                     ELSE 'Unknown status'
                 END as request_flow_status,
                 -- Add next action needed
                 CASE 
                     WHEN ss.status_name = 'pending_approval' THEN 'Go to front desk to complete payment'
                     WHEN ss.status_name = 'approved' THEN 'Membership is active'
                     WHEN ss.status_name = 'rejected' THEN 'Contact front desk for assistance'
                     WHEN ss.status_name = 'cancelled' THEN 'Request a new subscription if needed'
                     ELSE 'Contact support'
                 END as next_action
             FROM subscription s
             LEFT JOIN member_subscription_plan msp ON s.plan_id = msp.id
             LEFT JOIN subscription_status ss ON s.status_id = ss.id
             WHERE s.user_id = ?
             ORDER BY s.start_date DESC
         ");
             
             $subscriptionHistoryStmt->execute([$userId]);
             $allSubscriptions = $subscriptionHistoryStmt->fetchAll(PDO::FETCH_ASSOC);
             
             // Calculate periods and total duration for each subscription
             foreach ($allSubscriptions as &$sub) {
                 $periods = 1;
                 $originalPrice = floatval($sub['original_price'] ?? 0);
                 $amountPaid = floatval($sub['amount_paid'] ?? 0);
                 
                 if ($originalPrice > 0) {
                     $periods = round($amountPaid / $originalPrice);
                     if ($periods < 1) $periods = 1;
                 }
                 
                 $sub['periods'] = $periods;
                 
                 // Calculate total duration based on periods
                 $baseDurationMonths = intval($sub['duration_months'] ?? 0);
                 $baseDurationDays = intval($sub['duration_days'] ?? 0);
                 
                 if ($baseDurationDays > 0) {
                     $sub['total_duration_days'] = $baseDurationDays * $periods;
                     $sub['total_duration_months'] = 0;
                 } else {
                     $sub['total_duration_months'] = $baseDurationMonths * $periods;
                     $sub['total_duration_days'] = 0;
                 }
             }
             unset($sub); // Break reference
             
            // Get current subscription using the SAME logic as subscription_plans.php
            // Filter active subscriptions directly in SQL using CURDATE() (same as getAvailablePlansForUser)
            $activeSubscriptionsStmt = $pdo->prepare("
                SELECT 
                    s.*,
                    msp.plan_name,
                    msp.price as original_price,
                    msp.duration_months,
                    msp.duration_days,
                    ss.status_name
                FROM subscription s
                JOIN subscription_status ss ON s.status_id = ss.id
                JOIN member_subscription_plan msp ON s.plan_id = msp.id
                WHERE s.user_id = ? 
                AND ss.status_name = 'approved' 
                AND s.end_date >= CURDATE()
                ORDER BY s.start_date DESC
            ");
            $activeSubscriptionsStmt->execute([$userId]);
            $activeSubscriptions = $activeSubscriptionsStmt->fetchAll(PDO::FETCH_ASSOC);
            
            error_log("DEBUG getSubscriptionHistory: Found " . count($activeSubscriptions) . " active subscriptions (using SQL filter with CURDATE())");
            foreach ($activeSubscriptions as $idx => $sub) {
                error_log("DEBUG getSubscriptionHistory: Active Subscription #$idx - ID: {$sub['id']}, Plan ID: {$sub['plan_id']}, Plan Name: {$sub['plan_name']}, Start: {$sub['start_date']}, End: {$sub['end_date']}");
            }
            
            // Calculate periods and total duration for each active subscription
            foreach ($activeSubscriptions as &$sub) {
                $periods = 1;
                $originalPrice = floatval($sub['original_price'] ?? 0);
                $amountPaid = floatval($sub['amount_paid'] ?? 0);
                
                if ($originalPrice > 0) {
                    $periods = round($amountPaid / $originalPrice);
                    if ($periods < 1) $periods = 1;
                }
                
                $sub['periods'] = $periods;
                
                // Calculate total duration based on periods
                $baseDurationMonths = intval($sub['duration_months'] ?? 0);
                $baseDurationDays = intval($sub['duration_days'] ?? 0);
                
                if ($baseDurationDays > 0) {
                    $sub['total_duration_days'] = $baseDurationDays * $periods;
                    $sub['total_duration_months'] = 0;
                } else {
                    $sub['total_duration_months'] = $baseDurationMonths * $periods;
                    $sub['total_duration_days'] = 0;
                }
            }
            unset($sub); // Break reference
            
            // Prioritize active subscriptions: Day Pass (plan_id 6) > Monthly Access (plan_id 2, 3) > Membership (plan_id 1)
            $currentSubscription = null;
            $dayPassSubscription = null;
            $monthlySubscription = null;
            $membershipSubscription = null;
            
            foreach ($activeSubscriptions as $sub) {
                $planId = intval($sub['plan_id']);
                
                // Categorize active subscriptions by plan type
                if ($planId == 6) {
                    // Day Pass - prioritize most recent
                    if ($dayPassSubscription === null || $sub['start_date'] > $dayPassSubscription['start_date']) {
                        $dayPassSubscription = $sub;
                    }
                } elseif ($planId == 2 || $planId == 3) {
                    // Monthly Access - prioritize most recent
                    if ($monthlySubscription === null || $sub['start_date'] > $monthlySubscription['start_date']) {
                        $monthlySubscription = $sub;
                    }
                } elseif ($planId == 1) {
                    // Membership - prioritize most recent
                    if ($membershipSubscription === null || $sub['start_date'] > $membershipSubscription['start_date']) {
                        $membershipSubscription = $sub;
                    }
                }
            }
            
            // Select subscription based on priority: Day Pass > Monthly > Membership
            error_log("DEBUG getSubscriptionHistory: Active subscriptions found - Day Pass: " . ($dayPassSubscription ? "YES (ID: {$dayPassSubscription['id']}, Plan: {$dayPassSubscription['plan_name']})" : "NO") . ", Monthly: " . ($monthlySubscription ? "YES (ID: {$monthlySubscription['id']}, Plan: {$monthlySubscription['plan_name']})" : "NO") . ", Membership: " . ($membershipSubscription ? "YES (ID: {$membershipSubscription['id']}, Plan: {$membershipSubscription['plan_name']})" : "NO"));
            
            if ($dayPassSubscription !== null) {
                $currentSubscription = $dayPassSubscription;
                error_log("DEBUG getSubscriptionHistory: Selected Day Pass subscription (ID: {$currentSubscription['id']}, Plan: {$currentSubscription['plan_name']})");
            } elseif ($monthlySubscription !== null) {
                $currentSubscription = $monthlySubscription;
                error_log("DEBUG getSubscriptionHistory: Selected Monthly subscription (ID: {$currentSubscription['id']}, Plan: {$currentSubscription['plan_name']})");
            } elseif ($membershipSubscription !== null) {
                $currentSubscription = $membershipSubscription;
                error_log("DEBUG getSubscriptionHistory: Selected Membership subscription (ID: {$currentSubscription['id']}, Plan: {$currentSubscription['plan_name']})");
            } else {
                error_log("DEBUG getSubscriptionHistory: No active subscription found");
            }
            
            // Calculate periods and total duration for current subscription if it exists
            if ($currentSubscription) {
                $periods = 1;
                $originalPrice = floatval($currentSubscription['original_price'] ?? 0);
                $amountPaid = floatval($currentSubscription['amount_paid'] ?? 0);
                
                if ($originalPrice > 0) {
                    $periods = round($amountPaid / $originalPrice);
                    if ($periods < 1) $periods = 1;
                }
                
                $currentSubscription['periods'] = $periods;
                
                // Calculate total duration based on periods
                $baseDurationMonths = intval($currentSubscription['duration_months'] ?? 0);
                $baseDurationDays = intval($currentSubscription['duration_days'] ?? 0);
                
                if ($baseDurationDays > 0) {
                    $currentSubscription['total_duration_days'] = $baseDurationDays * $periods;
                    $currentSubscription['total_duration_months'] = 0;
                } else {
                    $currentSubscription['total_duration_months'] = $baseDurationMonths * $periods;
                    $currentSubscription['total_duration_days'] = 0;
                }
            }
             
             error_log("Subscription history query executed successfully, found " . count($allSubscriptions) . " subscription requests");
            
            
        // Process the data with complete coach details
        $processedRequests = [];
        foreach ($requests as $request) {
            $processedRequests[] = [
                'request_id' => $request['request_id'],
                'coach_id' => $request['coach_id'],
                'coach_name' => trim(($request['coach_fname'] ?? '') . ' ' . ($request['coach_lname'] ?? '')),
                'coach_email' => $request['coach_email'] ?? '',
                'coach_specialty' => $request['specialty'] ?? '',
                'coach_experience' => $request['experience'] ?? '',
                'session_package_rate' => $request['session_package_rate'] ?? null,
                'session_package_count' => $request['session_package_count'] ?? null,
                'status' => $request['status'],
                'status_display' => $request['status_display'],
                'coach_approval' => $request['coach_approval'],
                'staff_approval' => $request['staff_approval'],
                'requested_at' => $request['requested_at'],
                'coach_approved_at' => $request['coach_approved_at'],
                'staff_approved_at' => $request['staff_approved_at'],
                'expires_at' => $request['expires_at'],
                'days_remaining' => $request['days_remaining'],
                'remaining_sessions' => $request['remaining_sessions'],
                'rate_type' => $request['rate_type']
            ];
        }
            
            // Get payment information for current subscription
            $paymentInfo = null;
            if ($currentSubscription) {
                $paymentStmt = $pdo->prepare("
                    SELECT COUNT(*) as payment_count, SUM(amount) as total_paid
                    FROM payment 
                    WHERE subscription_id = ?
                ");
                $paymentStmt->execute([$currentSubscription['id']]);
                $paymentInfo = $paymentStmt->fetch(PDO::FETCH_ASSOC);
                
                // If no payments found, use amount_paid from subscription
                if ($paymentInfo['payment_count'] == 0) {
                    $paymentInfo['total_paid'] = $currentSubscription['amount_paid'] ?? 0;
                }
            }
            
             $response = [
                 'success' => true,
                 'requests' => $processedRequests,
                 'current_subscription' => $currentSubscription,
                 'subscription_history' => $allSubscriptions, // Include all subscription requests
                 'payment_info' => $paymentInfo,
                 'total_requests' => count($processedRequests),
                 'total_subscription_requests' => count($allSubscriptions)
             ];
            
            error_log("Sending response: " . json_encode($response));
            echo json_encode($response);
            
        } catch (PDOException $e) {
            error_log("ERROR - Get subscription history failed: " . $e->getMessage());
            error_log("ERROR - PDO Error Code: " . $e->getCode());
            error_log("ERROR - PDO Error Info: " . json_encode($e->errorInfo));
            echo json_encode([
                'success' => false,
                'message' => 'Failed to get subscription history',
                'error_details' => $e->getMessage(),
                'error_code' => $e->getCode()
            ]);
        }
    }

    function getCurrentSubscription($pdo, $userId) {
        try {
            error_log("Getting current subscription for user: $userId");
            
            // Debug: Test database connection
            if (!$pdo) {
                error_log("ERROR - Database connection is null in getCurrentSubscription");
                throw new Exception("Database connection failed");
            }
            
            // First, let's check if the user exists
            $userCheckStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE id = ?");
            $userCheckStmt->execute([$userId]);
            $user = $userCheckStmt->fetch(PDO::FETCH_ASSOC);
            
            
            if (!$user) {
                error_log("User with ID $userId not found in getCurrentSubscription");
                echo json_encode([
                    'success' => false,
                    'message' => 'User not found'
                ]);
                return;
            }
            
            error_log("User found in getCurrentSubscription: " . json_encode($user));
            
        // Get current active coach connection with coach details
        $activeCoachStmt = $pdo->prepare("
            SELECT 
                cml.*,
                u.fname as coach_fname,
                u.lname as coach_lname,
                u.email as coach_email,
                c.session_package_rate,
                c.session_package_count,
                c.specialty,
                c.experience
            FROM coach_member_list cml
            LEFT JOIN user u ON u.id = cml.coach_id
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.member_id = ? 
            AND (cml.status = 'active' OR (cml.status = '' AND cml.coach_approval = 'approved' AND cml.staff_approval = 'approved'))
            ORDER BY cml.requested_at DESC
            LIMIT 1
        ");
            
            $activeCoachStmt->execute([$userId]);
            $activeCoach = $activeCoachStmt->fetch(PDO::FETCH_ASSOC);
            
            
        // Get ALL subscription history (not just current)
        // Use the SAME query structure as subscription_plans.php for consistency
        $subscriptionStmt = $pdo->prepare("
            SELECT 
                s.*,
                msp.plan_name,
                msp.price as original_price,
                msp.duration_months,
                msp.duration_days,
                ss.status_name,
                CASE 
                    WHEN ss.status_name = 'approved' AND s.end_date >= CURDATE() THEN 'Active'
                    WHEN ss.status_name = 'approved' AND s.end_date < CURDATE() THEN 'Expired'
                    WHEN ss.status_name = 'pending_approval' THEN 'Pending Staff Approval'
                    WHEN ss.status_name = 'rejected' THEN 'Rejected by Staff'
                    WHEN ss.status_name = 'cancelled' THEN 'Cancelled'
                    ELSE ss.status_name
                END as display_status,
                -- Add request flow information
                CASE 
                    WHEN ss.status_name = 'pending_approval' THEN 'Waiting for staff approval and payment at front desk'
                    WHEN ss.status_name = 'approved' THEN 'Approved and paid - membership active'
                    WHEN ss.status_name = 'rejected' THEN 'Rejected by staff - contact front desk'
                    WHEN ss.status_name = 'cancelled' THEN 'Cancelled by user'
                    ELSE 'Unknown status'
                END as request_flow_status
            FROM subscription s
            LEFT JOIN member_subscription_plan msp ON s.plan_id = msp.id
            LEFT JOIN subscription_status ss ON s.status_id = ss.id
            WHERE s.user_id = ?
            ORDER BY s.start_date DESC
        ");
            
            $subscriptionStmt->execute([$userId]);
            $allSubscriptions = $subscriptionStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Debug: Log all subscriptions found
            error_log("DEBUG getCurrentSubscription: Found " . count($allSubscriptions) . " total subscriptions for user $userId");
            foreach ($allSubscriptions as $idx => $sub) {
                error_log("DEBUG getCurrentSubscription: Subscription #$idx - ID: {$sub['id']}, Plan ID: {$sub['plan_id']}, Plan Name: {$sub['plan_name']}, Status: {$sub['status_name']}, Start: {$sub['start_date']}, End: {$sub['end_date']}");
            }
            
            // Calculate periods and total duration for each subscription
            foreach ($allSubscriptions as &$sub) {
                $periods = 1;
                $originalPrice = floatval($sub['original_price'] ?? 0);
                $amountPaid = floatval($sub['amount_paid'] ?? 0);
                
                if ($originalPrice > 0) {
                    $periods = round($amountPaid / $originalPrice);
                    if ($periods < 1) $periods = 1;
                }
                
                $sub['periods'] = $periods;
                
                // Calculate total duration based on periods
                $baseDurationMonths = intval($sub['duration_months'] ?? 0);
                $baseDurationDays = intval($sub['duration_days'] ?? 0);
                
                if ($baseDurationDays > 0) {
                    $sub['total_duration_days'] = $baseDurationDays * $periods;
                    $sub['total_duration_months'] = 0;
                } else {
                    $sub['total_duration_months'] = $baseDurationMonths * $periods;
                    $sub['total_duration_days'] = 0;
                }
            }
            unset($sub); // Break reference
            
            // Note: plan_id 5 (combination package) now creates separate subscriptions for plan_id 1 and 2
            // So we show all active subscriptions together
            
            // Get current subscription using the SAME logic as subscription_plans.php
            // Filter active subscriptions directly in SQL using CURDATE() (same as getAvailablePlansForUser)
            $activeSubscriptionsStmt = $pdo->prepare("
                SELECT 
                    s.*,
                    msp.plan_name,
                    msp.price as original_price,
                    msp.duration_months,
                    msp.duration_days,
                    ss.status_name
                FROM subscription s
                JOIN subscription_status ss ON s.status_id = ss.id
                JOIN member_subscription_plan msp ON s.plan_id = msp.id
                WHERE s.user_id = ? 
                AND ss.status_name = 'approved' 
                AND s.end_date >= CURDATE()
                ORDER BY s.start_date DESC
            ");
            $activeSubscriptionsStmt->execute([$userId]);
            $activeSubscriptions = $activeSubscriptionsStmt->fetchAll(PDO::FETCH_ASSOC);
            
            error_log("DEBUG getCurrentSubscription: Found " . count($activeSubscriptions) . " active subscriptions (using SQL filter with CURDATE())");
            foreach ($activeSubscriptions as $idx => $sub) {
                error_log("DEBUG getCurrentSubscription: Active Subscription #$idx - ID: {$sub['id']}, Plan ID: {$sub['plan_id']}, Plan Name: {$sub['plan_name']}, Start: {$sub['start_date']}, End: {$sub['end_date']}");
            }
            
            // Calculate periods and total duration for each active subscription
            foreach ($activeSubscriptions as &$sub) {
                $periods = 1;
                $originalPrice = floatval($sub['original_price'] ?? 0);
                $amountPaid = floatval($sub['amount_paid'] ?? 0);
                
                if ($originalPrice > 0) {
                    $periods = round($amountPaid / $originalPrice);
                    if ($periods < 1) $periods = 1;
                }
                
                $sub['periods'] = $periods;
                
                // Calculate total duration based on periods
                $baseDurationMonths = intval($sub['duration_months'] ?? 0);
                $baseDurationDays = intval($sub['duration_days'] ?? 0);
                
                if ($baseDurationDays > 0) {
                    $sub['total_duration_days'] = $baseDurationDays * $periods;
                    $sub['total_duration_months'] = 0;
                } else {
                    $sub['total_duration_months'] = $baseDurationMonths * $periods;
                    $sub['total_duration_days'] = 0;
                }
            }
            unset($sub); // Break reference
            
            // Prioritize active subscriptions: Day Pass (plan_id 6) > Monthly Access (plan_id 2, 3) > Membership (plan_id 1)
            $subscription = null;
            $dayPassSubscription = null;
            $monthlySubscription = null;
            $membershipSubscription = null;
            
            foreach ($activeSubscriptions as $sub) {
                $planId = intval($sub['plan_id']);
                
                // Categorize active subscriptions by plan type
                if ($planId == 6) {
                    // Day Pass - prioritize most recent
                    if ($dayPassSubscription === null || $sub['start_date'] > $dayPassSubscription['start_date']) {
                        $dayPassSubscription = $sub;
                    }
                } elseif ($planId == 2 || $planId == 3) {
                    // Monthly Access - prioritize most recent
                    if ($monthlySubscription === null || $sub['start_date'] > $monthlySubscription['start_date']) {
                        $monthlySubscription = $sub;
                    }
                } elseif ($planId == 1) {
                    // Membership - prioritize most recent
                    if ($membershipSubscription === null || $sub['start_date'] > $membershipSubscription['start_date']) {
                        $membershipSubscription = $sub;
                    }
                }
            }
            
            // Select subscription based on priority: Day Pass > Monthly > Membership
            error_log("DEBUG getCurrentSubscription: Active subscriptions found - Day Pass: " . ($dayPassSubscription ? "YES (ID: {$dayPassSubscription['id']}, Plan: {$dayPassSubscription['plan_name']})" : "NO") . ", Monthly: " . ($monthlySubscription ? "YES (ID: {$monthlySubscription['id']}, Plan: {$monthlySubscription['plan_name']})" : "NO") . ", Membership: " . ($membershipSubscription ? "YES (ID: {$membershipSubscription['id']}, Plan: {$membershipSubscription['plan_name']})" : "NO"));
            
            if ($dayPassSubscription !== null) {
                $subscription = $dayPassSubscription;
                error_log("DEBUG getCurrentSubscription: Selected Day Pass subscription (ID: {$subscription['id']}, Plan: {$subscription['plan_name']})");
            } elseif ($monthlySubscription !== null) {
                $subscription = $monthlySubscription;
                error_log("DEBUG getCurrentSubscription: Selected Monthly subscription (ID: {$subscription['id']}, Plan: {$subscription['plan_name']})");
            } elseif ($membershipSubscription !== null) {
                $subscription = $membershipSubscription;
                error_log("DEBUG getCurrentSubscription: Selected Membership subscription (ID: {$subscription['id']}, Plan: {$subscription['plan_name']})");
            } else {
                error_log("DEBUG getCurrentSubscription: No active subscription found");
            }
            
            // Calculate periods and total duration for current subscription if it exists
            if ($subscription) {
                $periods = 1;
                $originalPrice = floatval($subscription['original_price'] ?? 0);
                $amountPaid = floatval($subscription['amount_paid'] ?? 0);
                
                if ($originalPrice > 0) {
                    $periods = round($amountPaid / $originalPrice);
                    if ($periods < 1) $periods = 1;
                }
                
                $subscription['periods'] = $periods;
                
                // Calculate total duration based on periods
                $baseDurationMonths = intval($subscription['duration_months'] ?? 0);
                $baseDurationDays = intval($subscription['duration_days'] ?? 0);
                
                if ($baseDurationDays > 0) {
                    $subscription['total_duration_days'] = $baseDurationDays * $periods;
                    $subscription['total_duration_months'] = 0;
                } else {
                    $subscription['total_duration_months'] = $baseDurationMonths * $periods;
                    $subscription['total_duration_days'] = 0;
                }
            }
            
            
            // Calculate subscription status
            $subscriptionStatus = 'Inactive';
            $daysRemaining = 0;
            
            if ($subscription) {
                $startDate = new DateTime($subscription['start_date']);
                $endDate = new DateTime($subscription['end_date']);
                $now = new DateTime();
                $today = $now->format('Y-m-d');
                
                $startDateOnly = $startDate->format('Y-m-d');
                $endDateOnly = $endDate->format('Y-m-d');
                
                // Use date-only comparison for consistency
                if ($startDateOnly <= $today && $endDateOnly >= $today) {
                    $subscriptionStatus = 'Active';
                    // Calculate days remaining using date difference
                    $endDateObj = new DateTime($endDateOnly);
                    $todayObj = new DateTime($today);
                    $daysRemaining = $todayObj->diff($endDateObj)->days;
                } elseif ($endDateOnly < $today) {
                    $subscriptionStatus = 'Expired';
                } else {
                    $subscriptionStatus = 'Pending';
                }
            }
            
            // Process active coach data
            $processedActiveCoach = null;
            if ($activeCoach && is_array($activeCoach)) {
                $processedActiveCoach = [
                    'coach_id' => $activeCoach['coach_id'],
                    'coach_name' => trim(($activeCoach['coach_fname'] ?? '') . ' ' . ($activeCoach['coach_lname'] ?? '')),
                    'coach_email' => $activeCoach['coach_email'] ?? '',
                    'coach_specialty' => $activeCoach['specialty'] ?? '',
                    'coach_experience' => $activeCoach['experience'] ?? '',
                    'session_package_rate' => $activeCoach['session_package_rate'] ?? null,
                    'session_package_count' => $activeCoach['session_package_count'] ?? null,
                    'status' => $activeCoach['status'],
                    'rate_type' => $activeCoach['rate_type'],
                    'remaining_sessions' => $activeCoach['remaining_sessions'],
                    'expires_at' => $activeCoach['expires_at']
                ];
            }
            
            // Get payment information for subscription
            $paymentInfo = null;
            if ($subscription) {
                $paymentStmt = $pdo->prepare("
                    SELECT COUNT(*) as payment_count, SUM(amount) as total_paid
                    FROM payment 
                    WHERE subscription_id = ?
                ");
                $paymentStmt->execute([$subscription['id']]);
                $paymentInfo = $paymentStmt->fetch(PDO::FETCH_ASSOC);
                
                
                // If no payments found, use amount_paid from subscription
                if ($paymentInfo['payment_count'] == 0) {
                    $paymentInfo['total_paid'] = $subscription['amount_paid'] ?? 0;
                }
            }
            
            // Get active gym membership separately (plan_id = 1) if it exists and is active
            // This is separate from the prioritized subscription, so users can see their membership status
            // even if they have a Day Pass or Monthly Access as their current subscription
            $activeMembership = null;
            if ($membershipSubscription !== null) {
                // Calculate membership status and days remaining
                $membershipStartDate = new DateTime($membershipSubscription['start_date']);
                $membershipEndDate = new DateTime($membershipSubscription['end_date']);
                $now = new DateTime();
                $today = $now->format('Y-m-d');
                
                $membershipStartDateOnly = $membershipStartDate->format('Y-m-d');
                $membershipEndDateOnly = $membershipEndDate->format('Y-m-d');
                
                $membershipStatus = 'Inactive';
                $membershipDaysRemaining = 0;
                
                if ($membershipStartDateOnly <= $today && $membershipEndDateOnly >= $today) {
                    $membershipStatus = 'Active';
                    $membershipEndDateObj = new DateTime($membershipEndDateOnly);
                    $todayObj = new DateTime($today);
                    $membershipDaysRemaining = $todayObj->diff($membershipEndDateObj)->days;
                } elseif ($membershipEndDateOnly < $today) {
                    $membershipStatus = 'Expired';
                } else {
                    $membershipStatus = 'Pending';
                }
                
                $activeMembership = [
                    'id' => $membershipSubscription['id'],
                    'plan_id' => $membershipSubscription['plan_id'],
                    'plan_name' => $membershipSubscription['plan_name'],
                    'start_date' => $membershipSubscription['start_date'],
                    'end_date' => $membershipSubscription['end_date'],
                    'original_price' => $membershipSubscription['original_price'],
                    'amount_paid' => $membershipSubscription['amount_paid'],
                    'status' => $membershipStatus,
                    'days_remaining' => $membershipDaysRemaining,
                    'duration_months' => $membershipSubscription['duration_months'],
                    'duration_days' => $membershipSubscription['duration_days'],
                ];
            }
            
             echo json_encode([
                 'success' => true,
                 'active_coach' => $processedActiveCoach,
                 'subscription' => $subscription,
                 'active_membership' => $activeMembership, // Gym membership status (plan_id = 1) if active
                 'subscription_history' => $allSubscriptions, // Include all subscription requests
                 'subscription_status' => $subscriptionStatus,
                 'days_remaining' => $daysRemaining,
                 'is_premium' => $subscription && $subscription['plan_id'] == 2, // Plan ID 2 is Member Rate (Premium)
                 'payment_info' => $paymentInfo
             ]);
            
        } catch (PDOException $e) {
            error_log("ERROR - Get current subscription failed: " . $e->getMessage());
            error_log("ERROR - PDO Error Code: " . $e->getCode());
            error_log("ERROR - PDO Error Info: " . json_encode($e->errorInfo));
            echo json_encode([
                'success' => false,
                'message' => 'Failed to get current subscription',
                'error_details' => $e->getMessage(),
                'error_code' => $e->getCode()
            ]);
        }
    }
    ?>
