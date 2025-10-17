<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";


// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
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
        case 'get_notifications':
            // Get user notifications with pagination
            $page = intval($_GET['page'] ?? 1);
            $limit = intval($_GET['limit'] ?? 20);
            $offset = ($page - 1) * $limit;
            
            $notificationsStmt = $pdo->prepare("
                SELECT 
                    n.id,
                    n.message,
                    n.timestamp,
                    ns.status_name,
                    nt.type_name,
                    CASE 
                        WHEN ns.status_name = 'Unread' THEN 1 
                        ELSE 0 
                    END as is_unread
                FROM notification n
                LEFT JOIN notification_status ns ON n.status_id = ns.id
                LEFT JOIN notification_type nt ON n.type_id = nt.id
                WHERE n.user_id = ?
                ORDER BY n.timestamp DESC
                LIMIT " . intval($limit) . " OFFSET " . intval($offset)
            );
            $notificationsStmt->execute([$user_id]);
            $notifications = $notificationsStmt->fetchAll();

            // Get total count for pagination
            $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM notification WHERE user_id = ?");
            $countStmt->execute([$user_id]);
            $totalCount = $countStmt->fetch()['total'];

            // Get unread count
            $unreadStmt = $pdo->prepare("
                SELECT COUNT(*) as unread_count 
                FROM notification n
                LEFT JOIN notification_status ns ON n.status_id = ns.id
                WHERE n.user_id = ? AND ns.status_name = 'Unread'
            ");
            $unreadStmt->execute([$user_id]);
            $unreadCount = $unreadStmt->fetch()['unread_count'];

            sendResponse([
                'success' => true,
                'data' => [
                    'notifications' => $notifications,
                    'pagination' => [
                        'current_page' => $page,
                        'total_pages' => ceil($totalCount / $limit),
                        'total_count' => $totalCount,
                        'has_more' => $offset + $limit < $totalCount
                    ],
                    'unread_count' => $unreadCount
                ]
            ]);
            break;

        case 'mark_as_read':
            // Read JSON data from request body
            $input = json_decode(file_get_contents('php://input'), true);
            $notification_id = $input['notification_id'] ?? $_POST['notification_id'] ?? '';
            
            if (!$notification_id) {
                sendError('Notification ID is required', 400);
            }

            // Get the read status ID (use the first available Read status)
            $statusStmt = $pdo->prepare("SELECT id FROM notification_status WHERE status_name = 'Read' ORDER BY id LIMIT 1");
            $statusStmt->execute();
            $readStatusId = $statusStmt->fetch()['id'];

            if (!$readStatusId) {
                sendError('Read status not found', 500);
            }

            $updateStmt = $pdo->prepare("UPDATE notification SET status_id = ? WHERE id = ? AND user_id = ?");
            $updateStmt->execute([$readStatusId, $notification_id, $user_id]);

            if ($updateStmt->rowCount() > 0) {
                sendResponse(['success' => true, 'message' => 'Notification marked as read']);
            } else {
                sendError('Notification not found or already read', 404);
            }
            break;

        case 'mark_all_as_read':
            // Get the read status ID (use the first available Read status)
            $statusStmt = $pdo->prepare("SELECT id FROM notification_status WHERE status_name = 'Read' ORDER BY id LIMIT 1");
            $statusStmt->execute();
            $readStatusId = $statusStmt->fetch()['id'];

            if (!$readStatusId) {
                sendError('Read status not found', 500);
            }

            $updateStmt = $pdo->prepare("UPDATE notification SET status_id = ? WHERE user_id = ?");
            $updateStmt->execute([$readStatusId, $user_id]);

            sendResponse([
                'success' => true, 
                'message' => 'All notifications marked as read',
                'updated_count' => $updateStmt->rowCount()
            ]);
            break;

        case 'delete_notification':
            // Read JSON data from request body
            $input = json_decode(file_get_contents('php://input'), true);
            $notification_id = $input['notification_id'] ?? $_POST['notification_id'] ?? '';
            
            if (!$notification_id) {
                sendError('Notification ID is required', 400);
            }

            $deleteStmt = $pdo->prepare("DELETE FROM notification WHERE id = ? AND user_id = ?");
            $deleteStmt->execute([$notification_id, $user_id]);

            if ($deleteStmt->rowCount() > 0) {
                sendResponse(['success' => true, 'message' => 'Notification deleted']);
            } else {
                sendError('Notification not found', 404);
            }
            break;

        case 'clear_all':
            $deleteStmt = $pdo->prepare("DELETE FROM notification WHERE user_id = ?");
            $deleteStmt->execute([$user_id]);

            sendResponse([
                'success' => true, 
                'message' => 'All notifications cleared',
                'deleted_count' => $deleteStmt->rowCount()
            ]);
            break;

        case 'get_unread_count':
            $unreadStmt = $pdo->prepare("
                SELECT COUNT(*) as unread_count 
                FROM notification n
                LEFT JOIN notification_status ns ON n.status_id = ns.id
                WHERE n.user_id = ? AND ns.status_name = 'Unread'
            ");
            $unreadStmt->execute([$user_id]);
            $unreadCount = $unreadStmt->fetch()['unread_count'];

            sendResponse([
                'success' => true,
                'data' => [
                    'unread_count' => $unreadCount
                ]
            ]);
            break;

        case 'create_notification':
            // For testing or manual notification creation
            // Read JSON data from request body
            $input = json_decode(file_get_contents('php://input'), true);
            $message = $input['message'] ?? $_POST['message'] ?? '';
            $type_id = $input['type_id'] ?? $_POST['type_id'] ?? 1; // Default to info type
            
            if (!$message) {
                sendError('Message is required', 400);
            }

            // Get unread status ID
            $statusStmt = $pdo->prepare("SELECT id FROM notification_status WHERE status_name = 'Unread' LIMIT 1");
            $statusStmt->execute();
            $unreadStatusId = $statusStmt->fetch()['id'];

            if (!$unreadStatusId) {
                sendError('Unread status not found', 500);
            }

            $insertStmt = $pdo->prepare("
                INSERT INTO notification (user_id, message, status_id, type_id, timestamp) 
                VALUES (?, ?, ?, ?, NOW())
            ");
            $insertStmt->execute([$user_id, $message, $unreadStatusId, $type_id]);

            sendResponse([
                'success' => true, 
                'message' => 'Notification created',
                'notification_id' => $pdo->lastInsertId()
            ]);
            break;

        default:
            sendError('Invalid action', 400);
    }

} catch(PDOException $e) {
    error_log('Database error in notifications.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in notifications.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>
