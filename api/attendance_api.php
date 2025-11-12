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
    case 'checkin':
        checkIn($pdo);
        break;
    case 'checkout':
        checkOut($pdo);
        break;
    case 'status':
        getAttendanceStatus($pdo);
        break;
    case 'get_attendance':
        getAttendance($pdo);
        break;
    case 'history':
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
        
        // Parse QR data - support multiple formats
        $userId = null;
        $gymId = 1; // Default gym ID
        
        // Format 1: CNERGY_ATTENDANCE:user_id
        if (preg_match('/^CNERGY_ATTENDANCE:(\d+)$/', $qrData, $matches)) {
            $userId = (int)$matches[1];
        }
        // Format 2: user_id|gym_id
        else {
            $qrParts = explode('|', $qrData);
            if (count($qrParts) >= 2) {
                $userId = (int)$qrParts[0];
                $gymId = (int)$qrParts[1];
            } elseif (count($qrParts) == 1 && is_numeric($qrParts[0])) {
                // Just user_id provided
                $userId = (int)$qrParts[0];
            }
        }
        
        if (!$userId) {
            echo json_encode(['success' => false, 'error' => 'Invalid QR code format']);
            return;
        }
        
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
            SELECT id, check_in, check_out 
            FROM attendance 
            WHERE user_id = ? AND DATE(check_in) = CURDATE()
            ORDER BY check_in DESC 
            LIMIT 1
        ");
        $attendanceStmt->execute([$userId]);
        $currentAttendance = $attendanceStmt->fetch();
        
        if ($currentAttendance && $currentAttendance['check_out'] === null) {
            // User is checked in, perform check out
            $updateStmt = $pdo->prepare("
                UPDATE attendance 
                SET check_out = NOW() 
                WHERE id = ?
            ");
            $updateStmt->execute([$currentAttendance['id']]);
            
            // Combine first and last name
            $userName = trim(($user['fname'] ?? '') . ' ' . ($user['lname'] ?? ''));
            
            echo json_encode([
                'success' => true,
                'action' => 'checked_out',
                'message' => 'Successfully checked out',
                'user_name' => $userName,
                'check_in_time' => $currentAttendance['check_in'],
                'check_out_time' => date('Y-m-d H:i:s')
            ]);
        } else {
            // User is not checked in, perform check in
            $insertStmt = $pdo->prepare("
                INSERT INTO attendance (user_id, gym_id, check_in) 
                VALUES (?, ?, NOW())
            ");
            $insertStmt->execute([$userId, $gymId]);
            
            // Combine first and last name
            $userName = trim(($user['fname'] ?? '') . ' ' . ($user['lname'] ?? ''));
            
            echo json_encode([
                'success' => true,
                'action' => 'checked_in',
                'message' => 'Successfully checked in',
                'user_name' => $userName,
                'check_in_time' => date('Y-m-d H:i:s')
            ]);
        }
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}

function checkIn($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = $input['user_id'] ?? null;
        
        if (!$userId) {
            echo json_encode(['success' => false, 'error' => 'User ID is required']);
            return;
        }
        
        // Get user name
        $userStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE id = ?");
        $userStmt->execute([$userId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            echo json_encode(['success' => false, 'error' => 'User not found']);
            return;
        }
        
        // Check if already checked in today
        $attendanceStmt = $pdo->prepare("
            SELECT id, check_in, check_out 
            FROM attendance 
            WHERE user_id = ? AND DATE(check_in) = CURDATE()
            ORDER BY check_in DESC 
            LIMIT 1
        ");
        $attendanceStmt->execute([$userId]);
        $currentAttendance = $attendanceStmt->fetch();
        
        if ($currentAttendance && $currentAttendance['check_out'] === null) {
            echo json_encode([
                'success' => false,
                'error' => 'Already checked in. Please check out first.'
            ]);
            return;
        }
        
        // Get gym_id (default to 1 or get from user's subscription)
        $gymId = 1; // Default gym ID, you can modify this based on your logic
        
        // Insert check-in
        $insertStmt = $pdo->prepare("
            INSERT INTO attendance (user_id, gym_id, check_in) 
            VALUES (?, ?, NOW())
        ");
        $insertStmt->execute([$userId, $gymId]);
        
        // Combine first and last name
        $userName = trim(($user['fname'] ?? '') . ' ' . ($user['lname'] ?? ''));
        
        echo json_encode([
            'success' => true,
            'action' => 'checked_in',
            'message' => 'Successfully checked in',
            'user_name' => $userName,
            'check_in_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}

function checkOut($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = $input['user_id'] ?? null;
        
        if (!$userId) {
            echo json_encode(['success' => false, 'error' => 'User ID is required']);
            return;
        }
        
        // Get user name
        $userStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE id = ?");
        $userStmt->execute([$userId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            echo json_encode(['success' => false, 'error' => 'User not found']);
            return;
        }
        
        // Find the latest check-in for today
        $attendanceStmt = $pdo->prepare("
            SELECT id, check_in, check_out 
            FROM attendance 
            WHERE user_id = ? AND DATE(check_in) = CURDATE() 
            AND check_out IS NULL
            ORDER BY check_in DESC 
            LIMIT 1
        ");
        $attendanceStmt->execute([$userId]);
        $currentAttendance = $attendanceStmt->fetch();
        
        if (!$currentAttendance) {
            echo json_encode([
                'success' => false,
                'error' => 'No active check-in found'
            ]);
            return;
        }
        
        // Update check-out
        $updateStmt = $pdo->prepare("
            UPDATE attendance 
            SET check_out = NOW() 
            WHERE id = ?
        ");
        $updateStmt->execute([$currentAttendance['id']]);
        
        // Combine first and last name
        $userName = trim(($user['fname'] ?? '') . ' ' . ($user['lname'] ?? ''));
        
        echo json_encode([
            'success' => true,
            'action' => 'checked_out',
            'message' => 'Successfully checked out',
            'user_name' => $userName,
            'check_in_time' => $currentAttendance['check_in'],
            'check_out_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}

function getAttendanceStatus($pdo) {
    try {
        $userId = $_GET['user_id'] ?? '';
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'error' => 'User ID is required']);
            return;
        }
        
        // Get today's latest attendance record
        $stmt = $pdo->prepare("
            SELECT a.id, a.check_in, a.check_out, u.fname, u.lname
            FROM attendance a
            LEFT JOIN user u ON a.user_id = u.id
            WHERE a.user_id = ? AND DATE(a.check_in) = CURDATE()
            ORDER BY a.check_in DESC 
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $attendance = $stmt->fetch();
        
        if (!$attendance || $attendance['check_out'] !== null) {
            // Not checked in or already checked out
            echo json_encode([
                'success' => true,
                'is_checked_in' => false,
                'current_session' => null
            ]);
            return;
        }
        
        // User is currently checked in
        echo json_encode([
            'success' => true,
            'is_checked_in' => true,
            'current_session' => [
                'id' => $attendance['id'],
                'user_id' => $userId,
                'check_in' => $attendance['check_in'],
                'check_out' => null,
                'fname' => $attendance['fname'],
                'lname' => $attendance['lname']
            ]
        ]);
        
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
            SELECT id, check_in, check_out,
                   CASE 
                       WHEN check_out IS NULL THEN 'checked_in'
                       ELSE 'checked_out'
                   END as status
            FROM attendance 
            WHERE user_id = ? AND DATE(check_in) = CURDATE()
            ORDER BY check_in DESC 
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $attendance = $stmt->fetch();
        
        if (!$attendance) {
            echo json_encode([
                'success' => true,
                'data' => [
                    'status' => 'not_checked_in',
                    'check_in' => null,
                    'check_out' => null
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
        $limit = intval($_GET['limit'] ?? 30);
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'error' => 'User ID is required']);
            return;
        }
        
        // Get attendance history with user names
        // Note: Database columns are 'check_in' and 'check_out', not 'check_in_time' and 'check_out_time'
        // LIMIT must be an integer, so we use it directly in the query
        $stmt = $pdo->prepare("
            SELECT a.id, a.user_id, a.check_in, a.check_out,
                   u.fname, u.lname,
                   CASE 
                       WHEN a.check_out IS NULL THEN 'checked_in'
                       ELSE 'checked_out'
                   END as status,
                   TIMESTAMPDIFF(MINUTE, a.check_in, COALESCE(a.check_out, NOW())) as duration_minutes
            FROM attendance a
            LEFT JOIN user u ON a.user_id = u.id
            WHERE a.user_id = ?
            ORDER BY a.check_in DESC 
            LIMIT " . intval($limit) . "
        ");
        $stmt->execute([$userId]);
        $attendanceHistory = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format the data for the frontend
        $formattedHistory = array_map(function($record) {
            return [
                'id' => $record['id'],
                'user_id' => $record['user_id'],
                'check_in' => $record['check_in'],
                'check_out' => $record['check_out'],
                'fname' => $record['fname'],
                'lname' => $record['lname'],
                'status' => $record['status'],
                'duration_minutes' => $record['duration_minutes']
            ];
        }, $attendanceHistory);
        
        echo json_encode([
            'success' => true,
            'data' => $formattedHistory
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    }
}
?>
