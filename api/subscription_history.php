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
                 msp.price,
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
             
             // Get current subscription (most recent approved one with latest end date)
             $currentSubscription = null;
             $latestEndDate = null;
             foreach ($allSubscriptions as $sub) {
                 if ($sub['status_name'] === 'approved' && $sub['end_date'] >= date('Y-m-d')) {
                     // Select the subscription with the latest end date (most recent/active)
                     if ($latestEndDate === null || $sub['end_date'] > $latestEndDate) {
                         $currentSubscription = $sub;
                         $latestEndDate = $sub['end_date'];
                     }
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
        $subscriptionStmt = $pdo->prepare("
            SELECT 
                s.*,
                msp.plan_name,
                msp.price,
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
            
            // Filter out individual plans if user has combination package
            $hasCombinationPackage = false;
            foreach ($allSubscriptions as $sub) {
                if ($sub['plan_id'] == 5) { // Membership + 1 Month Access package
                    $hasCombinationPackage = true;
                    break;
                }
            }
            
            if ($hasCombinationPackage) {
                // Remove individual plans (Gym Membership Fee and Monthly Access) when combination package exists
                $allSubscriptions = array_filter($allSubscriptions, function($sub) {
                    return !($sub['plan_id'] == 1 || $sub['plan_id'] == 2); // Keep only combination package and other plans
                });
                error_log("Filtered out individual plans due to combination package");
            }
            
            // Get current subscription (most recent approved one with latest end date)
            $subscription = null;
            $latestEndDate = null;
            foreach ($allSubscriptions as $sub) {
                if ($sub['status_name'] === 'approved' && $sub['end_date'] >= date('Y-m-d')) {
                    // Select the subscription with the latest end date (most recent/active)
                    if ($latestEndDate === null || $sub['end_date'] > $latestEndDate) {
                        $subscription = $sub;
                        $latestEndDate = $sub['end_date'];
                    }
                }
            }
            
            
            // Calculate subscription status
            $subscriptionStatus = 'Inactive';
            $daysRemaining = 0;
            
            if ($subscription) {
                $startDate = new DateTime($subscription['start_date']);
                $endDate = new DateTime($subscription['end_date']);
                $now = new DateTime();
                
                if ($now >= $startDate && $now <= $endDate) {
                    $subscriptionStatus = 'Active';
                    $daysRemaining = $now->diff($endDate)->days;
                } elseif ($now > $endDate) {
                    $subscriptionStatus = 'Expired';
                } else {
                    $subscriptionStatus = 'Pending';
                }
            }
            
            // Process active coach data
            $processedActiveCoach = false;
            if ($activeCoach) {
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
            
             echo json_encode([
                 'success' => true,
                 'active_coach' => $processedActiveCoach,
                 'subscription' => $subscription,
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
