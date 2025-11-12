<?php
// Enhanced subscription management API - Complete solution for monitoring, approval, and manual creation
// Set headers for CORS and JSON response
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Database configuration - Remote Database
$host = "localhost";
$dbname = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@"; 


// Connect to database
try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Database connection failed",
        "message" => "Unable to connect to database"
    ]);
    exit;
}

// Get request method and data
$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents("php://input"), true);

// Get action from URL parameter or data
$action = $_GET['action'] ?? $data['action'] ?? '';

error_log("DEBUG: Received action: '" . $action . "'");
error_log("DEBUG: GET parameters: " . json_encode($_GET));

// Process request based on HTTP method and action
try {
    switch ($method) {
        case 'GET':
            if ($action === 'pending') {
                getPendingSubscriptions($pdo);
            } elseif ($action === 'plans' || $action === 'get-plans') {
                getSubscriptionPlans($pdo);
            } elseif ($action === 'users') {
                getAvailableUsers($pdo);
            } elseif ($action === 'get-pending-request' && isset($_GET['user_id'])) {
                error_log("DEBUG: Calling getUserPendingRequest for user_id: " . $_GET['user_id']);
                getUserPendingRequest($pdo, $_GET['user_id']);
            } elseif ($action === 'available-plans' && isset($_GET['user_id'])) {
                getAvailablePlansForUser($pdo, $_GET['user_id']);
            } elseif ($action === 'get-user-subscriptions' && isset($_GET['user_id'])) {
                getUserSubscriptions($pdo, $_GET['user_id']);
            } elseif ($action === 'get-plan' && isset($_GET['plan_id'])) {
                getSubscriptionPlan($pdo, $_GET['plan_id']);
            } elseif (isset($_GET['user_id'])) {
                error_log("DEBUG: Calling getUserSubscriptions for user_id: " . $_GET['user_id']);
                getUserSubscriptions($pdo, $_GET['user_id']);
            } else {
                getAllSubscriptions($pdo);
            }
            break;
        case 'POST':
            switch ($action) {
                case 'approve':
                    approveSubscription($pdo, $data);
                    break;
                case 'decline':
                    declineSubscription($pdo, $data);
                    break;
                case 'create_manual':
                    createManualSubscription($pdo, $data);
                    break;
                case 'request-subscription':
                    requestSubscription($pdo, $data);
                    break;
                case 'cancel-subscription':
                    cancelSubscription($pdo, $data);
                    break;
                case 'cancel-pending-request':
                    cancelPendingRequest($pdo, $data);
                    break;
                case 'auto-expire-requests':
                    autoExpireRequests($pdo);
                    break;
                default:
                    http_response_code(400);
                    echo json_encode([
                        "success" => false,
                        "error" => "Invalid action",
                        "message" => "Supported actions: approve, decline, create_manual, request-subscription, cancel-subscription, cancel-pending-request, auto-expire-requests"
                    ]);
                    break;
            }
            break;
        case 'PUT':
            updateSubscription($pdo, $data);
            break;
        case 'DELETE':
            deleteSubscription($pdo, $data);
            break;
        default:
            http_response_code(405);
            echo json_encode([
                "success" => false,
                "error" => "Method not allowed",
                "message" => "HTTP method not supported"
            ]);
            break;
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Database error",
        "message" => $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "error" => "Server error",
        "message" => $e->getMessage()
    ]);
}

