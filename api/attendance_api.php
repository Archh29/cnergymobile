<?php
// Database configuration
$host = "127.0.0.1:3306";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed. Please check your database configuration.',
        'details' => $e->getMessage()
    ]);
    exit();
}

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get request method and parse JSON input
$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

if ($input === null && $method === 'POST') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Invalid JSON input'
    ]);
    exit();
}

// Route requests
switch ($method) {
    case 'POST':
        $action = $input['action'] ?? '';
        switch ($action) {
            case 'scan':
                scanQRCode($pdo, $input);
                break;
            case 'checkin':
                checkIn($pdo, $input);
                break;
            case 'checkout':
                checkOut($pdo, $input);
                break;
            default:
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'Invalid action'
                ]);
                break;
        }
        break;
    default:
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'error' => 'Method not allowed'
        ]);
        break;
}

function scanQRCode($pdo, $input) {
    try {
        $qrData = $input['qr_data'] ?? '';
        
        if (empty($qrData)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'QR data is required'
            ]);
            return;
        }
        
        // Parse QR data to determine type
        $qrInfo = parseQRData($qrData);
        
        if (!$qrInfo) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Invalid QR code format'
            ]);
            return;
        }
        
        if ($qrInfo['type'] === 'user') {
            // Handle user attendance
            handleUserAttendance($pdo, $qrInfo);
        } elseif ($qrInfo['type'] === 'guest') {
            // Handle guest attendance
            handleGuestAttendance($pdo, $qrInfo);
        } else {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Unknown QR code type'
            ]);
            return;
        }
        
    } catch (Exception $e) {
        error_log('QR scan error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Internal server error: ' . $e->getMessage()
        ]);
    }
}

function parseQRData($qrData) {
    // Check if it's a user QR code: CNERGY_ATTENDANCE:user_id
    if (preg_match('/^CNERGY_ATTENDANCE:(\d+)$/', $qrData, $matches)) {
        return [
            'type' => 'user',
            'user_id' => (int)$matches[1]
        ];
    }
    
    // Check if it's a guest QR code: CNERGY_GUEST_ATTENDANCE:guest_session_id:expires_at
    if (preg_match('/^CNERGY_GUEST_ATTENDANCE:(\d+):(\d+)$/', $qrData, $matches)) {
        $sessionId = (int)$matches[1];
        $expiresAt = (int)$matches[2];
        
        // Check if QR code has expired
        if (time() * 1000 > $expiresAt) {
            return [
                'type' => 'guest',
                'session_id' => $sessionId,
                'expired' => true
            ];
        }
        
        return [
            'type' => 'guest',
            'session_id' => $sessionId,
            'expired' => false
        ];
    }
    
    return null;
}

function handleUserAttendance($pdo, $qrInfo) {
    try {
        $userId = $qrInfo['user_id'];
        
        // Check if user exists
        $stmt = $pdo->prepare("SELECT id, full_name FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'error' => 'User not found'
            ]);
            return;
        }
        
        // Check current attendance status
        $stmt = $pdo->prepare("
            SELECT id, check_in_time, check_out_time 
            FROM attendance_log 
            WHERE user_id = ? AND DATE(check_in_time) = CURDATE()
            ORDER BY check_in_time DESC 
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $attendance = $stmt->fetch();
        
        if (!$attendance || $attendance['check_out_time']) {
            // Check in
            $stmt = $pdo->prepare("
                INSERT INTO attendance_log (user_id, check_in_time, status) 
                VALUES (?, NOW(), 'checked_in')
            ");
            $stmt->execute([$userId]);
            
            echo json_encode([
                'success' => true,
                'action' => 'checked_in',
                'message' => 'Successfully checked in',
                'user_name' => $user['full_name'],
                'check_in_time' => date('Y-m-d H:i:s')
            ]);
        } else {
            // Check out
            $stmt = $pdo->prepare("
                UPDATE attendance_log 
                SET check_out_time = NOW(), status = 'checked_out' 
                WHERE id = ?
            ");
            $stmt->execute([$attendance['id']]);
            
            echo json_encode([
                'success' => true,
                'action' => 'checked_out',
                'message' => 'Successfully checked out',
                'user_name' => $user['full_name'],
                'check_out_time' => date('Y-m-d H:i:s')
            ]);
        }
        
    } catch (Exception $e) {
        error_log('User attendance error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Failed to process user attendance: ' . $e->getMessage()
        ]);
    }
}

