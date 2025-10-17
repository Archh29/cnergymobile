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
        $featuresStmt = $pdo->prepare("
            SELECT feature_name, description 
            FROM subscription_feature 
            WHERE plan_id = ?
        ");
        $featuresStmt->execute([$plan['id']]);
        $plan['features'] = $featuresStmt->fetchAll();
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
    
    // Get payment information for each subscription
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
    $hasActiveMonthlyPlan = in_array(2, $activePlanIds) || in_array(3, $activePlanIds) || in_array(5, $activePlanIds);
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
        $availabilityStatus = getPlanAvailabilityStatus($planId, $hasActiveMemberFee, $hasActiveMonthlyPlan, $hasActiveDayPass, $isPlanActive, $activeMonthlyPlan);
        
        $plan['is_available'] = $availabilityStatus['available'];
        $plan['is_locked'] = !$availabilityStatus['available'];
        $plan['lock_reason'] = $availabilityStatus['reason'];
        $plan['lock_message'] = $availabilityStatus['message'];
        $plan['lock_icon'] = $availabilityStatus['icon'];
        
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
function getPlanAvailabilityStatus($planId, $hasActiveMemberFee, $hasActiveMonthlyPlan, $hasActiveDayPass, $isPlanActive, $activeMonthlyPlan) {
    switch ($planId) {
        case 1: // Membership Fee - always available
            return [
                'available' => !$isPlanActive,
                'reason' => $isPlanActive ? 'already_active' : 'available',
                'message' => $isPlanActive ? 'You already have an active Membership Fee subscription.' : 'One-time fee for member benefits and discounts on monthly plans.',
                'icon' => $isPlanActive ? '🔒' : '✅'
            ];
            
        case 2: // Member Monthly Plan
            if ($isPlanActive) {
                return [
                    'available' => false,
                    'reason' => 'already_active',
                    'message' => 'You already have an active Member Monthly Plan.',
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
            
        case 3: // Non-Member Monthly Plan
            if ($isPlanActive) {
                return [
                    'available' => false,
                    'reason' => 'already_active',
                    'message' => 'You already have an active Non-Member Monthly Plan.',
                    'icon' => '🔒'
                ];
            }
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
            if ($hasActiveMemberFee || $hasActiveMonthlyPlan) {
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
            
        case 6: // Day Pass
            if ($isPlanActive) {
                return [
                    'available' => false,
                    'reason' => 'already_active',
                    'message' => 'You already have an active Day Pass.',
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
                    'message' => "You currently have an active {$planName} until {$endDate}. Please wait for it to expire before purchasing a Day Pass.",
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
                'message' => '1-day gym access with member benefits. Perfect for trying out the gym!',
                'icon' => '✅'
            ];
            
        default: // Other plans
            return [
                'available' => !$isPlanActive,
                'reason' => $isPlanActive ? 'already_active' : 'available',
                'message' => $isPlanActive ? 'You already have an active subscription to this plan.' : 'This plan is available for subscription.',
                'icon' => $isPlanActive ? '🔒' : '✅'
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
        
        if ($plan['duration_days'] && $plan['duration_days'] > 0) {
            // Use duration_days for day-based plans
            $end_date_obj->add(new DateInterval('P' . $plan['duration_days'] . 'D'));
        } else {
            // Use duration_months for month-based plans
            $end_date_obj->add(new DateInterval('P' . $plan['duration_months'] . 'M'));
        }
        $end_date = $end_date_obj->format('Y-m-d');

        // Get approved status ID
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'approved'");
        $statusStmt->execute();
        $status = $statusStmt->fetch();
        
        if (!$status) {
            throw new Exception("Approved status not found in database");
        }

        // Check for existing active subscriptions to prevent duplicates
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

        // Create subscription
        $subscriptionStmt = $pdo->prepare("
            INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discounted_price, discount_type, amount_paid) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $subscriptionStmt->execute([$user_id, $plan_id, $status['id'], $start_date, $end_date, $payment_amount, $discount_type, $payment_amount]);
        $subscription_id = $pdo->lastInsertId();

        // Create payment record
        $paymentStmt = $pdo->prepare("
            INSERT INTO payment (subscription_id, amount, payment_date) 
            VALUES (?, ?, NOW())
        ");
        $paymentStmt->execute([$subscription_id, $payment_amount]);
        $payment_id = $pdo->lastInsertId();

        // Create sales record
        $salesStmt = $pdo->prepare("
            INSERT INTO sales (user_id, total_amount, sale_date, sale_type) 
            VALUES (?, ?, NOW(), 'Subscription')
        ");
        $salesStmt->execute([$user_id, $payment_amount]);
        $sale_id = $pdo->lastInsertId();

        // Create sales details
        $salesDetailStmt = $pdo->prepare("
            INSERT INTO sales_details (sale_id, subscription_id, quantity, price) 
            VALUES (?, ?, 1, ?)
        ");
        $salesDetailStmt->execute([$sale_id, $subscription_id, $payment_amount]);

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

        echo json_encode([
            "success" => true,
            "message" => "Manual subscription created successfully",
            "data" => [
                "subscription_id" => $subscription_id,
                "payment_id" => $payment_id,
                "sale_id" => $sale_id,
                "user_name" => $user['fname'] . ' ' . $user['lname'],
                "user_email" => $user['email'],
                "plan_name" => $plan['plan_name'],
                "start_date" => $start_date,
                "end_date" => $end_date,
                "amount_paid" => $payment_amount,
                "discount_type" => $discount_type,
                "existing_subscription_warning" => $existingSubscription ? "User had an active subscription ending on " . $existingSubscription['end_date'] : null
            ]
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
        
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'approved'");
        $statusStmt->execute();
        $approvedStatus = $statusStmt->fetch();
        
        if (!$approvedStatus) throw new Exception("Approved status not found in database.");
        
        $updateStmt = $pdo->prepare("UPDATE subscription SET status_id = ? WHERE id = ?");
        $updateStmt->execute([$approvedStatus['id'], $subscriptionId]);
        
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

        // Check plan compatibility logic
        $compatibilityCheck = checkPlanCompatibility($pdo, $user_id, $plan_id);
        if (!$compatibilityCheck['compatible']) {
            throw new Exception($compatibilityCheck['message']);
        }

        // Calculate dates
        $start_date = date('Y-m-d');
        $start_date_obj = new DateTime($start_date);
        $end_date_obj = clone $start_date_obj;
        
        if ($plan['duration_days'] && $plan['duration_days'] > 0) {
            // Use duration_days for day-based plans
            $end_date_obj->add(new DateInterval('P' . $plan['duration_days'] . 'D'));
        } else {
            // Use duration_months for month-based plans
            $end_date_obj->add(new DateInterval('P' . $plan['duration_months'] . 'M'));
        }
        $end_date = $end_date_obj->format('Y-m-d');

        // Get pending status ID
        $statusStmt = $pdo->prepare("SELECT id FROM subscription_status WHERE status_name = 'pending_approval'");
        $statusStmt->execute();
        $status = $statusStmt->fetch();
        
        if (!$status) {
            throw new Exception("Pending approval status not found in database");
        }

        // Create subscription request
        $subscriptionStmt = $pdo->prepare("
            INSERT INTO subscription (user_id, plan_id, status_id, start_date, end_date, discount_type, amount_paid) 
            VALUES (?, ?, ?, ?, ?, 'none', ?)
        ");
        $subscriptionStmt->execute([$user_id, $plan_id, $status['id'], $start_date, $end_date, $plan['price']]);
        $subscription_id = $pdo->lastInsertId();

        $pdo->commit();

        echo json_encode([
            "success" => true,
            "message" => "Subscription request submitted successfully",
            "data" => [
                "subscription_id" => $subscription_id,
                "user_name" => $user['fname'] . ' ' . $user['lname'],
                "user_email" => $user['email'],
                "plan_name" => $plan['plan_name'],
                "start_date" => $start_date,
                "end_date" => $end_date,
                "amount" => $plan['price'],
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
    foreach ($activeSubscriptions as $sub) {
        if ($sub['plan_id'] == 1) { // Membership Fee
            $hasActiveMembershipFee = true;
            break;
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
            
        case 6: // Day Pass - requires active Membership Fee, cannot have active monthly plans
            if (!$hasActiveMembershipFee) {
                return [
                    'compatible' => false,
                    'message' => 'You need an active Membership Fee subscription to request Day Pass. Please request Membership Fee first.'
                ];
            }
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
    
    $stmt = $pdo->prepare("
        SELECT s.id, s.plan_id, s.start_date, s.end_date, s.amount_paid,
               p.plan_name, p.price, p.duration_months,
               ss.status_name,
               s.start_date as request_date
        FROM subscription s
        JOIN member_subscription_plan p ON s.plan_id = p.id
        JOIN subscription_status ss ON s.status_id = ss.id
        WHERE s.user_id = ? AND ss.status_name = 'pending_approval'
        ORDER BY s.start_date DESC
        LIMIT 1
    ");
    
    $stmt->execute([$user_id]);
    $pendingRequest = $stmt->fetch();
    
    error_log("DEBUG: Found pending request: " . json_encode($pendingRequest));
    
    if (!$pendingRequest) {
        echo json_encode([
            "success" => true,
            "has_pending_request" => false,
            "message" => "No pending requests found"
        ]);
        return;
    }
    
    // Calculate expiry date (48 hours from request date)
    $requestDate = new DateTime($pendingRequest['request_date']);
    $expiryDate = clone $requestDate;
    $expiryDate->add(new DateInterval('PT48H')); // 48 hours
    $now = new DateTime();
    
    $isExpired = $now > $expiryDate;
    $timeRemaining = $isExpired ? 0 : $expiryDate->getTimestamp() - $now->getTimestamp();
    
    echo json_encode([
        "success" => true,
        "has_pending_request" => true,
        "pending_request" => $pendingRequest,
        "expiry_date" => $expiryDate->format('Y-m-d H:i:s'),
        "is_expired" => $isExpired,
        "time_remaining_seconds" => $timeRemaining,
        "time_remaining_hours" => round($timeRemaining / 3600, 1)
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
        // Get expired pending requests (older than 48 hours)
        $expiredStmt = $pdo->prepare("
            SELECT s.id, s.user_id, p.plan_name, s.start_date
            FROM subscription s
            JOIN subscription_status st ON s.status_id = st.id
            JOIN member_subscription_plan p ON s.plan_id = p.id
            WHERE st.status_name = 'pending_approval'
            AND s.start_date < DATE_SUB(NOW(), INTERVAL 48 HOUR)
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
 