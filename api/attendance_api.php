<?php
// CORS and JSON headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");
header("Access-Control-Max-Age: 86400");
header('Content-Type: application/json');

// Preflight
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
	http_response_code(200);
	exit();
}

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
	$pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
	$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
	$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
	echo json_encode(['success' => false, 'message' => 'Database connection failed']);
	exit;
}

// Get action from request
$action = '';
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = $_GET['action'] ?? '';
} else {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? $_POST['action'] ?? '';
}

// Route to appropriate functions
switch($action) {
    case 'scan':
        scanQRCode($pdo);
        break;
    case 'get_attendance':
        getAttendance($pdo);
        break;
    case 'get_attendance_history':
        getAttendanceHistory($pdo);
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
        break;
}

function scanQRCode($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $qrData = $input['qr_data'] ?? '';
        
        if (empty($qrData)) {
            echo json_encode(['success' => false, 'error' => 'QR data is required']);
            return;
        }
        
        // Parse QR data to get user_id and gym_id
        $qrParts = explode('|', $qrData);
        if (count($qrParts) < 2) {
            echo json_encode(['success' => false, 'error' => 'Invalid QR code format']);
            return;
        }
        
        $userId = $qrParts[0];
        $gymId = $qrParts[1];
        
        // Check if user exists
        $userStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE id = ?");
        $userStmt->execute([$userId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            echo json_encode(['success' => false, 'error' => 'User not found']);
            return;
        }
        
        // Check current attendance status
        $attendanceStmt = $pdo->prepare("
            SELECT id, check_in_time, check_out_time 
            FROM attendance 
            WHERE user_id = ? AND DATE(check_in_time) = CURDATE()
            ORDER BY check_in_time DESC 
            LIMIT 1
        ");
        $attendanceStmt->execute([$userId]);
        $currentAttendance = $attendanceStmt->fetch();
        
        if ($currentAttendance && $currentAttendance['check_out_time'] === null) {
            // User is checked in, perform check out
            $updateStmt = $pdo->prepare("
                UPDATE attendance 
                SET check_out_time = NOW() 
                WHERE id = ?
            ");
            $updateStmt->execute([$currentAttendance['id']]);
            
            echo json_encode([
                'success' => true,
                'action' => 'check_out',
                'message' => 'Successfully checked out',
                'user' => $user,
                'check_in_time' => $currentAttendance['check_in_time'],
                'check_out_time' => date('Y-m-d H:i:s')
            ]);
        } else {
            // User is not checked in, perform check in
            $insertStmt = $pdo->prepare("
                INSERT INTO attendance (user_id, gym_id, check_in_time) 
                VALUES (?, ?, NOW())
            ");
            $insertStmt->execute([$userId, $gymId]);
            
            echo json_encode([
                'success' => true,
                'action' => 'check_in',
                'message' => 'Successfully checked in',
                'user' => $user,
                'check_in_time' => date('Y-m-d H:i:s')
            ]);
        }
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}

function getAttendance($pdo) {
    try {
        $userId = $_GET['user_id'] ?? '';
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'error' => 'User ID is required']);
            return;
        }
        
        // Get today's attendance
        $stmt = $pdo->prepare("
            SELECT id, check_in_time, check_out_time,
                   CASE 
                       WHEN check_out_time IS NULL THEN 'checked_in'
                       ELSE 'checked_out'
                   END as status
            FROM attendance 
            WHERE user_id = ? AND DATE(check_in_time) = CURDATE()
            ORDER BY check_in_time DESC 
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $attendance = $stmt->fetch();
        
        if (!$attendance) {
            echo json_encode([
                'success' => true,
                'data' => [
                    'status' => 'not_checked_in',
                    'check_in_time' => null,
                    'check_out_time' => null
                ]
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $attendance
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}

function getAttendanceHistory($pdo) {
    try {
        $userId = $_GET['user_id'] ?? '';
        $limit = $_GET['limit'] ?? 30;
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'error' => 'User ID is required']);
            return;
        }
        
        // Get attendance history
        $stmt = $pdo->prepare("
            SELECT id, check_in_time, check_out_time,
                   CASE 
                       WHEN check_out_time IS NULL THEN 'checked_in'
                       ELSE 'checked_out'
                   END as status,
                   TIMESTAMPDIFF(MINUTE, check_in_time, COALESCE(check_out_time, NOW())) as duration_minutes
            FROM attendance 
            WHERE user_id = ?
            ORDER BY check_in_time DESC 
            LIMIT ?
        ");
        $stmt->execute([$userId, $limit]);
        $attendanceHistory = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $attendanceHistory
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}
?>