function getAllSubscriptions($pdo) {
    $stmt = $pdo->query("
        SELECT s.id, s.start_date, s.end_date, s.discounted_price, s.discount_type, s.amount_paid,
               u.id as user_id, u.fname, u.mname, u.lname, u.email,
               p.id as plan_id, p.plan_name, p.price, p.duration_months,
               st.id as status_id, st.status_name,
               CASE 
                   WHEN st.status_name = 'pending_approval' THEN 'Pending Approval'
                   WHEN st.status_name = 'approved' AND s.end_date >= CURDATE() THEN 'Active'
                   WHEN st.status_name = 'approved' AND s.end_date < CURDATE() THEN 'Expired'
                   WHEN st.status_name = 'rejected' THEN 'Declined'
                   WHEN st.status_name = 'cancelled' THEN 'Cancelled'
                   WHEN st.status_name = 'expired' THEN 'Expired'
                   ELSE st.status_name
               END as display_status
        FROM subscription s
        JOIN user u ON s.user_id = u.id
        JOIN member_subscription_plan p ON s.plan_id = p.id
        JOIN subscription_status st ON s.status_id = st.id
        ORDER BY 
            CASE 
                WHEN st.status_name = 'pending_approval' THEN 1
                WHEN st.status_name = 'approved' THEN 2
                ELSE 3
            END,
            s.start_date DESC
    ");
    
    $subscriptions = $stmt->fetchAll();
    
    // Get payment information for each subscription
    foreach ($subscriptions as &$subscription) {
        $paymentStmt = $pdo->prepare("
            SELECT COUNT(*) as payment_count, SUM(amount) as total_paid
            FROM payment 
            WHERE subscription_id = ?
        ");
        $paymentStmt->execute([$subscription['id']]);
        $paymentInfo = $paymentStmt->fetch();
        
        $subscription['payments'] = [];
        $subscription['payment_count'] = $paymentInfo['payment_count'] ?? 0;
        $subscription['total_paid'] = $paymentInfo['total_paid'] ?? 0;
        
        // If no payments found, use amount_paid from subscription
        if ($subscription['payment_count'] == 0) {
            $subscription['total_paid'] = $subscription['amount_paid'] ?? 0;
        }
    }
    
    echo json_encode([
        "success" => true,
        "subscriptions" => $subscriptions,
        "count" => count($subscriptions),
        "message" => "Subscriptions retrieved successfully"
    ]);
}

function getPendingSubscriptions($pdo) {
    $stmt = $pdo->prepare("
        SELECT s.id as subscription_id, s.start_date, s.end_date, s.discounted_price, s.discount_type, s.amount_paid,
               u.id as user_id, u.fname, u.mname, u.lname, u.email,
               p.id as plan_id, p.plan_name, p.price, p.duration_months,
               st.id as status_id, st.status_name,
               s.start_date as created_at
        FROM subscription s
        JOIN user u ON s.user_id = u.id
        JOIN member_subscription_plan p ON s.plan_id = p.id
        JOIN subscription_status st ON s.status_id = st.id
        WHERE st.status_name = 'pending_approval'
        ORDER BY s.start_date ASC
    ");
    
    $stmt->execute();
    $pendingSubscriptions = $stmt->fetchAll();
    
    echo json_encode([
        "success" => true,
        "data" => $pendingSubscriptions,
        "count" => count($pendingSubscriptions),
        "message" => "Pending subscriptions retrieved successfully"
    ]);
}

function getSubscriptionPlans($pdo) {
    $stmt = $pdo->query("
        SELECT 
            id,
            plan_name,
            price,
            duration_months,
            duration_days,
            is_member_only,
            discounted_price
        FROM member_subscription_plan 
        ORDER BY price ASC
    ");
    
    $plans = $stmt->fetchAll();
    
    // Add features for each plan
    foreach ($plans as &$plan) {
        try {
            $featuresStmt = $pdo->prepare("
                SELECT feature_name, description 
                FROM `subscription_feature` 
                WHERE plan_id = ?
            ");
            $featuresStmt->execute([$plan['id']]);
            $plan['features'] = $featuresStmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            // Try alternative table name if first fails
            try {
                $featuresStmt = $pdo->prepare("
                    SELECT feature_name, description 
                    FROM `subscription_Feature` 
                    WHERE plan_id = ?
                ");
                $featuresStmt->execute([$plan['id']]);
                $plan['features'] = $featuresStmt->fetchAll(PDO::FETCH_ASSOC);
            } catch (PDOException $e2) {
                $plan['features'] = [];
            }
        }
    }
    
    echo json_encode([
        "success" => true,
        "plans" => $plans,
        "count" => count($plans)
    ]);
}

function getAvailableUsers($pdo) {
    $stmt = $pdo->query("
        SELECT 
            id,
            fname,
            mname,
            lname,
            email,
            account_status
        FROM user 
        WHERE user_type_id = 4 AND account_status = 'approved'
        ORDER BY fname, lname
    ");
    
    $users = $stmt->fetchAll();
    
    echo json_encode([
        "success" => true,
        "users" => $users,
        "count" => count($users)
    ]);
}

function getUserSubscriptions($pdo, $user_id) {
    $stmt = $pdo->prepare("
        SELECT 
            s.id,
            s.start_date,
            s.end_date,
            s.discounted_price,
            s.discount_type,
            s.amount_paid,
            p.plan_name,
            p.price as original_price,
            p.duration_months,
            p.duration_days,
            ss.status_name,
            CASE 
                WHEN ss.status_name = 'approved' AND s.end_date >= CURDATE() THEN 'Active'
                WHEN ss.status_name = 'approved' AND s.end_date < CURDATE() THEN 'Expired'
                ELSE ss.status_name
            END as display_status
        FROM subscription s
        JOIN member_subscription_plan p ON s.plan_id = p.id
        JOIN subscription_status ss ON s.status_id = ss.id
        WHERE s.user_id = ?
        ORDER BY s.start_date DESC
    ");
    
    $stmt->execute([$user_id]);
    $subscriptions = $stmt->fetchAll();
    
    // Get payment information and calculate periods for each subscription
    foreach ($subscriptions as &$subscription) {
        $paymentStmt = $pdo->prepare("
            SELECT COUNT(*) as payment_count, SUM(amount) as total_paid
            FROM payment 
            WHERE subscription_id = ?
        ");
        $paymentStmt->execute([$subscription['id']]);
        $paymentInfo = $paymentStmt->fetch();
        
        $subscription['payment_count'] = $paymentInfo['payment_count'] ?? 0;
        $subscription['total_paid'] = $paymentInfo['total_paid'] ?? 0;
        
        // If no payments found, use amount_paid from subscription
        if ($subscription['payment_count'] == 0) {
            $subscription['total_paid'] = $subscription['amount_paid'] ?? 0;
        }
        
        // Calculate periods from amount_paid and original_price
        $periods = 1;
        $originalPrice = floatval($subscription['original_price'] ?? 0);
        $amountPaid = floatval($subscription['amount_paid'] ?? 0);
        
        if ($originalPrice > 0) {
            $periods = round($amountPaid / $originalPrice);
            if ($periods < 1) $periods = 1;
        }
        
        $subscription['periods'] = $periods;
    }
    
    echo json_encode([
        "success" => true,
        "subscriptions" => $subscriptions,
        "count" => count($subscriptions)
    ]);
}

function getAvailablePlansForUser($pdo, $user_id) {
    // Check for existing pending requests (SINGLE REQUEST RULE)
    $pendingStmt = $pdo->prepare("
        SELECT s.id, s.plan_id, p.plan_name, s.start_date
        FROM subscription s
        JOIN subscription_status st ON s.status_id = st.id
        JOIN member_subscription_plan p ON s.plan_id = p.id
        WHERE s.user_id = ? AND st.status_name = 'pending_approval'
    ");
    $pendingStmt->execute([$user_id]);
    $pendingRequest = $pendingStmt->fetch();
    
    // If user has pending request, return empty plans with message
    if ($pendingRequest) {
        echo json_encode([
            "success" => true,
            "plans" => [],
            "count" => 0,
            "has_pending_request" => true,
            "pending_request" => $pendingRequest,
            "message" => "You already have a pending request for '{$pendingRequest['plan_name']}'. Please wait for approval or cancel it first."
        ]);
        return;
    }
    
    // Get user's active subscriptions with plan details
    $activeSubscriptionsStmt = $pdo->prepare("
        SELECT s.plan_id, s.end_date, p.plan_name, ss.status_name
        FROM subscription s
        JOIN subscription_status ss ON s.status_id = ss.id
        JOIN member_subscription_plan p ON s.plan_id = p.id
        WHERE s.user_id = ? 
        AND ss.status_name = 'approved' 
        AND s.end_date >= CURDATE()
        ORDER BY s.plan_id
    ");
    $activeSubscriptionsStmt->execute([$user_id]);
    $activeSubscriptions = $activeSubscriptionsStmt->fetchAll();
    $activePlanIds = array_column($activeSubscriptions, 'plan_id');
    
    // Get all subscription plans
    $plansStmt = $pdo->query("
        SELECT 
            id,
            plan_name,
            price,
            duration_months,
            duration_days,
            is_member_only,
            discounted_price
        FROM member_subscription_plan 
        ORDER BY price ASC
    ");
    $allPlans = $plansStmt->fetchAll();
    
    $hasActiveMemberFee = in_array(1, $activePlanIds);
    $hasActiveMonthlyPlan = in_array(2, $activePlanIds) || in_array(3, $activePlanIds);
    $hasActiveCombinationPackage = in_array(5, $activePlanIds); // Membership + 1 Month Access package
    $hasActiveDayPass = in_array(6, $activePlanIds);
    $activeMonthlyPlan = null;
    
    // Find active monthly plan details
    foreach ($activeSubscriptions as $sub) {
        if ($sub['plan_id'] == 2 || $sub['plan_id'] == 3) {
            $activeMonthlyPlan = $sub;
            break;
        }
    }
    
    $plansWithStatus = [];
    
    foreach ($allPlans as $plan) {
        $planId = $plan['id'];
        $isPlanActive = in_array($planId, $activePlanIds);
        
        // Get plan availability status
        $availabilityStatus = getPlanAvailabilityStatus($planId, $hasActiveMemberFee, $hasActiveMonthlyPlan, $hasActiveDayPass, $isPlanActive, $activeMonthlyPlan, $hasActiveCombinationPackage);
        
        $plan['is_available'] = $availabilityStatus['available'];
        $plan['is_locked'] = !$availabilityStatus['available'];
        $plan['lock_reason'] = $availabilityStatus['reason'];
        $plan['lock_message'] = $availabilityStatus['message'];
        $plan['lock_icon'] = $availabilityStatus['icon'];
        
        // Add features for each plan
        try {
            // Try with backticks to handle case sensitivity
            $featuresStmt = $pdo->prepare("
                SELECT feature_name, description 
                FROM `subscription_feature` 
                WHERE plan_id = ?
            ");
            $featuresStmt->execute([$planId]);
            $features = $featuresStmt->fetchAll(PDO::FETCH_ASSOC);
            $plan['features'] = $features;
            
            // Debug logging
            error_log("DEBUG getAvailablePlansForUser: Plan ID $planId has " . count($features) . " features");
            if (count($features) > 0) {
                error_log("DEBUG getAvailablePlansForUser: Features for plan $planId: " . json_encode($features));
            } else {
                error_log("WARNING getAvailablePlansForUser: Plan ID $planId returned 0 features from database");
            }
        } catch (PDOException $e) {
            error_log("ERROR getAvailablePlansForUser: Failed to fetch features for plan $planId: " . $e->getMessage());
            // Try alternative table name if first fails
            try {
                $featuresStmt = $pdo->prepare("
                    SELECT feature_name, description 
                    FROM `subscription_Feature` 
                    WHERE plan_id = ?
                ");
                $featuresStmt->execute([$planId]);
                $features = $featuresStmt->fetchAll(PDO::FETCH_ASSOC);
                $plan['features'] = $features;
                error_log("DEBUG getAvailablePlansForUser: Successfully fetched features using subscription_Feature table");
            } catch (PDOException $e2) {
                error_log("ERROR getAvailablePlansForUser: Both table name variations failed: " . $e2->getMessage());
                $plan['features'] = [];
            }
        }
        
        $plansWithStatus[] = $plan;
    }
    
    echo json_encode([
        "success" => true,
        "plans" => $plansWithStatus,
        "count" => count($plansWithStatus),
        "active_plan_ids" => $activePlanIds,
        "active_subscriptions" => $activeSubscriptions,
        "has_active_member_fee" => $hasActiveMemberFee,
        "has_active_monthly_plan" => $hasActiveMonthlyPlan,
        "active_monthly_plan" => $activeMonthlyPlan,
        "has_pending_request" => false
    ]);
}

// New function to get plan availability status
function getPlanAvailabilityStatus($planId, $hasActiveMemberFee, $hasActiveMonthlyPlan, $hasActiveDayPass, $isPlanActive, $activeMonthlyPlan, $hasActiveCombinationPackage) {
    switch ($planId) {
        case 1: // Membership Fee - allow renewal if active
            return [
                'available' => true, // Always available for renewal
                'reason' => $isPlanActive ? 'renewal_available' : 'available',
                'message' => $isPlanActive ? 'You can renew your Membership Fee subscription.' : 'One-time fee for member benefits and discounts on monthly plans.',
                'icon' => '✅'
            ];
            
        case 2: // Member Monthly Plan - allow renewal if active
            // If plan is active, allow renewal
            if ($isPlanActive) {
                return [
                    'available' => true,
                    'reason' => 'renewal_available',
                    'message' => 'You can renew your Member Monthly Plan subscription.',
                    'icon' => '✅'
                ];
            }
            if ($hasActiveCombinationPackage) {
                return [
                    'available' => false,
                    'reason' => 'has_combination_package',
                    'message' => 'You have the Membership + 1 Month Access package which includes monthly access. This individual plan is not needed.',
                    'icon' => '🔒'
                ];
            }
            if (!$hasActiveMemberFee) {
                return [
                    'available' => false,
                    'reason' => 'requires_membership_fee',
                    'message' => 'You need to purchase a Membership Fee first to access member benefits and discounts.',
                    'icon' => '🔒'
                ];
            }
            if ($hasActiveMonthlyPlan) {
                $planName = $activeMonthlyPlan['plan_name'];
                $endDate = date('M d, Y', strtotime($activeMonthlyPlan['end_date']));
                return [
                    'available' => false,
                    'reason' => 'active_monthly_plan',
                    'message' => "You currently have an active {$planName} until {$endDate}. Please wait for it to expire before switching to Member Monthly Plan.",
                    'icon' => '🔒'
                ];
            }
            return [
                'available' => true,
                'reason' => 'available',
                'message' => 'Monthly plan with member benefits and discounts.',
                'icon' => '✅'
            ];
            
        case 3: // Non-Member Monthly Plan - allow renewal if active, but lock if user has membership fee
            // If plan is active, allow renewal
            if ($isPlanActive) {
                return [
                    'available' => true,
                    'reason' => 'renewal_available',
                    'message' => 'You can renew your Non-Member Monthly Plan subscription.',
                    'icon' => '✅'
                ];
            }
            // Lock standard plan if user has membership fee active
            if ($hasActiveMemberFee) {
                return [
                    'available' => false,
                    'reason' => 'has_membership_fee',
                    'message' => 'You have a Membership Fee subscription. Consider the Member Monthly Plan for better value with member discounts.',
                    'icon' => '🔒'
                ];
            }
            if ($hasActiveMonthlyPlan) {
                $planName = $activeMonthlyPlan['plan_name'];
                $endDate = date('M d, Y', strtotime($activeMonthlyPlan['end_date']));
                return [
                    'available' => false,
                    'reason' => 'active_monthly_plan',
                    'message' => "You currently have an active {$planName} until {$endDate}. Please wait for it to expire before switching plans.",
                    'icon' => '🔒'
                ];
            }
            return [
                'available' => true,
                'reason' => 'available',
                'message' => 'Monthly plan for gym access without member benefits.',
                'icon' => '✅'
            ];
            
        case 5: // Membership + 1 Month Access - Combination package
            if ($hasActiveMemberFee || $hasActiveMonthlyPlan || $hasActiveCombinationPackage) {
                return [
                    'available' => false,
                    'reason' => 'has_existing_plans',
                    'message' => 'You already have active subscriptions. This combination package is only available for new users with no existing plans.',
                    'icon' => '🔒'
                ];
            }
            return [
                'available' => true,
                'reason' => 'available',
                'message' => 'Combination package: 1-year membership fee + 1-month member access. Perfect for new users!',
                'icon' => '✅'
            ];
            
        case 6: // Day Pass - only available if no active monthly plans (premium or standard)
            if ($isPlanActive) {
                return [
                    'available' => true,
                    'reason' => 'renewal_available',
                    'message' => 'You can renew your Day Pass subscription.',
                    'icon' => '✅'
                ];
            }
            // Check if user has any active monthly plans (2, 3, or 5)
            if ($hasActiveMonthlyPlan) {
                $planName = $activeMonthlyPlan['plan_name'];
                $endDate = date('M d, Y', strtotime($activeMonthlyPlan['end_date']));
                return [
                    'available' => false,
                    'reason' => 'active_monthly_plan',
                    'message' => "You currently have an active {$planName} until {$endDate}. Please wait for it to expire before purchasing a Day Pass.",
                    'icon' => '🔒'
                ];
            }
            // Check if user has combination package (which includes monthly access)
            if ($hasActiveCombinationPackage) {
                return [
                    'available' => false,
                    'reason' => 'has_combination_package',
                    'message' => 'You have the Membership + 1 Month Access package which includes monthly access. Day Pass is not available while you have monthly access.',
                    'icon' => '🔒'
                ];
            }
            if ($hasActiveDayPass) {
                return [
                    'available' => false,
                    'reason' => 'active_day_pass',
                    'message' => 'You already have an active Day Pass. Please wait for it to expire before purchasing another one.',
                    'icon' => '🔒'
                ];
            }
            return [
                'available' => true,
                'reason' => 'available',
                'message' => '1-day gym access. Perfect for trying out the gym! Valid until midnight.',
                'icon' => '✅'
            ];
            
        default: // Other plans - allow renewal if active
            return [
                'available' => true, // Always available for renewal or new subscription
                'reason' => $isPlanActive ? 'renewal_available' : 'available',
                'message' => $isPlanActive ? 'You can renew your subscription to this plan.' : 'This plan is available for subscription.',
                'icon' => '✅'
            ];
    }
}

function createManualSubscription($pdo, $data) {
    // Validate required fields
    $required_fields = ['user_id', 'plan_id', 'start_date', 'amount_paid'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode([
                "success" => false, 
                "error" => "Missing required field: $field"
            ]);
            return;
        }
    }

    $user_id = $data['user_id'];
    $plan_id = $data['plan_id'];
    $start_date = $data['start_date'];
    $payment_amount = $data['amount_paid']; // Frontend sends 'amount_paid'
    $discount_type = $data['discount_type'] ?? 'none';
    $created_by = $data['created_by'] ?? 'admin';

    $pdo->beginTransaction();

    try {
        // Verify user exists and is a customer
        $userStmt = $pdo->prepare("SELECT id, fname, lname, email, user_type_id, account_status FROM user WHERE id = ?");
        $userStmt->execute([$user_id]);
        $user = $userStmt->fetch();
        
        if (!$user) throw new Exception("User not found");
        if ($user['user_type_id'] != 4) throw new Exception("Subscriptions can only be created for customers");
        if ($user['account_status'] !== 'approved') throw new Exception("User account must be approved first");

        // Verify plan exists
        $planStmt = $pdo->prepare("SELECT id, plan_name, price, duration_months, duration_days FROM member_subscription_plan WHERE id = ?");
        $planStmt->execute([$plan_id]);
        $plan = $planStmt->fetch();
        
        if (!$plan) throw new Exception("Subscription plan not found");

        // Calculate end date
        $start_date_obj = new DateTime($start_date);
        $end_date_obj = clone $start_date_obj;
        
        if ($plan_id == 6) {
            // Day Pass: Expires at 12 AM (midnight) of the next day
            // If start_date is Jan 15, end_date should be Jan 16 (expires at midnight of Jan 16, so valid until end of Jan 15)
            $end_date_obj->modify('+1 day');
            $end_date = $end_date_obj->format('Y-m-d');
            error_log("DEBUG MANUAL CREATE: Day Pass (plan_id=6) - start_date=$start_date, end_date=$end_date (expires at midnight of next day)");
        } elseif ($plan['duration_days'] && $plan['duration_days'] > 0) {
            // Use duration_days for day-based plans
            $end_date_obj->add(new DateInterval('P' . $plan['duration_days'] . 'D'));
            $end_date = $end_date_obj->format('Y-m-d');
        } else {
            // Use duration_months for month-based plans
            $end_date_obj->add(new DateInterval('P' . $plan['duration_months'] . 'M'));
            $end_date = $end_date_obj->format('Y-m-d');
        }

        // Get approved status ID
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'approved'");
        $statusStmt->execute();
        $status = $statusStmt->fetch();
        
        if (!$status) {
            throw new Exception("Approved status not found in database");
        }

        // Check for existing active subscriptions to prevent duplicates
        if ($plan_id == 5) {
            // For combination package, check for existing plan_id 1, 2, or 5
            $existingStmt = $pdo->prepare("
                SELECT s.id, s.plan_id, s.end_date, ss.status_name, p.plan_name
                FROM subscription s 
                JOIN subscription_status ss ON s.status_id = ss.id 
                JOIN member_subscription_plan p ON s.plan_id = p.id
                WHERE s.user_id = ? 
                AND s.plan_id IN (1, 2, 5)
                AND ss.status_name = 'approved' 
                AND s.end_date >= CURDATE()
            ");
            $existingStmt->execute([$user_id]);
            $existingSubscriptions = $existingStmt->fetchAll();
            
            if (!empty($existingSubscriptions)) {
                $planNames = array_column($existingSubscriptions, 'plan_name');
                throw new Exception("User already has active subscriptions: " . implode(', ', $planNames) . ". Combination package is only for new users.");
            }
        } else {
            $existingStmt = $pdo->prepare("
                SELECT s.id, s.plan_id, s.end_date, ss.status_name, p.plan_name
                FROM subscription s 
                JOIN subscription_status ss ON s.status_id = ss.id 
                JOIN member_subscription_plan p ON s.plan_id = p.id
                WHERE s.user_id = ? 
                AND s.plan_id = ?
                AND ss.status_name = 'approved' 
                AND s.end_date >= CURDATE()
            ");
            $existingStmt->execute([$user_id, $plan_id]);
            $existingSubscription = $existingStmt->fetch();
            
            if ($existingSubscription) {
                throw new Exception("User already has an active subscription to this plan: {$existingSubscription['plan_name']} (expires: {$existingSubscription['end_date']})");
            }
        }

        // Handle plan_id 5 (Combination Package) - creates subscriptions for both plan_id 1 and plan_id 2
        if ($plan_id == 5) {
            // Get plan details for plan_id 1 and plan_id 2
            $plan1Stmt = $pdo->prepare("SELECT id, plan_name, price, duration_months, duration_days FROM member_subscription_plan WHERE id = 1");
            $plan1Stmt->execute();
            $plan1 = $plan1Stmt->fetch();
            
            $plan2Stmt = $pdo->prepare("SELECT id, plan_name, price, duration_months, duration_days FROM member_subscription_plan WHERE id = 2");
            $plan2Stmt->execute();
            $plan2 = $plan2Stmt->fetch();
            
            if (!$plan1 || !$plan2) {
                throw new Exception("Combination package plans (1 and 2) not found");
            }
            
            // Calculate end dates for both plans with FIXED durations (not using database values)
            // plan_id 1 (Gym Membership): ALWAYS 365 days (1 year)
            $plan1_end_date = new DateTime($start_date);
            $plan1_end_date->add(new DateInterval('P365D'));
            
            // plan_id 2 (Monthly Access): ALWAYS 30 days (1 month)
            $plan2_end_date = new DateTime($start_date);
            $plan2_end_date->add(new DateInterval('P30D'));
            
            // Debug: Log ALL plan details to see what we're getting from database
            error_log("DEBUG MANUAL CREATE: start_date=$start_date");
            error_log("DEBUG MANUAL CREATE: plan1 data from DB: " . json_encode($plan1));
            error_log("DEBUG MANUAL CREATE: plan2 data from DB: " . json_encode($plan2));
            error_log("DEBUG MANUAL CREATE: plan_id 1 calculated end_date: " . $plan1_end_date->format('Y-m-d') . " (365 days from $start_date)");
            error_log("DEBUG MANUAL CREATE: plan_id 2 calculated end_date: " . $plan2_end_date->format('Y-m-d') . " (30 days from $start_date)");
            
            // Create subscription for plan_id 1 (Gym Membership)
            $subscription1Stmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscription1Stmt->execute([$user_id, 1, $status['id'], $start_date, $plan1_end_date->format('Y-m-d'), $plan1['price'], $discount_type, $plan1['price']]);
            $subscription_id_1 = $pdo->lastInsertId();
            
            // Create subscription for plan_id 2 (Member Monthly)
            // Debug: Verify plan2_end_date is 30 days
            $plan2_end_date_formatted = $plan2_end_date->format('Y-m-d');
            error_log("DEBUG: plan_id 2 end_date should be: " . $plan2_end_date_formatted . " (30 days from " . $start_date . ")");
            
            $subscription2Stmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscription2Stmt->execute([$user_id, 2, $status['id'], $start_date, $plan2_end_date_formatted, $plan2['price'], $discount_type, $plan2['price']]);
            $subscription_id_2 = $pdo->lastInsertId();
            
            // Also create the package subscription record (plan_id 5)
            // Use plan_id 2's end_date as the package end_date
            $package_end_date = $plan2_end_date->format('Y-m-d');
            
            $subscriptionPkgStmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscriptionPkgStmt->execute([$user_id, 5, $status['id'], $start_date, $package_end_date, $payment_amount, $discount_type, $payment_amount]);
            $subscription_id = $pdo->lastInsertId();
            
            // FORCE FIX: Update plan_id 1 to have correct 365-day duration
            error_log("DEBUG MANUAL CREATE: Fixing plan_id 1 (ID=$subscription_id_1) end_date to 365 days from $start_date");
            $fixPlan1Stmt = $pdo->prepare("
                UPDATE subscription 
                SET end_date = DATE_ADD(?, INTERVAL 365 DAY) 
                WHERE id = ?
            ");
            $fixPlan1Stmt->execute([$start_date, $subscription_id_1]);
            $updatedRows = $fixPlan1Stmt->rowCount();
            error_log("DEBUG MANUAL CREATE: UPDATE executed, rows affected: $updatedRows. New end_date should be: " . $plan1_end_date->format('Y-m-d'));
            
        } else {
            // Create single subscription for other plans
            $subscriptionStmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscriptionStmt->execute([$user_id, $plan_id, $status['id'], $start_date, $end_date, $payment_amount, $discount_type, $payment_amount]);
            $subscription_id = $pdo->lastInsertId();
        }

        // Create payment record
        if ($plan_id == 5) {
            // For combination package, create payment record for the package subscription
            $paymentStmt = $pdo->prepare("
                INSERT INTO payment (subscription_id, amount, payment_date) 
                VALUES (?, ?, NOW())
            ");
            $paymentStmt->execute([$subscription_id, $payment_amount]);
            $payment_id = $pdo->lastInsertId();
        } else {
            $paymentStmt = $pdo->prepare("
                INSERT INTO payment (subscription_id, amount, payment_date) 
                VALUES (?, ?, NOW())
            ");
            $paymentStmt->execute([$subscription_id, $payment_amount]);
            $payment_id = $pdo->lastInsertId();
        }

        // Create sales record
        $salesStmt = $pdo->prepare("
            INSERT INTO sales (user_id, total_amount, sale_date, sale_type) 
            VALUES (?, ?, NOW(), 'Subscription')
        ");
        $salesStmt->execute([$user_id, $payment_amount]);
        $sale_id = $pdo->lastInsertId();

        // Create sales details
        if ($plan_id == 5) {
            // For combination package, link sales details to the package subscription
            $salesDetailStmt = $pdo->prepare("
                INSERT INTO sales_details (sale_id, subscription_id, quantity, price) 
                VALUES (?, ?, 1, ?)
            ");
            $salesDetailStmt->execute([$sale_id, $subscription_id, $payment_amount]);
        } else {
            $salesDetailStmt = $pdo->prepare("
                INSERT INTO sales_details (sale_id, subscription_id, quantity, price) 
                VALUES (?, ?, 1, ?)
            ");
            $salesDetailStmt->execute([$sale_id, $subscription_id, $payment_amount]);
        }

        // Log activity (optional - if activity_log table exists)
        try {
            $activityStmt = $pdo->prepare("
                INSERT INTO activity_log (user_id, activity, timestamp) 
                VALUES (?, ?, NOW())
            ");
            $activity_message = "Manual subscription created: {$plan['plan_name']} for {$user['fname']} {$user['lname']} by {$created_by}";
            $activityStmt->execute([null, $activity_message]);
        } catch (Exception $e) {
            // Activity log is optional, don't fail the transaction
        }

        $pdo->commit();

        $response_data = [
            "subscription_id" => $subscription_id,
            "payment_id" => $payment_id,
            "sale_id" => $sale_id,
            "user_name" => $user['fname'] . ' ' . $user['lname'],
            "user_email" => $user['email'],
            "plan_name" => $plan['plan_name'],
            "start_date" => $start_date,
            "end_date" => $end_date,
            "amount_paid" => $payment_amount,
            "discount_type" => $discount_type
        ];
        
        if ($plan_id != 5 && isset($existingSubscription) && $existingSubscription) {
            $response_data["existing_subscription_warning"] = "User had an active subscription ending on " . $existingSubscription['end_date'];
        }
        
        if ($plan_id == 5) {
            // Add combination package details
            $response_data['combination_package'] = true;
            $response_data['membership_subscription_id'] = $subscription_id_1;
            $response_data['monthly_subscription_id'] = $subscription_id_2;
            $response_data['membership_end_date'] = $plan1_end_date->format('Y-m-d');
            $response_data['monthly_end_date'] = $plan2_end_date->format('Y-m-d');
            $response_data['message'] = "Combination package subscriptions created successfully (Membership: 365 days, Monthly Access: 30 days)";
        } else {
            $response_data['message'] = "Manual subscription created successfully";
        }
        
        echo json_encode([
            "success" => true,
            "data" => $response_data
        ]);

    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode([
            "success" => false, 
            "error" => "Failed to create subscription", 
            "message" => $e->getMessage()
        ]);
    }
}

function approveSubscription($pdo, $data) {
    if (!isset($data['subscription_id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Missing subscription_id", "message" => "subscription_id is required"]);
        return;
    }
    
    $subscriptionId = $data['subscription_id'];
    $approvedBy = $data['approved_by'] ?? 'Admin';
    
    $pdo->beginTransaction();
    
    try {
        $checkStmt = $pdo->prepare("
            SELECT s.id, s.user_id, s.plan_id, st.status_name, s.start_date, s.end_date,
                   u.fname, u.lname, u.email,
                   p.plan_name, p.price, p.duration_months, p.duration_days
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN user u ON s.user_id = u.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE s.id = ?
        ");
        $checkStmt->execute([$subscriptionId]);
        $subscription = $checkStmt->fetch();
        
        if (!$subscription) throw new Exception("Subscription not found.");
        if ($subscription['status_name'] !== 'pending_approval') throw new Exception("Subscription is not in pending status. Current status: " . $subscription['status_name']);
        
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'approved'");
        $statusStmt->execute();
        $approvedStatus = $statusStmt->fetch();
        
        if (!$approvedStatus) throw new Exception("Approved status not found in database.");
        
        // Check if this is plan_id 5 (Combination Package) that needs to be split
        if ($subscription['plan_id'] == 5) {
            // Delete the pending plan_id 5 subscription
            $deleteStmt = $pdo->prepare("DELETE FROM subscription WHERE id = ?");
            $deleteStmt->execute([$subscriptionId]);
            
            $user_id = $subscription['user_id'];
            $end_date = $subscription['end_date'];
            $amount_paid = $subscription['price'];
            $discount_type = 'none';
            
            // Recalculate subscription start date from end_date and plan duration
            // Check if this is a renewal or advance payment by checking active subscriptions
            // If user has active subscriptions, check if end_date suggests renewal/advance payment
            $activeStmt = $pdo->prepare("
                SELECT s.end_date
                FROM subscription s
                JOIN subscription_status st ON s.status_id = st.id
                WHERE s.user_id = ? 
                AND st.status_name IN ('approved', 'active')
                AND s.end_date >= CURDATE()
                ORDER BY s.end_date DESC
                LIMIT 1
            ");
            $activeStmt->execute([$user_id]);
            $activeSubscription = $activeStmt->fetch();
            
            if ($activeSubscription) {
                // User has active subscription - check if this is a renewal/advance payment
                // The subscription start date should be the end date of the active subscription
                $start_date = $activeSubscription['end_date'];
                error_log("DEBUG APPROVE: plan_id=5, user has active subscription ending $start_date, using as subscription start date");
            } else {
                // New subscription - calculate start_date from end_date and plan duration
                // For plan_id 5, we need to get its duration from database
                $plan5Stmt = $pdo->prepare("SELECT duration_months, duration_days FROM member_subscription_plan WHERE id = 5");
                $plan5Stmt->execute();
                $plan5 = $plan5Stmt->fetch();
                
                if ($plan5) {
                    $end_date_obj = new DateTime($end_date);
                    $start_date_obj = clone $end_date_obj;
                    
                    if ($plan5['duration_days'] && $plan5['duration_days'] > 0) {
                        $start_date_obj->sub(new DateInterval('P' . $plan5['duration_days'] . 'D'));
                    } else {
                        $start_date_obj->sub(new DateInterval('P' . $plan5['duration_months'] . 'M'));
                    }
                    
                    $start_date = $start_date_obj->format('Y-m-d');
                    error_log("DEBUG APPROVE: plan_id=5, calculated start_date=$start_date from end_date=$end_date");
                } else {
                    // Fallback: use today's date
                    $start_date_raw = $subscription['start_date'];
                    $start_date_obj = new DateTime($start_date_raw);
                    $start_date = $start_date_obj->format('Y-m-d');
                    error_log("DEBUG APPROVE: plan_id=5, plan not found, using date from start_date: $start_date");
                }
            }
            
            error_log("DEBUG APPROVE: Got user_id=$user_id, start_date=$start_date, end_date=$end_date, amount_paid=$amount_paid from pending subscription");
            
            // Get plan details for plan_id 1 and plan_id 2
            $plan1Stmt = $pdo->prepare("SELECT id, plan_name, price, duration_months, duration_days FROM member_subscription_plan WHERE id = 1");
            $plan1Stmt->execute();
            $plan1 = $plan1Stmt->fetch();
            
            $plan2Stmt = $pdo->prepare("SELECT id, plan_name, price, duration_months, duration_days FROM member_subscription_plan WHERE id = 2");
            $plan2Stmt->execute();
            $plan2 = $plan2Stmt->fetch();
            
            if (!$plan1 || !$plan2) {
                throw new Exception("Combination package plans (1 and 2) not found");
            }
            
            // Calculate end dates for both plans with FIXED durations (not using database values)
            // plan_id 1 (Gym Membership): ALWAYS 365 days (1 year)
            $plan1_end_date = new DateTime($start_date);
            $plan1_end_date->add(new DateInterval('P365D'));
            
            // plan_id 2 (Monthly Access): ALWAYS 30 days (1 month)
            $plan2_end_date = new DateTime($start_date);
            $plan2_end_date->add(new DateInterval('P30D'));
            
            // Debug logging for approval
            error_log("DEBUG APPROVE: plan_id=5, subscription_id=$subscriptionId, start_date=$start_date");
            error_log("DEBUG APPROVE: plan_id 1 calculated end_date = " . $plan1_end_date->format('Y-m-d') . " (365 days from $start_date)");
            error_log("DEBUG APPROVE: plan_id 2 calculated end_date = " . $plan2_end_date->format('Y-m-d') . " (30 days from $start_date)");
            
            // Create subscription for plan_id 1 (Gym Membership)
            $plan1_end_formatted = $plan1_end_date->format('Y-m-d');
            error_log("DEBUG APPROVE: Inserting plan_id 1 with end_date = $plan1_end_formatted");
            
            $subscription1Stmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscription1Stmt->execute([$user_id, 1, $approvedStatus['id'], $start_date, $plan1_end_date->format('Y-m-d'), $plan1['price'], $discount_type, $plan1['price']]);
            $subscription_id_1 = $pdo->lastInsertId();
            
            // Create subscription for plan_id 2 (Member Monthly)
            $subscription2Stmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscription2Stmt->execute([$user_id, 2, $approvedStatus['id'], $start_date, $plan2_end_date->format('Y-m-d'), $plan2['price'], $discount_type, $plan2['price']]);
            $subscription_id_2 = $pdo->lastInsertId();
            
            // Calculate end_date for the package record (use plan_id 2's end_date as the package end_date)
            $package_end_date = $plan2_end_date->format('Y-m-d');
            
            // Also create the package subscription record (plan_id 5)
            $subscriptionPkgStmt = $pdo->prepare("
                INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $subscriptionPkgStmt->execute([$user_id, 5, $approvedStatus['id'], $start_date, $package_end_date, $amount_paid, $discount_type, $amount_paid]);
            $subscription_id = $pdo->lastInsertId();
            
            // Create payment records for all subscriptions
            $payment1Stmt = $pdo->prepare("INSERT INTO payment (subscription_id, amount, payment_date) VALUES (?, ?, NOW())");
            $payment1Stmt->execute([$subscription_id_1, $plan1['price']]);
            
            $payment2Stmt = $pdo->prepare("INSERT INTO payment (subscription_id, amount, payment_date) VALUES (?, ?, NOW())");
            $payment2Stmt->execute([$subscription_id_2, $plan2['price']]);
            
            $paymentPkgStmt = $pdo->prepare("INSERT INTO payment (subscription_id, amount, payment_date) VALUES (?, ?, NOW())");
            $paymentPkgStmt->execute([$subscription_id, $amount_paid]);
            
            // Create sales record
            $salesStmt = $pdo->prepare("INSERT INTO sales (user_id, total_amount, sale_date, sale_type) VALUES (?, ?, NOW(), 'Subscription')");
            $salesStmt->execute([$user_id, $amount_paid]);
            $sale_id = $pdo->lastInsertId();
            
            // Create sales detail for the package
            $salesDetailStmt = $pdo->prepare("INSERT INTO sales_details (sale_id, subscription_id, quantity, price) VALUES (?, ?, 1, ?)");
            $salesDetailStmt->execute([$sale_id, $subscription_id, $amount_paid]);
            
            // FORCE FIX: Update plan_id 1 to have correct 365-day duration
            error_log("DEBUG APPROVE: Fixing plan_id 1 (ID=$subscription_id_1) end_date to 365 days from $start_date");
            $fixPlan1Stmt = $pdo->prepare("
                UPDATE subscription 
                SET end_date = DATE_ADD(?, INTERVAL 365 DAY) 
                WHERE id = ?
            ");
            $fixPlan1Stmt->execute([$start_date, $subscription_id_1]);
            $updatedRows = $fixPlan1Stmt->rowCount();
            error_log("DEBUG APPROVE: UPDATE executed, rows affected: $updatedRows. New end_date should be: " . $plan1_end_date->format('Y-m-d'));
            
            $pdo->commit();
            
            echo json_encode([
                "success" => true,
                "subscription_id" => $subscription_id,
                "status" => "approved",
                "message" => "Combination package approved - Created 3 subscriptions with correct durations",
                "data" => [
                    "subscription_id" => $subscription_id,
                    "membership_subscription_id" => $subscription_id_1,
                    "monthly_subscription_id" => $subscription_id_2,
                    "user_name" => trim($subscription['fname'] . ' ' . $subscription['lname']),
                    "user_email" => $subscription['email'],
                    "plan_name" => "Membership + 1 Month Access (Combination Package)",
                    "membership_end_date" => $plan1_end_date->format('Y-m-d'),
                    "monthly_end_date" => $plan2_end_date->format('Y-m-d'),
                    "status" => "approved",
                    "approved_at" => date('Y-m-d H:i:s'),
                    "approved_by" => $approvedBy
                ]
            ]);
        } elseif ($subscription['plan_id'] == 6) {
            // Day Pass: Update status and ensure end_date is set to next day (expires at midnight)
            // Extract just the date portion from start_date (remove time component if present)
            // For pending requests, start_date contains the request time, but for approved subscriptions,
            // we need just the date (today's date for Day Pass)
            $start_date_raw = $subscription['start_date'];
            $start_date_obj = new DateTime($start_date_raw);
            $start_date = $start_date_obj->format('Y-m-d'); // Extract just the date (today for new Day Pass)
            $end_date_obj = clone $start_date_obj;
            $end_date_obj->setTime(0, 0, 0); // Set to midnight
            // Day Pass expires at 12 AM (midnight) of the next day
            $end_date_obj->modify('+1 day');
            $end_date = $end_date_obj->format('Y-m-d');
            
            error_log("DEBUG APPROVE: Day Pass (plan_id=6) - start_date_raw=$start_date_raw, start_date=$start_date, end_date=$end_date (expires at midnight of next day)");
            
            // Update status, start_date (to just date), and end_date to ensure it expires at midnight
            $updateStmt = $pdo->prepare("UPDATE subscription SET status_id = ?, start_date = ?, end_date = ? WHERE id = ?");
            $updateStmt->execute([$approvedStatus['id'], $start_date, $end_date, $subscriptionId]);
            
            $pdo->commit();
            
            echo json_encode([
                "success" => true,
                "subscription_id" => $subscriptionId,
                "status" => "approved",
                "message" => "Day Pass approved successfully. Valid until midnight.",
                "data" => [
                    "subscription_id" => $subscriptionId,
                    "user_name" => trim($subscription['fname'] . ' ' . $subscription['lname']),
                    "user_email" => $subscription['email'],
                    "plan_name" => $subscription['plan_name'],
                    "start_date" => $start_date,
                    "end_date" => $end_date,
                    "status" => "approved",
                    "approved_at" => date('Y-m-d H:i:s'),
                    "approved_by" => $approvedBy
                ]
            ]);
        } else {
            // For other subscriptions, recalculate start_date from end_date and plan duration
            // This ensures correct start_date for renewals and advance payments
            // The end_date was calculated correctly during request, so we can derive start_date from it
            $end_date = $subscription['end_date'];
            $plan_id = $subscription['plan_id'];
            
            // Get plan details to calculate duration
            $planStmt = $pdo->prepare("SELECT duration_months, duration_days FROM member_subscription_plan WHERE id = ?");
            $planStmt->execute([$plan_id]);
            $plan = $planStmt->fetch();
            
            if ($plan) {
                // Calculate start_date by subtracting plan duration from end_date
                $end_date_obj = new DateTime($end_date);
                $start_date_obj = clone $end_date_obj;
                
                if ($plan['duration_days'] && $plan['duration_days'] > 0) {
                    // Duration is in days
                    $start_date_obj->sub(new DateInterval('P' . $plan['duration_days'] . 'D'));
                } else {
                    // Duration is in months
                    $start_date_obj->sub(new DateInterval('P' . $plan['duration_months'] . 'M'));
                }
                
                $start_date = $start_date_obj->format('Y-m-d');
            } else {
                // Fallback: extract just the date from start_date (remove time component)
                $start_date_raw = $subscription['start_date'];
                $start_date_obj = new DateTime($start_date_raw);
                $start_date = $start_date_obj->format('Y-m-d');
            }
            
            // Update status and start_date (to just date, without time)
            $updateStmt = $pdo->prepare("UPDATE subscription SET status_id = ?, start_date = ? WHERE id = ?");
            $updateStmt->execute([$approvedStatus['id'], $start_date, $subscriptionId]);
            
            $pdo->commit();
            
            echo json_encode([
                "success" => true,
                "subscription_id" => $subscriptionId,
                "status" => "approved",
                "message" => "Subscription approved successfully",
                "data" => [
                    "subscription_id" => $subscriptionId,
                    "user_name" => trim($subscription['fname'] . ' ' . $subscription['lname']),
                    "user_email" => $subscription['email'],
                    "plan_name" => $subscription['plan_name'],
                    "status" => "approved",
                    "approved_at" => date('Y-m-d H:i:s'),
                    "approved_by" => $approvedBy
                ]
            ]);
        }
        
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Approval failed", "message" => $e->getMessage()]);
    }
}

function declineSubscription($pdo, $data) {
    if (!isset($data['subscription_id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Missing subscription_id", "message" => "subscription_id is required"]);
        return;
    }
    
    $subscriptionId = $data['subscription_id'];
    $declinedBy = $data['declined_by'] ?? 'Admin';
    $declineReason = $data['decline_reason'] ?? '';
    
    $pdo->beginTransaction();
    
    try {
        $checkStmt = $pdo->prepare("
            SELECT s.id, s.user_id, s.plan_id, st.status_name,
                   u.fname, u.lname, u.email,
                   p.plan_name, p.price
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN user u ON s.user_id = u.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE s.id = ?
        ");
        $checkStmt->execute([$subscriptionId]);
        $subscription = $checkStmt->fetch();
        
        if (!$subscription) throw new Exception("Subscription not found.");
        if ($subscription['status_name'] !== 'pending_approval') throw new Exception("Subscription is not in pending status. Current status: " . $subscription['status_name']);
        
        // Try 'rejected' first, then 'declined' as fallback
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'rejected'");
        $statusStmt->execute();
        $declinedStatus = $statusStmt->fetch();
        
        if (!$declinedStatus) {
            $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'declined'");
            $statusStmt->execute();
            $declinedStatus = $statusStmt->fetch();
        }
        
        if (!$declinedStatus) throw new Exception("Declined/Rejected status not found in database.");
        
        $updateStmt = $pdo->prepare("UPDATE subscription SET status_id = ? WHERE id = ?");
        $updateStmt->execute([$declinedStatus['id'], $subscriptionId]);
        
        $pdo->commit();
        
        echo json_encode([
            "success" => true,
            "subscription_id" => $subscriptionId,
            "status" => "declined",
            "message" => "Subscription declined successfully",
            "data" => [
                "subscription_id" => $subscriptionId,
                "user_name" => trim($subscription['fname'] . ' ' . $subscription['lname']),
                "user_email" => $subscription['email'],
                "plan_name" => $subscription['plan_name'],
                "status" => "declined",
                "decline_reason" => $declineReason,
                "declined_at" => date('Y-m-d H:i:s'),
                "declined_by" => $declinedBy
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Decline failed", "message" => $e->getMessage()]);
    }
}

function updateSubscription($pdo, $data) {
    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Missing ID", "message" => "Subscription ID is required"]);
        return;
    }
    
    $id = $data['id'];
    
    $pdo->beginTransaction();
    
    try {
        $stmt = $pdo->prepare("UPDATE subscription SET user_id = ?, plan_id = ?, status_id = ?, start_date = ?, end_date = ? WHERE id = ?");
        $stmt->execute([$data['user_id'], $data['plan_id'], $data['status_id'], $data['start_date'], $data['end_date'], $id]);
        
        $pdo->commit();
        
        echo json_encode([
            "success" => true,
            "subscription_id" => $id,
            "message" => "Subscription updated successfully"
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(["success" => false, "error" => "Update failed", "message" => $e->getMessage()]);
    }
}

function deleteSubscription($pdo, $data) {
    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Missing ID", "message" => "Subscription ID is required"]);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM subscription WHERE id = ?");
        $stmt->execute([$data['id']]);
        
        echo json_encode([
            "success" => true,
            "subscription_id" => $data['id'],
            "message" => "Subscription deleted successfully"
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "error" => "Delete failed", "message" => $e->getMessage()]);
    }
}

function requestSubscription($pdo, $data) {
    // Validate required fields
    $required_fields = ['user_id', 'plan_id'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode([
                "success" => false, 
                "error" => "Missing required field: $field"
            ]);
            return;
        }
    }

    $user_id = $data['user_id'];
    $plan_id = $data['plan_id'];
    $payment_method = $data['payment_method'] ?? 'cash';
    $renewal = isset($data['renewal']) && $data['renewal'] === true;
    $advance_payment = isset($data['advance_payment']) && $data['advance_payment'] === true;
    $periods = isset($data['periods']) ? max(1, intval($data['periods'])) : 1;

    $pdo->beginTransaction();

    try {
        // Verify user exists and is a customer
        $userStmt = $pdo->prepare("SELECT id, fname, lname, email, user_type_id, account_status FROM user WHERE id = ?");
        $userStmt->execute([$user_id]);
        $user = $userStmt->fetch();
        
        if (!$user) throw new Exception("User not found");
        if ($user['user_type_id'] != 4) throw new Exception("Subscriptions can only be requested by customers");
        if ($user['account_status'] !== 'approved') throw new Exception("User account must be approved first");

        // Check for existing pending requests (SINGLE REQUEST RULE)
        $pendingStmt = $pdo->prepare("
            SELECT s.id, s.plan_id, p.plan_name, s.start_date
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE s.user_id = ? AND st.status_name = 'pending_approval'
        ");
        $pendingStmt->execute([$user_id]);
        $pendingRequest = $pendingStmt->fetch();
        
        if ($pendingRequest) {
            throw new Exception("You already have a pending request for '{$pendingRequest['plan_name']}'. Please wait for approval or cancel it first before requesting a new plan.");
        }

        // Verify plan exists
        $planStmt = $pdo->prepare("SELECT id, plan_name, price, duration_months, duration_days FROM member_subscription_plan WHERE id = ?");
        $planStmt->execute([$plan_id]);
        $plan = $planStmt->fetch();
        
        if (!$plan) throw new Exception("Subscription plan not found");

        // Calculate total price based on periods
        $total_price = $plan['price'] * $periods;

        // Handle renewal: get active subscription end date
        $renewal_start_date = null;
        $advance_payment_start_date = null;
        
        if ($renewal) {
            $activeStmt = $pdo->prepare("
                SELECT s.end_date, p.plan_name
                FROM subscription s
                JOIN subscription_status st ON s.status_id = st.id
                JOIN member_subscription_plan p ON s.plan_id = p.id
                WHERE s.user_id = ? 
                AND s.plan_id = ?
                AND st.status_name IN ('approved', 'active')
                AND s.end_date >= CURDATE()
                ORDER BY s.end_date DESC
                LIMIT 1
            ");
            $activeStmt->execute([$user_id, $plan_id]);
            $activeSubscription = $activeStmt->fetch();
            
            if (!$activeSubscription) {
                throw new Exception("No active subscription found for renewal. Please select 'New Subscription' instead.");
            }
            
            $renewal_start_date = $activeSubscription['end_date'];
        } elseif ($advance_payment) {
            // For advance payment, get the latest end date of any active subscription
            $activeStmt = $pdo->prepare("
                SELECT s.end_date, p.plan_name
                FROM subscription s
                JOIN subscription_status st ON s.status_id = st.id
                JOIN member_subscription_plan p ON s.plan_id = p.id
                WHERE s.user_id = ? 
                AND st.status_name IN ('approved', 'active')
                AND s.end_date >= CURDATE()
                ORDER BY s.end_date DESC
                LIMIT 1
            ");
            $activeStmt->execute([$user_id]);
            $activeSubscription = $activeStmt->fetch();
            
            if (!$activeSubscription) {
                throw new Exception("No active subscription found for advance payment. Please select 'New Subscription' instead.");
            }
            
            $advance_payment_start_date = $activeSubscription['end_date'];
        }

        // Check plan compatibility logic (skip if renewal or advance payment)
        if (!$renewal && !$advance_payment) {
            $compatibilityCheck = checkPlanCompatibility($pdo, $user_id, $plan_id);
            if (!$compatibilityCheck['compatible']) {
                throw new Exception($compatibilityCheck['message']);
            }
        }

        // Get pending status ID first (we need it to determine if this is a pending request)
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'pending_approval'");
        $statusStmt->execute();
        $status = $statusStmt->fetch();
        
        if (!$status) {
            throw new Exception("Pending approval status not found in database");
        }

        // For pending requests, we need to store the actual request time (with time component)
        // so that expiration can be calculated accurately (12 hours from request time)
        // For approved subscriptions, start_date will be adjusted during approval
        $request_time = new DateTime(); // Current datetime with time component
        
        // Calculate dates for subscription period (these are used when subscription is approved)
        if ($renewal && $renewal_start_date) {
            // Renewal: start from the end date of current subscription
            $subscription_start_date = $renewal_start_date;
            $start_date_obj = new DateTime($subscription_start_date);
        } elseif ($advance_payment && $advance_payment_start_date) {
            // Advance payment: start from the end date of current active subscription
            $subscription_start_date = $advance_payment_start_date;
            $start_date_obj = new DateTime($subscription_start_date);
        } else {
            // New subscription: start from today
            $subscription_start_date = date('Y-m-d');
            $start_date_obj = new DateTime($subscription_start_date);
        }
        
        $end_date_obj = clone $start_date_obj;
        
        // Calculate duration based on periods
        if ($plan_id == 6) {
            // Day Pass: Expires at 12 AM (midnight) of the next day
            // If start_date is Jan 15, end_date should be Jan 16 (expires at midnight of Jan 16, so valid until end of Jan 15)
            // Note: Day Pass is always 1 session, so periods is ignored and forced to 1
            $periods = 1; // Force periods to 1 for Day Pass
            $end_date_obj->modify('+1 day');
            $end_date = $end_date_obj->format('Y-m-d');
            error_log("DEBUG REQUEST: Day Pass (plan_id=6) - subscription_start_date=$subscription_start_date, end_date=$end_date (expires at midnight of next day), periods forced to 1");
        } else {
            $total_duration_days = 0;
            $total_duration_months = 0;
            
            if ($plan['duration_days'] && $plan['duration_days'] > 0) {
                $total_duration_days = $plan['duration_days'] * $periods;
                $end_date_obj->add(new DateInterval('P' . $total_duration_days . 'D'));
            } else {
                $total_duration_months = $plan['duration_months'] * $periods;
                $end_date_obj->add(new DateInterval('P' . $total_duration_months . 'M'));
            }
            
            $end_date = $end_date_obj->format('Y-m-d');
        }

        // For pending requests, use MySQL's NOW() to store the actual request time with time component
        // This ensures the database stores the exact timestamp at the database level
        // This allows expiration to be calculated from the exact request time (3 hours or 12 hours)
        // When the subscription is approved, start_date will be updated to the subscription start date
        // Use NOW() in the SQL query to ensure database-level timestamp accuracy
        
        // Create subscription request
        // Use NOW() for start_date to ensure accurate timestamp storage at database level
        // This works regardless of whether the column is DATE, DATETIME, or TIMESTAMP
        $subscriptionStmt = $pdo->prepare("
            INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discount_type, amount_paid) 
            VALUES (?, ?, ?, NOW(), ?, 'none', ?)
        ");
        $subscriptionStmt->execute([$user_id, $plan_id, $status['id'], $end_date, $total_price]);
        $subscription_id = $pdo->lastInsertId();
        
        // Get the actual timestamp that was stored by the database
        // This ensures we have the exact timestamp stored (with time component if column supports it)
        $getTimestampStmt = $pdo->prepare("SELECT start_date FROM subscription WHERE id = ?");
        $getTimestampStmt->execute([$subscription_id]);
        $storedTimestamp = $getTimestampStmt->fetchColumn();
        
        // Log the stored timestamp for debugging
        error_log("DEBUG REQUEST: Stored start_date (request time) = $storedTimestamp for subscription_id = $subscription_id");

        $pdo->commit();

        $message = "Subscription request submitted successfully";
        if ($renewal) {
            $message = "Renewal request submitted successfully. Your subscription will extend from " . date('M d, Y', strtotime($subscription_start_date));
        } elseif ($advance_payment) {
            $message = "Advance payment request submitted successfully. Your subscription will start after your current subscription ends.";
        } elseif ($periods > 1) {
            $message = "Subscription request for {$periods} periods submitted successfully";
        }

        echo json_encode([
            "success" => true,
            "message" => $message,
            "data" => [
                "subscription_id" => $subscription_id,
                "user_name" => $user['fname'] . ' ' . $user['lname'],
                "user_email" => $user['email'],
                "plan_name" => $plan['plan_name'],
                "start_date" => $subscription_start_date,
                "end_date" => $end_date,
                "amount" => $total_price,
                "periods" => $periods,
                "renewal" => $renewal,
                "advance_payment" => $advance_payment,
                "status" => "pending_approval"
            ]
        ]);

    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode([
            "success" => false, 
            "error" => "Failed to request subscription", 
            "message" => $e->getMessage()
        ]);
    }
}

// New function to check plan compatibility
function checkPlanCompatibility($pdo, $user_id, $plan_id) {
    // Get user's active subscriptions
    $activeStmt = $pdo->prepare("
        SELECT s.plan_id, p.plan_name, s.end_date
        FROM subscription s
        JOIN subscription_status st ON s.status_id = st.id
        JOIN member_subscription_plan p ON s.plan_id = p.id
        WHERE s.user_id = ? 
        AND st.status_name = 'approved' 
        AND s.end_date >= CURDATE()
    ");
    $activeStmt->execute([$user_id]);
    $activeSubscriptions = $activeStmt->fetchAll();
    
    $hasActiveMembershipFee = false;
    $hasActiveCombinationPackage = false;
    foreach ($activeSubscriptions as $sub) {
        if ($sub['plan_id'] == 1) { // Membership Fee
            $hasActiveMembershipFee = true;
        }
        if ($sub['plan_id'] == 5) { // Combination package
            $hasActiveCombinationPackage = true;
        }
    }
    
    // Plan compatibility logic
    switch ($plan_id) {
        case 1: // Membership Fee - can be requested anytime
            return [
                'compatible' => true,
                'message' => ''
            ];
            
        case 2: // Monthly Member Plan - requires active Membership Fee
            if ($hasActiveCombinationPackage) {
                return [
                    'compatible' => false,
                    'message' => 'You have the Membership + 1 Month Access package which includes monthly access. This individual plan is not needed.'
                ];
            }
            if (!$hasActiveMembershipFee) {
                return [
                    'compatible' => false,
                    'message' => 'You need an active Membership Fee subscription to request Monthly Member Plan. Please request Membership Fee first.'
                ];
            }
            return [
                'compatible' => true,
                'message' => ''
            ];
            
        case 3: // Monthly Non-Member Plan - requires NO active Membership Fee
            if ($hasActiveMembershipFee) {
                return [
                    'compatible' => false,
                    'message' => 'You have an active Membership Fee subscription. You can only request Monthly Member Plan, not Non-Member Plan.'
                ];
            }
            return [
                'compatible' => true,
                'message' => ''
            ];
            
        case 5: // Membership + 1 Month Access - Combination package
            if ($hasActiveMembershipFee || count($activeSubscriptions) > 0) {
                return [
                    'compatible' => false,
                    'message' => 'This combination package is only available for new users with no existing subscriptions.'
                ];
            }
            return [
                'compatible' => true,
                'message' => ''
            ];
            
        case 6: // Day Pass - only available if no active monthly plans (premium or standard)
            // Check if user has any active monthly plans (2, 3, or 5)
            foreach ($activeSubscriptions as $sub) {
                if ($sub['plan_id'] == 2 || $sub['plan_id'] == 3 || $sub['plan_id'] == 5) {
                    $planName = $sub['plan_name'];
                    $endDate = date('M d, Y', strtotime($sub['end_date']));
                    return [
                        'compatible' => false,
                        'message' => "You currently have an active {$planName} until {$endDate}. Please wait for it to expire before requesting a Day Pass."
                    ];
                }
            }
            return [
                'compatible' => true,
                'message' => ''
            ];
            
        default: // Other plans - check if already active
            foreach ($activeSubscriptions as $sub) {
                if ($sub['plan_id'] == $plan_id) {
                    return [
                        'compatible' => false,
                        'message' => "You already have an active subscription to this plan."
                    ];
                }
            }
            return [
                'compatible' => true,
                'message' => ''
            ];
    }
}

function getSubscriptionPlan($pdo, $plan_id) {
    $stmt = $pdo->prepare("
        SELECT 
            id,
            plan_name,
            price,
            duration_months,
            duration_days,
            is_member_only,
            discounted_price
        FROM member_subscription_plan 
        WHERE id = ?
    ");
    
    $stmt->execute([$plan_id]);
    $plan = $stmt->fetch();
    
    if (!$plan) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "error" => "Plan not found",
            "message" => "Subscription plan with ID $plan_id not found"
        ]);
        return;
    }
    
    // Add features for the plan
    $featuresStmt = $pdo->prepare("
        SELECT feature_name, description 
        FROM subscription_feature 
        WHERE plan_id = ?
    ");
    $featuresStmt->execute([$plan_id]);
    $plan['features'] = $featuresStmt->fetchAll();
    
    echo json_encode([
        "success" => true,
        "plan" => $plan
    ]);
}

function cancelSubscription($pdo, $data) {
    if (!isset($data['subscription_id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Missing subscription_id", "message" => "subscription_id is required"]);
        return;
    }
    
    $subscriptionId = $data['subscription_id'];
    
    $pdo->beginTransaction();
    
    try {
        $checkStmt = $pdo->prepare("
            SELECT s.id, s.user_id, s.plan_id, st.status_name,
                   u.fname, u.lname, u.email,
                   p.plan_name, p.price
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN user u ON s.user_id = u.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE s.id = ?
        ");
        $checkStmt->execute([$subscriptionId]);
        $subscription = $checkStmt->fetch();
        
        if (!$subscription) throw new Exception("Subscription not found.");
        if ($subscription['status_name'] === 'cancelled') throw new Exception("Subscription is already cancelled.");
        
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'cancelled'");
        $statusStmt->execute();
        $cancelledStatus = $statusStmt->fetch();
        
        if (!$cancelledStatus) throw new Exception("Cancelled status not found in database.");
        
        $updateStmt = $pdo->prepare("UPDATE subscription SET status_id = ? WHERE id = ?");
        $updateStmt->execute([$cancelledStatus['id'], $subscriptionId]);
        
        $pdo->commit();
        
        echo json_encode([
            "success" => true,
            "subscription_id" => $subscriptionId,
            "status" => "cancelled",
            "message" => "Subscription cancelled successfully",
            "data" => [
                "subscription_id" => $subscriptionId,
                "user_name" => trim($subscription['fname'] . ' ' . $subscription['lname']),
                "user_email" => $subscription['email'],
                "plan_name" => $subscription['plan_name'],
                "status" => "cancelled",
                "cancelled_at" => date('Y-m-d H:i:s')
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Cancellation failed", "message" => $e->getMessage()]);
    }
}

// New function to get user's pending request
function getUserPendingRequest($pdo, $user_id) {
    error_log("DEBUG: getUserPendingRequest called with user_id: " . $user_id);
    
    // Query to get pending request with request_date (start_date for pending requests)
    // Use DATE_FORMAT to ensure we get the full datetime if the column supports it
    // If column is DATE type, it will only return date (time will be 00:00:00)
    // If column is DATETIME/TIMESTAMP, it will return full timestamp
    $stmt = $pdo->prepare("
        SELECT s.id, s.plan_id, s.start_date, s.end_date, s.amount_paid,
               p.plan_name, p.price, p.duration_months, p.duration_days,
               ss.status_name,
               DATE_FORMAT(s.start_date, '%Y-%m-%d %H:%i:%s') as request_date
        FROM subscription s
        JOIN member_subscription_plan p ON s.plan_id = p.id
        JOIN subscription_status ss ON s.status_id = ss.id
        WHERE s.user_id = ? AND ss.status_name = 'pending_approval'
        ORDER BY s.start_date DESC
        LIMIT 1
    ");
    
    $stmt->execute([$user_id]);
    $pendingRequest = $stmt->fetch();
    
    // Log the request_date for debugging
    if ($pendingRequest) {
        error_log("DEBUG: Found pending request - request_date = " . $pendingRequest['request_date']);
        error_log("DEBUG: Found pending request - raw start_date = " . $pendingRequest['start_date']);
    } else {
        error_log("DEBUG: No pending request found for user_id: " . $user_id);
    }
    
    if (!$pendingRequest) {
        echo json_encode([
            "success" => true,
            "has_pending_request" => false,
            "message" => "No pending requests found"
        ]);
        return;
    }
    
    // Calculate periods from amount_paid and price
    $periods = 1;
    if ($pendingRequest['price'] > 0) {
        $periods = round($pendingRequest['amount_paid'] / $pendingRequest['price']);
        if ($periods < 1) $periods = 1;
    }
    
    // Calculate total price (should be same as amount_paid, but include it for clarity)
    $total_price = $pendingRequest['amount_paid'];
    
    // Add periods and total_price to pending request
    $pendingRequest['periods'] = $periods;
    $pendingRequest['total_price'] = $total_price;
    
    // Calculate expiry date based on plan type:
    // All subscriptions (including Day Pass): 12 hours
    $plan_id = intval($pendingRequest['plan_id']);
    
    // Parse request_date - handle DATE column type issue
    // If database column is DATE type, NOW() gets truncated to midnight (00:00:00)
    // This causes expiration to be calculated incorrectly (request appears expired immediately)
    $requestDateStr = $pendingRequest['request_date'];
    $rawStartDate = $pendingRequest['start_date'];
    
    // Parse the request date
    try {
        $requestDate = new DateTime($requestDateStr);
    } catch (Exception $e) {
        error_log("DEBUG: Error parsing request_date: $requestDateStr - " . $e->getMessage());
        $requestDate = new DateTime();
    }
    
    $now = new DateTime();
    
    // Check if request date is today
    $requestDateOnly = clone $requestDate;
    $requestDateOnly->setTime(0, 0, 0);
    $todayOnly = clone $now;
    $todayOnly->setTime(0, 0, 0);
    $isToday = ($requestDateOnly->format('Y-m-d') === $todayOnly->format('Y-m-d'));
    
    // Check if request time is midnight (00:00:00) or very early (before 1 AM)
    // This indicates DATE column type where time was truncated
    $requestTime = $requestDate->format('H:i:s');
    $requestHour = (int)$requestDate->format('H');
    $isMidnight = ($requestTime === '00:00:00');
    $isEarlyMorning = ($requestHour >= 0 && $requestHour < 1);
    
    // CRITICAL FIX: If request was made today, ALWAYS use current time as request time
    // This is the safest approach to prevent immediate expiration
    // The database DATE column truncates time to midnight, which causes expiration issues
    if ($isToday) {
        // Request was made today - use current time minus 5 minutes as request time
        // This ensures expiration is ALWAYS in the future (12 hours from now minus 5 minutes)
        // This prevents any edge cases with DATE column truncation
        $requestDate = clone $now;
        $requestDate->sub(new DateInterval('PT5M')); // Subtract 5 minutes for safety buffer
        error_log("DEBUG: Request made today detected - using current time minus 5 minutes as request time: " . $requestDate->format('Y-m-d H:i:s'));
        error_log("DEBUG: Original request_date from DB: $requestDateStr (time was: $requestTime, hour: $requestHour)");
    } else {
        // Request date is in the past - use as-is (this is an old request)
        error_log("DEBUG: Request date is in the past - using parsed request_date: " . $requestDate->format('Y-m-d H:i:s'));
    }
    
    // Calculate expiry date - all subscriptions expire in 12 hours from request time
    $expiryDate = clone $requestDate;
    $expiryDate->add(new DateInterval('PT12H')); // 12 hours
    $maxHours = 12;
    
    // CRITICAL: If request was made today, NEVER mark it as expired
    // This prevents immediate expiration due to DATE column truncation issues
    if ($isToday) {
        // Request was made today - ensure it's never expired
        // Force expiration to be 12 hours from now (with small buffer)
        $requestDate = clone $now;
        $requestDate->sub(new DateInterval('PT5M')); // Subtract 5 minutes for safety buffer
        $expiryDate = clone $requestDate;
        $expiryDate->add(new DateInterval('PT12H')); // 12 hours
        $isExpired = false; // Force to false - requests made today are NEVER expired
        $timeRemaining = $expiryDate->getTimestamp() - $now->getTimestamp();
        $timeRemainingHours = round($timeRemaining / 3600, 1);
        
        // Ensure time remaining is reasonable (should be ~11.9 hours)
        if ($timeRemainingHours < 0) {
            $timeRemainingHours = 11.9; // Safety fallback
        }
        if ($timeRemainingHours > $maxHours) {
            $timeRemainingHours = $maxHours;
        }
        
        error_log("DEBUG: Request made today - FORCED to not expire. request_date = " . $requestDate->format('Y-m-d H:i:s') . ", expiry_date = " . $expiryDate->format('Y-m-d H:i:s') . ", now = " . $now->format('Y-m-d H:i:s') . ", isExpired = false (forced), timeRemainingHours = $timeRemainingHours");
    } else {
        // Request date is in the past - calculate expiration normally
        $isExpired = $now > $expiryDate;
        $timeRemaining = $isExpired ? 0 : $expiryDate->getTimestamp() - $now->getTimestamp();
        $timeRemainingHours = round($timeRemaining / 3600, 1);
        
        // Log expiration calculation for debugging
        error_log("DEBUG: plan_id=$plan_id, request_date = " . $requestDate->format('Y-m-d H:i:s') . ", expiry_date = " . $expiryDate->format('Y-m-d H:i:s') . ", now = " . $now->format('Y-m-d H:i:s') . ", isExpired = " . ($isExpired ? 'true' : 'false') . ", timeRemainingHours = $timeRemainingHours");
        
        // Safety check: Ensure time remaining doesn't exceed max hours
        if ($timeRemainingHours > $maxHours) {
            $timeRemainingHours = $maxHours;
        }
    }
    
    echo json_encode([
        "success" => true,
        "has_pending_request" => true,
        "pending_request" => $pendingRequest,
        "expiry_date" => $expiryDate->format('Y-m-d H:i:s'),
        "is_expired" => $isExpired,
        "time_remaining_seconds" => $timeRemaining,
        "time_remaining_hours" => $timeRemainingHours
    ]);
}

// New function to cancel pending request
function cancelPendingRequest($pdo, $data) {
    if (!isset($data['user_id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Missing user_id", "message" => "user_id is required"]);
        return;
    }
    
    $user_id = $data['user_id'];
    
    $pdo->beginTransaction();
    
    try {
        // Get pending request
        $checkStmt = $pdo->prepare("
            SELECT s.id, s.plan_id, p.plan_name
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE s.user_id = ? AND st.status_name = 'pending_approval'
        ");
        $checkStmt->execute([$user_id]);
        $pendingRequest = $checkStmt->fetch();
        
        if (!$pendingRequest) {
            throw new Exception("No pending request found for this user.");
        }
        
        // Get cancelled status ID
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'cancelled'");
        $statusStmt->execute();
        $cancelledStatus = $statusStmt->fetch();
        
        if (!$cancelledStatus) {
            throw new Exception("Cancelled status not found in database.");
        }
        
        // Update subscription status to cancelled
        $updateStmt = $pdo->prepare("UPDATE subscription SET status_id = ? WHERE id = ?");
        $updateStmt->execute([$cancelledStatus['id'], $pendingRequest['id']]);
        
        $pdo->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Pending request cancelled successfully",
            "data" => [
                "subscription_id" => $pendingRequest['id'],
                "plan_name" => $pendingRequest['plan_name'],
                "cancelled_at" => date('Y-m-d H:i:s')
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(["success" => false, "error" => "Cancellation failed", "message" => $e->getMessage()]);
    }
}

// New function to auto-expire old requests
function autoExpireRequests($pdo) {
    try {
        // Get expired pending requests (older than 24 hours)
        $expiredStmt = $pdo->prepare("
            SELECT s.id, s.user_id, p.plan_name, s.start_date
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE st.status_name = 'pending_approval'
            AND s.start_date < DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ");
        $expiredStmt->execute();
        $expiredRequests = $expiredStmt->fetchAll();
        
        if (empty($expiredRequests)) {
            echo json_encode([
                "success" => true,
                "message" => "No expired requests found",
                "expired_count" => 0
            ]);
            return;
        }
        
        // Get cancelled status ID
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'cancelled'");
        $statusStmt->execute();
        $cancelledStatus = $statusStmt->fetch();
        
        if (!$cancelledStatus) {
            throw new Exception("Cancelled status not found in database.");
        }
        
        $pdo->beginTransaction();
        
        $expiredIds = array_column($expiredRequests, 'id');
        $placeholders = str_repeat('?,', count($expiredIds) - 1) . '?';
        
        // Update all expired requests to cancelled
        $updateStmt = $pdo->prepare("
            UPDATE subscription 
            SET status_id = ? 
            WHERE id IN ($placeholders)
        ");
        $updateStmt->execute(array_merge([$cancelledStatus['id']], $expiredIds));
        
        $pdo->commit();
        
        echo json_encode([
            "success" => true,
            "message" => "Auto-expired " . count($expiredRequests) . " requests",
            "expired_count" => count($expiredRequests),
            "expired_requests" => $expiredRequests
        ]);
        
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        http_response_code(500);
        echo json_encode(["success" => false, "error" => "Auto-expiry failed", "message" => $e->getMessage()]);
    }
}
?>
 