function handleGuestAttendance($pdo, $qrInfo) {
    try {
        $sessionId = $qrInfo['session_id'];
        
        if ($qrInfo['expired']) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Guest QR code has expired'
            ]);
            return;
        }
        
        // Check if guest session exists and is valid
        $stmt = $pdo->prepare("
            SELECT id, guest_name, status, paid 
            FROM guest_session 
            WHERE id = ? AND status = 'approved'
        ");
        $stmt->execute([$sessionId]);
        $session = $stmt->fetch();
        
        if (!$session) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'error' => 'Guest session not found or not approved'
            ]);
            return;
        }
        
        // Check if guest has already checked in today
        $stmt = $pdo->prepare("
            SELECT id, check_in_time, check_out_time 
            FROM attendance_log 
            WHERE guest_session_id = ? AND DATE(check_in_time) = CURDATE()
            ORDER BY check_in_time DESC 
            LIMIT 1
        ");
        $stmt->execute([$sessionId]);
        $attendance = $stmt->fetch();
        
        if (!$attendance || $attendance['check_out_time']) {
            // Check in guest
            $stmt = $pdo->prepare("
                INSERT INTO attendance_log (guest_session_id, check_in_time, status, guest_name) 
                VALUES (?, NOW(), 'checked_in', ?)
            ");
            $stmt->execute([$sessionId, $session['guest_name']]);
            
            echo json_encode([
                'success' => true,
                'action' => 'checked_in',
                'message' => 'Guest successfully checked in',
                'guest_name' => $session['guest_name'],
                'session_id' => $sessionId,
                'check_in_time' => date('Y-m-d H:i:s')
            ]);
        } else {
            // Check out guest
            $stmt = $pdo->prepare("
                UPDATE attendance_log 
                SET check_out_time = NOW(), status = 'checked_out' 
                WHERE id = ?
            ");
            $stmt->execute([$attendance['id']]);
            
            echo json_encode([
                'success' => true,
                'action' => 'checked_out',
                'message' => 'Guest successfully checked out',
                'guest_name' => $session['guest_name'],
                'session_id' => $sessionId,
                'check_out_time' => date('Y-m-d H:i:s')
            ]);
        }
        
    } catch (Exception $e) {
        error_log('Guest attendance error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Failed to process guest attendance: ' . $e->getMessage()
        ]);
    }
}

function checkIn($pdo, $input) {
    // Manual check-in functionality
    $userId = $input['user_id'] ?? null;
    
    if (!$userId) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'User ID is required'
        ]);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO attendance_log (user_id, check_in_time, status) 
            VALUES (?, NOW(), 'checked_in')
        ");
        $stmt->execute([$userId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Successfully checked in',
            'check_in_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (Exception $e) {
        error_log('Manual check-in error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Failed to check in: ' . $e->getMessage()
        ]);
    }
}

function checkOut($pdo, $input) {
    // Manual check-out functionality
    $userId = $input['user_id'] ?? null;
    
    if (!$userId) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'User ID is required'
        ]);
        return;
    }
    
    try {
        // Find the latest check-in for today
        $stmt = $pdo->prepare("
            SELECT id FROM attendance_log 
            WHERE user_id = ? AND DATE(check_in_time) = CURDATE() 
            AND check_out_time IS NULL
            ORDER BY check_in_time DESC 
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $attendance = $stmt->fetch();
        
        if (!$attendance) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'No active check-in found'
            ]);
            return;
        }
        
        $stmt = $pdo->prepare("
            UPDATE attendance_log 
            SET check_out_time = NOW(), status = 'checked_out' 
            WHERE id = ?
        ");
        $stmt->execute([$attendance['id']]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Successfully checked out',
            'check_out_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (Exception $e) {
        error_log('Manual check-out error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Failed to check out: ' . $e->getMessage()
        ]);
    }
}
?>