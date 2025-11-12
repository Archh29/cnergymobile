<?php
// Complete CORS headers - Fixed for localhost development
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin, X-CSRF-Token, Cache-Control, Pragma");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH");
header("Access-Control-Max-Age: 86400");
header("Access-Control-Allow-Credentials: false");
header("Content-Type: application/json; charset=utf-8");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// === DATABASE CONNECTION ===
try {
    $pdo = new PDO("mysql:host=localhost;dbname=u773938685_cnergydb", "u773938685_archh29", "Gwapoko385@");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    $pdo->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
    exit;
}

// === HELPER FUNCTIONS ===
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_NUMERIC_CHECK);
    exit;
}

// === ROUTER ===
$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

// Add debug logging
error_log("Coach Revenue API - Action: $action, Method: $method");

switch ($action) {
    case 'get-revenue':
        if ($method === 'GET' && isset($_GET['coach_id'])) {
            getRevenueData($pdo, (int)$_GET['coach_id'], $_GET['period'] ?? 'month');
        } else {
            sendResponse(['success' => false, 'message' => 'Coach ID required'], 400);
        }
        break;
        
    case 'get-transactions':
        if ($method === 'GET' && isset($_GET['coach_id'])) {
            getTransactions($pdo, (int)$_GET['coach_id'], $_GET['limit'] ?? 10);
        } else {
            sendResponse(['success' => false, 'message' => 'Coach ID required'], 400);
        }
        break;
        
    default:
        sendResponse(['success' => false, 'message' => 'Invalid action'], 400);
        break;
}

// === API FUNCTIONS ===

