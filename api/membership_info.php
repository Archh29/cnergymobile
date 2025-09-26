<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration for remote server
$host = 'localhost';
$dbname = 'u773938685_cnergydb';
$username = 'u773938685_archh29';
$password = 'Gwapoko385@';

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Function to send JSON response
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// Function to send error response
function sendError($message, $statusCode = 400) {
    http_response_code($statusCode);
    echo json_encode(['error' => $message], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    // Database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Get action from request
    $action = $_GET['action'] ?? $_POST['action'] ?? '';
    $user_id = $_GET['user_id'] ?? $_POST['user_id'] ?? '';

    if (!$user_id) {
        sendError('User ID is required', 400);
    }

    switch ($action) {
        case 'get_membership':
            // Get user's membership information
            $membershipStmt = $pdo->prepare("
                SELECT 
                    s.id,
                    s.user_id,
                    s.plan_id,
                    s.status_id,
                    s.start_date,
                    s.end_date,
                    s.discounted_price,
                    ss.status_name,
                    msp.plan_name,
                    msp.price,
                    msp.duration_months
                FROM subscription s
                LEFT JOIN subscription_status ss ON s.status_id = ss.id
                LEFT JOIN member_subscription_plan msp ON s.plan_id = msp.id
                WHERE s.user_id = ? 
                AND s.status_id = 2 
                ORDER BY s.end_date DESC 
                LIMIT 1
            ");
            $membershipStmt->execute([$user_id]);
            $membership = $membershipStmt->fetch();

            if (!$membership) {
                // No active membership found
                sendResponse([
                    'success' => true,
                    'data' => [
                        'has_membership' => false,
                        'message' => 'No active membership found'
                    ]
                ]);
            }

            // Calculate membership duration and days remaining
            $startDate = new DateTime($membership['start_date']);
            $endDate = new DateTime($membership['end_date']);
            $today = new DateTime();
            
            // Calculate total duration in days
            $totalDuration = $startDate->diff($endDate)->days;
            
            // Calculate days remaining
            $daysRemaining = $today->diff($endDate)->days;
            if ($endDate < $today) {
                $daysRemaining = 0; // Expired
            }
            
            // Calculate days used
            $daysUsed = $startDate->diff($today)->days;
            if ($daysUsed > $totalDuration) {
                $daysUsed = $totalDuration;
            }
            
            // Calculate percentage used
            $percentageUsed = $totalDuration > 0 ? ($daysUsed / $totalDuration) * 100 : 0;
            
            // Determine membership type
            $membershipType = 'Monthly';
            if ($membership['duration_months'] >= 12) {
                $membershipType = 'Annual';
            } elseif ($membership['duration_months'] > 1) {
                $membershipType = $membership['duration_months'] . ' Months';
            }

            sendResponse([
                'success' => true,
                'data' => [
                    'has_membership' => true,
                    'plan_name' => $membership['plan_name'],
                    'membership_type' => $membershipType,
                    'start_date' => $membership['start_date'],
                    'end_date' => $membership['end_date'],
                    'status' => $membership['status_name'],
                    'price' => $membership['discounted_price'] ?? $membership['price'],
                    'total_duration_days' => $totalDuration,
                    'days_remaining' => $daysRemaining,
                    'days_used' => $daysUsed,
                    'percentage_used' => round($percentageUsed, 1),
                    'is_expired' => $endDate < $today,
                    'is_expiring_soon' => $daysRemaining <= 7 && $daysRemaining > 0
                ]
            ]);
            break;

        default:
            sendError('Invalid action', 400);
    }

} catch(PDOException $e) {
    error_log('Database error in membership_info.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in membership_info.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>

