function getRevenueData($pdo, $coachId, $period = 'month') {
    try {
        // Calculate date range based on period for coach_member_list
        $memberDateCondition = '';
        $salesDateCondition = '';
        
        switch ($period) {
            case 'week':
                $memberDateCondition = "AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
                $salesDateCondition = "AND cs.sale_date IS NOT NULL AND cs.sale_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
                break;
            case 'month':
                $memberDateCondition = "AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
                $salesDateCondition = "AND cs.sale_date IS NOT NULL AND cs.sale_date >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
                break;
            case 'year':
                $memberDateCondition = "AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)";
                $salesDateCondition = "AND cs.sale_date IS NOT NULL AND cs.sale_date >= DATE_SUB(NOW(), INTERVAL 1 YEAR)";
                break;
            default:
                $memberDateCondition = "AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
                $salesDateCondition = "AND cs.sale_date IS NOT NULL AND cs.sale_date >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
        }
        
        // Get revenue from active subscriptions (coach_member_list)
        // Revenue is calculated based on rate_type and coach pricing
        $revenueStmt = $pdo->prepare("
            SELECT 
                COALESCE(SUM(
                    CASE 
                        WHEN cml.rate_type = 'monthly' THEN COALESCE(c.monthly_rate, 0)
                        WHEN cml.rate_type = 'package' THEN COALESCE(c.session_package_rate, 0)
                        WHEN cml.rate_type = 'per_session' THEN COALESCE(c.per_session_rate, 0) * COALESCE(cml.remaining_sessions, 0)
                        ELSE 0
                    END
                ), 0) as total_revenue,
                COUNT(DISTINCT cml.id) as total_subscriptions
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            $memberDateCondition
        ");
        $revenueStmt->execute([$coachId]);
        $revenueData = $revenueStmt->fetch();
        
        // Get revenue from coach_sales table (historical sales)
        $salesStmt = $pdo->prepare("
            SELECT 
                COALESCE(SUM(COALESCE(amount, 0)), 0) as sales_revenue,
                COUNT(*) as sales_count
            FROM coach_sales cs
            WHERE cs.coach_user_id = ?
            $salesDateCondition
        ");
        $salesStmt->execute([$coachId]);
        $salesData = $salesStmt->fetch();
        
        // Calculate total revenue (subscriptions + sales)
        $totalRevenue = (float)($revenueData['total_revenue'] ?? 0) + (float)($salesData['sales_revenue'] ?? 0);
        
        // Get weekly revenue
        $weeklyStmt = $pdo->prepare("
            SELECT 
                COALESCE(SUM(
                    CASE 
                        WHEN cml.rate_type = 'monthly' THEN COALESCE(c.monthly_rate, 0)
                        WHEN cml.rate_type = 'package' THEN COALESCE(c.session_package_rate, 0)
                        WHEN cml.rate_type = 'per_session' THEN COALESCE(c.per_session_rate, 0) * COALESCE(cml.remaining_sessions, 0)
                        ELSE 0
                    END
                ), 0) as weekly_revenue
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ");
        $weeklyStmt->execute([$coachId]);
        $weeklyData = $weeklyStmt->fetch();
        
        $weeklySalesStmt = $pdo->prepare("
            SELECT COALESCE(SUM(COALESCE(amount, 0)), 0) as weekly_sales
            FROM coach_sales
            WHERE coach_user_id = ?
            AND sale_date IS NOT NULL
            AND sale_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ");
        $weeklySalesStmt->execute([$coachId]);
        $weeklySalesData = $weeklySalesStmt->fetch();
        
        $weeklyRevenue = (float)($weeklyData['weekly_revenue'] ?? 0) + (float)($weeklySalesData['weekly_sales'] ?? 0);
        
        // Get monthly revenue
        $monthlyStmt = $pdo->prepare("
            SELECT 
                COALESCE(SUM(
                    CASE 
                        WHEN cml.rate_type = 'monthly' THEN COALESCE(c.monthly_rate, 0)
                        WHEN cml.rate_type = 'package' THEN COALESCE(c.session_package_rate, 0)
                        WHEN cml.rate_type = 'per_session' THEN COALESCE(c.per_session_rate, 0) * COALESCE(cml.remaining_sessions, 0)
                        ELSE 0
                    END
                ), 0) as monthly_revenue
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
        ");
        $monthlyStmt->execute([$coachId]);
        $monthlyData = $monthlyStmt->fetch();
        
        $monthlySalesStmt = $pdo->prepare("
            SELECT COALESCE(SUM(COALESCE(amount, 0)), 0) as monthly_sales
            FROM coach_sales
            WHERE coach_user_id = ?
            AND sale_date IS NOT NULL
            AND sale_date >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
        ");
        $monthlySalesStmt->execute([$coachId]);
        $monthlySalesData = $monthlySalesStmt->fetch();
        
        $monthlyRevenue = (float)($monthlyData['monthly_revenue'] ?? 0) + (float)($monthlySalesData['monthly_sales'] ?? 0);
        
        // Get yearly revenue
        $yearlyStmt = $pdo->prepare("
            SELECT 
                COALESCE(SUM(
                    CASE 
                        WHEN cml.rate_type = 'monthly' THEN COALESCE(c.monthly_rate, 0)
                        WHEN cml.rate_type = 'package' THEN COALESCE(c.session_package_rate, 0)
                        WHEN cml.rate_type = 'per_session' THEN COALESCE(c.per_session_rate, 0) * COALESCE(cml.remaining_sessions, 0)
                        ELSE 0
                    END
                ), 0) as yearly_revenue
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            AND cml.requested_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
        ");
        $yearlyStmt->execute([$coachId]);
        $yearlyData = $yearlyStmt->fetch();
        
        $yearlySalesStmt = $pdo->prepare("
            SELECT COALESCE(SUM(COALESCE(amount, 0)), 0) as yearly_sales
            FROM coach_sales
            WHERE coach_user_id = ?
            AND sale_date IS NOT NULL
            AND sale_date >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
        ");
        $yearlySalesStmt->execute([$coachId]);
        $yearlySalesData = $yearlySalesStmt->fetch();
        
        $yearlyRevenue = (float)($yearlyData['yearly_revenue'] ?? 0) + (float)($yearlySalesData['yearly_sales'] ?? 0);
        
        // Get statistics
        // Total sessions (from session usage)
        $sessionsStmt = $pdo->prepare("
            SELECT COUNT(*) as total_sessions
            FROM coach_session_usage csu
            JOIN coach_member_list cml ON csu.coach_member_id = cml.id
            WHERE cml.coach_id = ?
        ");
        $sessionsStmt->execute([$coachId]);
        $sessionsData = $sessionsStmt->fetch();
        $totalSessions = (int)($sessionsData['total_sessions'] ?? 0);
        
        // Active members
        $membersStmt = $pdo->prepare("
            SELECT COUNT(DISTINCT cml.member_id) as active_members
            FROM coach_member_list cml
            WHERE cml.coach_id = ?
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
        ");
        $membersStmt->execute([$coachId]);
        $membersData = $membersStmt->fetch();
        $activeMembers = (int)($membersData['active_members'] ?? 0);
        
        // Average per session (total revenue / total sessions, or 0 if no sessions)
        $averagePerSession = $totalSessions > 0 ? ($totalRevenue / $totalSessions) : 0;
        
        sendResponse([
            'success' => true,
            'data' => [
                'total_revenue' => (float)$totalRevenue,
                'weekly_revenue' => (float)$weeklyRevenue,
                'monthly_revenue' => (float)$monthlyRevenue,
                'yearly_revenue' => (float)$yearlyRevenue,
                'total_sessions' => $totalSessions,
                'active_members' => $activeMembers,
                'average_per_session' => (float)$averagePerSession,
                'period' => $period
            ]
        ]);
        
    } catch (PDOException $e) {
        error_log("ERROR - Get revenue data failed: " . $e->getMessage());
        error_log("ERROR - SQL Error Info: " . print_r($e->errorInfo, true));
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage(),
            'error_info' => $e->errorInfo
        ], 500);
    } catch (Exception $e) {
        error_log("ERROR - General error: " . $e->getMessage());
        error_log("ERROR - Stack trace: " . $e->getTraceAsString());
        sendResponse([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ], 500);
    }
}

function getTransactions($pdo, $coachId, $limit = 10) {
    try {
        // Get transactions from coach_sales table
        $salesStmt = $pdo->prepare("
            SELECT 
                cs.sale_id as id,
                cs.item as member_name,
                cs.amount,
                cs.rate_type as type,
                DATE(cs.sale_date) as date,
                cs.sale_date as created_at,
                'completed' as status
            FROM coach_sales cs
            WHERE cs.coach_user_id = ?
            ORDER BY cs.sale_date DESC
            LIMIT ?
        ");
        $salesStmt->execute([$coachId, (int)$limit]);
        $sales = $salesStmt->fetchAll();
        
        // Get transactions from active subscriptions (coach_member_list)
        // These represent subscription purchases
        $subscriptionsStmt = $pdo->prepare("
            SELECT 
                cml.id,
                CONCAT(u.fname, ' ', u.lname) as member_name,
                CASE 
                    WHEN cml.rate_type = 'monthly' THEN COALESCE(c.monthly_rate, 0)
                    WHEN cml.rate_type = 'package' THEN COALESCE(c.session_package_rate, 0)
                    WHEN cml.rate_type = 'per_session' THEN COALESCE(c.per_session_rate, 0) * COALESCE(cml.remaining_sessions, 0)
                    ELSE 0
                END as amount,
                cml.rate_type as type,
                DATE(cml.requested_at) as date,
                cml.requested_at as created_at,
                CASE 
                    WHEN cml.status = 'active' AND cml.coach_approval = 'approved' AND cml.staff_approval = 'approved' THEN 'completed'
                    WHEN cml.coach_approval = 'pending' OR cml.staff_approval = 'pending' THEN 'pending'
                    ELSE 'cancelled'
                END as status
            FROM coach_member_list cml
            LEFT JOIN user u ON cml.member_id = u.id
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.coach_id = ?
            ORDER BY cml.requested_at DESC
            LIMIT ?
        ");
        $subscriptionsStmt->execute([$coachId, (int)$limit]);
        $subscriptions = $subscriptionsStmt->fetchAll();
        
        // Combine and sort by date
        $allTransactions = array_merge($sales, $subscriptions);
        
        // Sort by created_at descending
        usort($allTransactions, function($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });
        
        // Limit to requested number
        $allTransactions = array_slice($allTransactions, 0, (int)$limit);
        
        // Format transactions
        $formattedTransactions = [];
        foreach ($allTransactions as $transaction) {
            $formattedTransactions[] = [
                'id' => (int)$transaction['id'],
                'member_name' => $transaction['member_name'] ?? 'Unknown Member',
                'amount' => (float)$transaction['amount'],
                'type' => ucfirst($transaction['type'] ?? 'N/A'),
                'date' => $transaction['date'],
                'status' => $transaction['status'] ?? 'completed'
            ];
        }
        
        sendResponse([
            'success' => true,
            'data' => [
                'transactions' => $formattedTransactions,
                'count' => count($formattedTransactions)
            ]
        ]);
        
    } catch (PDOException $e) {
        error_log("ERROR - Get transactions failed: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ], 500);
    } catch (Exception $e) {
        error_log("ERROR - General error: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ], 500);
    }
}

?>

